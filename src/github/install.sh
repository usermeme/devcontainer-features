#!/usr/bin/env bash
# Build time, as root: install GitHub CLI (gh) if needed and configure system Git to authenticate
# with GH_TOKEN / GITHUB_TOKEN (populated at runtime from host DEVCONTAINER_GITHUB_TOKEN).
set -e

log() { echo "[github] $*"; }
warn() { echo "[github] WARNING: $*" >&2; }
die() {
  echo "[github] ERROR: $*" >&2
  exit 1
}
install_packages() {
  if command -v apt-get &>/dev/null; then
    apt-get update -y && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends "$@" && rm -rf /var/lib/apt/lists/*
  elif command -v apk &>/dev/null; then
    apk add --no-cache "$@"
  elif command -v dnf &>/dev/null; then
    dnf install -y "$@"
  else
    warn "no supported package manager found to install: $*"
    return 1
  fi
}

VERSION="${VERSION:-latest}"
GITPROTOCOL="${GITPROTOCOL:-https}"

log "Installing GitHub feature (version: $VERSION, gitProtocol: $GITPROTOCOL)..."

if ! [[ "$VERSION" =~ ^[0-9A-Za-z][0-9A-Za-z.+-]*$ ]]; then
  die "invalid version '$VERSION'"
fi

if ! command -v git &>/dev/null; then
  log "Installing Git..."
  install_packages git ca-certificates
fi

if [ "$VERSION" = "latest" ] && command -v gh &>/dev/null; then
  log "GitHub CLI already installed ($(gh --version | head -n 1)); skipping download."
else
  if ! command -v curl &>/dev/null || ! command -v tar &>/dev/null; then
    install_packages curl tar ca-certificates
  fi

  case "$(uname -m)" in
    x86_64 | amd64) GH_ARCH="amd64" ;;
    aarch64 | arm64) GH_ARCH="arm64" ;;
    *) GH_ARCH="" ;;
  esac

  if [ -n "$GH_ARCH" ]; then
    GH_VERSION="${VERSION#v}"
    if [ "$GH_VERSION" = "latest" ]; then
      LATEST_URL="$(curl -fsSLI --proto '=https' --tlsv1.2 --retry 3 -o /dev/null -w '%{url_effective}' https://github.com/cli/cli/releases/latest || true)"
      GH_VERSION="${LATEST_URL##*/v}"
    fi

    if [[ "$GH_VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+[0-9A-Za-z.+-]*$ ]]; then
      ASSET="gh_${GH_VERSION}_linux_${GH_ARCH}.tar.gz"
      BASE_URL="https://github.com/cli/cli/releases/download/v${GH_VERSION}"
      TMP_DIR="$(mktemp -d)"
      log "Downloading GitHub CLI v${GH_VERSION} (${GH_ARCH})..."
      if curl -fsSL --proto '=https' --tlsv1.2 --retry 3 "${BASE_URL}/${ASSET}" -o "$TMP_DIR/$ASSET" &&
        curl -fsSL --proto '=https' --tlsv1.2 --retry 3 "${BASE_URL}/gh_${GH_VERSION}_checksums.txt" -o "$TMP_DIR/checksums.txt"; then
        EXPECTED_LINE="$(grep -F "  ${ASSET}" "$TMP_DIR/checksums.txt" | head -n 1 || true)"
        if [ -z "$EXPECTED_LINE" ]; then
          rm -rf "$TMP_DIR"
          die "could not find checksum for ${ASSET} in gh_${GH_VERSION}_checksums.txt"
        fi
        if ! (cd "$TMP_DIR" && printf '%s\n' "$EXPECTED_LINE" | sha256sum -c - >/dev/null 2>&1); then
          rm -rf "$TMP_DIR"
          die "SHA-256 checksum mismatch for ${ASSET}; refusing to install"
        fi
        tar --no-same-owner -xzf "$TMP_DIR/$ASSET" -C "$TMP_DIR"
        install -o root -g root -m 755 "$TMP_DIR/gh_${GH_VERSION}_linux_${GH_ARCH}/bin/gh" /usr/local/bin/gh
      else
        warn "GitHub CLI release download failed; falling back to package manager."
      fi
      rm -rf "$TMP_DIR"
    else
      warn "could not resolve GitHub CLI release version ('$VERSION'); falling back to package manager."
    fi
  fi

  if ! command -v gh &>/dev/null; then
    log "Installing GitHub CLI via system package manager..."
    if command -v apk &>/dev/null; then
      install_packages github-cli || true
    else
      install_packages gh || true
    fi
  fi
fi

command -v gh &>/dev/null || die "GitHub CLI (gh) could not be installed."
log "$(gh --version | head -n 1) ready."

# Git settings go to the image's system config (/etc/gitconfig), never to ~/.gitconfig:
# with the dotfiles feature ~/.gitconfig can be a symlink into the developer's host dotfiles repo.
GH_BIN="$(command -v gh)"
for host in "https://github.com" "https://gist.github.com"; do
  # An empty helper entry resets any previously defined credential helpers before invoking gh.
  git -C / config --system --replace-all "credential.${host}.helper" ""
  git -C / config --system --add "credential.${host}.helper" "!${GH_BIN} auth git-credential"
done

if [ "$GITPROTOCOL" = "https" ]; then
  # Rewrite SSH GitHub remotes to HTTPS inside the container so git push/fetch uses the restricted
  # token via gh rather than an unrestricted host SSH key forwarded over SSH_AUTH_SOCK.
  for prefix in "git@github.com:" "ssh://git@github.com/"; do
    git -C / config --system --get-all url."https://github.com/".insteadOf 2>/dev/null | grep -qxF "$prefix" ||
      git -C / config --system --add url."https://github.com/".insteadOf "$prefix"
  done
fi

log "GitHub feature installed successfully."
