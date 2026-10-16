#!/usr/bin/env bash
# postCreate, as the container user: hand the node_modules volume to that user.
set -e

log() { echo "[node-modules-volume] $*"; }
warn() { echo "[node-modules-volume] WARNING: $*" >&2; }
as_root() { if [ "$(id -u)" = 0 ]; then "$@"; else sudo -n "$@"; fi; }

# postCreateCommand runs in the workspace folder, where the volume is mounted.
NODE_MODULES="$PWD/node_modules"

log "Ensuring $NODE_MODULES is writable..."

# Read /proc directly: busybox-based images have no util-linux `mountpoint`.
if ! awk -v p="$(readlink -f "$NODE_MODULES" 2>/dev/null)" '$5==p{found=1} END{exit !found}' /proc/self/mountinfo 2>/dev/null; then
  warn "$NODE_MODULES is not a volume mount. The volume targets /workspaces/<folder name>/node_modules; a custom workspaceFolder or workspaceMount does not get it."
  exit 0
fi

# A fresh named volume is mounted root-owned. Only its top level is claimed (no -R: it can
# hold 100k+ files and is kept across rebuilds), and only when it is not ours.
[ -O "$NODE_MODULES" ] || as_root chown "$(id -u):$(id -g)" "$NODE_MODULES" ||
  warn "$NODE_MODULES is not owned by $(id -un) and could not be fixed. Fix it with: docker exec -u root <container> chown $(id -un): $NODE_MODULES"
[ -w "$NODE_MODULES" ] || warn "$NODE_MODULES is not writable by $(id -un)."

log "Setup finished."
