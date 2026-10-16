#!/usr/bin/env bash
# postCreate, as node: claim the opencode-data volume and install the CLI if the build was offline.
set -e

log() { echo "[opencode] $*"; }
warn() { echo "[opencode] WARNING: $*" >&2; }
as_root() { if [ "$(id -u)" = 0 ]; then "$@"; else sudo -n "$@"; fi; }

# shellcheck disable=SC1091
. /usr/local/share/opencode/options.env

log "Setting up OpenCode environment..."

# opencode.db (logins and sessions) lives in the opencode-data volume, not on the host: SQLite
# locking does not work across the macOS <-> VM bind mount, and concurrent sessions corrupted
# the host database. The volume keeps the uid of the container that created it, so after a
# UID remap on a Linux host it has to be claimed. Only its top level: it is shared by every
# devcontainer on this machine.
DATA_DIR="$HOME/.local/share/opencode"
if [ -d "$DATA_DIR" ]; then
  [ -O "$DATA_DIR" ] || as_root chown "$(id -u):$(id -g)" "$DATA_DIR" || warn "$DATA_DIR is not owned by $(id -un) and could not be fixed (no root/sudo)."
  chmod o-w "$DATA_DIR" 2>/dev/null || true
fi

# ~/.config/opencode is the developer's host directory: never chown it.
for dir in "$HOME/.config/opencode" "$DATA_DIR"; do
  [ ! -e "$dir" ] || [ -w "$dir" ] || warn "$dir is not writable by $(id -un). If it is a host bind mount, fix its ownership on the host."
done

# Install OpenCode CLI if missing (e.g. image was built offline)
if ! command -v opencode &>/dev/null; then
  log "OpenCode CLI not found; installing via the official installer..."
  OC_INSTALLER="$(mktemp)"
  OC_INSTALL_ARGS=()
  if [ "$VERSION" != "latest" ]; then
    OC_INSTALL_ARGS=(--version "$VERSION")
  fi
  if curl -fsSL --proto '=https' --tlsv1.2 --retry 3 https://opencode.ai/v2/install -o "$OC_INSTALLER"; then
    bash "$OC_INSTALLER" "${OC_INSTALL_ARGS[@]}" || warn "OpenCode CLI install failed."
  else
    warn "OpenCode CLI install skipped (network unreachable or offline)."
  fi
  rm -f "$OC_INSTALLER"
fi

if command -v opencode &>/dev/null; then
  log "OpenCode $(opencode --version 2>/dev/null | head -n 1) is ready."
elif [ -x "$HOME/.opencode/bin/opencode" ]; then
  log "OpenCode installed to $HOME/.opencode/bin; open a new shell to pick up PATH."
else
  warn "OpenCode CLI is not available yet. Download https://opencode.ai/v2/install to a file, read it, then run it with bash."
fi

log "OpenCode setup finished."
