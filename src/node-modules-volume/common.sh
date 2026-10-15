# shellcheck shell=bash
# Shared helpers for every feature in this repository.
#
# Edit lib/common.sh only. scripts/sync-lib.sh copies it into src/<feature>/common.sh,
# because a feature is published as a self-contained archive and cannot reference files
# outside its own folder. CI fails when a copy drifts from this file.
#
# Usage (install.sh, runs as root at image build):
#   FEATURE=<id>; source "$(dirname "$0")/common.sh"
# Usage (lifecycle script, runs as the container user):
#   FEATURE=<id>; source "/usr/local/share/<id>/common.sh"; load_options
#
# Rules every feature follows (CI greps for violations):
#   - never chmod 777: world-writable dirs on PATH let any process plant a fake `git`/`sudo`
#   - never chown inside a bind mount: that rewrites ownership of the developer's host files
#   - never pipe a download into a shell: download to a file, check the result, then run it
#   - feature options only exist while install.sh runs: persist_options/load_options them

: "${FEATURE:?FEATURE must be set before sourcing common.sh}"

FEATURE_SHARE="/usr/local/share/$FEATURE"
FEATURE_SRC="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# Mount targets in every devcontainer-feature.json are fixed to this home: the json cannot
# reference the remote user, so non-node users reach them through link_from_node_home.
NODE_HOME="/home/node"

log() { echo "[$FEATURE] $*"; }
warn() { echo "[$FEATURE] WARNING: $*" >&2; }
die() {
  echo "[$FEATURE] ERROR: $*" >&2
  exit 1
}

# Run a command as root: directly when we are root, through non-interactive sudo otherwise.
as_root() {
  if [ "$(id -u)" = "0" ]; then
    "$@"
  elif command -v sudo >/dev/null 2>&1; then
    sudo -n "$@"
  else
    return 1
  fi
}

# Sets OWNER/OWNER_GROUP for lifecycle scripts: always the user actually running.
resolve_owner() {
  OWNER="$(id -un)"
  OWNER_GROUP="$(id -gn)"
}

# Sets OWNER/OWNER_GROUP for install.sh (root, image build): the user whose home is
# _REMOTE_USER_HOME (looked up by name so it survives the UID remap), else the owner of
# /home/node, else root.
resolve_build_owner() {
  OWNER=""
  if [ -n "${_REMOTE_USER_HOME:-}" ]; then
    OWNER="$(awk -F: -v h="$_REMOTE_USER_HOME" '$6==h{print $1; exit}' /etc/passwd)"
  fi
  if [ -z "$OWNER" ] && [ -d "$NODE_HOME" ]; then
    OWNER="$(stat -c %U "$NODE_HOME" 2>/dev/null || true)"
  fi
  if [ -z "$OWNER" ] || [ "$OWNER" = "UNKNOWN" ]; then
    OWNER="root"
  fi
  OWNER_GROUP="$(id -gn "$OWNER" 2>/dev/null || echo "$OWNER")"
}

# True when PATH (after resolving symlinks) is a mount point. Reads /proc directly because
# busybox-based images have no util-linux `mountpoint`.
is_mount() {
  local path
  path="$(readlink -f "$1" 2>/dev/null)" || return 1
  awk -v p="$path" '$5==p{found=1} END{exit !found}' /proc/self/mountinfo 2>/dev/null
}

is_owned() {
  [ "$(stat -c %U "$1" 2>/dev/null)" = "$OWNER" ]
}

# Give one directory (not its contents) to OWNER when it is not theirs yet.
# Used for mount points of named volumes and for dirs this feature created itself.
claim_dir() {
  local dir="$1"
  [ -d "$dir" ] && [ ! -L "$dir" ] || return 0
  is_owned "$dir" && return 0
  as_root chown "$OWNER:$OWNER_GROUP" "$dir" 2>/dev/null ||
    warn "$dir is owned by $(stat -c %U "$dir"), not $OWNER, and could not be fixed (no root/sudo). Fix it with: docker exec -u root <container> chown $OWNER: $dir"
}

# ensure_owned_dir BASE REL [MODE]
# Create BASE/REL and every missing component between them, each owned by OWNER.
# Without this, `mkdir -p` as root leaves root-owned ancestors (e.g. ~/.local) and the
# tool later fails with EACCES creating a sibling such as ~/.local/state.
# Non-recursive and mount-aware: nothing at or below a mount point or a symlink is touched,
# so host files behind a bind mount keep their ownership.
ensure_owned_dir() {
  local base="$1" rel="$2" mode="${3:-}" dir="$1" part foreign=""
  local -a parts
  [ -d "$base" ] || as_root mkdir -p "$base" || mkdir -p "$base" || {
    warn "cannot create $base"
    return 0
  }
  IFS=/ read -ra parts <<<"$rel"
  for part in "${parts[@]}"; do
    [ -n "$part" ] || continue
    dir="$dir/$part"
    if [ -L "$dir" ]; then
      foreign=1
      continue
    fi
    if [ ! -d "$dir" ]; then
      mkdir "$dir" 2>/dev/null || as_root mkdir "$dir" 2>/dev/null || {
        warn "cannot create $dir"
        return 0
      }
    fi
    if [ -z "$foreign" ] && is_mount "$dir"; then
      foreign=1
    fi
    [ -n "$foreign" ] || claim_dir "$dir"
  done
  if [ -n "$mode" ] && [ -z "$foreign" ]; then
    as_root chmod "$mode" "$dir" 2>/dev/null || chmod "$mode" "$dir" 2>/dev/null || true
  fi
}

