#!/usr/bin/env bash
set -e

FEATURE=antigravity
# shellcheck source=../../lib/common.sh
source "$(dirname "$0")/common.sh"

SYMLINKSKILLS="${SYMLINKSKILLS:-true}"

log "Installing Antigravity feature..."

if ! command -v curl &>/dev/null; then
  install_packages curl ca-certificates bash
fi

# Mount points and ~/.local/bin (first on PATH) belong to the remote user, never 777:
# a world-writable dir on PATH lets any process in the container plant a fake `git` or `sudo`.
resolve_build_owner
for rel in .gemini .agents/skills .config/gcloud .local/bin; do
  ensure_owned_dir "$NODE_HOME" "$rel" 755
done

persist_options SYMLINKSKILLS
install_runtime setup-antigravity.sh

log "Antigravity feature installed successfully."
