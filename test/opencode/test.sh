#!/usr/bin/env bash
set -e

source dev-container-features-test-lib

check "setup-opencode script exists" test -x /usr/local/share/opencode/setup-opencode.sh
check "options persisted for postCreate" grep -q '^VERSION=' /usr/local/share/opencode/options.env
check "run setup-opencode" /usr/local/share/opencode/setup-opencode.sh
check "opencode binary installed" test -x /usr/local/bin/opencode
check "opencode on PATH" command -v opencode
check "opencode version" opencode --version
check "config directory exists" test -d /home/node/.config/opencode
check "data directory exists" test -d /home/node/.local/share/opencode

reportResults
