#!/usr/bin/env bash
set -e

source dev-container-features-test-lib

# Regression: options used to be read at postCreate, where they are never set
check "symlinkSkills=false persisted" grep -qx 'SYMLINKSKILLS=false' /usr/local/share/antigravity/options.env
# ~/.gemini is the host's directory, shared by every scenario (and your real one when run
# locally), so a link from another run may already be there. Assert on what setup does.
check "setup leaves ~/.gemini/skills alone" bash -c '! /usr/local/share/antigravity/setup-antigravity.sh 2>&1 | grep -q "gemini/skills"'

reportResults
