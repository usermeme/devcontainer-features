#!/usr/bin/env bash
# Build time, as root: install the Cline CLI and prepare ~/.cline under /home/node.
set -e

log() { echo "[cline] $*"; }
warn() { echo "[cline] WARNING: $*" >&2; }

VERSION="${VERSION:-latest}"

log "Installing Cline feature (version: $VERSION)..."

# Only ~/.cline/data/settings is mounted from the host. Cline keeps sessions (SQLite), task
# history and the hub daemon's PID/port records in the rest of ~/.cline/data, which must stay
# in the container and belong to node, or Cline fails with EACCES creating them.
# The mount targets /home/node, so only the node user is supported. Every level is listed:
# `install -d` would leave the parents it creates root-owned.
OWNER=node
id node &>/dev/null || OWNER=root
[ "${_REMOTE_USER:-node}" = node ] || warn "remoteUser is '$_REMOTE_USER': the mount lives in /home/node and only the node user is supported."
install -d -o "$OWNER" -g "$OWNER" -m 755 /home/node/.cline /home/node/.cline/data /home/node/.cline/data/settings

# Best effort: when the build has no network access, setup-cline.sh retries at container startup
status=0
bash "$(dirname "$0")/install-cline.sh" "$VERSION" || status=$?
if [ "$status" = "2" ]; then
  echo "[cline] ERROR: Cline CLI download failed verification; refusing to continue." >&2
  exit 1
elif [ "$status" != "0" ]; then
  warn "Cline CLI not installed; setup-cline.sh will retry during postCreate."
fi

# Verify the binary can execute (glibc/CPU compatibility check). A broken one would stay on PATH
# and make setup-cline.sh report it as ready.
if [ -x /usr/local/bin/cline ] && ! /usr/local/bin/cline --version &>/dev/null; then
  warn "Prebuilt Cline CLI is not runnable on this base image; removing it. Install it with: npm install -g cline"
  rm -rf /usr/local/bin/cline /usr/local/lib/cline
fi

# Feature options only exist while install.sh runs: keep them for postCreate.
mkdir -p /usr/local/share/cline
printf 'VERSION=%q\n' "$VERSION" >/usr/local/share/cline/options.env
install -m 755 "$(dirname "$0")/setup-cline.sh" "$(dirname "$0")/install-cline.sh" /usr/local/share/cline/

log "Cline feature installed successfully."
