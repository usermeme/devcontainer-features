#!/usr/bin/env bash
set -e

VERSION="${VERSION:-latest}"

echo "Installing OpenCode feature (version: $VERSION)..."

# Ensure curl, tar and ca-certificates
if ! command -v curl &>/dev/null || ! command -v tar &>/dev/null; then
  if [ -x "$(command -v apt-get)" ]; then
    apt-get update -y
    apt-get install -y --no-install-recommends curl tar ca-certificates bash
    rm -rf /var/lib/apt/lists/*
  elif [ -x "$(command -v apk)" ]; then
    apk add --no-cache curl tar ca-certificates bash
  fi
fi

# Pre-create mount point directories
mkdir -p /home/node/.config/opencode /home/node/.local/share/opencode /home/node/.opencode/bin
chmod -R 777 /home/node/.config/opencode /home/node/.local/share/opencode /home/node/.opencode 2>/dev/null || true

# Detect architecture and libc for the official OpenCode binary
ARCH=$(uname -m)
case "$ARCH" in
  arm64 | aarch64) OC_ARCH="arm64" ;;
  x86_64 | amd64) OC_ARCH="x64" ;;
  *) OC_ARCH="" ;;
esac

OC_TARGET=""
if [ -n "$OC_ARCH" ]; then
  OC_TARGET="linux-$OC_ARCH"
  # x64 CPUs without AVX2 need the baseline build
  if [ "$OC_ARCH" = "x64" ] && ! grep -qwi avx2 /proc/cpuinfo 2>/dev/null; then
    OC_TARGET="$OC_TARGET-baseline"
  fi
  # musl-based systems (Alpine) need the dedicated build
  if [ -f /etc/alpine-release ] || (command -v ldd >/dev/null 2>&1 && ldd --version 2>&1 | grep -qi musl); then
    OC_TARGET="$OC_TARGET-musl"
  fi
fi

# Best effort: when the build has no network access, setup-opencode.sh retries at container startup
if [ "$VERSION" = "latest" ] && [ -n "$OC_TARGET" ]; then
  OC_URL="https://opencode.ai/update/api/latest/cli/opencode/opencode-$OC_TARGET.tar.gz"
  echo "Downloading OpenCode from $OC_URL..."
  TMP_DIR=$(mktemp -d)
  if curl -fsSL "$OC_URL" -o "$TMP_DIR/opencode.tar.gz"; then
    tar -xzf "$TMP_DIR/opencode.tar.gz" -C "$TMP_DIR"
    OC_BIN=$(find "$TMP_DIR" -type f -name opencode | head -n 1)
    if [ -n "$OC_BIN" ]; then
      cp "$OC_BIN" /usr/local/bin/opencode
      chmod 755 /usr/local/bin/opencode
    fi
  else
    echo "Warning: OpenCode download failed; setup-opencode.sh will retry during postCreate."
  fi
  rm -rf "$TMP_DIR"
elif [ "$VERSION" != "latest" ]; then
  # Pinned versions are resolved by the official installer (npm registry packages)
  echo "Installing OpenCode $VERSION via the official installer..."
  TMP_HOME=$(mktemp -d)
  if curl -fsSL https://opencode.ai/v2/install -o "$TMP_HOME/install.sh"; then
    HOME="$TMP_HOME" bash "$TMP_HOME/install.sh" --version "$VERSION" --no-modify-path || echo "Warning: official installer failed for version $VERSION."
    if [ -f "$TMP_HOME/.opencode/bin/opencode" ]; then
      cp "$TMP_HOME/.opencode/bin/opencode" /usr/local/bin/opencode
      chmod 755 /usr/local/bin/opencode
    fi
  else
    echo "Warning: OpenCode installer download failed; setup-opencode.sh will retry during postCreate."
  fi
  rm -rf "$TMP_HOME"
fi

# Verify the binary can execute (glibc/baseline compatibility check)
if [ -f /usr/local/bin/opencode ] && ! /usr/local/bin/opencode --version &>/dev/null; then
  echo "Notice: prebuilt OpenCode binary is not runnable on this base image; setup-opencode.sh will retry during postCreate."
  rm -f /usr/local/bin/opencode
fi

if [ -f /usr/local/bin/opencode ]; then
  echo "OpenCode $(/usr/local/bin/opencode --version 2>/dev/null | head -n 1) installed to /usr/local/bin/opencode."
fi

# Copy runtime setup script
INSTALL_DIR="/usr/local/share/opencode"
mkdir -p "$INSTALL_DIR"
cp "$(dirname "$0")/setup-opencode.sh" "$INSTALL_DIR/setup-opencode.sh"
chmod +x "$INSTALL_DIR/setup-opencode.sh"

echo "OpenCode feature installed successfully."
