#!/usr/bin/env bash
set -e

source dev-container-features-test-lib

check "setup-hermes script exists" test -x /usr/local/share/hermes/setup-hermes.sh
check "install-hermes script exists" test -x /usr/local/share/hermes/install-hermes.sh
check "options persisted for postCreate" grep -q '^VERSION=' /usr/local/share/hermes/options.env
check "mount target directory exists" test -d /home/node/.hermes
check "run setup-hermes" /usr/local/share/hermes/setup-hermes.sh
check "HERMES_HOME is set" test "$HERMES_HOME" = "/home/node/.hermes"

reportResults
