#!/usr/bin/env bash
set -e

echo "[node-modules-volume] Ensuring node_modules directory permissions..."

CURRENT_USER="$(id -u):$(id -g)"
if [ -d "node_modules" ]; then
  sudo chown -R "$CURRENT_USER" node_modules 2>/dev/null || chown -R "$CURRENT_USER" node_modules 2>/dev/null || true
fi

echo "[node-modules-volume] Setup finished."
