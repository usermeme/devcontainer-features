#!/usr/bin/env bash
# Build time, as root: configure system git for the shared host .git and install setup-worktree.sh.
set -e

log() { echo "[worktree] $*"; }

SAFEDIRECTORY="${SAFEDIRECTORY:-true}"
SETUPNX="${SETUPNX:-true}"

log "Installing worktree feature..."

if ! command -v git &>/dev/null; then
  log "Installing Git..."
  if command -v apt-get &>/dev/null; then
    apt-get update -y && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends git ca-certificates && rm -rf /var/lib/apt/lists/*
  elif command -v apk &>/dev/null; then
    apk add --no-cache git ca-certificates
  elif command -v dnf &>/dev/null; then
    dnf install -y git ca-certificates
  fi
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

# The Nx cache belongs to the remote user (any user: nothing here lives in a home dir).
# setup-worktree.sh claims it again after a UID remap.
if [ "$SETUPNX" = "true" ]; then
  OWNER="${_REMOTE_USER:-root}"
  id "$OWNER" &>/dev/null || OWNER=root
  install -d -o "$OWNER" -g "$(id -gn "$OWNER")" -m 755 /workspaces/.nx
fi

# Feature options only exist while install.sh runs: keep them for postCreate.
mkdir -p /usr/local/share/worktree
printf 'SAFEDIRECTORY=%q\nSETUPNX=%q\n' "$SAFEDIRECTORY" "$SETUPNX" >/usr/local/share/worktree/options.env
install -m 755 "$(dirname "$0")/setup-worktree.sh" /usr/local/share/worktree/

log "Worktree feature installed successfully."
