#!/usr/bin/env bash
set -e

source dev-container-features-test-lib

check "setup-kilocode script exists" test -x /usr/local/share/kilocode/setup-kilocode.sh
check "install-kilocode script exists" test -x /usr/local/share/kilocode/install-kilocode.sh
check "options persisted for postCreate" grep -q '^VERSION=' /usr/local/share/kilocode/options.env
check "run setup-kilocode" /usr/local/share/kilocode/setup-kilocode.sh
check "kilo binary installed" test -x /usr/local/bin/kilo
check "kilocode alias installed" test -L /usr/local/bin/kilocode
check "kilo on PATH" command -v kilo
check "kilo version" kilo --version
check "shim passes the system CA bundle to Bun" bash -c 'grep -q NODE_EXTRA_CA_CERTS /usr/local/bin/kilo'
check "shim passes the tree-sitter WASM dir" bash -c 'grep -q KILO_TREE_SITTER_WASM_DIR /usr/local/bin/kilo'
check "tree-sitter grammars shipped next to the binary" test -f /usr/local/lib/kilocode/bin/tree-sitter/tree-sitter.wasm
check "sandbox helper shipped next to the binary" test -x /usr/local/lib/kilocode/bin/bwrap
check "kilo install is not writable by others" test -z "$(find /usr/local/lib/kilocode -perm -o+w -not -type l)"
check "auto-update disabled" test "$KILO_DISABLE_AUTOUPDATE" = 1
check "config directory exists" test -d /home/node/.config/kilo
check "data directory exists" test -d /home/node/.local/share/kilo

reportResults
