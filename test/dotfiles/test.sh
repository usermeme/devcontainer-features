#!/usr/bin/env bash
set -e

source dev-container-features-test-lib

# /opt/dotfiles is a bind mount of the host's ~/dotfiles: this test only reads it.
# CI prepares ~/dotfiles/mockpkg/.config/mock.conf (see .github/workflows/test.yaml).

check "stow is installed" stow --version
check "apply-dotfiles script exists" test -x /usr/local/share/dotfiles/apply-dotfiles.sh
check "options persisted for postCreate" grep -q '^PACKAGES=' /usr/local/share/dotfiles/options.env
check "run apply-dotfiles" /usr/local/share/dotfiles/apply-dotfiles.sh

if [ -f /opt/dotfiles/mockpkg/.config/mock.conf ]; then
  check "mock file is stowed" test -L "$HOME/.config/mock.conf"
  # Regression: without --no-folding stow could turn ~/.config itself into a link into the
  # host dotfiles repo, so every tool's state would be written to the host repo.
  check "~/.config is a real directory, not folded into the dotfiles repo" bash -c "[ -d '$HOME/.config' ] && [ ! -L '$HOME/.config' ]"
fi

reportResults
