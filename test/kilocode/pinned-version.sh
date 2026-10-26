#!/usr/bin/env bash
set -e

source dev-container-features-test-lib

check "pinned version persisted" grep -q '^VERSION=7.8.17$' /usr/local/share/kilocode/options.env
check "pinned version installed" bash -c 'kilo --version | grep -F 7.8.17'

reportResults
