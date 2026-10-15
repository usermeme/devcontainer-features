## Host requirements

The host paths `~/.gemini`, `~/.agents/skills` and `~/.config/gcloud` must exist, or the container fails to start (bind mounts are not created on demand):

```json
"initializeCommand": "mkdir -p ~/.gemini ~/.agents/skills ~/.config/gcloud"
```

## Security

- `~/.config/gcloud` is mounted read-write, because `gcloud` writes its token caches and logs there. Every process in the container, including any dependency's install script, can read your gcloud refresh token and use it against your GCP projects until you revoke it. Only add this feature to projects whose dependencies you trust.
- The feature never changes ownership of the mounted host directories.
- `~/.gemini/skills` is created as a relative link (`../.agents/skills`), so it is valid on the host as well. An existing `~/.gemini/skills` is left untouched.
