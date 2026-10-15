#!/usr/bin/env bash
set -e

FEATURE=dotfiles
# shellcheck source=../../lib/common.sh
source /usr/local/share/dotfiles/common.sh
load_options

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
  log "Dotfiles directory not found. Skipping stow."
  exit 0
fi

if ! command -v stow &>/dev/null; then
  warn "GNU Stow is not installed. Skipping dotfiles."
  exit 0
fi

log "Applying dotfiles from $DOTFILES_DIR to target $TARGET..."
cd -P "$DOTFILES_DIR"
REAL_DIR="$(pwd -P)"

# --no-folding: link files, never whole directories. Without it stow turns a missing ~/.config
# into a symlink into the host's dotfiles repo, and every tool's state, cache and tokens
# written under ~/.config would land in that repo (one `git add -A && git push` from public).
stow_package() {
  log "Stowing package: $1"
  stow --no-folding --dir="$REAL_DIR" --target="$TARGET" -R "$1" || warn "failed to stow $1"
}

if [ -n "$PACKAGES" ]; then
  IFS=',' read -ra PKG_LIST <<< "$PACKAGES"
  for pkg in "${PKG_LIST[@]}"; do
    pkg=$(echo "$pkg" | xargs)
    if [ -d "$pkg" ]; then
      stow_package "$pkg"
    else
      log "Package directory '$pkg' not found, skipping."
    fi
  done
else
  for dir in */; do
    if [ -d "$dir" ]; then
      pkg="${dir%/}"
      if [ "$pkg" != ".git" ]; then
        stow_package "$pkg"
      fi
    fi
  done
fi

log "Dotfiles setup finished."
