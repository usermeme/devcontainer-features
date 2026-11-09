#!/usr/bin/env bash
# install-idb.sh: installs Meta's iOS Development Bridge (idb) Python client into /usr/local/lib/idb/venv.
set -e

log() { echo "[react-native] $*"; }
warn() { echo "[react-native] WARNING: $*" >&2; }

if [ "$(id -u)" != "0" ]; then
  warn "install-idb.sh must run as root"
  exit 1
fi

IDB_DIR="/usr/local/lib/idb"
mkdir -p "$IDB_DIR"

if ! command -v python3 &>/dev/null; then
  warn "python3 is not installed; skipping idb installation"
  exit 1
fi

log "Creating Python virtualenv for idb in $IDB_DIR/venv..."
python3 -m venv "$IDB_DIR/venv"

log "Installing fb-idb client from PyPI..."
if "$IDB_DIR/venv/bin/pip" install --no-cache-dir fb-idb; then
  ln -sf "$IDB_DIR/venv/bin/idb" /usr/local/bin/idb
  chmod -R go-w "$IDB_DIR" 2>/dev/null || true
  log "idb CLI installed successfully to /usr/local/bin/idb."
else
  warn "fb-idb pip install failed (network unreachable or offline)."
  exit 1
fi
