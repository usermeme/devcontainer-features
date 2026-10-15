#!/usr/bin/env bash
set -e

FEATURE=neovim
# shellcheck source=../../lib/common.sh
source /usr/local/share/neovim/common.sh
load_options

INSTALL_LINTERS="${INSTALLLINTERS:-true}"

if [ "$INSTALL_LINTERS" = "true" ] && command -v npm &>/dev/null; then
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
