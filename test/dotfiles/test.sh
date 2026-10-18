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

if [ -f /opt/dotfiles/cline/.cline/hooks/PostToolUse ]; then
  # The Cline CLI skips symlinks when discovering hooks (readdir isFile()), so the hooks
  # directory must be a folded directory symlink with real files inside it.
  check "~/.cline/hooks is a folded directory symlink" test -L "$HOME/.cline/hooks"
  check "hook file is a real file through the fold" bash -c "[ -f '$HOME/.cline/hooks/PostToolUse' ] && [ ! -L '$HOME/.cline/hooks/PostToolUse' ]"
  check "~/.cline itself is a real directory, not folded" bash -c "[ -d '$HOME/.cline' ] && [ ! -L '$HOME/.cline' ]"
fi

check "~/.bashrc puts ~/.local/bin on PATH" grep -q '.local/bin' "$HOME/.bashrc"

reportResults
