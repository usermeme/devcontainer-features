#!/usr/bin/env bash
set -e

FEATURE=pnpm
# shellcheck source=../../lib/common.sh
source /usr/local/share/pnpm/common.sh
load_options

RUN_INSTALL="${RUNINSTALL:-false}"
FROZEN_LOCKFILE="${FROZENLOCKFILE:-true}"

PNPM_DIR="$NODE_HOME/.local/share/pnpm"
STORE_DIR="$PNPM_DIR/store"

log "Configuring pnpm..."

resolve_owner

link_from_node_home .local/share/pnpm

ensure_owned_dir "$NODE_HOME" .local/share/pnpm
# pnpm-store is a named volume shared by every devcontainer on this machine. Only its top
# level is claimed, and only when it is not ours: a recursive chown would walk a multi-GB
# store on every create and take files away from projects running under another uid.
claim_dir "$STORE_DIR"
drop_world_write "$STORE_DIR"
claim_corepack_home
warn_unless_writable "$PNPM_DIR" "$STORE_DIR"

export PATH="$PNPM_DIR:$PNPM_DIR/bin:$PATH"
export PNPM_CONFIG_STORE_DIR="$STORE_DIR"

if command -v pnpm &>/dev/null; then
  pnpm config set store-dir "$STORE_DIR" --global || warn "could not set the global pnpm store-dir"
fi

if [ "$RUN_INSTALL" = "true" ]; then
  if [ -f "pnpm-lock.yaml" ] || [ -f "package.json" ]; then
    log "Installing dependencies..."
    if [ "$FROZEN_LOCKFILE" = "true" ] && [ -f "pnpm-lock.yaml" ]; then
      pnpm install --frozen-lockfile
    else
      pnpm install
    fi
  fi
fi

log "pnpm setup finished."
