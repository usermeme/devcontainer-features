#!/usr/bin/env bash
# Build time, as root: prepare mount points under /home/node and install setup-penpot.sh.
set -e

log() { echo "[penpot] $*"; }
warn() { echo "[penpot] WARNING: $*" >&2; }

SYMLINKPENPOT="${SYMLINKPENPOT:-true}"

log "Installing Penpot feature..."

# The mounts target /home/node (devcontainer-feature.json cannot reference the remote user),
# so only the node user is supported.
OWNER=node
id node &>/dev/null || OWNER=root
[ "${_REMOTE_USER:-node}" = node ] || warn "remoteUser is '$_REMOTE_USER': the mounts live in /home/node and only the node user is supported."
install -d -o "$OWNER" -g "$OWNER" -m 755 /home/node/.penpot-ai-kit

# Feature options only exist while install.sh runs: keep them for postCreate.
mkdir -p /usr/local/share/penpot
printf 'SYMLINKPENPOT=%q\n' "$SYMLINKPENPOT" >/usr/local/share/penpot/options.env
install -m 755 "$(dirname "$0")/setup-penpot.sh" /usr/local/share/penpot/

log "Penpot feature installed successfully."
