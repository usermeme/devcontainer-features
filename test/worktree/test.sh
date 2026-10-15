#!/usr/bin/env bash
set -e

source dev-container-features-test-lib

check "git is installed" git --version
check "setup-worktree script exists" test -x /usr/local/share/worktree/setup-worktree.sh
check "safe.directory is not a blanket '*'" bash -c "! git -C / config --get-all safe.directory | grep -qxF '*'"

reportResults
