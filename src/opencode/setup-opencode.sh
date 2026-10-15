#!/usr/bin/env bash
set -e

VERSION="${VERSION:-latest}"

echo "[opencode] Setting up OpenCode environment..."

CURRENT_USER="$(id -u):$(id -g)"

SUDO=""
if [ "$(id -u)" != "0" ] && command -v sudo >/dev/null 2>&1; then
  SUDO="sudo"
fi

# OpenCode uses four XDG directories, but only config and data are bind-mounted from the
# host: ~/.local/state and ~/.cache have to be created by the container user itself.
# Feature install scripts run as root, so the ancestors (~/.local, ~/.local/share) can be
# baked into the image root-owned, and OpenCode then fails before it can create anything:
#   Error: EACCES: permission denied, mkdir '/home/node/.local/state'
# Hand those ancestors back to whoever is actually running the container.
# Non-recursive on purpose: ~/.config/opencode and ~/.local/share/opencode are bind mounts
# of the developer's real home directory, so chown -R / chmod -R would write through to
# host files (and 777 would expose them to every user in the image).
for DIR in "$HOME/.cache" "$HOME/.config" "$HOME/.local" "$HOME/.local/share"; do
  $SUDO mkdir -p "$DIR" 2>/dev/null || mkdir -p "$DIR" 2>/dev/null || true
  $SUDO chown "$CURRENT_USER" "$DIR" 2>/dev/null || chown "$CURRENT_USER" "$DIR" 2>/dev/null || true
  if [ ! -w "$DIR" ]; then
    echo "[opencode] WARNING: $DIR is not writable by $CURRENT_USER; OpenCode may fail to start."
  fi
done

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
