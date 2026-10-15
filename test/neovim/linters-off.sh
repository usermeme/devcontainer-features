#!/usr/bin/env bash
set -e

source dev-container-features-test-lib

# Regression: installLinters was read at postCreate, where options are never set
check "installLinters=false persisted" grep -qx 'INSTALLLINTERS=false' /usr/local/share/neovim/options.env
check "run post-create" /usr/local/share/neovim/post-create.sh
check "eslint_d was not installed" bash -c "! command -v eslint_d"

reportResults
