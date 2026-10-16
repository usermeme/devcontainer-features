#!/usr/bin/env bash
# Build time, as root: prepare the mount points under /home/node and install setup-antigravity.sh.
set -e

log() { echo "[antigravity] $*"; }
warn() { echo "[antigravity] WARNING: $*" >&2; }

SYMLINKSKILLS="${SYMLINKSKILLS:-true}"

log "Installing Antigravity feature..."

if ! command -v curl &>/dev/null; then
  if command -v apt-get &>/dev/null; then
    apt-get update -y && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends curl ca-certificates && rm -rf /var/lib/apt/lists/*
  elif command -v apk &>/dev/null; then
    apk add --no-cache curl ca-certificates bash
  elif command -v dnf &>/dev/null; then
    dnf install -y curl ca-certificates
  fi
fi

# The mounts target /home/node (devcontainer-feature.json cannot reference the remote user),
# so only the node user is supported. Every level is listed: `install -d` would leave the
# parents it creates root-owned, and a root-owned ~/.local breaks every tool writing there.
# Never 777: ~/.local/bin is on PATH, and a world-writable dir there lets any process plant
# a fake `git` or `sudo`.
OWNER=node
id node &>/dev/null || OWNER=root
[ "${_REMOTE_USER:-node}" = node ] || warn "remoteUser is '$_REMOTE_USER': the mounts live in /home/node and only the node user is supported."
install -d -o "$OWNER" -g "$OWNER" -m 755 \
  /home/node/.gemini /home/node/.agents /home/node/.agents/skills \
  /home/node/.config /home/node/.config/gcloud /home/node/.local /home/node/.local/bin

# Feature options only exist while install.sh runs: keep them for postCreate.
mkdir -p /usr/local/share/antigravity
printf 'SYMLINKSKILLS=%q\n' "$SYMLINKSKILLS" >/usr/local/share/antigravity/options.env
install -m 755 "$(dirname "$0")/setup-antigravity.sh" /usr/local/share/antigravity/

log "Antigravity feature installed successfully."
