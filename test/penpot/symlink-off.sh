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

check "run setup-penpot with symlink off" as_node /usr/local/share/penpot/setup-penpot.sh
check "symlink ~/.penpot not created" as_node '[ ! -e "$HOME/.penpot" ] && [ ! -L "$HOME/.penpot" ]'

reportResults
