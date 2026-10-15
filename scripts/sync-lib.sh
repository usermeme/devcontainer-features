#!/usr/bin/env bash
# Copy lib/common.sh into every feature. Features are published as self-contained
# archives of src/<feature>/, so the shared library has to live inside each of them.
# CI runs this and fails on `git diff`, so edit lib/common.sh and re-run, never the copies.
set -e

ROOT="$(cd "$(dirname "$0")/.." && pwd)"

for feature_dir in "$ROOT"/src/*/; do
  cp "$ROOT/lib/common.sh" "$feature_dir/common.sh"
done

echo "Synced lib/common.sh into $(find "$ROOT/src" -mindepth 2 -maxdepth 2 -name common.sh | wc -l | tr -d ' ') features."
