#!/usr/bin/env bash
set -e

source dev-container-features-test-lib

# install.sh runs as root; the default scenario runs as root on a plain ubuntu image, where
# ownership bugs are invisible. Kilo creates its XDG dirs (~/.local/state/kilo, ~/.cache/kilo)
# next to the mounts and writes auth.json into the shared volume; all of them must belong to
# the remote user, or Kilo fails with EACCES.

as_node() {
  if [ "$(id -u)" = "0" ]; then
    su node -s /bin/bash -c "$1"
  else
    bash -c "$1"
  fi
}

check "kilo binary installed" test -x /usr/local/bin/kilo
check "~/.config is owned by node" test "$(stat -c %U /home/node/.config)" = node
check "~/.local is owned by node" test "$(stat -c %U /home/node/.local)" = node
check "~/.local/share is owned by node" test "$(stat -c %U /home/node/.local/share)" = node
check "~/.local/state/kilo is owned by node" test "$(stat -c %U /home/node/.local/state/kilo)" = node
check "~/.cache/kilo is owned by node" test "$(stat -c %U /home/node/.cache/kilo)" = node
check "~/.local/share/kilo is not world-writable" test -z "$(find /home/node/.local/share/kilo -maxdepth 0 -perm -o+w)"
check "node cannot modify the kilo binary" as_node 'test ! -w /usr/local/lib/kilocode/bin/kilo'
check "node cannot modify the kilo shim" as_node 'test ! -w /usr/local/bin/kilo'
check "run setup-kilocode as node" as_node /usr/local/share/kilocode/setup-kilocode.sh
check "node can write the data volume" as_node 'touch "$HOME/.local/share/kilo/probe" && rm "$HOME/.local/share/kilo/probe"'
check "node can write ~/.local/state/kilo" as_node 'touch "$HOME/.local/state/kilo/probe" && rm "$HOME/.local/state/kilo/probe"'
check "kilo version as node" as_node 'kilo --version'

reportResults
