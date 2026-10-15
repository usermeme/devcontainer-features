
# OpenCode CLI & Host Environment (opencode)

Installs the OpenCode CLI and mounts host config (~/.config/opencode) and credentials (~/.local/share/opencode) for seamless AI pair-programming inside devcontainer.

## Example Usage

```json
"features": {
    "ghcr.io/usermeme/devcontainer-features/opencode:1": {}
}
```

## Options

| Options Id | Description | Type | Default Value |
|-----|-----|-----|-----|
| version | OpenCode version to install (e.g. 'latest' or a specific release like '2.0.29') | string | latest |



---

_Note: This file was auto-generated from the [devcontainer-feature.json](devcontainer-feature.json).  Add additional notes to a `NOTES.md`._
