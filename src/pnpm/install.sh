#!/usr/bin/env bash
set -e

VERSION="${VERSION:-latest}"

echo "Installing pnpm feature (version: $VERSION)..."

# Ensure curl / ca-certificates
if ! command -v curl &>/dev/null; then
  if [ -x "$(command -v apt-get)" ]; then
    apt-get update -y
    apt-get install -y --no-install-recommends curl ca-certificates
    rm -rf /var/lib/apt/lists/*
  elif [ -x "$(command -v apk)" ]; then
    apk add --no-cache curl ca-certificates
  fi
fi

# Install or enable pnpm
if command -v corepack &>/dev/null; then
  echo "Enabling Corepack for pnpm..."
  corepack enable || true
  if [ "$VERSION" = "latest" ]; then
    corepack prepare pnpm@latest --activate 2>/dev/null || true
  else
    corepack prepare "pnpm@$VERSION" --activate 2>/dev/null || true
  fi
fi

if ! command -v pnpm &>/dev/null; then
  if command -v npm &>/dev/null; then
    echo "Installing pnpm via npm..."
    if [ "$VERSION" = "latest" ]; then
      npm install -g pnpm
    else
      npm install -g "pnpm@$VERSION"
    fi
  else
    echo "Installing standalone pnpm binary..."
    export SHELL="bash"
    curl -fsSL https://get.pnpm.io/install.sh | env PNPM_VERSION="$VERSION" sh -
    if [ -f "/root/.local/share/pnpm/pnpm" ]; then
      ln -sf "/root/.local/share/pnpm/pnpm" "/usr/local/bin/pnpm"
    fi
  fi
fi

# Ensure store directory structure exists
mkdir -p /home/node/.local/share/pnpm/store
chmod -R 777 /home/node/.local/share/pnpm

# Setup system-wide environment variables
mkdir -p /etc/profile.d
cat << 'EOF' > /etc/profile.d/pnpm.sh
export PNPM_HOME="/home/node/.local/share/pnpm"
export PNPM_CONFIG_STORE_DIR="/home/node/.local/share/pnpm/store"
export PATH="/home/node/.local/share/pnpm:/home/node/.local/share/pnpm/bin:$PATH"
EOF
chmod +x /etc/profile.d/pnpm.sh

# Copy runtime setup script
INSTALL_DIR="/usr/local/share/pnpm"
mkdir -p "$INSTALL_DIR"
cp "$(dirname "$0")/setup-pnpm.sh" "$INSTALL_DIR/setup-pnpm.sh"
chmod +x "$INSTALL_DIR/setup-pnpm.sh"

echo "pnpm feature installed successfully."
