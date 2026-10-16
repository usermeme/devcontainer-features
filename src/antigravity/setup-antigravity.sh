#!/usr/bin/env bash
# postCreate, as node: install the Antigravity CLI if missing and link the shared skills.
set -e

log() { echo "[antigravity] $*"; }
warn() { echo "[antigravity] WARNING: $*" >&2; }

# shellcheck disable=SC1091
. /usr/local/share/antigravity/options.env

log "Setting up Antigravity environment..."

# ~/.gemini and ~/.config/gcloud are the developer's host directories: never chown them.
[ ! -e "$HOME/.gemini" ] || [ -w "$HOME/.gemini" ] || warn "$HOME/.gemini is not writable by $(id -un); fix its ownership on the host."

if ! command -v agy &>/dev/null && ! command -v antigravity &>/dev/null; then
  log "Installing Antigravity CLI..."
  AGY_INSTALLER="$(mktemp)"
  if curl -fsSL --proto '=https' --tlsv1.2 --retry 3 https://antigravity.google/cli/install.sh -o "$AGY_INSTALLER"; then
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
if [ "$SYMLINKSKILLS" = "true" ]; then
  SKILLS_LINK="$HOME/.gemini/skills"
  if [ -L "$SKILLS_LINK" ] && [ "$(readlink "$SKILLS_LINK")" = "/home/node/.agents/skills" ]; then
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