warn_unless_writable() {
  local dir
  for dir in "$@"; do
    if [ -e "$dir" ] && [ ! -w "$dir" ]; then
      warn "$dir is not writable by $(id -un). If it is a host bind mount, fix its ownership on the host."
    fi
  done
}

# Non-node users: point $HOME/REL at the mount under /home/node. Must run before anything
# creates $HOME/REL, otherwise the link is never made.
link_from_node_home() {
  local src="$NODE_HOME/$1" dst="$HOME/$1"
  [ "$HOME" != "$NODE_HOME" ] && [ -e "$src" ] || return 0
  [ -L "$dst" ] && return 0
  if [ -d "$dst" ] && ! rmdir "$dst" 2>/dev/null; then
    warn "$dst already exists and is not empty; not linking it to $src"
    return 0
  fi
  if [ -e "$dst" ]; then
    warn "$dst already exists; not linking it to $src"
    return 0
  fi
  { mkdir -p "$(dirname "$dst")" && ln -s "$src" "$dst"; } || warn "could not link $dst to $src"
}

# Feature options are exported only while install.sh runs. Persist them for lifecycle
# scripts, every listed option is written (empty included) so it overrides a same-named
# variable that happens to be in the runtime environment.
persist_options() {
  local var file="$FEATURE_SHARE/options.env"
  mkdir -p "$FEATURE_SHARE"
  : >"$file"
  for var in "$@"; do
    printf '%s=%q\n' "$var" "${!var:-}" >>"$file"
  done
  chmod 644 "$file"
}

load_options() {
  if [ -r "$FEATURE_SHARE/options.env" ]; then
    # shellcheck disable=SC1091
    . "$FEATURE_SHARE/options.env"
  else
    warn "$FEATURE_SHARE/options.env is missing; using option defaults"
  fi
}

# Copy a lifecycle script and this library to /usr/local/share/<feature>.
install_runtime() {
  local script
  mkdir -p "$FEATURE_SHARE"
  install -m 644 "$FEATURE_SRC/common.sh" "$FEATURE_SHARE/common.sh"
  for script in "$@"; do
    install -m 755 "$FEATURE_SRC/$script" "$FEATURE_SHARE/$script"
  done
}

install_packages() {
  if command -v apt-get >/dev/null 2>&1; then
    DEBIAN_FRONTEND=noninteractive apt-get update -y &&
      DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends "$@" &&
      rm -rf /var/lib/apt/lists/*
  elif command -v apk >/dev/null 2>&1; then
    apk add --no-cache "$@"
  elif command -v dnf >/dev/null 2>&1; then
    dnf install -y "$@"
  else
    warn "no supported package manager found to install: $*"
    return 1
  fi
}

# Install curl/tar/ca-certificates when a download is about to happen.
ensure_download_tools() {
  if ! command -v curl >/dev/null 2>&1 || ! command -v tar >/dev/null 2>&1; then
    install_packages curl tar ca-certificates
  fi
}

# Remove write permission for others from a dir we own (volumes created by 1.0.0 were 777).
drop_world_write() {
  [ -d "$1" ] && [ ! -L "$1" ] || return 0
  [ -n "$(find "$1" -maxdepth 0 -perm -o+w 2>/dev/null)" ] || return 0
  chmod o-w "$1" 2>/dev/null || as_root chmod o-w "$1" 2>/dev/null || warn "$1 is world-writable and could not be fixed"
}

# corepack_activate TOOL SPEC: activate TOOL@SPEC through Corepack (build time, as root).
# COREPACK_HOME is shared and owned by OWNER: by default Corepack records the activated
# version under root's ~/.cache, the remote user never sees it and silently gets another one.
# devcontainer-feature.json sets the same COREPACK_HOME in containerEnv for runtime.
COREPACK_SHARED_HOME="/usr/local/share/corepack"
corepack_activate() {
  command -v corepack >/dev/null 2>&1 || return 1
  export COREPACK_HOME="$COREPACK_SHARED_HOME"
  mkdir -p "$COREPACK_HOME"
  corepack enable "$1" || warn "corepack enable $1 failed"
  corepack prepare "$1@$2" --activate || return 1
  # Image-local dir created by this feature, not a mount: recursive chown is safe here.
  chown -R "$OWNER:$OWNER_GROUP" "$COREPACK_HOME"
}

# Lifecycle scripts: the CLI remaps the remote user's UID on Linux hosts and re-chowns only
# that user's home, so the shared COREPACK_HOME can keep the build-time UID and Corepack fails
# with EACCES when a project's packageManager needs a version that is not cached yet.
claim_corepack_home() {
  local dir="$COREPACK_SHARED_HOME"
  [ -d "$dir" ] && [ ! -L "$dir" ] || return 0
  is_owned "$dir" && return 0
  as_root chown -R "$OWNER:$OWNER_GROUP" "$dir" 2>/dev/null ||
    warn "$dir is not owned by $OWNER and could not be fixed; Corepack downloads will fail."
}

# fetch URL FILE: download over HTTPS only, with retries. Returns non-zero on failure.
fetch() {
  curl -fsSL --proto '=https' --tlsv1.2 --retry 3 "$1" -o "$2"
}
