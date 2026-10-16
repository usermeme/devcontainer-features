#!/usr/bin/env bash
# install-cline.sh [VERSION]: install the prebuilt Cline CLI into /usr/local/lib/cline (as root).
# Used by install.sh at build time and by setup-cline.sh when the build had no network.
#
# The npm package `cline` is only a Node wrapper around the per-platform package
# @cline/cli-linux-<arch>, a self-contained binary with Bun embedded. Installing that package
# directly keeps Node out of the requirements. The whole package dir is kept, not just the
# binary: it finds extensions/ (plugin sandbox) at <binary>/../../extensions.
# Exit codes: 0 installed, 1 not installed (offline, unsupported platform), 2 checksum mismatch.
set -e

log() { echo "[cline] $*"; }
warn() { echo "[cline] WARNING: $*" >&2; }
install_packages() {
  if command -v apt-get &>/dev/null; then
    apt-get update -y && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends "$@" && rm -rf /var/lib/apt/lists/*
  elif command -v dnf &>/dev/null; then
    dnf install -y "$@"
  else
    return 1
  fi
}

VERSION="${1:-latest}"
PREFIX="/usr/local/lib/cline"

if [ "$(id -u)" != "0" ]; then
  warn "install-cline.sh must run as root"
  exit 1
fi

# The version ends up in a URL: allow dist-tags and semver only.
if ! [[ "$VERSION" =~ ^[0-9A-Za-z][0-9A-Za-z.+-]*$ ]]; then
  warn "invalid version '$VERSION'"
  exit 1
fi

case "$(uname -m)" in
  arm64 | aarch64) CLINE_ARCH="arm64" ;;
  x86_64 | amd64) CLINE_ARCH="x64" ;;
  *)
    warn "no prebuilt Cline CLI for $(uname -m)"
    exit 1
    ;;
esac

# The prebuilt binary links against glibc
if [ -f /etc/alpine-release ] || (command -v ldd >/dev/null 2>&1 && ldd --version 2>&1 | grep -qi musl); then
  warn "no prebuilt Cline CLI for musl-based images (Alpine); install it with: npm install -g cline"
  exit 1
fi

if ! command -v curl &>/dev/null || ! command -v tar &>/dev/null; then
  install_packages curl tar ca-certificates || true
fi

PKG="cli-linux-$CLINE_ARCH"
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

# Version metadata from the npm registry resolves dist-tags (latest, nightly) and carries the
# tarball's sha512, so a tampered or truncated download is rejected before it is installed.
if ! curl -fsSL --proto '=https' --tlsv1.2 --retry 3 "https://registry.npmjs.org/@cline/$PKG/$VERSION" -o "$TMP_DIR/meta.json"; then
  warn "could not resolve Cline CLI version '$VERSION' from registry.npmjs.org"
  exit 1
fi
RESOLVED="$(grep -o '"version":"[^"]*"' "$TMP_DIR/meta.json" | head -n 1 | cut -d'"' -f4)"
INTEGRITY="$(grep -o '"integrity":"sha512-[^"]*"' "$TMP_DIR/meta.json" | head -n 1 | cut -d'"' -f4)"
if ! [[ "$RESOLVED" =~ ^[0-9]+\.[0-9]+\.[0-9]+[0-9A-Za-z.+-]*$ ]]; then
  warn "unexpected registry response for Cline CLI '$VERSION'"
  exit 1
fi

log "Downloading Cline CLI $RESOLVED ($PKG)..."
if ! curl -fsSL --proto '=https' --tlsv1.2 --retry 3 "https://registry.npmjs.org/@cline/$PKG/-/$PKG-$RESOLVED.tgz" -o "$TMP_DIR/cline.tgz"; then
  warn "Cline CLI download failed"
  exit 1
fi

if [ -z "$INTEGRITY" ]; then
  warn "registry response for Cline CLI $RESOLVED has no sha512; not installing an unverified download"
  exit 1
fi
command -v openssl >/dev/null 2>&1 || install_packages openssl || true
if ! command -v openssl >/dev/null 2>&1; then
  warn "openssl is not available to verify the download; not installing Cline CLI"
  exit 1
fi
ACTUAL="sha512-$(openssl dgst -sha512 -binary "$TMP_DIR/cline.tgz" | openssl base64 -A)"
if [ "$ACTUAL" != "$INTEGRITY" ]; then
  echo "[cline] ERROR: checksum mismatch for $PKG-$RESOLVED.tgz (expected $INTEGRITY, got $ACTUAL); not installing it" >&2
  exit 2
fi

tar --no-same-owner -xzf "$TMP_DIR/cline.tgz" -C "$TMP_DIR"
[ -f "$TMP_DIR/package/bin/cline" ] || {
  warn "unexpected Cline CLI package layout (no bin/cline)"
  exit 1
}

# Root-owned and not writable by the container user: a user-writable binary on PATH could be
# replaced by any process in the container. Updates go through this script, not self-update.
rm -rf "$PREFIX"
mkdir -p "$(dirname "$PREFIX")"
mv "$TMP_DIR/package" "$PREFIX"
chown -R root:root "$PREFIX"
chmod -R go-w "$PREFIX"
chmod 755 "$PREFIX/bin/cline"

# A shim, not a symlink: Bun does not read the OS trust store, so the npm wrapper hands it the
# system CA bundle through NODE_EXTRA_CA_CERTS. Without that, a company CA added to the image
# (TLS-inspecting proxies) fails every request. rm first: writing through an old symlink would
# overwrite the binary.
rm -f /usr/local/bin/cline
cat >/usr/local/bin/cline <<EOF
#!/bin/sh
if [ -z "\${NODE_EXTRA_CA_CERTS:-}" ]; then
  for ca in /etc/ssl/certs/ca-certificates.crt /etc/pki/tls/certs/ca-bundle.crt; do
    if [ -r "\$ca" ]; then
      NODE_EXTRA_CA_CERTS="\$ca"
      export NODE_EXTRA_CA_CERTS
      break
    fi
  done
fi
exec $PREFIX/bin/cline "\$@"
EOF
chmod 755 /usr/local/bin/cline

log "Cline CLI $RESOLVED installed to $PREFIX."
