#!/usr/bin/env bash
set -e

VERSION="${VERSION:-latest}"

echo "Installing Yarn feature (version: $VERSION)..."

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

# Enable Corepack or install via npm
if command -v corepack &>/dev/null; then
  echo "Enabling Corepack for yarn..."
  corepack enable || true
  if [ "$VERSION" = "latest" ]; then
    corepack prepare yarn@stable --activate 2>/dev/null || true
  else
    corepack prepare "yarn@$VERSION" --activate 2>/dev/null || true
  fi
fi

if ! command -v yarn &>/dev/null; then
  if command -v npm &>/dev/null; then
    echo "Installing yarn via npm..."
    if [ "$VERSION" = "latest" ]; then
      npm install -g yarn
    else
      npm install -g "yarn@$VERSION"
    fi
  else
    # Fallback to installing Yarn Classic or Node
    if [ -x "$(command -v apt-get)" ]; then
      apt-get update -y
      apt-get install -y --no-install-recommends yarn 2>/dev/null || true
      rm -rf /var/lib/apt/lists/*
    fi
  fi
fi

# Ensure yarn cache directory exists
mkdir -p /home/node/.cache/yarn
chmod -R 777 /home/node/.cache/yarn

# Copy runtime setup script
INSTALL_DIR="/usr/local/share/yarn"
mkdir -p "$INSTALL_DIR"
cp "$(dirname "$0")/setup-yarn.sh" "$INSTALL_DIR/setup-yarn.sh"
chmod +x "$INSTALL_DIR/setup-yarn.sh"

echo "Yarn feature installed successfully."
