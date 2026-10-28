#!/usr/bin/env bash
set -e

source dev-container-features-test-lib

check "setup-cline script exists" test -x /usr/local/share/cline/setup-cline.sh
check "install-cline script exists" test -x /usr/local/share/cline/install-cline.sh
check "options persisted for postCreate" grep -q '^VERSION=' /usr/local/share/cline/options.env
check "run setup-cline" /usr/local/share/cline/setup-cline.sh
check "cline binary installed" test -x /usr/local/bin/cline
check "cline on PATH" command -v cline
check "cline version" cline --version
check "shim passes the system CA bundle to Bun" bash -c 'grep -q NODE_EXTRA_CA_CERTS /usr/local/bin/cline'
# In Cline <3.0.74 the plugin sandbox was a separate file beside the binary; in 3.0.74+ it is embedded in the binary
check "plugin runtime available" bash -c 'test -f /usr/local/lib/cline/extensions/plugin-sandbox-bootstrap.js || cline plugin --help'
check "cline install is not writable by others" test -z "$(find /usr/local/lib/cline -perm -o+w -not -type l)"
check "auto-update disabled" test "$CLINE_NO_AUTO_UPDATE" = 1
check "settings directory exists" test -d /home/node/.cline/data/settings

reportResults
