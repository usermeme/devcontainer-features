#!/usr/bin/env bash
set -e

FEATURE=worktree
# shellcheck source=../../lib/common.sh
source "$(dirname "$0")/common.sh"

SAFEDIRECTORY="${SAFEDIRECTORY:-true}"
SETUPNX="${SETUPNX:-true}"

log "Installing worktree feature..."

if ! command -v git &>/dev/null; then
  log "Installing Git..."
  install_packages git ca-certificates
fi

# Git settings go to the image's system config, never to ~/.gitconfig: with the dotfiles
# feature that file can be a symlink into the developer's host dotfiles repo.

# The shared .git is the host's. Its worktrees/*/gitdir back-links hold host paths that do
# not exist in the container, so an automatic `git gc` here would prune every sibling
# worktree's metadata on the host. Explicit `git worktree prune` still does; see NOTES.md.
git -C / config --system gc.worktreePruneExpire never

# `safe.directory "*"` disables git's ownership check for every repository in the container
# (a repo unpacked into /tmp with core.fsmonitor set would run that command as you on the
# next `git status`). Trust only /workspaces: prefix patterns need git >= 2.46, older git gets
# the exact paths added by setup-worktree.sh at container start.
GIT_VERSION="$(git --version | awk '{print $3}')"
if [ "$SAFEDIRECTORY" = "true" ] && [ "$(printf '%s\n' 2.46 "$GIT_VERSION" | sort -V | head -n 1)" = "2.46" ]; then
  git -C / config --system --get-all safe.directory 2>/dev/null | grep -qxF '/workspaces/*' ||
    git -C / config --system --add safe.directory '/workspaces/*'
fi

if [ "$SETUPNX" = "true" ]; then
  resolve_build_owner
  ensure_owned_dir /workspaces .nx 755
fi

persist_options SAFEDIRECTORY SETUPNX
install_runtime setup-worktree.sh

log "Worktree feature installed successfully."
