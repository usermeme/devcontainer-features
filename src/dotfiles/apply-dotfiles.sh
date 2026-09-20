#!/usr/bin/env bash
set -e

TARGET="${TARGET:-$HOME}"
PACKAGES="${PACKAGES:-}"

DOTFILES_DIR=""
if [ -d "$HOME/dotfiles" ]; then
  DOTFILES_DIR="$HOME/dotfiles"
elif [ -d "/opt/dotfiles" ]; then
  DOTFILES_DIR="/opt/dotfiles"
  if [ ! -e "$HOME/dotfiles" ]; then
    ln -sfn /opt/dotfiles "$HOME/dotfiles" 2>/dev/null || true
  fi
elif [ -d "/home/node/dotfiles" ]; then
  DOTFILES_DIR="/home/node/dotfiles"
fi

if [ -z "$DOTFILES_DIR" ] || [ ! -d "$DOTFILES_DIR" ]; then
  echo "[dotfiles] Dotfiles directory not found. Skipping stow."
  exit 0
fi

if ! command -v stow &>/dev/null; then
  echo "[dotfiles] Warning: GNU Stow is not installed. Skipping dotfiles."
  exit 0
fi

echo "[dotfiles] Applying dotfiles from $DOTFILES_DIR to target $TARGET..."
cd -P "$DOTFILES_DIR"
REAL_DIR="$(pwd -P)"

if [ -n "$PACKAGES" ]; then
  IFS=',' read -ra PKG_LIST <<< "$PACKAGES"
  for pkg in "${PKG_LIST[@]}"; do
    pkg=$(echo "$pkg" | xargs)
    if [ -d "$pkg" ]; then
      echo "[dotfiles] Stowing package: $pkg"
      stow --dir="$REAL_DIR" --target="$TARGET" -R "$pkg" || echo "[dotfiles] Warning: failed to stow $pkg"
    else
      echo "[dotfiles] Package directory '$pkg' not found, skipping."
    fi
  done
else
  for dir in */; do
    if [ -d "$dir" ]; then
      pkg="${dir%/}"
      if [ "$pkg" != ".git" ]; then
        echo "[dotfiles] Stowing package: $pkg"
        stow --dir="$REAL_DIR" --target="$TARGET" -R "$pkg" || echo "[dotfiles] Warning: failed to stow $pkg"
      fi
    fi
  done
fi

echo "[dotfiles] Dotfiles setup finished."
