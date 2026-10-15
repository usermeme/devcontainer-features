#!/usr/bin/env bash
set -e

source dev-container-features-test-lib

WORKSPACE="$(find /workspaces -mindepth 1 -maxdepth 1 -type d ! -name .git ! -name .nx | head -n 1)"
cd "$WORKSPACE"

check "git is installed" git --version
check "options persisted for postCreate" grep -q '^SAFEDIRECTORY=' /usr/local/share/worktree/options.env
check "/workspaces/.git is mounted" test -d /workspaces/.git
check "run setup-worktree script" /usr/local/share/worktree/setup-worktree.sh

# The .git file is the host's: it must get a pointer valid on both sides, never a
# container-only /workspaces path (1.0.0 broke git on the host that way).
check "host .git pointer rewritten to a relative path" bash -c "[ \"\$(cat .git)\" = 'gitdir: ../.git/worktrees/wt' ]"

printf 'gitdir: /workspaces/.git/worktrees/wt\n' >.git
check "rerun setup-worktree" /usr/local/share/worktree/setup-worktree.sh
check "pointer written by 1.0.0 is healed" bash -c "[ \"\$(cat .git)\" = 'gitdir: ../.git/worktrees/wt' ]"

check "safe.directory is not a blanket '*'" bash -c "! git -C / config --get-all safe.directory | grep -qxF '*'"
check "workspace is trusted" bash -c "git -C / config --get-all safe.directory | grep -qxF -e '/workspaces/*' -e '$WORKSPACE'"
check "safe.directory is not duplicated on rerun" bash -c "[ \"\$(git -C / config --system --get-all safe.directory | sort | uniq -d)\" = '' ]"
check "gc never prunes the host's worktree metadata" bash -c "[ \"\$(git -C / config --get gc.worktreePruneExpire)\" = never ]"
check "/workspaces/.nx is writable" bash -c "touch /workspaces/.nx/probe && rm /workspaces/.nx/probe"

reportResults
