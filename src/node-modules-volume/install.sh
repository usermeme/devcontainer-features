#!/usr/bin/env bash
set -e

FEATURE=node-modules-volume
# shellcheck source=../../lib/common.sh
source "$(dirname "$0")/common.sh"

install_runtime setup-volume.sh

log "Node modules volume feature installed."
