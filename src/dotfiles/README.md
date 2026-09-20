
# Dotfiles (GNU Stow) (dotfiles)

Mounts host dotfiles directory and manages configuration symlinks via GNU Stow inside devcontainer.

## Example Usage

```json
"features": {
    "ghcr.io/usermeme/devcontainer-features/dotfiles:1": {}
}
```

## Options

| Options Id | Description | Type | Default Value |
|-----|-----|-----|-----|
| packages | Comma-separated list of dotfiles packages to stow (e.g. 'nvim,tmux,gemini'). If empty, all subdirectories are stowed. | string | - |
| target | Target directory to stow files into. Defaults to user $HOME. | string | - |



---

_Note: This file was auto-generated from the [devcontainer-feature.json](devcontainer-feature.json).  Add additional notes to a `NOTES.md`._
