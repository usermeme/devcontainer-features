#!/usr/bin/env bash
# Build time, as root: install the Kilo Code CLI and prepare its directories under /home/node.
set -e

log() { echo "[kilocode] $*"; }
warn() { echo "[kilocode] WARNING: $*" >&2; }

VERSION="${VERSION:-latest}"

log "Installing Kilo Code feature (version: $VERSION)..."

# Kilo CLI creates its XDG dirs on startup (packages/core/src/global.ts in the kilocode repo):
# config is bind-mounted from the host (~/.config/kilo), data is the kilocode-data volume
# (~/.local/share/kilo: auth.json with logins, sessions, logs, repos), state and cache are
# container-local. All of them and their ancestors must belong to node, or Kilo fails with
# EACCES creating them. The mounts target /home/node, so only the node user is supported.
# Every level is listed: `install -d` would leave the parents it creates root-owned.
OWNER=node
id node &>/dev/null || OWNER=root
[ "${_REMOTE_USER:-node}" = node ] || warn "remoteUser is '$_REMOTE_USER': the mounts live in /home/node and only the node user is supported."
install -d -o "$OWNER" -g "$OWNER" -m 755 \
  /home/node/.config /home/node/.config/kilo \
  /home/node/.local /home/node/.local/share /home/node/.local/share/kilo \
  /home/node/.local/state /home/node/.local/state/kilo \
  /home/node/.cache /home/node/.cache/kilo

# Best effort: when the build has no network access, setup-kilocode.sh retries at container startup
status=0
bash "$(dirname "$0")/install-kilocode.sh" "$VERSION" || status=$?
if [ "$status" = "2" ]; then
  echo "[kilocode] ERROR: Kilo Code CLI download failed verification; refusing to continue." >&2
  exit 1
elif [ "$status" != "0" ]; then
  warn "Kilo Code CLI not installed; setup-kilocode.sh will retry during postCreate."
fi

# Verify the binary can execute (glibc/CPU compatibility check). A broken one would stay on PATH
# and make setup-kilocode.sh report it as ready.
if [ -x /usr/local/bin/kilo ] && ! /usr/local/bin/kilo --version &>/dev/null; then
  warn "Prebuilt Kilo Code CLI is not runnable on this base image; removing it. Install it with: npm install -g @kilocode/cli"
  rm -rf /usr/local/bin/kilo /usr/local/bin/kilocode /usr/local/lib/kilocode
fi

# Feature options only exist while install.sh runs: keep them for postCreate.
mkdir -p /usr/local/share/kilocode
printf 'VERSION=%q\n' "$VERSION" >/usr/local/share/kilocode/options.env
install -m 755 "$(dirname "$0")/setup-kilocode.sh" "$(dirname "$0")/install-kilocode.sh" /usr/local/share/kilocode/

log "Kilo Code feature installed successfully."
