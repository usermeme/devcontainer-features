#!/usr/bin/env bash
set -e

source dev-container-features-test-lib

check "stow is installed" stow --version
check "apply-dotfiles script exists" test -x /usr/local/share/dotfiles/apply-dotfiles.sh

# Test stowing mock dotfiles
mkdir -p /opt/dotfiles/testpkg/.config/testpkg
echo "hello=world" > /opt/dotfiles/testpkg/.config/testpkg/config.ini

check "run apply-dotfiles" /usr/local/share/dotfiles/apply-dotfiles.sh
check "verify symlink created" test -f "$HOME/.config/testpkg/config.ini"

# Cleanup mock
rm -rf /opt/dotfiles/testpkg "$HOME/.config/testpkg"

reportResults
