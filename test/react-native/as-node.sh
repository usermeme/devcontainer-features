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

check "sim executable as node" as_node 'command -v sim'
check "sim help as node" as_node 'sim --help'
check "run setup-react-native as node" as_node /usr/local/share/react-native/setup-react-native.sh

reportResults
