#!/usr/bin/env bash
# postCreate, as node: verify mount and create convenience symlinks for agents/tools.
set -e

log() { echo "[penpot] $*"; }
warn() { echo "[penpot] WARNING: $*" >&2; }

# shellcheck disable=SC1091
[ -f /usr/local/share/penpot/options.env ] && . /usr/local/share/penpot/options.env

log "Setting up Penpot environment..."

# ~/.penpot-ai-kit is the developer's host directory: never chown it.
[ ! -e "$HOME/.penpot-ai-kit" ] || [ -w "$HOME/.penpot-ai-kit" ] || warn "$HOME/.penpot-ai-kit is not writable by $(id -un); fix its ownership on the host."

# Symlink ~/.penpot -> ~/.penpot-ai-kit if requested and not already existing
if [ "${SYMLINKPENPOT:-true}" = "true" ]; then
  PENPOT_LINK="$HOME/.penpot"
  if [ -L "$PENPOT_LINK" ] && [ ! -e "$PENPOT_LINK" ]; then
    rm -f "$PENPOT_LINK" || warn "could not remove broken link $PENPOT_LINK"
  fi
  if [ -e "$PENPOT_LINK" ] || [ -L "$PENPOT_LINK" ]; then
    log "$PENPOT_LINK already exists; leaving it as is."
  elif [ -d "$HOME/.penpot-ai-kit" ]; then
    log "Linking $PENPOT_LINK -> .penpot-ai-kit"
    ln -s .penpot-ai-kit "$PENPOT_LINK" || warn "could not create $PENPOT_LINK (is $HOME writable?)"
  fi
fi

log "Penpot setup finished."
