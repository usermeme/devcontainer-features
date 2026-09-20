#!/usr/bin/env bash
set -e

source dev-container-features-test-lib

check "pnpm is installed" pnpm --version
check "setup-pnpm script exists" test -x /usr/local/share/pnpm/setup-pnpm.sh
check "run setup-pnpm" /usr/local/share/pnpm/setup-pnpm.sh
check "pnpm store dir exists" test -d /home/node/.local/share/pnpm/store

reportResults
