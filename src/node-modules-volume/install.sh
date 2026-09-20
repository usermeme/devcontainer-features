#!/usr/bin/env bash
set -e

INSTALL_DIR="/usr/local/share/node-modules-volume"
mkdir -p "$INSTALL_DIR"
cp "$(dirname "$0")/setup-volume.sh" "$INSTALL_DIR/setup-volume.sh"
chmod +x "$INSTALL_DIR/setup-volume.sh"

echo "Node modules volume feature installed."
