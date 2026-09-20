#!/usr/bin/env bash
set -e

source dev-container-features-test-lib

check "setup-antigravity script exists" test -x /usr/local/share/antigravity/setup-antigravity.sh
check "run setup-antigravity" /usr/local/share/antigravity/setup-antigravity.sh
check "gemini directory exists" test -d "$HOME/.gemini"

reportResults
