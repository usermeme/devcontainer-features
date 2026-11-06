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

check "~/.hermes is owned by node" test "$(stat -c %U /home/node/.hermes)" = node
check "run setup-hermes as node" as_node /usr/local/share/hermes/setup-hermes.sh

reportResults
