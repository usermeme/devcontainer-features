#!/usr/bin/env bash
# install-kilocode.sh [VERSION]: install the prebuilt Kilo Code CLI into /usr/local/lib/kilocode (as root).
# Used by install.sh at build time and by setup-kilocode.sh when the build had no network.
#
# The npm package `@kilocode/cli` is only a Node wrapper around the per-platform package
# @kilocode/cli-linux-<arch>[-baseline][-musl], a self-contained Bun binary plus the resources
# it loads from next to itself (tree-sitter WASM grammars, bwrap sandbox, console web UI).
# Installing that package directly keeps Node out of the requirements. The whole package dir is
# kept, not just the binary: it finds those resources at <binary>/../.
# Exit codes: 0 installed, 1 not installed (offline, unsupported platform), 2 checksum mismatch.
set -e

log() { echo "[kilocode] $*"; }
warn() { echo "[kilocode] WARNING: $*" >&2; }
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
PREFIX="/usr/local/lib/kilocode"

if [ "$(id -u)" != "0" ]; then
  warn "install-kilocode.sh must run as root"
  exit 1
fi

# The version ends up in a URL: allow dist-tags and semver only.
if ! [[ "$VERSION" =~ ^[0-9A-Za-z][0-9A-Za-z.+-]*$ ]]; then
  warn "invalid version '$VERSION'"
  exit 1
fi

case "$(uname -m)" in
  arm64 | aarch64) KILO_ARCH="arm64" ;;
  x86_64 | amd64) KILO_ARCH="x64" ;;
  *)
    warn "no prebuilt Kilo Code CLI for $(uname -m)"
    exit 1
    ;;
esac

# Variant selection mirrors the upstream wrapper's packageNames() (postinstall.mjs in
# @kilocode/cli): x64 CPUs without AVX2 need the baseline build (the default one crashes
# with "Illegal instruction"), musl-based systems (Alpine) need the dedicated build.
KILO_VARIANT=""
if [ "$KILO_ARCH" = "x64" ] && ! grep -qwi avx2 /proc/cpuinfo 2>/dev/null; then
  KILO_VARIANT="-baseline"
fi
if [ -f /etc/alpine-release ] || (command -v ldd >/dev/null 2>&1 && ldd --version 2>&1 | grep -qi musl); then
  KILO_VARIANT="$KILO_VARIANT-musl"
fi
PKG="cli-linux-$KILO_ARCH$KILO_VARIANT"

if ! command -v curl &>/dev/null || ! command -v tar &>/dev/null; then
  install_packages curl tar ca-certificates || true
fi

TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

# Version metadata from the npm registry resolves dist-tags (latest, rc) and carries the
# tarball's sha512, so a tampered or truncated download is rejected before it is installed.
if ! curl -fsSL --proto '=https' --tlsv1.2 --retry 3 "https://registry.npmjs.org/@kilocode/$PKG/$VERSION" -o "$TMP_DIR/meta.json"; then
  warn "could not resolve Kilo Code CLI version '$VERSION' from registry.npmjs.org"
  exit 1
fi
RESOLVED="$(grep -o '"version":"[^"]*"' "$TMP_DIR/meta.json" | head -n 1 | cut -d'"' -f4)"
INTEGRITY="$(grep -o '"integrity":"sha512-[^"]*"' "$TMP_DIR/meta.json" | head -n 1 | cut -d'"' -f4)"
if ! [[ "$RESOLVED" =~ ^[0-9]+\.[0-9]+\.[0-9]+[0-9A-Za-z.+-]*$ ]]; then
  warn "unexpected registry response for Kilo Code CLI '$VERSION'"
  exit 1
fi

log "Downloading Kilo Code CLI $RESOLVED ($PKG)..."
if ! curl -fsSL --proto '=https' --tlsv1.2 --retry 3 "https://registry.npmjs.org/@kilocode/$PKG/-/$PKG-$RESOLVED.tgz" -o "$TMP_DIR/kilo.tgz"; then
  warn "Kilo Code CLI download failed"
  exit 1
fi

if [ -z "$INTEGRITY" ]; then
  warn "registry response for Kilo Code CLI $RESOLVED has no sha512; not installing an unverified download"
  exit 1
fi
command -v openssl >/dev/null 2>&1 || install_packages openssl || true
if ! command -v openssl >/dev/null 2>&1; then
  warn "openssl is not available to verify the download; not installing Kilo Code CLI"
  exit 1
fi
ACTUAL="sha512-$(openssl dgst -sha512 -binary "$TMP_DIR/kilo.tgz" | openssl base64 -A)"
if [ "$ACTUAL" != "$INTEGRITY" ]; then
  echo "[kilocode] ERROR: checksum mismatch for $PKG-$RESOLVED.tgz (expected $INTEGRITY, got $ACTUAL); not installing it" >&2
  exit 2
fi

tar --no-same-owner -xzf "$TMP_DIR/kilo.tgz" -C "$TMP_DIR"
[ -f "$TMP_DIR/package/bin/kilo" ] || {
  warn "unexpected Kilo Code CLI package layout (no bin/kilo)"
  exit 1
}

# Root-owned and not writable by the container user: a user-writable binary on PATH could be
# replaced by any process in the container. Updates go through this script, not self-update.
rm -rf "$PREFIX"
mkdir -p "$(dirname "$PREFIX")"
mv "$TMP_DIR/package" "$PREFIX"
chown -R root:root "$PREFIX"
chmod -R go-w "$PREFIX"
chmod 755 "$PREFIX/bin/kilo" "$PREFIX/bin/bwrap" "$PREFIX/bin/kilo-sandbox-seccomp"

# A shim, not a symlink: Bun does not read the OS trust store, so NODE_EXTRA_CA_CERTS hands it
# the system CA bundle (without that, a company CA added to the image — TLS-inspecting proxies —
# fails every request), and the upstream Node wrapper's KILO_TREE_SITTER_WASM_DIR must be set
# the same way for the WASM grammars shipped next to the binary. rm first: writing through an
# old symlink would overwrite the binary.
rm -f /usr/local/bin/kilo /usr/local/bin/kilocode
cat >/usr/local/bin/kilo <<EOF
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
if [ -z "\${KILO_TREE_SITTER_WASM_DIR:-}" ] && [ -f "$PREFIX/bin/tree-sitter/tree-sitter.wasm" ]; then
  KILO_TREE_SITTER_WASM_DIR="$PREFIX/bin/tree-sitter"
  export KILO_TREE_SITTER_WASM_DIR
fi
exec $PREFIX/bin/kilo "\$@"
EOF
chmod 755 /usr/local/bin/kilo
# The npm package exposes both names for the same binary.
ln -s /usr/local/bin/kilo /usr/local/bin/kilocode

log "Kilo Code CLI $RESOLVED installed to $PREFIX."
