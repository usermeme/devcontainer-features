#!/usr/bin/env bash
# postCreate, as node: claim the shared store volume, point pnpm at it, optionally install.
set -e

log() { echo "[pnpm] $*"; }
warn() { echo "[pnpm] WARNING: $*" >&2; }
as_root() { if [ "$(id -u)" = 0 ]; then "$@"; else sudo -n "$@"; fi; }

# shellcheck disable=SC1091
. /usr/local/share/pnpm/options.env

PNPM_DIR="/home/node/.local/share/pnpm"
STORE_DIR="$PNPM_DIR/store"
COREPACK_DIR="/usr/local/share/corepack"

log "Configuring pnpm..."

# pnpm-store is a named volume shared by every devcontainer on this machine and keeps the uid
# of the container that created it. Only its top level is claimed, and only when it is not
# ours: a recursive chown would walk a multi-GB store on every create and take files away
# from projects running under another uid. Volumes created by 1.0.0 were 777: any container
# could swap a package that every other project then installs.
if [ -d "$STORE_DIR" ]; then
  [ -O "$STORE_DIR" ] || as_root chown "$(id -u):$(id -g)" "$STORE_DIR" || warn "$STORE_DIR is not owned by $(id -un) and could not be fixed (no root/sudo)."
  chmod o-w "$STORE_DIR" 2>/dev/null || as_root chmod o-w "$STORE_DIR" || warn "$STORE_DIR is world-writable and could not be fixed."
fi

# COREPACK_HOME is outside $HOME, so the CLI's UID remap on Linux hosts does not re-chown it,
# and Corepack fails with EACCES when packageManager needs a version that is not cached yet.
if [ -d "$COREPACK_DIR" ] && [ ! -O "$COREPACK_DIR" ]; then
  as_root chown -R "$(id -u):$(id -g)" "$COREPACK_DIR" || warn "$COREPACK_DIR is not owned by $(id -un); Corepack downloads will fail."
fi

for dir in "$PNPM_DIR" "$STORE_DIR"; do
  [ ! -e "$dir" ] || [ -w "$dir" ] || warn "$dir is not writable by $(id -un)."
done

export PATH="$PNPM_DIR:$PNPM_DIR/bin:$PATH"
export PNPM_CONFIG_STORE_DIR="$STORE_DIR"

if command -v pnpm &>/dev/null; then
  pnpm config set store-dir "$STORE_DIR" --global || warn "could not set the global pnpm store-dir"
fi

if [ "$RUNINSTALL" = "true" ]; then
  if [ -f "pnpm-lock.yaml" ] || [ -f "package.json" ]; then
    log "Installing dependencies..."
    if [ "$FROZENLOCKFILE" = "true" ] && [ -f "pnpm-lock.yaml" ]; then
      pnpm install --frozen-lockfile
    else
      pnpm install
    fi
  fi
fi

log "pnpm setup finished."
