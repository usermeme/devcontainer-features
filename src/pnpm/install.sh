#!/usr/bin/env bash
set -e

FEATURE=pnpm
# shellcheck source=../../lib/common.sh
source "$(dirname "$0")/common.sh"

VERSION="${VERSION:-latest}"
RUNINSTALL="${RUNINSTALL:-false}"
FROZENLOCKFILE="${FROZENLOCKFILE:-true}"

log "Installing pnpm feature (version: $VERSION)..."

if ! command -v curl &>/dev/null; then
  install_packages curl ca-certificates
fi

resolve_build_owner

# Install or enable pnpm: Corepack first, then npm, then the standalone binary
# A failed `prepare` still leaves the Corepack shim on PATH, which would skip the fallbacks
# below and silently ignore a pinned version: fail the build instead.
if command -v corepack &>/dev/null && ! corepack_activate pnpm "$VERSION"; then
  [ "$VERSION" = "latest" ] || die "Corepack could not activate pnpm@$VERSION (offline, or unknown version)."
  warn "Corepack could not pre-download pnpm; it will be fetched on first use."
fi

if ! command -v pnpm &>/dev/null; then
  if command -v npm &>/dev/null; then
    log "Installing pnpm via npm..."
    npm install -g "pnpm@$VERSION"
  else
    # System-wide location: the installer's default (root's ~/.local/share/pnpm) sits under
    # /root, which is mode 700, so the binary would be unusable for any other user.
    log "Installing standalone pnpm binary..."
    PNPM_INSTALLER="$(mktemp)"
    fetch https://get.pnpm.io/install.sh "$PNPM_INSTALLER" || die "could not download the pnpm installer"
    PNPM_HOME=/usr/local/share/pnpm-standalone PNPM_VERSION="$VERSION" SHELL=bash sh "$PNPM_INSTALLER"
    rm -f "$PNPM_INSTALLER"
    # pnpm < 11 puts the binary in $PNPM_HOME, newer releases in $PNPM_HOME/bin
    for PNPM_BIN in /usr/local/share/pnpm-standalone/bin/pnpm /usr/local/share/pnpm-standalone/pnpm; do
      if [ -x "$PNPM_BIN" ]; then
        ln -sf "$PNPM_BIN" /usr/local/bin/pnpm
        break
      fi
    done
  fi
fi
command -v pnpm &>/dev/null || die "pnpm $VERSION could not be installed."

# PNPM_HOME holds global binaries and is first on PATH: owned by the remote user, never 777.
ensure_owned_dir "$NODE_HOME" .local/share/pnpm/store 755

# Setup system-wide environment variables
mkdir -p /etc/profile.d
cat <<'PROFILE' >/etc/profile.d/pnpm.sh
export PNPM_HOME="/home/node/.local/share/pnpm"
export PNPM_CONFIG_STORE_DIR="/home/node/.local/share/pnpm/store"
export COREPACK_HOME="/usr/local/share/corepack"
export PATH="/home/node/.local/share/pnpm:/home/node/.local/share/pnpm/bin:/usr/local/share/corepack-shims:$PATH"
PROFILE
chmod 644 /etc/profile.d/pnpm.sh

persist_options RUNINSTALL FROZENLOCKFILE
install_runtime setup-pnpm.sh

log "pnpm feature installed successfully."
