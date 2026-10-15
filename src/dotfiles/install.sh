#!/usr/bin/env bash
set -e

FEATURE=dotfiles
# shellcheck source=../../lib/common.sh
source "$(dirname "$0")/common.sh"

PACKAGES="${PACKAGES:-}"
TARGET="${TARGET:-}"

log "Installing dotfiles feature..."

if ! command -v stow &>/dev/null; then
  log "Installing GNU Stow..."
  install_packages stow || true
fi
command -v stow &>/dev/null || die "GNU Stow could not be installed on this image (on RHEL-based images enable EPEL first)."

persist_options PACKAGES TARGET
install_runtime apply-dotfiles.sh

log "Dotfiles feature installed successfully."
