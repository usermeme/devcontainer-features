## Host requirements

`~/dotfiles` must exist on the host, or the container fails to start:

```json
"initializeCommand": "mkdir -p ~/dotfiles"
```

## Notes

- Packages are stowed with `--no-folding`: only files are linked, never whole directories, so tools writing to `~/.config` do not write into your dotfiles repository.
- Files that are linked still point at the host repository (the mount is read-write), so a tool rewriting one of them changes your dotfiles.
