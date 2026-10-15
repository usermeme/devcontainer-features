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

# Regression: `corepack prepare` ran as root and recorded the version under /root, so the
# remote user silently got a different pnpm.
# The official Node feature preinstalls the latest pnpm in /usr/local/share/npm-global/bin,
# which used to shadow the version activated through Corepack.
check "pnpm resolves to the Corepack shim" as_node '[ "$(command -v pnpm)" = /usr/local/share/corepack-shims/pnpm ]'
check "node gets the pinned pnpm" as_node 'cd /tmp && [ "$(pnpm --version)" = 9.15.0 ]'

reportResults
