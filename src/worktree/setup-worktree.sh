#!/usr/bin/env bash
# postCreate, as the container user: fix the host .git pointer, trust the workspace, claim .nx.
set -e

log() { echo "[worktree] $*"; }
warn() { echo "[worktree] WARNING: $*" >&2; }
as_root() { if [ "$(id -u)" = 0 ]; then "$@"; else sudo -n "$@"; fi; }

# shellcheck disable=SC1091
. /usr/local/share/worktree/options.env

log "Setting up Git and worktree environment..."

# The worktree's .git file lives in the bind-mounted workspace: it is the host's file.
# Git writes it with an absolute host path (e.g. /Users/me/repo/.git/worktrees/feat) that does
# not exist here. Rewrite it to a relative pointer, which resolves to the same directory both
# on the host and in the container. Never write a container-only path into it: 1.0.0 did
# (gitdir: /workspaces/.git/worktrees/<name>), which broke git for that worktree on the host,
# and this also heals those files. Back-links in .git/worktrees/*/gitdir are left alone:
# relative back-links need a repository extension that older host git refuses.
if [ -f .git ]; then
  GITDIR_LINE="$(tr -d '\r' <.git)"
  if [[ "$GITDIR_LINE" =~ ^gitdir:\ (.*)$ ]]; then
    RECORDED_PATH="${BASH_REMATCH[1]}"
    WT_NAME="$(basename "$RECORDED_PATH")"
    RELATIVE_PATH="../.git/worktrees/$WT_NAME"
    case "$RECORDED_PATH" in
      /workspaces/.git/worktrees/*) NEEDS_REWRITE=1 ;;
      /*) [ -e "$RECORDED_PATH" ] && NEEDS_REWRITE="" || NEEDS_REWRITE=1 ;;
      *) NEEDS_REWRITE="" ;;
    esac
    if [ -n "$NEEDS_REWRITE" ]; then
      if [ -d "$RELATIVE_PATH" ]; then
        log "Rewriting .git to the relative pointer 'gitdir: $RELATIVE_PATH' (valid on host and container)."
        printf 'gitdir: %s\n' "$RELATIVE_PATH" >.git || warn "could not rewrite .git (not writable)"
      else
        warn ".git points to $RECORDED_PATH, which does not exist here, and $RELATIVE_PATH was not found either. Is the parent .git mounted at /workspaces/.git?"
      fi
    fi
  fi
fi

# Exact paths for git < 2.46, which cannot match the '/workspaces/*' set at build time.
# System config only (see install.sh); skipped with a warning when root is not available.
# `git -C /`: inside the workspace git may refuse to start (dubious ownership, broken pointer).
if [ "$SAFEDIRECTORY" = "true" ]; then
  for dir in "$PWD" /workspaces/.git; do
    if ! git -C / config --system --get-all safe.directory 2>/dev/null | grep -qxF -e "$dir" -e '/workspaces/*'; then
      as_root git -C / config --system --add safe.directory "$dir" ||
        warn "could not add $dir to safe.directory (no root/sudo)"
    fi
  done
fi

# /workspaces/.nx is outside $HOME, so a UID remap on Linux hosts leaves it with the build-time
# uid. Skipped when it is a mount: chown there would rewrite the host's file ownership.
NX_DIR=/workspaces/.nx
if [ "$SETUPNX" = "true" ] && [ -d /workspaces ] &&
  ! awk -v p="$NX_DIR" '$5==p{found=1} END{exit !found}' /proc/self/mountinfo 2>/dev/null; then
  [ -d "$NX_DIR" ] || mkdir "$NX_DIR" 2>/dev/null || as_root mkdir "$NX_DIR" || warn "cannot create $NX_DIR"
  [ ! -d "$NX_DIR" ] || [ -O "$NX_DIR" ] || as_root chown "$(id -u):$(id -g)" "$NX_DIR" ||
    warn "$NX_DIR is not owned by $(id -un) and could not be fixed (no root/sudo)."
fi

log "Worktree setup finished."
