#!/usr/bin/env bash
# Build time, as root: install setup-volume.sh.
set -e

mkdir -p /usr/local/share/node-modules-volume
install -m 755 "$(dirname "$0")/setup-volume.sh" /usr/local/share/node-modules-volume/

echo "[node-modules-volume] Node modules volume feature installed."
