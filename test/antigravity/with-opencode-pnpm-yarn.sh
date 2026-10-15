#!/usr/bin/env bash
set -e

source dev-container-features-test-lib

# All $HOME-touching features together, as a real override.json combines them. Catches one
# feature undoing another's ownership fix, and lifecycle scripts writing through bind mounts.

as_node() {
  if [ "$(id -u)" = "0" ]; then
    su node -s /bin/bash -c "$1"
  else
    bash -c "$1"
  fi
}

OPENCODE_DATA_OWNER="$(stat -c %u /home/node/.local/share/opencode)"
GEMINI_OWNER="$(stat -c %u /home/node/.gemini)"

check "opencode setup as node" as_node /usr/local/share/opencode/setup-opencode.sh
check "antigravity setup as node" as_node /usr/local/share/antigravity/setup-antigravity.sh
check "pnpm setup as node" as_node /usr/local/share/pnpm/setup-pnpm.sh
check "yarn setup as node" as_node /usr/local/share/yarn/setup-yarn.sh

check "host mount ~/.local/share/opencode ownership unchanged" test "$(stat -c %u /home/node/.local/share/opencode)" = "$OPENCODE_DATA_OWNER"
check "host mount ~/.gemini ownership unchanged" test "$(stat -c %u /home/node/.gemini)" = "$GEMINI_OWNER"
check "node can create ~/.local/state" as_node 'mkdir -p "$HOME/.local/state/probe" && rmdir "$HOME/.local/state/probe"'
check "node can create ~/.cache entries" as_node 'mkdir -p "$HOME/.cache/probe" && rmdir "$HOME/.cache/probe"'
check "nothing world-writable under /home/node (outside mounts)" test -z "$(find /home/node -xdev -maxdepth 3 -perm -o+w ! -type l 2>/dev/null)"
check "opencode runs as node" as_node 'opencode --version'
check "pnpm runs as node" as_node 'pnpm --version'
check "yarn runs as node" as_node 'yarn --version'

reportResults
