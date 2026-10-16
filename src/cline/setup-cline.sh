#!/usr/bin/env bash
set -e

FEATURE=cline
# shellcheck source=../../lib/common.sh
source /usr/local/share/cline/common.sh
load_options

VERSION="${VERSION:-latest}"

log "Setting up Cline environment..."

resolve_owner

# Non-node users reach the host settings mounted under /home/node.
# Linking has to happen before anything below creates these paths.
link_from_node_home .cline/data/settings
# Shared skills (mounted by the antigravity feature) are discovered natively by Cline
link_from_node_home .agents

# Repeat the build-time ownership fix with the uid that is actually running. The settings
# mount itself is skipped: it is the developer's host directory.
ensure_owned_dir "$HOME" .cline/data/settings
warn_unless_writable "$HOME/.cline/data/settings"

# Install Cline CLI if missing (e.g. image was built offline)
if ! command -v cline &>/dev/null; then
  log "Cline CLI not found; installing..."
  as_root bash /usr/local/share/cline/install-cline.sh "$VERSION" ||
    warn "Cline CLI install failed (offline, or no root/sudo)."
fi

if command -v cline &>/dev/null; then
  log "Cline $(cline --version 2>/dev/null | head -n 1) is ready."
else
  warn "Cline CLI is not available. Install it manually with: npm install -g cline"
fi

log "Cline setup finished."
