#!/usr/bin/env bash
# Build time, as root: prepare /home/node/.hermes and install the Hermes Agent CLI.
set -e

log() { echo "[hermes] $*"; }
warn() { echo "[hermes] WARNING: $*" >&2; }

VERSION="${VERSION:-latest}"

log "Installing Hermes Agent feature (version: $VERSION)..."

# Mount target: /home/node/.hermes
# The mount targets /home/node, so only the node user is supported.
# install -d creates the directory with proper owner and permissions.
OWNER=node
id node &>/dev/null || OWNER=root
[ "${_REMOTE_USER:-node}" = node ] || warn "remoteUser is '$_REMOTE_USER': the mount lives in /home/node and only the node user is supported."
install -d -o "$OWNER" -g "$OWNER" -m 755 /home/node/.hermes

# Best effort: when the build has no network access, setup-hermes.sh retries at container startup
status=0
bash "$(dirname "$0")/install-hermes.sh" "$VERSION" || status=$?
if [ "$status" != "0" ]; then
  warn "Hermes Agent CLI not installed; setup-hermes.sh will retry during postCreate."
fi

# Verify the binary can execute
if [ -x /usr/local/bin/hermes ] && ! /usr/local/bin/hermes --version &>/dev/null; then
  warn "Prebuilt Hermes Agent CLI is not runnable on this base image; removing it."
  rm -rf /usr/local/bin/hermes /usr/local/bin/hermes-agent /usr/local/lib/hermes-agent
fi

# Feature options only exist while install.sh runs: keep them for postCreate.
mkdir -p /usr/local/share/hermes
printf 'VERSION=%q\n' "$VERSION" >/usr/local/share/hermes/options.env
install -m 755 "$(dirname "$0")/setup-hermes.sh" "$(dirname "$0")/install-hermes.sh" /usr/local/share/hermes/

log "Hermes Agent feature installed successfully."
