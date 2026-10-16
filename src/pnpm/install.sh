#!/usr/bin/env bash
# Build time, as root: install pnpm and prepare PNPM_HOME and the store mount under /home/node.
set -e

log() { echo "[pnpm] $*"; }
warn() { echo "[pnpm] WARNING: $*" >&2; }
die() {
  echo "[pnpm] ERROR: $*" >&2
  exit 1
}

VERSION="${VERSION:-latest}"
RUNINSTALL="${RUNINSTALL:-false}"
FROZENLOCKFILE="${FROZENLOCKFILE:-true}"

log "Installing pnpm feature (version: $VERSION)..."

if ! command -v curl &>/dev/null; then
  if command -v apt-get &>/dev/null; then
    apt-get update -y && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends curl ca-certificates && rm -rf /var/lib/apt/lists/*
  elif command -v apk &>/dev/null; then
    apk add --no-cache curl ca-certificates
  elif command -v dnf &>/dev/null; then
    dnf install -y curl ca-certificates
  fi
fi

# The store mount and PNPM_HOME are fixed to /home/node, so only the node user is supported.
OWNER=node
id node &>/dev/null || OWNER=root
[ "${_REMOTE_USER:-node}" = node ] || warn "remoteUser is '$_REMOTE_USER': PNPM_HOME and the store live in /home/node and only the node user is supported."

# Install or enable pnpm: Corepack first, then npm, then the standalone binary.
# COREPACK_HOME is shared and owned by node: by default Corepack records the activated version
# under root's ~/.cache, node never sees it and silently gets another one. containerEnv sets
# the same COREPACK_HOME at runtime. The shims go to a dedicated root-owned dir placed first on
# PATH: base images often ship their own pnpm (the official Node feature preinstalls one into
# /usr/local/share/npm-global/bin), which would otherwise shadow the activated version.
if command -v corepack &>/dev/null; then
  export COREPACK_HOME=/usr/local/share/corepack
  mkdir -p "$COREPACK_HOME" /usr/local/share/corepack-shims
  if corepack enable --install-directory /usr/local/share/corepack-shims pnpm && corepack prepare "pnpm@$VERSION" --activate; then
    # Image-local dir created here, not a mount: recursive chown is safe.
    chown -R "$OWNER:$OWNER" "$COREPACK_HOME"
  else
    # A failed `prepare` still leaves the Corepack shim on PATH, which would skip the fallbacks
    # below and silently ignore a pinned version: fail the build instead.
    [ "$VERSION" = "latest" ] || die "Corepack could not activate pnpm@$VERSION (offline, or unknown version)."
    warn "Corepack could not pre-download pnpm; it will be fetched on first use."
  fi
fi

if ! command -v pnpm &>/dev/null; then
  if command -v npm &>/dev/null; then
    log "Installing pnpm via npm..."
    npm install -g "pnpm@$VERSION"
  else
    # System-wide location: the installer's default (root's ~/.local/share/pnpm) sits under
    # /root, which is mode 700, so the binary would be unusable for any other user.
    log "Installing standalone pnpm binary..."
    PNPM_INSTALLER="$(mktemp)"
    curl -fsSL --proto '=https' --tlsv1.2 --retry 3 https://get.pnpm.io/install.sh -o "$PNPM_INSTALLER" || die "could not download the pnpm installer"
    PNPM_HOME=/usr/local/share/pnpm-standalone PNPM_VERSION="$VERSION" SHELL=bash sh "$PNPM_INSTALLER"
    rm -f "$PNPM_INSTALLER"
    # pnpm < 11 puts the binary in $PNPM_HOME, newer releases in $PNPM_HOME/bin
    for PNPM_BIN in /usr/local/share/pnpm-standalone/bin/pnpm /usr/local/share/pnpm-standalone/pnpm; do
      if [ -x "$PNPM_BIN" ]; then
        ln -sf "$PNPM_BIN" /usr/local/bin/pnpm
        break
      fi
    done
  fi
fi
command -v pnpm &>/dev/null || die "pnpm $VERSION could not be installed."

# PNPM_HOME holds global binaries and is first on PATH: owned by node, never 777. Every level
# is listed: `install -d` would leave the parents it creates root-owned.
install -d -o "$OWNER" -g "$OWNER" -m 755 \
  /home/node/.local /home/node/.local/share /home/node/.local/share/pnpm /home/node/.local/share/pnpm/store

# Setup system-wide environment variables
mkdir -p /etc/profile.d
cat <<'PROFILE' >/etc/profile.d/pnpm.sh
export PNPM_HOME="/home/node/.local/share/pnpm"
export PNPM_CONFIG_STORE_DIR="/home/node/.local/share/pnpm/store"
export COREPACK_HOME="/usr/local/share/corepack"
export PATH="/home/node/.local/share/pnpm:/home/node/.local/share/pnpm/bin:/usr/local/share/corepack-shims:$PATH"
PROFILE
chmod 644 /etc/profile.d/pnpm.sh

# Feature options only exist while install.sh runs: keep them for postCreate.
mkdir -p /usr/local/share/pnpm
printf 'RUNINSTALL=%q\nFROZENLOCKFILE=%q\n' "$RUNINSTALL" "$FROZENLOCKFILE" >/usr/local/share/pnpm/options.env
install -m 755 "$(dirname "$0")/setup-pnpm.sh" /usr/local/share/pnpm/

log "pnpm feature installed successfully."
