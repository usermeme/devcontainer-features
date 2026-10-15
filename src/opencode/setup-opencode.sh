#!/usr/bin/env bash
set -e

FEATURE=opencode
# shellcheck source=../../lib/common.sh
source /usr/local/share/opencode/common.sh
load_options

VERSION="${VERSION:-latest}"

log "Setting up OpenCode environment..."

resolve_owner

# Non-node users reach the host config and credentials mounted under /home/node.
# Linking has to happen before anything below creates these paths.
link_from_node_home .config/opencode
link_from_node_home .local/share/opencode
# Shared skills (mounted by the antigravity feature) are discovered natively by OpenCode
link_from_node_home .agents

# Repeat the build-time ownership fix with the uid that is actually running: OpenCode
# creates its state and cache dirs on startup and fails with EACCES under a root-owned parent.
for rel in .config/opencode .local/share/opencode .local/state/opencode .cache/opencode .opencode/bin; do
  ensure_owned_dir "$HOME" "$rel"
done
warn_unless_writable "$HOME/.config/opencode" "$HOME/.local/share/opencode"

# Install OpenCode CLI if missing (e.g. image was built offline)
if ! command -v opencode &>/dev/null; then
  log "OpenCode CLI not found; installing via the official installer..."
  OC_INSTALLER="$(mktemp)"
  OC_INSTALL_ARGS=()
  if [ "$VERSION" != "latest" ]; then
    OC_INSTALL_ARGS=(--version "$VERSION")
  fi
  if fetch https://opencode.ai/v2/install "$OC_INSTALLER"; then
    bash "$OC_INSTALLER" "${OC_INSTALL_ARGS[@]}" || warn "OpenCode CLI install failed."
  else
    warn "OpenCode CLI install skipped (network unreachable or offline)."
  fi
  rm -f "$OC_INSTALLER"
fi

if command -v opencode &>/dev/null; then
  log "OpenCode $(opencode --version 2>/dev/null | head -n 1) is ready."
elif [ -x "$HOME/.opencode/bin/opencode" ]; then
  log "OpenCode installed to $HOME/.opencode/bin; open a new shell to pick up PATH."
else
  warn "OpenCode CLI is not available yet. Install it manually with: curl -fsSL https://opencode.ai/v2/install -o /tmp/oc.sh && bash /tmp/oc.sh"
fi

log "OpenCode setup finished."
