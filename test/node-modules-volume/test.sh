#!/usr/bin/env bash
set -e

source dev-container-features-test-lib

check "setup-volume script exists" test -x /usr/local/share/node-modules-volume/setup-volume.sh
check "run setup-volume" /usr/local/share/node-modules-volume/setup-volume.sh

reportResults
