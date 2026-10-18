#!/usr/bin/env bash
# postCreate, as the container user: stow the host dotfiles packages into $HOME.
set -e

log() { echo "[dotfiles] $*"; }
warn() { echo "[dotfiles] WARNING: $*" >&2; }

# shellcheck disable=SC1091
. /usr/local/share/dotfiles/options.env

TARGET="${TARGET:-$HOME}"

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
#
# Exception - cline: the Cline CLI discovers hooks with readdir(...).isFile(), which skips
# symlinks, so per-file links would make ~/.cline/hooks/PostToolUse invisible to it. Stow cline
# with folding instead: ~/.cline/hooks becomes a directory symlink and the hook files inside it
# stay real files. Creating .cline first guarantees only hooks is folded - folding all of .cline
# would put Cline's session data inside the dotfiles repo when the cline feature is not used.
stow_cline() {
  log "Stowing package: cline (folded hooks directory)"
  mkdir -p "$TARGET/.cline"
  if [ -d "$TARGET/.cline/hooks" ] && [ ! -L "$TARGET/.cline/hooks" ]; then
    rm -rf "$TARGET/.cline/hooks" || warn "could not replace $TARGET/.cline/hooks" # migrate pre-folding deploys
  fi
  stow --dir="$REAL_DIR" --target="$TARGET" -R cline || warn "failed to stow cline"
}

stow_package() {
  if [ "$1" = "cline" ]; then
    stow_cline
    return
  fi
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

# Stowed scripts (e.g. Gemini CLI hook commands referenced by bare name like
# session-start-ensure-daemons.sh) are only found if ~/.local/bin is on PATH. Debian's
# ~/.profile adds it for login shells only; make interactive shells (and the agent CLIs
# launched from them) see it too. Idempotent.
BASHRC="$TARGET/.bashrc"
if ! grep -qs '\.local/bin' "$BASHRC"; then
  echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$BASHRC" 2>/dev/null ||
    warn "could not add ~/.local/bin to PATH in $BASHRC"
fi

log "Dotfiles setup finished."
