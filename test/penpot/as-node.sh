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

check "~/.penpot-ai-kit is owned by node" test "$(stat -c %U /home/node/.penpot-ai-kit)" = node
check "run setup-penpot as node" as_node /usr/local/share/penpot/setup-penpot.sh
check "symlink ~/.penpot points to .penpot-ai-kit" as_node '[ -L "$HOME/.penpot" ] && [ "$(readlink "$HOME/.penpot")" = .penpot-ai-kit ]'

reportResults
