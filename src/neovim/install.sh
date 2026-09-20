#!/usr/bin/env bash
set -e

export DEBIAN_FRONTEND=noninteractive
export TZ=Etc/UTC

VERSION="${VERSION:-latest}"
INSTALL_DEV_TOOLS="${INSTALLDEVTOOLS:-true}"
INSTALL_LINTERS="${INSTALLLINTERS:-true}"

echo "Installing Neovim feature (version: $VERSION)..."

# Install dev tools (ripgrep, fd, build-essential, curl, tar)
if [ "$INSTALL_DEV_TOOLS" = "true" ]; then
  if [ -x "$(command -v apt-get)" ]; then
    apt-get update -y
    apt-get install -y --no-install-recommends ripgrep fd-find build-essential curl tar ca-certificates
    rm -rf /var/lib/apt/lists/*
  elif [ -x "$(command -v apk)" ]; then
    apk add --no-cache ripgrep fd build-base curl tar ca-certificates
  fi

  # Symlink fd if fdfind exists
  if command -v fdfind &>/dev/null && ! command -v fd &>/dev/null; then
    ln -sf "$(command -v fdfind)" /usr/local/bin/fd
  fi
fi

# Detect architecture for Neovim binary
ARCH=$(dpkg --print-architecture 2>/dev/null || uname -m)
if [ "$ARCH" = "arm64" ] || [ "$ARCH" = "aarch64" ]; then
  NVIM_ARCH="arm64"
else
  NVIM_ARCH="x86_64"
fi

echo "Downloading Neovim for architecture: $NVIM_ARCH..."
if [ "$VERSION" = "latest" ]; then
  NVIM_URL="https://github.com/neovim/neovim/releases/latest/download/nvim-linux-$NVIM_ARCH.tar.gz"
else
  NVIM_URL="https://github.com/neovim/neovim/releases/download/$VERSION/nvim-linux-$NVIM_ARCH.tar.gz"
fi

curl -fsSL "$NVIM_URL" -o /tmp/nvim.tar.gz
mkdir -p /opt
tar -C /opt -xzf /tmp/nvim.tar.gz
rm -f /tmp/nvim.tar.gz

NVIM_DIR=$(find /opt -maxdepth 1 -name "nvim-linux*" | head -n 1)
if [ -n "$NVIM_DIR" ] && [ -x "$NVIM_DIR/bin/nvim" ]; then
  ln -sf "$NVIM_DIR/bin/nvim" /usr/local/bin/nvim
  echo "Neovim successfully linked to /usr/local/bin/nvim."
fi

# Check if the binary can execute (glibc compatibility check)
if ! /usr/local/bin/nvim --version &>/dev/null; then
  echo "Notice: Prebuilt Neovim binary requires newer glibc than provided by this OS. Falling back to system neovim package..."
  rm -f /usr/local/bin/nvim
  if [ -x "$(command -v apt-get)" ]; then
    apt-get update -y
    apt-get install -y --no-install-recommends software-properties-common
    add-apt-repository -y ppa:neovim-ppa/unstable 2>/dev/null || true
    apt-get update -y
    apt-get install -y --no-install-recommends neovim
    rm -rf /var/lib/apt/lists/*
  elif [ -x "$(command -v apk)" ]; then
    apk add --no-cache neovim
  fi
fi

# Install linters if npm is present
if [ "$INSTALL_LINTERS" = "true" ] && command -v npm &>/dev/null; then
  echo "Installing eslint_d and @fsouza/prettierd..."
  npm install -g eslint_d @fsouza/prettierd || true
fi

# Copy post-create script
INSTALL_DIR="/usr/local/share/neovim"
mkdir -p "$INSTALL_DIR"
cp "$(dirname "$0")/post-create.sh" "$INSTALL_DIR/post-create.sh"
chmod +x "$INSTALL_DIR/post-create.sh"

echo "Neovim feature installation complete."
