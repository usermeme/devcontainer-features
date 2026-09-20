#!/usr/bin/env bash
set -e

SYMLINK_SKILLS="${SYMLINKSKILLS:-true}"

echo "[antigravity] Setting up directory permissions..."

CURRENT_USER="$(id -u):$(id -g)"
sudo mkdir -p "$HOME/.local/bin" "$HOME/.config" "$HOME/.gemini" 2>/dev/null || mkdir -p "$HOME/.local/bin" "$HOME/.config" "$HOME/.gemini"
sudo chown -R "$CURRENT_USER" "$HOME/.local" 2>/dev/null || chown -R "$CURRENT_USER" "$HOME/.local" 2>/dev/null || true
sudo chown "$CURRENT_USER" "$HOME/.config" 2>/dev/null || chown "$CURRENT_USER" "$HOME/.config" 2>/dev/null || true
sudo chown -R "$CURRENT_USER" "$HOME/.gemini" 2>/dev/null || true

# If running as non-node user, link the node mounted paths
if [ "$HOME" != "/home/node" ]; then
  if [ -d "/home/node/.gemini" ] && [ ! -e "$HOME/.gemini" ]; then
    ln -sfn /home/node/.gemini "$HOME/.gemini" 2>/dev/null || true
  fi
  if [ -d "/home/node/.agents" ] && [ ! -e "$HOME/.agents" ]; then
    ln -sfn /home/node/.agents "$HOME/.agents" 2>/dev/null || true
  fi
  if [ -d "/home/node/.config/gcloud" ]; then
    mkdir -p "$HOME/.config"
    ln -sfn /home/node/.config/gcloud "$HOME/.config/gcloud" 2>/dev/null || true
  fi
fi

# Install Antigravity CLI if missing
if ! command -v agy &>/dev/null && ! command -v antigravity &>/dev/null; then
  echo "[antigravity] Installing Antigravity CLI..."
  curl -fsSL https://antigravity.google/cli/install.sh | bash || echo "[antigravity] Antigravity CLI install skipped (network unreachable or offline)."
fi

# Symlink skills if configured
if [ "$SYMLINK_SKILLS" = "true" ]; then
  SKILLS_DIR=""
  if [ -d "$HOME/.agents/skills" ]; then
    SKILLS_DIR="$HOME/.agents/skills"
  elif [ -d "/home/node/.agents/skills" ]; then
    SKILLS_DIR="/home/node/.agents/skills"
  fi

  if [ -n "$SKILLS_DIR" ]; then
    echo "[antigravity] Symlinking skills from $SKILLS_DIR to $HOME/.gemini/skills..."
    mkdir -p "$HOME/.gemini"
    ln -sfn "$SKILLS_DIR" "$HOME/.gemini/skills"
  fi
fi

echo "[antigravity] Antigravity setup finished."
