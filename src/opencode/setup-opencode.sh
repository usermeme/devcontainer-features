#!/usr/bin/env bash
set -e

VERSION="${VERSION:-latest}"

echo "[opencode] Setting up OpenCode environment..."

CURRENT_USER="$(id -u):$(id -g)"

# Link a directory mounted under /home/node into the current user's HOME,
# replacing it only when the target is absent or an empty directory.
link_mounted_dir() {
  MOUNTED="$1"
  TARGET="$2"
  if [ -d "$MOUNTED" ] && [ ! -L "$TARGET" ]; then
    if [ -d "$TARGET" ] && [ -z "$(ls -A "$TARGET" 2>/dev/null)" ]; then
      rmdir "$TARGET" 2>/dev/null || true
    fi
    if [ ! -e "$TARGET" ]; then
      mkdir -p "$(dirname "$TARGET")"
      ln -sfn "$MOUNTED" "$TARGET" 2>/dev/null || true
    fi
  fi
}

# If running as non-node user, link the node mounted paths
if [ "$HOME" != "/home/node" ]; then
  link_mounted_dir /home/node/.config/opencode "$HOME/.config/opencode"
  link_mounted_dir /home/node/.local/share/opencode "$HOME/.local/share/opencode"
  # Shared skills (mounted by the antigravity feature) are discovered natively by OpenCode
  if [ -d "/home/node/.agents" ] && [ ! -e "$HOME/.agents" ]; then
    ln -sfn /home/node/.agents "$HOME/.agents" 2>/dev/null || true
  fi
fi

# Ensure directories exist and are usable by the container user (best effort on bind mounts)
sudo mkdir -p "$HOME/.config/opencode" "$HOME/.local/share/opencode" "$HOME/.opencode/bin" 2>/dev/null || mkdir -p "$HOME/.config/opencode" "$HOME/.local/share/opencode" "$HOME/.opencode/bin" 2>/dev/null || true
sudo chown "$CURRENT_USER" "$HOME/.config/opencode" 2>/dev/null || chown "$CURRENT_USER" "$HOME/.config/opencode" 2>/dev/null || true
sudo chown "$CURRENT_USER" "$HOME/.local/share/opencode" 2>/dev/null || chown "$CURRENT_USER" "$HOME/.local/share/opencode" 2>/dev/null || true
sudo chown -R "$CURRENT_USER" "$HOME/.opencode" 2>/dev/null || chown -R "$CURRENT_USER" "$HOME/.opencode" 2>/dev/null || true

# Install OpenCode CLI if missing (e.g. image was built offline)
if ! command -v opencode &>/dev/null; then
  echo "[opencode] OpenCode CLI not found; installing via the official installer..."
  OC_INSTALLER="$(mktemp)"
  OC_INSTALL_ARGS=""
  if [ "$VERSION" != "latest" ]; then
    OC_INSTALL_ARGS="--version $VERSION"
  fi
  if curl -fsSL https://opencode.ai/v2/install -o "$OC_INSTALLER"; then
    # shellcheck disable=SC2086
    bash "$OC_INSTALLER" $OC_INSTALL_ARGS || echo "[opencode] OpenCode CLI install failed."
  else
    echo "[opencode] OpenCode CLI install skipped (network unreachable or offline)."
  fi
  rm -f "$OC_INSTALLER"
fi

if command -v opencode &>/dev/null; then
  echo "[opencode] OpenCode $(opencode --version 2>/dev/null | head -n 1) is ready."
else
  echo "[opencode] OpenCode CLI is not available yet. Install it manually with: curl -fsSL https://opencode.ai/v2/install | bash"
fi

echo "[opencode] OpenCode setup finished."
