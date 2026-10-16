#!/usr/bin/env bash
# postCreate, as the container user: install the linters if the build could not.
set -e

log() { echo "[neovim] $*"; }
warn() { echo "[neovim] WARNING: $*" >&2; }
as_root() { if [ "$(id -u)" = 0 ]; then "$@"; else sudo -n "$@"; fi; }

# shellcheck disable=SC1091
. /usr/local/share/neovim/options.env

if [ "$INSTALLLINTERS" = "true" ] && command -v npm &>/dev/null; then
  if ! command -v eslint_d &>/dev/null || ! command -v prettierd &>/dev/null; then
    log "Installing eslint_d and @fsouza/prettierd..."
    # User-writable npm prefixes (nvm) work directly; system prefixes need root. PATH is passed
    # explicitly because sudo's secure_path drops nvm's bin directory.
    npm install -g eslint_d @fsouza/prettierd ||
      as_root env "PATH=$PATH" npm install -g eslint_d @fsouza/prettierd ||
      warn "could not install eslint_d and @fsouza/prettierd"
  fi
fi

log "Neovim post-create setup finished."
