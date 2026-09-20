#!/usr/bin/env bash
set -e

INSTALL_LINTERS="${INSTALLLINTERS:-true}"

if [ "$INSTALL_LINTERS" = "true" ] && command -v npm &>/dev/null; then
  if ! command -v eslint_d &>/dev/null || ! command -v prettierd &>/dev/null; then
    echo "[neovim] Installing eslint_d and @fsouza/prettierd..."
    npm install -g eslint_d @fsouza/prettierd 2>/dev/null || sudo npm install -g eslint_d @fsouza/prettierd 2>/dev/null || true
  fi
fi

echo "[neovim] Neovim post-create setup finished."
