#!/usr/bin/env bash
# postCreate: verify mobile bridge tools and install idb if build was offline.
set -e

log() { echo "[react-native] $*"; }
warn() { echo "[react-native] WARNING: $*" >&2; }
as_root() { if [ "$(id -u)" = 0 ]; then "$@"; else sudo -n "$@"; fi; }

# shellcheck disable=SC1091
if [ -f /usr/local/share/react-native/options.env ]; then
  . /usr/local/share/react-native/options.env
fi

log "Setting up React Native & Mobile Simulator Bridge environment..."

if ! command -v idb &>/dev/null; then
  log "idb CLI not found; attempting installation..."
  as_root bash /usr/local/share/react-native/install-idb.sh ||
    warn "idb CLI installation failed (offline or PyPI unreachable)."
fi

if command -v sim &>/dev/null; then
  log "Mobile Simulator CLI 'sim' is ready."
fi

log "React Native mobile bridge setup finished."
