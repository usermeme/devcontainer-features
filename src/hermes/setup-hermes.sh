#!/usr/bin/env bash
# postCreate, as node: install the Hermes Agent CLI if missing and verify host mount.
set -e

log() { echo "[hermes] $*"; }
warn() { echo "[hermes] WARNING: $*" >&2; }
as_root() { if [ "$(id -u)" = 0 ]; then "$@"; else sudo -n "$@"; fi; }

# shellcheck disable=SC1091
. /usr/local/share/hermes/options.env

log "Setting up Hermes Agent environment..."

# ~/.hermes is the developer's host directory: never chown it.
HERMES_DIR="${HERMES_HOME:-$HOME/.hermes}"
[ ! -e "$HERMES_DIR" ] || [ -w "$HERMES_DIR" ] || warn "$HERMES_DIR is not writable by $(id -un); fix its ownership on the host."

# If hermes CLI is not found (e.g. build had no network access), try installing now
if ! command -v hermes &>/dev/null; then
  log "Hermes Agent CLI not found; installing..."
  as_root bash /usr/local/share/hermes/install-hermes.sh "$VERSION" ||
    warn "Hermes Agent CLI install failed (offline, or no root/sudo)."
fi

if command -v hermes &>/dev/null; then
  log "Hermes Agent $(hermes --version 2>/dev/null || true) is ready."
else
  warn "Hermes Agent CLI is not available."
fi

log "Hermes Agent setup finished."
