#!/usr/bin/env bash
set -e

source dev-container-features-test-lib

check "pnpm is installed" pnpm --version
check "setup-pnpm script exists" test -x /usr/local/share/pnpm/setup-pnpm.sh
check "options persisted for postCreate" grep -q '^RUNINSTALL=' /usr/local/share/pnpm/options.env
check "run setup-pnpm" /usr/local/share/pnpm/setup-pnpm.sh
check "pnpm store dir exists" test -d /home/node/.local/share/pnpm/store
check "PNPM_HOME is not world-writable" test -z "$(find /home/node/.local/share/pnpm -maxdepth 0 -perm -o+w)"

reportResults
