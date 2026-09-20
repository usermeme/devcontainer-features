#!/usr/bin/env bash
set -e

RUN_INSTALL="${RUNINSTALL:-false}"
FROZEN_LOCKFILE="${FROZENLOCKFILE:-true}"

echo "[pnpm] Configuring pnpm and store permissions..."

STORE_DIR="/home/node/.local/share/pnpm/store"
PNPM_DIR="/home/node/.local/share/pnpm"

CURRENT_USER="$(id -u):$(id -g)"
if [ -d "$PNPM_DIR" ]; then
  sudo chown -R "$CURRENT_USER" "$PNPM_DIR" 2>/dev/null || chown -R "$CURRENT_USER" "$PNPM_DIR" 2>/dev/null || true
else
  sudo mkdir -p "$STORE_DIR" 2>/dev/null || mkdir -p "$STORE_DIR"
  sudo chown -R "$CURRENT_USER" "$PNPM_DIR" 2>/dev/null || chown -R "$CURRENT_USER" "$PNPM_DIR" 2>/dev/null || true
fi

# Ensure user's home pnpm dir links to /home/node if running as different user
if [ "$HOME" != "/home/node" ] && [ -d "/home/node/.local/share/pnpm" ]; then
  mkdir -p "$HOME/.local/share"
  ln -sfn "/home/node/.local/share/pnpm" "$HOME/.local/share/pnpm" 2>/dev/null || true
fi

export PATH="/home/node/.local/share/pnpm:/home/node/.local/share/pnpm/bin:$PATH"
export PNPM_CONFIG_STORE_DIR="$STORE_DIR"

if command -v pnpm &>/dev/null; then
  pnpm config set store-dir "$STORE_DIR" --global 2>/dev/null || true
fi

if [ "$RUN_INSTALL" = "true" ]; then
  if [ -f "pnpm-lock.yaml" ] || [ -f "package.json" ]; then
    echo "[pnpm] Installing dependencies..."
    if [ "$FROZEN_LOCKFILE" = "true" ] && [ -f "pnpm-lock.yaml" ]; then
      pnpm install --frozen-lockfile
    else
      pnpm install
    fi
  fi
fi

echo "[pnpm] pnpm setup finished."
