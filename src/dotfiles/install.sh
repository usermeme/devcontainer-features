#!/usr/bin/env bash
# Build time, as root: install GNU Stow and apply-dotfiles.sh.
set -e

log() { echo "[dotfiles] $*"; }

PACKAGES="${PACKAGES:-}"
TARGET="${TARGET:-}"

log "Installing dotfiles feature..."

if ! command -v stow &>/dev/null; then
  log "Installing GNU Stow..."
  if command -v apt-get &>/dev/null; then
    apt-get update -y && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends stow && rm -rf /var/lib/apt/lists/*
  elif command -v apk &>/dev/null; then
    apk add --no-cache stow
  elif command -v dnf &>/dev/null; then
    dnf install -y stow
  fi || true
fi
if ! command -v stow &>/dev/null; then
  echo "[dotfiles] ERROR: GNU Stow could not be installed on this image (on RHEL-based images enable EPEL first)." >&2
  exit 1
fi

# Feature options only exist while install.sh runs: keep them for postCreate.
mkdir -p /usr/local/share/dotfiles
printf 'PACKAGES=%q\nTARGET=%q\n' "$PACKAGES" "$TARGET" >/usr/local/share/dotfiles/options.env
install -m 755 "$(dirname "$0")/apply-dotfiles.sh" /usr/local/share/dotfiles/

log "Dotfiles feature installed successfully."
