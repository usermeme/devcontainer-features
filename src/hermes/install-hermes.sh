#!/usr/bin/env bash
# install-hermes.sh [VERSION]: install the Hermes Agent CLI into /usr/local/lib/hermes-agent (as root).
# Used by install.sh at build time and by setup-hermes.sh when the build had no network.
set -e

log() { echo "[hermes] $*"; }
warn() { echo "[hermes] WARNING: $*" >&2; }
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

VERSION="${1:-latest}"
INSTALL_DIR="/usr/local/lib/hermes-agent"

if [ "$(id -u)" != "0" ]; then
  warn "install-hermes.sh must run as root"
  exit 1
fi

# Install dependencies if missing
if ! command -v curl &>/dev/null || ! command -v git &>/dev/null || ! command -v tar &>/dev/null; then
  install_packages curl git ca-certificates tar || true
fi

# The version ends up in arguments: allow alphanumeric, dots, dashes, underscores
if ! [[ "$VERSION" =~ ^[0-9A-Za-z][0-9A-Za-z._-]*$ ]]; then
  warn "invalid version '$VERSION'"
  exit 1
fi

EXTRA_ARGS=()
case "$VERSION" in
  latest | stable)
    EXTRA_ARGS+=(--channel stable)
    ;;
  main)
    EXTRA_ARGS+=(--channel main)
    ;;
  *)
    if [[ "$VERSION" =~ ^[0-9a-f]{7,40}$ ]]; then
      EXTRA_ARGS+=(--commit "$VERSION")
    else
      EXTRA_ARGS+=(--branch "$VERSION")
    fi
    ;;
esac

TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

INSTALLER="$TMP_DIR/install.sh"
if ! curl -fsSL --proto '=https' --tlsv1.2 --retry 3 https://raw.githubusercontent.com/NousResearch/hermes-agent/main/scripts/install.sh -o "$INSTALLER"; then
  warn "failed to download Hermes Agent installer"
  exit 1
fi

chmod +x "$INSTALLER"
mkdir -p "$(dirname "$INSTALL_DIR")"

HERMES_HOME="/tmp/hermes-bootstrap" bash "$INSTALLER" \
  --dir "$INSTALL_DIR" \
  --non-interactive \
  --skip-browser \
  --skip-computer-use \
  "${EXTRA_ARGS[@]}" || {
    warn "Hermes Agent installer script execution failed"
    exit 1
}
rm -rf /tmp/hermes-bootstrap

# Ensure /usr/local/bin wrapper exists
if [ -x "$INSTALL_DIR/venv/bin/hermes" ] && [ ! -x /usr/local/bin/hermes ]; then
  cat > /usr/local/bin/hermes <<'EOF'
#!/usr/bin/env bash
unset PYTHONPATH
unset PYTHONHOME
exec /usr/local/lib/hermes-agent/venv/bin/hermes "$@"
EOF
  chmod 755 /usr/local/bin/hermes
fi

# Ensure hermes-agent alias exists in /usr/local/bin
if [ -x /usr/local/bin/hermes ] && [ ! -e /usr/local/bin/hermes-agent ]; then
  ln -sf hermes /usr/local/bin/hermes-agent
fi

# Ensure install directory is readable/executable by everyone but not world-writable
if [ -d "$INSTALL_DIR" ]; then
  chmod -R go-w "$INSTALL_DIR" 2>/dev/null || true
fi

log "Hermes Agent CLI installed successfully to $INSTALL_DIR."
