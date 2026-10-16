#!/usr/bin/env bash
# postCreate, as node: claim the shared cache volume, optionally install dependencies.
set -e

log() { echo "[yarn] $*"; }
warn() { echo "[yarn] WARNING: $*" >&2; }
as_root() { if [ "$(id -u)" = 0 ]; then "$@"; else sudo -n "$@"; fi; }

# shellcheck disable=SC1091
. /usr/local/share/yarn/options.env

CACHE_DIR="/home/node/.cache/yarn"
COREPACK_DIR="/usr/local/share/corepack"

log "Configuring yarn cache..."

# yarn-cache is a named volume shared by every devcontainer on this machine and keeps the uid
# of the container that created it. Only its top level is claimed, and only when it is not
# ours: a recursive chown would walk the whole cache on every create and take files away from
# projects running under another uid. Volumes created by 1.0.0 were 777: any container could
# swap a package that every other project then installs.
if [ -d "$CACHE_DIR" ]; then
  [ -O "$CACHE_DIR" ] || as_root chown "$(id -u):$(id -g)" "$CACHE_DIR" || warn "$CACHE_DIR is not owned by $(id -un) and could not be fixed (no root/sudo)."
  chmod o-w "$CACHE_DIR" 2>/dev/null || as_root chmod o-w "$CACHE_DIR" || warn "$CACHE_DIR is world-writable and could not be fixed."
  [ -w "$CACHE_DIR" ] || warn "$CACHE_DIR is not writable by $(id -un)."
fi

# COREPACK_HOME is outside $HOME, so the CLI's UID remap on Linux hosts does not re-chown it,
# and Corepack fails with EACCES when packageManager needs a version that is not cached yet.
if [ -d "$COREPACK_DIR" ] && [ ! -O "$COREPACK_DIR" ]; then
  as_root chown -R "$(id -u):$(id -g)" "$COREPACK_DIR" || warn "$COREPACK_DIR is not owned by $(id -un); Corepack downloads will fail."
fi

if [ "$RUNINSTALL" = "true" ]; then
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
