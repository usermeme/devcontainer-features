#!/usr/bin/env bash
# postCreate, as node: install the Cline CLI if the build was offline.
set -e

log() { echo "[cline] $*"; }
warn() { echo "[cline] WARNING: $*" >&2; }
as_root() { if [ "$(id -u)" = 0 ]; then "$@"; else sudo -n "$@"; fi; }

# shellcheck disable=SC1091
. /usr/local/share/cline/options.env

log "Setting up Cline environment..."

# ~/.cline/data/settings is the developer's host directory: never chown it.
SETTINGS_DIR="$HOME/.cline/data/settings"
[ ! -e "$SETTINGS_DIR" ] || [ -w "$SETTINGS_DIR" ] || warn "$SETTINGS_DIR is not writable by $(id -un); fix its ownership on the host."

if ! command -v cline &>/dev/null; then
  log "Cline CLI not found; installing..."
  as_root bash /usr/local/share/cline/install-cline.sh "$VERSION" ||
    warn "Cline CLI install failed (offline, or no root/sudo)."
fi

if command -v cline &>/dev/null; then
  log "Cline $(cline --version 2>/dev/null | head -n 1) is ready."
else
  warn "Cline CLI is not available. Install it manually with: npm install -g cline"
fi

log "Cline setup finished."
