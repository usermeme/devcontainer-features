#!/usr/bin/env bash
# Build time, as root: install Watchman, ADB, idb, and the agent simulator CLI (sim).
set -e

log() { echo "[react-native] $*"; }
warn() { echo "[react-native] WARNING: $*" >&2; }

IDBPORT="${IDBPORT:-10882}"
ADBPORT="${ADBPORT:-5037}"
INSTALLWATCHMAN="${INSTALLWATCHMAN:-true}"

log "Installing React Native & Mobile Simulator Bridge feature..."

install_packages() {
  if command -v apt-get &>/dev/null; then
    apt-get update -y && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends "$@" && rm -rf /var/lib/apt/lists/*
  elif command -v apk &>/dev/null; then
    apk add --no-cache "$@"
  elif command -v dnf &>/dev/null; then
    dnf install -y "$@"
  else
    return 1
  fi
}

# Core system prerequisites
PKGS=(curl ca-certificates tar python3 python3-pip python3-venv)

# Android ADB client
if ! command -v adb &>/dev/null; then
  if command -v apt-get &>/dev/null; then
    PKGS+=(adb)
  elif command -v apk &>/dev/null; then
    PKGS+=(android-tools)
  elif command -v dnf &>/dev/null; then
    PKGS+=(android-tools)
  fi
fi

# Optional Watchman
if [ "$INSTALLWATCHMAN" = "true" ] && ! command -v watchman &>/dev/null; then
  if command -v apt-get &>/dev/null; then
    PKGS+=(watchman)
  fi
fi

log "Installing base packages: ${PKGS[*]}..."
install_packages "${PKGS[@]}" || {
  # If watchman failed to resolve on older distros, retry without it
  if [ "$INSTALLWATCHMAN" = "true" ]; then
    warn "Package installation with watchman failed; retrying core packages..."
    FILTERED=()
    for p in "${PKGS[@]}"; do
      [ "$p" = "watchman" ] || FILTERED+=("$p")
    done
    install_packages "${FILTERED[@]}" || true
  fi
}

# Install sim and mobile-sim CLI tools
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
install -m 755 "$SCRIPT_DIR/sim" /usr/local/bin/sim
ln -sf /usr/local/bin/sim /usr/local/bin/mobile-sim

# Attempt to install idb (Meta iOS Development Bridge client)
status=0
bash "$SCRIPT_DIR/install-idb.sh" || status=$?
if [ "$status" != "0" ]; then
  warn "idb CLI not installed during image build; setup-react-native.sh will retry during postCreate."
fi

# Persist options for postCreate
mkdir -p /usr/local/share/react-native
printf 'IDBPORT=%q\nADBPORT=%q\nINSTALLWATCHMAN=%q\n' "$IDBPORT" "$ADBPORT" "$INSTALLWATCHMAN" > /usr/local/share/react-native/options.env
install -m 755 "$SCRIPT_DIR/setup-react-native.sh" "$SCRIPT_DIR/install-idb.sh" /usr/local/share/react-native/

log "React Native & Mobile Simulator Bridge feature installed successfully."
