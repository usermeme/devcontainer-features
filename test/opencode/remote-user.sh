#!/usr/bin/env bash
set -e

source dev-container-features-test-lib

# Regression for the failure that broke OpenCode in a real devcontainer:
# install.sh runs as root, and it used to create ~/.local and ~/.local/share root-owned
# (only the ~/.local/share/opencode mount leaf was fixed up). The container user then could
# not create OpenCode's other XDG directories, which are not mounted from the host:
#   Error: EACCES: permission denied, mkdir '/home/node/.local/state'
# The default test scenario runs as root on a plain ubuntu image, where that bug is invisible.

as_node() {
  if [ "$(id -u)" = "0" ]; then
    su node -s /bin/sh -c "$1"
  else
    sh -c "$1"
  fi
}

check "opencode binary installed" test -x /usr/local/bin/opencode
check "~/.local is owned by the remote user" test "$(stat -c %u /home/node/.local)" = "$(id -u node)"
check "~/.local/share is owned by the remote user" test "$(stat -c %u /home/node/.local/share)" = "$(id -u node)"
check "remote user can create ~/.local/state" as_node 'mkdir -p "$HOME/.local/state/probe" && rmdir "$HOME/.local/state/probe"'
check "remote user can create ~/.local/bin" as_node 'mkdir -p "$HOME/.local/bin/probe" && rmdir "$HOME/.local/bin/probe"'
check "run setup-opencode as the remote user" as_node '/usr/local/share/opencode/setup-opencode.sh'
check "opencode version as the remote user" as_node 'opencode --version'

reportResults
