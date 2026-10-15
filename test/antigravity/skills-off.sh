#!/usr/bin/env bash
set -e

source dev-container-features-test-lib

# Regression: options used to be read at postCreate, where they are never set
check "symlinkSkills=false persisted" grep -qx 'SYMLINKSKILLS=false' /usr/local/share/antigravity/options.env
check "run setup-antigravity" /usr/local/share/antigravity/setup-antigravity.sh
check "setup does not create the skills link" bash -c '! [ -L "$HOME/.gemini/skills" ] || [ "$(readlink "$HOME/.gemini/skills")" != ../.agents/skills ]'

reportResults
