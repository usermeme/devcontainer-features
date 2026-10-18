## Host requirements

`~/dotfiles` must exist on the host, or the container fails to start:

```json
"initializeCommand": "mkdir -p ~/dotfiles"
```

## Notes

- Packages are stowed with `--no-folding`: only files are linked, never whole directories, so tools writing to `~/.config` do not write into your dotfiles repository.
- Exception: the `cline` package is stowed with folding so `~/.cline/hooks` becomes a directory symlink. The Cline CLI discovers hooks via `readdir(...).isFile()`, which skips file-level symlinks; through a folded directory the hook files stay real files and are found. `~/.cline` itself is always created as a real directory first, so Cline session data never lands in the repository.
- `export PATH="$HOME/.local/bin:$PATH"` is appended to the target's `~/.bashrc` (idempotent) so agent hooks referencing stowed scripts by bare name (e.g. Gemini CLI's `session-start-ensure-daemons.sh`) resolve in interactive shells.
- Files that are linked still point at the host repository (the mount is read-write), so a tool rewriting one of them changes your dotfiles.
- Symlinked configs mounted into the container by other features (e.g. `opencode`'s `~/.config/opencode/opencode.jsonc`, `antigravity`'s `~/.gemini/settings.json`) resolve through the `$HOME/dotfiles -> /opt/dotfiles` link this feature creates, so use this feature whenever those features are used.
