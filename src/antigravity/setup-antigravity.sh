#!/usr/bin/env bash
set -e

FEATURE=antigravity
# shellcheck source=../../lib/common.sh
source /usr/local/share/antigravity/common.sh
load_options

SYMLINK_SKILLS="${SYMLINKSKILLS:-true}"

log "Setting up Antigravity environment..."

resolve_owner

# Non-node users reach the host mounts under /home/node. Linking has to happen before
# anything below creates these paths, otherwise the host credentials are never visible.
link_from_node_home .gemini
link_from_node_home .agents
link_from_node_home .config/gcloud

# Only the container-side dirs are fixed, non-recursively: ~/.gemini and ~/.config/gcloud are
# bind mounts of the developer's home, and chown on them rewrites host file ownership.
for rel in .local/bin .config .gemini; do
  ensure_owned_dir "$HOME" "$rel"
done
warn_unless_writable "$HOME/.gemini"

# Install Antigravity CLI if missing
if ! command -v agy &>/dev/null && ! command -v antigravity &>/dev/null; then
  log "Installing Antigravity CLI..."
  AGY_INSTALLER="$(mktemp)"
  if fetch https://antigravity.google/cli/install.sh "$AGY_INSTALLER"; then
    bash "$AGY_INSTALLER" || warn "Antigravity CLI install failed."
  else
    warn "Antigravity CLI install skipped (network unreachable or offline)."
  fi
  rm -f "$AGY_INSTALLER"
fi

# ~/.gemini is the host's directory, so the link is relative: ../.agents/skills resolves to
# the skills dir both in the container and on the host, instead of a dangling /home/node path.
# 1.0.0 wrote such an absolute link; it is replaced. Anything else at ~/.gemini/skills is the
# developer's and is left alone.
if [ "$SYMLINK_SKILLS" = "true" ]; then
  SKILLS_LINK="$HOME/.gemini/skills"
  if [ -L "$SKILLS_LINK" ] && [ "$(readlink "$SKILLS_LINK")" = "$NODE_HOME/.agents/skills" ]; then
    rm -f "$SKILLS_LINK" || warn "could not replace the absolute link $SKILLS_LINK"
  fi
  if [ -e "$SKILLS_LINK" ] || [ -L "$SKILLS_LINK" ]; then
    log "$SKILLS_LINK already exists; leaving it as is."
  elif [ -d "$HOME/.gemini/../.agents/skills" ]; then
    log "Linking $SKILLS_LINK -> ../.agents/skills"
    ln -s ../.agents/skills "$SKILLS_LINK" || warn "could not create $SKILLS_LINK (is ~/.gemini writable?)"
  fi
fi

log "Antigravity setup finished."
