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

# Regression: root-created /home/node/.local and .local/share broke every other tool
# writing there (EACCES), and PNPM_HOME was 777 while first on PATH.
check "~/.local is owned by node" test "$(stat -c %U /home/node/.local)" = node
check "~/.local/share is owned by node" test "$(stat -c %U /home/node/.local/share)" = node
check "PNPM_HOME is owned by node" test "$(stat -c %U /home/node/.local/share/pnpm)" = node
check "PNPM_HOME is not world-writable" test -z "$(find /home/node/.local/share/pnpm -maxdepth 0 -perm -o+w)"
check "run setup-pnpm as node" as_node /usr/local/share/pnpm/setup-pnpm.sh
check "store volume is writable by node" as_node 'touch /home/node/.local/share/pnpm/store/probe && rm /home/node/.local/share/pnpm/store/probe'
check "pnpm runs as node" as_node 'pnpm --version'
check "store resolves to the shared volume" as_node 'cd /tmp && pnpm store path | grep -q "^/home/node/.local/share/pnpm/store"'
# Corepack must be able to download versions it has not cached yet, as node (COREPACK_HOME
# keeps the build-time uid after a UID remap unless postCreate claims it).
check "packageManager pin is honoured as node" as_node 'd="$(mktemp -d)" && cd "$d" && printf "{\"packageManager\":\"pnpm@9.12.0\"}" >package.json && [ "$(COREPACK_ENABLE_DOWNLOAD_PROMPT=0 pnpm --version)" = 9.12.0 ]'

reportResults
