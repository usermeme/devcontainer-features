#!/usr/bin/env bash
# Build time, as root: install Yarn and prepare the cache mount under /home/node.
set -e

log() { echo "[yarn] $*"; }
warn() { echo "[yarn] WARNING: $*" >&2; }
die() {
  echo "[yarn] ERROR: $*" >&2
  exit 1
}

VERSION="${VERSION:-latest}"
RUNINSTALL="${RUNINSTALL:-false}"
IMMUTABLE="${IMMUTABLE:-true}"

log "Installing Yarn feature (version: $VERSION)..."

if ! command -v curl &>/dev/null; then
  if command -v apt-get &>/dev/null; then
    apt-get update -y && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends curl ca-certificates && rm -rf /var/lib/apt/lists/*
  elif command -v apk &>/dev/null; then
    apk add --no-cache curl ca-certificates
  elif command -v dnf &>/dev/null; then
    dnf install -y curl ca-certificates
  fi
fi

# The cache mount is fixed to /home/node, so only the node user is supported.
OWNER=node
id node &>/dev/null || OWNER=root
[ "${_REMOTE_USER:-node}" = node ] || warn "remoteUser is '$_REMOTE_USER': the cache lives in /home/node and only the node user is supported."

YARN_SPEC="$VERSION"
[ "$VERSION" = "latest" ] && YARN_SPEC="stable"

# COREPACK_HOME is shared and owned by node: by default Corepack records the activated version
# under root's ~/.cache, node never sees it and silently gets another one. containerEnv sets
# the same COREPACK_HOME at runtime. The shims go to a dedicated root-owned dir placed first on
# PATH, so a yarn preinstalled by the base image cannot shadow the activated version.
if command -v corepack &>/dev/null; then
  export COREPACK_HOME=/usr/local/share/corepack
  mkdir -p "$COREPACK_HOME" /usr/local/share/corepack-shims
  if corepack enable --install-directory /usr/local/share/corepack-shims yarn && corepack prepare "yarn@$YARN_SPEC" --activate; then
    # Image-local dir created here, not a mount: recursive chown is safe.
    chown -R "$OWNER:$OWNER" "$COREPACK_HOME"
  else
    # A failed `prepare` still leaves the Corepack shim on PATH, which would skip the fallback
    # below and silently ignore a pinned version: fail the build instead.
    [ "$VERSION" = "latest" ] || die "Corepack could not activate yarn@$YARN_SPEC (offline, or unknown version)."
    warn "Corepack could not pre-download yarn; it will be fetched on first use."
  fi
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

# Cache volume mount point: owned by node, never 777 (the volume is shared by every
# devcontainer on this machine, so anyone able to write it can poison other projects).
install -d -o "$OWNER" -g "$OWNER" -m 755 /home/node/.cache /home/node/.cache/yarn

# Feature options only exist while install.sh runs: keep them for postCreate.
mkdir -p /usr/local/share/yarn
printf 'RUNINSTALL=%q\nIMMUTABLE=%q\n' "$RUNINSTALL" "$IMMUTABLE" >/usr/local/share/yarn/options.env
install -m 755 "$(dirname "$0")/setup-yarn.sh" /usr/local/share/yarn/

log "Yarn feature installed successfully."
