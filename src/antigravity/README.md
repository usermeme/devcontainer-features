
# Antigravity CLI & Host Environment (antigravity)

Installs Antigravity CLI and mounts host credentials, skills (~/.agents/skills), and Google Cloud config for seamless pair-programming inside devcontainer.

## Example Usage

```json
"features": {
    "ghcr.io/usermeme/devcontainer-features/antigravity:1": {}
}
```

## Options

| Options Id | Description | Type | Default Value |
|-----|-----|-----|-----|
| symlinkSkills | Symlink ~/.agents/skills to ~/.gemini/skills inside the container | boolean | true |



---

_Note: This file was auto-generated from the [devcontainer-feature.json](devcontainer-feature.json).  Add additional notes to a `NOTES.md`._
