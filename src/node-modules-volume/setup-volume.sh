#!/usr/bin/env bash
set -e

FEATURE=node-modules-volume
# shellcheck source=../../lib/common.sh
source /usr/local/share/node-modules-volume/common.sh

# postCreateCommand runs in the workspace folder, where the volume is mounted.
NODE_MODULES="$PWD/node_modules"

log "Ensuring $NODE_MODULES is writable..."

resolve_owner

if ! is_mount "$NODE_MODULES"; then
  warn "$NODE_MODULES is not a volume mount. The volume targets /workspaces/<folder name>/node_modules; a custom workspaceFolder or workspaceMount does not get it."
  exit 0
fi

# A fresh named volume is mounted root-owned. Only its top level is claimed (no -R: it can
# hold 100k+ files and is kept across rebuilds), and only when it is not ours.
claim_dir "$NODE_MODULES"
warn_unless_writable "$NODE_MODULES"

log "Setup finished."
