#!/usr/bin/env bash
set -e

source dev-container-features-test-lib

check "git is installed" git --version
check "setup-worktree script exists" test -x /usr/local/share/worktree/setup-worktree.sh
check "run setup-worktree script" /usr/local/share/worktree/setup-worktree.sh
check "safe.directory configured" git config --global --get-all safe.directory | grep -q '\*'

reportResults
