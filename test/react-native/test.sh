#!/usr/bin/env bash
set -e

source dev-container-features-test-lib

check "sim CLI exists" test -x /usr/local/bin/sim
check "sim on PATH" command -v sim
check "mobile-sim alias exists" test -x /usr/local/bin/mobile-sim
check "sim help works" sim --help
check "setup script exists" test -x /usr/local/share/react-native/setup-react-native.sh
check "install-idb script exists" test -x /usr/local/share/react-native/install-idb.sh
check "options persisted" test -f /usr/local/share/react-native/options.env
check "containerEnv IDB_COMPANION set" test "$IDB_COMPANION" = "host.docker.internal:10882"
check "containerEnv ADB_SERVER_SOCKET set" test "$ADB_SERVER_SOCKET" = "tcp:host.docker.internal:5037"
check "containerEnv REACT_NATIVE_PACKAGER_HOSTNAME set" test "$REACT_NATIVE_PACKAGER_HOSTNAME" = "host.docker.internal"
check "run setup-react-native" /usr/local/share/react-native/setup-react-native.sh

reportResults
