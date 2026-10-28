#!/usr/bin/env bash
set -e

source dev-container-features-test-lib

check "gh is installed" gh --version
check "github.com credential helper uses gh" bash -c "git -C / config --system --get-all credential.https://github.com.helper | grep -q 'gh auth git-credential'"
check "git@github.com: is not rewritten when gitProtocol=ssh" bash -c "! git -C / config --system --get-all url.https://github.com/.insteadOf 2>/dev/null | grep -qxF 'git@github.com:'"

reportResults
