#!/usr/bin/env bash
# Build time, as root: install the OpenCode binary and prepare its directories under /home/node.
set -e

log() { echo "[opencode] $*"; }
warn() { echo "[opencode] WARNING: $*" >&2; }

VERSION="${VERSION:-latest}"

log "Installing OpenCode feature (version: $VERSION)..."

if ! command -v curl &>/dev/null || ! command -v tar &>/dev/null; then
  if command -v apt-get &>/dev/null; then
    apt-get update -y && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends curl tar ca-certificates && rm -rf /var/lib/apt/lists/*
  elif command -v apk &>/dev/null; then
    apk add --no-cache curl tar ca-certificates
  elif command -v dnf &>/dev/null; then
    dnf install -y curl tar ca-certificates
  fi
fi

# OpenCode creates four XDG dirs on startup (packages/util/src/global.ts in the opencode repo):
# config is bind-mounted from the host, data is the opencode-data volume (Docker seeds a new
# volume with this dir's ownership), state and cache are container-local. All of them and
# their ancestors must belong to node, or OpenCode fails with
#   Error: EACCES: permission denied, mkdir '/home/node/.local/state'
# The mounts target /home/node, so only the node user is supported. Every level is listed:
# `install -d` would leave the parents it creates root-owned.
OWNER=node
id node &>/dev/null || OWNER=root
[ "${_REMOTE_USER:-node}" = node ] || warn "remoteUser is '$_REMOTE_USER': the mounts live in /home/node and only the node user is supported."
install -d -o "$OWNER" -g "$OWNER" -m 755 \
  /home/node/.config /home/node/.config/opencode \
  /home/node/.local /home/node/.local/share /home/node/.local/share/opencode \
  /home/node/.local/state /home/node/.local/state/opencode \
  /home/node/.cache /home/node/.cache/opencode \
  /home/node/.opencode /home/node/.opencode/bin

# Detect architecture and libc for the official OpenCode binary
case "$(uname -m)" in
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
  log "Downloading OpenCode from $OC_URL..."
  TMP_DIR=$(mktemp -d)
  if curl -fsSL --proto '=https' --tlsv1.2 --retry 3 "$OC_URL" -o "$TMP_DIR/opencode.tar.gz"; then
    tar -xzf "$TMP_DIR/opencode.tar.gz" -C "$TMP_DIR"
    OC_BIN=$(find "$TMP_DIR" -type f -name opencode | head -n 1)
    if [ -n "$OC_BIN" ]; then
      cp "$OC_BIN" /usr/local/bin/opencode
      chmod 755 /usr/local/bin/opencode
    fi
  else
    warn "OpenCode download failed; setup-opencode.sh will retry during postCreate."
  fi
  rm -rf "$TMP_DIR"
elif [ "$VERSION" != "latest" ]; then
  # Pinned versions are resolved by the official installer (npm registry packages)
  log "Installing OpenCode $VERSION via the official installer..."
  TMP_HOME=$(mktemp -d)
  if curl -fsSL --proto '=https' --tlsv1.2 --retry 3 https://opencode.ai/v2/install -o "$TMP_HOME/install.sh"; then
    HOME="$TMP_HOME" bash "$TMP_HOME/install.sh" --version "$VERSION" --no-modify-path || warn "official installer failed for version $VERSION."
    if [ -f "$TMP_HOME/.opencode/bin/opencode" ]; then
      cp "$TMP_HOME/.opencode/bin/opencode" /usr/local/bin/opencode
      chmod 755 /usr/local/bin/opencode
    fi
  else
    warn "OpenCode installer download failed; setup-opencode.sh will retry during postCreate."
  fi
  rm -rf "$TMP_HOME"
fi

# Verify the binary can execute (glibc/baseline compatibility check)
if [ -f /usr/local/bin/opencode ] && ! /usr/local/bin/opencode --version &>/dev/null; then
  log "Prebuilt OpenCode binary is not runnable on this base image; setup-opencode.sh will retry during postCreate."
  rm -f /usr/local/bin/opencode
fi

if [ -f /usr/local/bin/opencode ]; then
  log "OpenCode $(/usr/local/bin/opencode --version 2>/dev/null | head -n 1) installed to /usr/local/bin/opencode."
fi

# Feature options only exist while install.sh runs: keep them for postCreate.
mkdir -p /usr/local/share/opencode
printf 'VERSION=%q\n' "$VERSION" >/usr/local/share/opencode/options.env
install -m 755 "$(dirname "$0")/setup-opencode.sh" /usr/local/share/opencode/

log "OpenCode feature installed successfully."
