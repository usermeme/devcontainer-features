#!/usr/bin/env bash
set -e

source dev-container-features-test-lib

check "pinned version persisted" grep -q '^VERSION=3.0.72$' /usr/local/share/cline/options.env
check "pinned version installed" bash -c 'cline --version | grep -F 3.0.72'

reportResults
