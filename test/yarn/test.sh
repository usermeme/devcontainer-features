#!/usr/bin/env bash
set -e

source dev-container-features-test-lib

check "yarn is installed" yarn --version
check "setup-yarn script exists" test -x /usr/local/share/yarn/setup-yarn.sh
check "run setup-yarn" /usr/local/share/yarn/setup-yarn.sh
check "yarn cache dir exists" test -d /home/node/.cache/yarn

reportResults
