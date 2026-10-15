#!/usr/bin/env bash
set -e

FEATURE=worktree
# shellcheck source=../../lib/common.sh
source /usr/local/share/worktree/common.sh
load_options

SAFEDIRECTORY="${SAFEDIRECTORY:-true}"
SETUPNX="${SETUPNX:-true}"

log "Setting up Git and worktree environment..."

resolve_owner

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

if [ "$SETUPNX" = "true" ] && [ -d /workspaces ]; then
  ensure_owned_dir /workspaces .nx
fi

log "Worktree setup finished."
