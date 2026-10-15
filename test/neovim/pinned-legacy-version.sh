#!/usr/bin/env bash
set -e

source dev-container-features-test-lib

# "0.10.0" without the v prefix, and a release that still used the nvim-linux64 asset name.
# installDevTools=false must still leave curl/tar available for the download.
check "pinned neovim is installed" bash -c "nvim --version | head -n 1 | grep -qF 'v0.10.0'"
check "binary comes from the official release" bash -c "readlink -f /usr/local/bin/nvim | grep -q '^/opt/nvim-'"

reportResults
