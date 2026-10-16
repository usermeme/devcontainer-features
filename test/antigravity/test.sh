#!/usr/bin/env bash
set -e

source dev-container-features-test-lib

check "setup-antigravity script exists" test -x /usr/local/share/antigravity/setup-antigravity.sh
check "options persisted for postCreate" grep -q '^SYMLINKSKILLS=' /usr/local/share/antigravity/options.env
check "run setup-antigravity" /usr/local/share/antigravity/setup-antigravity.sh
check "gemini directory exists" test -d /home/node/.gemini
check "~/.local/bin is not world-writable" test -z "$(find /home/node/.local/bin -maxdepth 0 -perm -o+w)"

reportResults
