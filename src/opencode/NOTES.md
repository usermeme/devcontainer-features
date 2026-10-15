## Host requirements

The host paths `~/.config/opencode` and `~/.local/share/opencode` must exist, or the container fails to start (bind mounts are not created on demand):

```json
"initializeCommand": "mkdir -p ~/.config/opencode ~/.local/share/opencode"
```

## Notes

- The mounts are your real host directories. The feature never changes their ownership; if they are not writable inside the container, fix the ownership on the host.
- OpenCode's state (`~/.local/state/opencode`) and cache (`~/.cache/opencode`) stay inside the container.
- Avoid running `opencode` on the host and in the container at the same time: they share the same credential database.
