#!/usr/bin/env bash
set -e

FEATURE=opencode
# shellcheck source=../../lib/common.sh
source "$(dirname "$0")/common.sh"

VERSION="${VERSION:-latest}"

log "Installing OpenCode feature (version: $VERSION)..."

ensure_download_tools

# OpenCode creates four XDG dirs on startup (packages/util/src/global.ts in the opencode repo):
# config is bind-mounted from the host, data is the opencode-data volume (Docker seeds a new
# volume with this dir's ownership), state and cache are container-local. All of them and
# their ancestors must belong to the remote user, or OpenCode fails with
#   Error: EACCES: permission denied, mkdir '/home/node/.local/state'
resolve_build_owner
for rel in .config/opencode .local/share/opencode .local/state/opencode .cache/opencode .opencode/bin; do
  ensure_owned_dir "$NODE_HOME" "$rel" 755
done

# Detect architecture and libc for the official OpenCode binary
ARCH=$(uname -m)
case "$ARCH" in
  arm64 | aarch64) OC_ARCH="arm64" ;;
  x86_64 | amd64) OC_ARCH="x64" ;;
  *) OC_ARCH="" ;;
esac

OC_TARGET=""
if [ -n "$OC_ARCH" ]; then
  OC_TARGET="linux-$OC_ARCH"
  # x64 CPUs without AVX2 need the baseline build
  if [ "$OC_ARCH" = "x64" ] && ! grep -qwi avx2 /proc/cpuinfo 2>/dev/null; then
    OC_TARGET="$OC_TARGET-baseline"
  fi
  # musl-based systems (Alpine) need the dedicated build
  if [ -f /etc/alpine-release ] || (command -v ldd >/dev/null 2>&1 && ldd --version 2>&1 | grep -qi musl); then
    OC_TARGET="$OC_TARGET-musl"
  fi
fi

# Best effort: when the build has no network access, setup-opencode.sh retries at container startup
if [ "$VERSION" = "latest" ] && [ -n "$OC_TARGET" ]; then
  OC_URL="https://opencode.ai/update/api/latest/cli/opencode/opencode-$OC_TARGET.tar.gz"
  log "Downloading OpenCode from $OC_URL..."
  TMP_DIR=$(mktemp -d)
  if fetch "$OC_URL" "$TMP_DIR/opencode.tar.gz"; then
    tar -xzf "$TMP_DIR/opencode.tar.gz" -C "$TMP_DIR"
    OC_BIN=$(find "$TMP_DIR" -type f -name opencode | head -n 1)
    if [ -n "$OC_BIN" ]; then
      cp "$OC_BIN" /usr/local/bin/opencode
      chmod 755 /usr/local/bin/opencode
    fi
  else
    warn "OpenCode download failed; setup-opencode.sh will retry during postCreate."
  fi
  rm -rf "$TMP_DIR"
elif [ "$VERSION" != "latest" ]; then
  # Pinned versions are resolved by the official installer (npm registry packages)
  log "Installing OpenCode $VERSION via the official installer..."
  TMP_HOME=$(mktemp -d)
  if fetch https://opencode.ai/v2/install "$TMP_HOME/install.sh"; then
    HOME="$TMP_HOME" bash "$TMP_HOME/install.sh" --version "$VERSION" --no-modify-path || warn "official installer failed for version $VERSION."
    if [ -f "$TMP_HOME/.opencode/bin/opencode" ]; then
      cp "$TMP_HOME/.opencode/bin/opencode" /usr/local/bin/opencode
      chmod 755 /usr/local/bin/opencode
    fi
  else
    warn "OpenCode installer download failed; setup-opencode.sh will retry during postCreate."
  fi
  rm -rf "$TMP_HOME"
fi

# Verify the binary can execute (glibc/baseline compatibility check)
if [ -f /usr/local/bin/opencode ] && ! /usr/local/bin/opencode --version &>/dev/null; then
  log "Prebuilt OpenCode binary is not runnable on this base image; setup-opencode.sh will retry during postCreate."
  rm -f /usr/local/bin/opencode
fi

if [ -f /usr/local/bin/opencode ]; then
  log "OpenCode $(/usr/local/bin/opencode --version 2>/dev/null | head -n 1) installed to /usr/local/bin/opencode."
fi

persist_options VERSION
install_runtime setup-opencode.sh

log "OpenCode feature installed successfully."
