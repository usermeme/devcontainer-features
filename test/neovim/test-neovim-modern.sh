#!/usr/bin/env bash
set -e

source dev-container-features-test-lib

check "neovim is installed" nvim --version
check "ripgrep is installed" rg --version
check "fd is installed" fd --version

reportResults
