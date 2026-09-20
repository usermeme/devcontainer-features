#!/usr/bin/env bash
set -e

SAFEDIRECTORY="${SAFEDIRECTORY:-true}"
SETUPNX="${SETUPNX:-true}"

echo "[worktree] Setting up Git and worktree environment..."

if [ "$SAFEDIRECTORY" = "true" ]; then
  echo "[worktree] Configuring Git safe.directory to allow all workspaces..."
  git config --global --add safe.directory "*" || true
fi

if [ "$SETUPNX" = "true" ] && [ -d "/workspaces" ]; then
  echo "[worktree] Ensuring /workspaces/.nx cache permissions..."
  sudo mkdir -p /workspaces/.nx 2>/dev/null || mkdir -p /workspaces/.nx
  CURRENT_USER="$(id -u):$(id -g)"
  sudo chown -R "$CURRENT_USER" /workspaces/.nx 2>/dev/null || chown -R "$CURRENT_USER" /workspaces/.nx 2>/dev/null || true
fi

# Check if current workspace has a .git worktree reference file
if [ -f .git ]; then
  echo "[worktree] Detected Git worktree file (.git)..."
  GITDIR_LINE=$(cat .git | tr -d '\r')
  if [[ "$GITDIR_LINE" =~ ^gitdir:\ (.*)$ ]]; then
    RECORDED_PATH="${BASH_REMATCH[1]}"
    if [ ! -e "$RECORDED_PATH" ]; then
      WT_BASENAME=$(basename "$RECORDED_PATH")
      if [ -d "/workspaces/.git/worktrees/$WT_BASENAME" ]; then
        echo "[worktree] Updating .git pointer to /workspaces/.git/worktrees/$WT_BASENAME"
        echo "gitdir: /workspaces/.git/worktrees/$WT_BASENAME" > .git
      elif [ -d "../.git/worktrees/$WT_BASENAME" ]; then
        echo "[worktree] Updating .git pointer to ../.git/worktrees/$WT_BASENAME"
        echo "gitdir: ../.git/worktrees/$WT_BASENAME" > .git
      fi
    fi
  fi
  git worktree repair /workspaces/.git 2>/dev/null || true
fi

echo "[worktree] Worktree setup finished."
