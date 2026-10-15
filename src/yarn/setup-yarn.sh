#!/usr/bin/env bash
set -e

FEATURE=yarn
# shellcheck source=../../lib/common.sh
source /usr/local/share/yarn/common.sh
load_options

RUN_INSTALL="${RUNINSTALL:-false}"
IMMUTABLE="${IMMUTABLE:-true}"

CACHE_DIR="$NODE_HOME/.cache/yarn"

log "Configuring yarn cache..."

resolve_owner

link_from_node_home .cache/yarn

ensure_owned_dir "$NODE_HOME" .cache
# yarn-cache is a named volume shared by every devcontainer on this machine. Only its top
# level is claimed, and only when it is not ours: a recursive chown would walk the whole
# cache on every create and take files away from projects running under another uid.
claim_dir "$CACHE_DIR"
drop_world_write "$CACHE_DIR"
claim_corepack_home
warn_unless_writable "$CACHE_DIR"

if [ "$RUN_INSTALL" = "true" ]; then
  if [ -f "yarn.lock" ] || [ -f "package.json" ]; then
    log "Installing dependencies..."
    # No silent fallback to a plain install: when the lockfile is out of date the install
    # must fail, not rewrite yarn.lock behind the developer's back.
    if [ "$IMMUTABLE" = "true" ] && [ -f ".yarnrc.yml" ]; then
      yarn install --immutable
    elif [ "$IMMUTABLE" = "true" ] && [ -f "yarn.lock" ]; then
      yarn install --frozen-lockfile
    else
      yarn install
    fi
  fi
fi

log "Yarn setup finished."
