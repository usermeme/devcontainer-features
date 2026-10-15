#!/usr/bin/env bash
set -e

source dev-container-features-test-lib

as_node() {
  if [ "$(id -u)" = "0" ]; then
    su node -s /bin/bash -c "$1"
  else
    bash -c "$1"
  fi
}

# A fresh named volume is mounted root-owned; postCreate must hand it to the remote user.
WORKSPACE="$(dirname "$(awk '$5 ~ /^\/workspaces\/[^/]+\/node_modules$/ {print $5; exit}' /proc/self/mountinfo)")"

check "node_modules volume is mounted" test -d "$WORKSPACE/node_modules"
check "run setup-volume as node in the workspace" as_node "cd '$WORKSPACE' && /usr/local/share/node-modules-volume/setup-volume.sh"
check "node_modules is owned by node" test "$(stat -c %U "$WORKSPACE/node_modules")" = node
check "node can write node_modules" as_node "touch '$WORKSPACE/node_modules/probe' && rm '$WORKSPACE/node_modules/probe'"

reportResults
