#!/usr/bin/env bash
set -e

FEATURE=yarn
# shellcheck source=../../lib/common.sh
source "$(dirname "$0")/common.sh"

VERSION="${VERSION:-latest}"
RUNINSTALL="${RUNINSTALL:-false}"
IMMUTABLE="${IMMUTABLE:-true}"

log "Installing Yarn feature (version: $VERSION)..."

if ! command -v curl &>/dev/null; then
  install_packages curl ca-certificates
fi

resolve_build_owner

YARN_SPEC="$VERSION"
[ "$VERSION" = "latest" ] && YARN_SPEC="stable"

# A failed `prepare` still leaves the Corepack shim on PATH, which would skip the fallback
# below and silently ignore a pinned version: fail the build instead.
if command -v corepack &>/dev/null && ! corepack_activate yarn "$YARN_SPEC"; then
  [ "$VERSION" = "latest" ] || die "Corepack could not activate yarn@$YARN_SPEC (offline, or unknown version)."
  warn "Corepack could not pre-download yarn; it will be fetched on first use."
fi

if ! command -v yarn &>/dev/null; then
  command -v npm &>/dev/null || die "Yarn needs Node.js (Corepack or npm) in the image; add a Node feature or use a Node base image."
  log "Installing yarn via npm..."
  if [ "$VERSION" = "latest" ]; then
    npm install -g yarn
  else
    npm install -g "yarn@$VERSION"
  fi
fi
command -v yarn &>/dev/null || die "yarn $VERSION could not be installed."

# Cache volume mount point: owned by the remote user, never 777 (the volume is shared by
# every devcontainer on this machine, so anyone able to write it can poison other projects).
ensure_owned_dir "$NODE_HOME" .cache/yarn 755

persist_options RUNINSTALL IMMUTABLE
install_runtime setup-yarn.sh

log "Yarn feature installed successfully."
