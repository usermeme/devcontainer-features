#!/usr/bin/env bash
set -e

SAFEDIRECTORY="${SAFEDIRECTORY:-true}"
SETUPNX="${SETUPNX:-true}"

echo "Installing worktree feature..."

# Ensure git is installed
if ! command -v git &>/dev/null; then
  echo "Installing Git..."
  if [ -x "$(command -v apt-get)" ]; then
    apt-get update -y
    apt-get install -y --no-install-recommends git ca-certificates
    rm -rf /var/lib/apt/lists/*
  elif [ -x "$(command -v apk)" ]; then
    apk add --no-cache git ca-certificates
  fi
fi

# Copy setup script to system share location
INSTALL_DIR="/usr/local/share/worktree"
mkdir -p "$INSTALL_DIR"
cp "$(dirname "$0")/setup-worktree.sh" "$INSTALL_DIR/setup-worktree.sh"
chmod +x "$INSTALL_DIR/setup-worktree.sh"

echo "Worktree feature installed successfully."
