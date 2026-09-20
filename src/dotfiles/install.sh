#!/usr/bin/env bash
set -e

echo "Installing dotfiles feature..."

# Install GNU stow
if ! command -v stow &>/dev/null; then
  echo "Installing GNU Stow..."
  if [ -x "$(command -v apt-get)" ]; then
    apt-get update -y
    apt-get install -y --no-install-recommends stow
    rm -rf /var/lib/apt/lists/*
  elif [ -x "$(command -v apk)" ]; then
    apk add --no-cache stow
  elif [ -x "$(command -v dnf)" ]; then
    dnf install -y stow
  fi
fi

# Copy script to system share location
INSTALL_DIR="/usr/local/share/dotfiles"
mkdir -p "$INSTALL_DIR"
cp "$(dirname "$0")/apply-dotfiles.sh" "$INSTALL_DIR/apply-dotfiles.sh"
chmod +x "$INSTALL_DIR/apply-dotfiles.sh"

echo "Dotfiles feature installed successfully."
