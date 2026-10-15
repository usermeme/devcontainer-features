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

# Regression: root-created /home/node/.cache made Corepack fail with EACCES on
# ~/.cache/node/corepack, breaking the yarn shim this feature enables.
check "~/.cache is owned by node" test "$(stat -c %U /home/node/.cache)" = node
check "cache volume is not world-writable" test -z "$(find /home/node/.cache/yarn -maxdepth 0 -perm -o+w)"
check "run setup-yarn as node" as_node /usr/local/share/yarn/setup-yarn.sh
check "cache volume is writable by node" as_node 'touch /home/node/.cache/yarn/probe && rm /home/node/.cache/yarn/probe'
check "yarn runs as node" as_node 'cd /tmp && yarn --version'
check "yarn resolves to the Corepack shim" as_node '[ "$(command -v yarn)" = /usr/local/share/corepack-shims/yarn ]'

reportResults
