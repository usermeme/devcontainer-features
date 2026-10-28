#!/usr/bin/env bash
set -e

source dev-container-features-test-lib

check "git is installed" git --version
check "gh is installed" gh --version
check "github.com credential helper uses gh" bash -c "git -C / config --system --get-all credential.https://github.com.helper | grep -q 'gh auth git-credential'"
check "gist.github.com credential helper uses gh" bash -c "git -C / config --system --get-all credential.https://gist.github.com.helper | grep -q 'gh auth git-credential'"
check "git credential fill resolves GH_TOKEN via gh" bash -c "printf 'protocol=https\nhost=github.com\n\n' | GH_TOKEN=ghp_testtoken123 git -C / credential fill | grep -qxF 'password=ghp_testtoken123'"
check "git@github.com: rewritten to https" bash -c "git -C / config --system --get-all url.https://github.com/.insteadOf | grep -qxF 'git@github.com:'"
check "ssh://git@github.com/ rewritten to https" bash -c "git -C / config --system --get-all url.https://github.com/.insteadOf | grep -qxF 'ssh://git@github.com/'"

reportResults
