#!/usr/bin/env bash
set -e

echo "Installing Antigravity feature..."

# Ensure curl and ca-certificates
if ! command -v curl &>/dev/null; then
  if [ -x "$(command -v apt-get)" ]; then
    apt-get update -y
    apt-get install -y --no-install-recommends curl ca-certificates bash
    rm -rf /var/lib/apt/lists/*
  elif [ -x "$(command -v apk)" ]; then
    apk add --no-cache curl ca-certificates bash
  fi
fi

# Pre-create mount point directories
mkdir -p /home/node/.gemini /home/node/.config /home/node/.agents /home/node/.local/bin
chmod -R 777 /home/node/.gemini /home/node/.config /home/node/.agents /home/node/.local 2>/dev/null || true

# Copy runtime setup script
INSTALL_DIR="/usr/local/share/antigravity"
mkdir -p "$INSTALL_DIR"
cp "$(dirname "$0")/setup-antigravity.sh" "$INSTALL_DIR/setup-antigravity.sh"
chmod +x "$INSTALL_DIR/setup-antigravity.sh"

echo "Antigravity feature installed successfully."
