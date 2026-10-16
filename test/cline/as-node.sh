#!/usr/bin/env bash
set -e

source dev-container-features-test-lib

# install.sh runs as root; the default scenario runs as root on a plain ubuntu image, where
# root-owned ancestors of the settings mount (~/.cline, ~/.cline/data) are invisible. Cline
# creates its sessions, db and hub lock dirs next to the mount and fails with EACCES there.

as_node() {
  if [ "$(id -u)" = "0" ]; then
    su node -s /bin/bash -c "$1"
  else
    bash -c "$1"
  fi
}

check "cline binary installed" test -x /usr/local/bin/cline
check "~/.cline is owned by node" test "$(stat -c %U /home/node/.cline)" = node
check "~/.cline/data is owned by node" test "$(stat -c %U /home/node/.cline/data)" = node
check "~/.cline/data is not world-writable" test -z "$(find /home/node/.cline/data -maxdepth 0 -perm -o+w)"
check "node cannot modify the cline binary" as_node 'test ! -w /usr/local/lib/cline/bin/cline'
check "node cannot modify the cline shim" as_node 'test ! -w /usr/local/bin/cline'
check "run setup-cline as node" as_node /usr/local/share/cline/setup-cline.sh
check "node can create ~/.cline/data/locks" as_node 'mkdir -p "$HOME/.cline/data/locks/probe" && rmdir "$HOME/.cline/data/locks/probe"'
check "cline version as node" as_node 'cline --version'

reportResults
