#!/usr/bin/env bash
set -e

source dev-container-features-test-lib

as_node() {
  if [ "$(id -u)" = "0" ]; then
    su node -s /bin/bash -c "$1"
  else
    bash -c "$1"
  fi
}

check "~/.local is owned by node" test "$(stat -c %U /home/node/.local)" = node
check "~/.local/bin is owned by node" test "$(stat -c %U /home/node/.local/bin)" = node
check "~/.local/bin is not world-writable" test -z "$(find /home/node/.local/bin -maxdepth 0 -perm -o+w)"
check "~/.config is not world-writable" test -z "$(find /home/node/.config -maxdepth 0 -perm -o+w)"
check "run setup-antigravity as node" as_node /usr/local/share/antigravity/setup-antigravity.sh
check "node can write ~/.local/bin" as_node 'touch "$HOME/.local/bin/probe" && rm "$HOME/.local/bin/probe"'
check "skills link is relative (valid on the host too)" as_node '[ ! -L "$HOME/.gemini/skills" ] || [ "$(readlink "$HOME/.gemini/skills")" = ../.agents/skills ]'

reportResults
