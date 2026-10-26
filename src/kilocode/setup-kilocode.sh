#!/usr/bin/env bash
# postCreate, as node: claim the kilocode-data volume and install the CLI if the build was offline.
set -e

log() { echo "[kilocode] $*"; }
warn() { echo "[kilocode] WARNING: $*" >&2; }
as_root() { if [ "$(id -u)" = 0 ]; then "$@"; else sudo -n "$@"; fi; }

# shellcheck disable=SC1091
. /usr/local/share/kilocode/options.env

log "Setting up Kilo Code environment..."

# auth.json (logins), sessions, logs and repos live in the kilocode-data volume, not on the
# host: SQLite locking does not work across the macOS <-> VM bind mount, and concurrent
# sessions would corrupt a host database. The volume keeps the uid of the container that
# created it, so after a UID remap on a Linux host it has to be claimed. Only its top level:
# it is shared by every devcontainer on this machine.
DATA_DIR="$HOME/.local/share/kilo"
if [ -d "$DATA_DIR" ]; then
  [ -O "$DATA_DIR" ] || as_root chown "$(id -u):$(id -g)" "$DATA_DIR" || warn "$DATA_DIR is not owned by $(id -un) and could not be fixed (no root/sudo)."
  chmod o-w "$DATA_DIR" 2>/dev/null || true
fi

# ~/.config/kilo is the developer's host directory: never chown it.
for dir in "$HOME/.config/kilo" "$DATA_DIR"; do
  [ ! -e "$dir" ] || [ -w "$dir" ] || warn "$dir is not writable by $(id -un). If it is a host bind mount, fix its ownership on the host."
done

# Install Kilo Code CLI if missing (e.g. image was built offline)
if ! command -v kilo &>/dev/null; then
  log "Kilo Code CLI not found; installing..."
  as_root bash /usr/local/share/kilocode/install-kilocode.sh "$VERSION" ||
    warn "Kilo Code CLI install failed (offline, or no root/sudo)."
fi

if command -v kilo &>/dev/null; then
  log "Kilo Code CLI $(kilo --version 2>/dev/null | head -n 1) is ready."
else
  warn "Kilo Code CLI is not available. Install it manually with: npm install -g @kilocode/cli"
fi

log "Kilo Code setup finished."
