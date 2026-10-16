#!/usr/bin/env bash
set -e

FEATURE=cline
# shellcheck source=../../lib/common.sh
source "$(dirname "$0")/common.sh"

VERSION="${VERSION:-latest}"

log "Installing Cline feature (version: $VERSION)..."

# Only ~/.cline/data/settings is mounted from the host. Cline keeps sessions (SQLite), task
# history and the hub daemon's PID/port records in the rest of ~/.cline/data, which must stay
# in the container and belong to the remote user, or Cline fails with EACCES creating them.
resolve_build_owner
ensure_owned_dir "$NODE_HOME" .cline/data/settings 755

# Best effort: when the build has no network access, setup-cline.sh retries at container startup
status=0
bash "$FEATURE_SRC/install-cline.sh" "$VERSION" || status=$?
if [ "$status" = "2" ]; then
  die "Cline CLI download failed verification; refusing to continue."
elif [ "$status" != "0" ]; then
  warn "Cline CLI not installed; setup-cline.sh will retry during postCreate."
fi

# Verify the binary can execute (glibc/CPU compatibility check). A broken one would stay on PATH
# and make setup-cline.sh report it as ready.
if [ -x /usr/local/bin/cline ] && ! /usr/local/bin/cline --version &>/dev/null; then
  warn "Prebuilt Cline CLI is not runnable on this base image; removing it. Install it with: npm install -g cline"
  rm -rf /usr/local/bin/cline /usr/local/lib/cline
fi

persist_options VERSION
install_runtime setup-cline.sh install-cline.sh

log "Cline feature installed successfully."
