#!/usr/bin/env bash
set -e

source dev-container-features-test-lib

check "setup-penpot script exists" test -x /usr/local/share/penpot/setup-penpot.sh
check "options persisted for postCreate" grep -q '^SYMLINKPENPOT=' /usr/local/share/penpot/options.env
check "mount target directory exists" test -d /home/node/.penpot-ai-kit
check "run setup-penpot" /usr/local/share/penpot/setup-penpot.sh

reportResults
