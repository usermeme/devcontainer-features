#!/usr/bin/env bash
set -e

RUN_INSTALL="${RUNINSTALL:-false}"
IMMUTABLE="${IMMUTABLE:-true}"

echo "[yarn] Configuring yarn cache permissions..."
CACHE_DIR="/home/node/.cache/yarn"
CURRENT_USER="$(id -u):$(id -g)"

if [ -d "$CACHE_DIR" ]; then
  sudo chown -R "$CURRENT_USER" "$CACHE_DIR" 2>/dev/null || chown -R "$CURRENT_USER" "$CACHE_DIR" 2>/dev/null || true
else
  sudo mkdir -p "$CACHE_DIR" 2>/dev/null || mkdir -p "$CACHE_DIR"
  sudo chown -R "$CURRENT_USER" "$CACHE_DIR" 2>/dev/null || chown -R "$CURRENT_USER" "$CACHE_DIR" 2>/dev/null || true
fi

# Ensure user's home cache dir links to /home/node/.cache/yarn if running as different user
if [ "$HOME" != "/home/node" ] && [ -d "$CACHE_DIR" ]; then
  mkdir -p "$HOME/.cache"
  ln -sfn "$CACHE_DIR" "$HOME/.cache/yarn" 2>/dev/null || true
fi

if [ "$RUN_INSTALL" = "true" ]; then
  if [ -f "yarn.lock" ] || [ -f "package.json" ]; then
    echo "[yarn] Installing dependencies..."
    if [ "$IMMUTABLE" = "true" ] && [ -f ".yarnrc.yml" ]; then
      yarn install --immutable
    elif [ -f "yarn.lock" ]; then
      yarn install --frozen-lockfile 2>/dev/null || yarn install
    else
      yarn install
    fi
  fi
fi

echo "[yarn] Yarn setup finished."
