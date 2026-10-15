#!/usr/bin/env bash
set -e

FEATURE=neovim
# shellcheck source=../../lib/common.sh
source "$(dirname "$0")/common.sh"

export TZ=Etc/UTC

VERSION="${VERSION:-latest}"
INSTALLDEVTOOLS="${INSTALLDEVTOOLS:-true}"
INSTALLLINTERS="${INSTALLLINTERS:-true}"

log "Installing Neovim feature (version: $VERSION)..."

# curl/tar are needed for the download whether or not the dev tools are wanted
ensure_download_tools

if [ "$INSTALLDEVTOOLS" = "true" ]; then
  if command -v apt-get &>/dev/null; then
    install_packages ripgrep fd-find build-essential
  elif command -v apk &>/dev/null; then
    install_packages ripgrep fd build-base
  else
    warn "no supported package manager; skipping ripgrep, fd and build tools"
  fi

  # Debian/Ubuntu ship fd as fdfind
  if command -v fdfind &>/dev/null && ! command -v fd &>/dev/null; then
    ln -sf "$(command -v fdfind)" /usr/local/bin/fd
  fi
fi

# Official release binaries exist for x86_64 and arm64 only; other architectures use the
# distro package below instead of downloading a binary that cannot run.
case "$(uname -m)" in
  x86_64 | amd64) NVIM_ARCH="x86_64" ;;
  aarch64 | arm64) NVIM_ARCH="arm64" ;;
  *) NVIM_ARCH="" ;;
esac

# Release tags carry a "v" prefix; accept "0.10.4" as well as "v0.10.4".
NVIM_TAG="$VERSION"
case "$NVIM_TAG" in
  latest | v*) ;;
  *) NVIM_TAG="v$NVIM_TAG" ;;
esac

if [ -n "$NVIM_ARCH" ]; then
  if [ "$NVIM_TAG" = "latest" ]; then
    NVIM_BASE_URL="https://github.com/neovim/neovim/releases/latest/download"
  else
    NVIM_BASE_URL="https://github.com/neovim/neovim/releases/download/$NVIM_TAG"
  fi
  # Releases before v0.10.4 named the x86_64 archive nvim-linux64.tar.gz
  NVIM_ASSETS="nvim-linux-$NVIM_ARCH.tar.gz"
  [ "$NVIM_ARCH" = "x86_64" ] && NVIM_ASSETS="$NVIM_ASSETS nvim-linux64.tar.gz"

  # Neovim releases publish no checksum file, so integrity relies on HTTPS to GitHub.
  TMP_DIR="$(mktemp -d)"
  NVIM_ARCHIVE=""
  for asset in $NVIM_ASSETS; do
    log "Downloading $NVIM_BASE_URL/$asset..."
    if fetch "$NVIM_BASE_URL/$asset" "$TMP_DIR/nvim.tar.gz"; then
      NVIM_ARCHIVE="$TMP_DIR/nvim.tar.gz"
      break
    fi
  done
  if [ -n "$NVIM_ARCHIVE" ]; then
    # Replace any previous extraction so a rebuild never links a stale version
    NVIM_TOP="$(tar -tzf "$NVIM_ARCHIVE" | head -n 1 | cut -d/ -f1)"
    case "$NVIM_TOP" in
      nvim-*) ;;
      *) die "unexpected Neovim archive layout (top-level entry: '$NVIM_TOP')" ;;
    esac
    NVIM_DIR="/opt/$NVIM_TOP"
    rm -rf "$NVIM_DIR"
    tar -C /opt -xzf "$NVIM_ARCHIVE"
    ln -sf "$NVIM_DIR/bin/nvim" /usr/local/bin/nvim
  else
    warn "Neovim $NVIM_TAG download failed; falling back to the distro package."
  fi
  rm -rf "$TMP_DIR"
fi

# Missing, or the prebuilt binary needs a newer glibc than this OS provides
if ! /usr/local/bin/nvim --version &>/dev/null; then
  log "Prebuilt Neovim is not usable here. Falling back to the system neovim package..."
  rm -f /usr/local/bin/nvim
  if command -v apt-get &>/dev/null; then
    install_packages software-properties-common
    add-apt-repository -y ppa:neovim-ppa/unstable 2>/dev/null || warn "could not add the neovim PPA; using the distro version"
    install_packages neovim
  elif command -v apk &>/dev/null; then
    install_packages neovim
  fi
fi
command -v nvim &>/dev/null || die "Neovim could not be installed."
log "$(nvim --version | head -n 1) installed."

if [ "$INSTALLLINTERS" = "true" ] && command -v npm &>/dev/null; then
  log "Installing eslint_d and @fsouza/prettierd..."
  npm install -g eslint_d @fsouza/prettierd || warn "linter install failed; post-create will retry."
fi

persist_options INSTALLLINTERS
install_runtime post-create.sh

log "Neovim feature installation complete."
