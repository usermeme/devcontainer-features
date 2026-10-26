
# Kilo Code CLI & Host Environment (kilocode)

Installs the Kilo Code CLI (kilo), mounts host config (~/.config/kilo) and keeps logins and sessions (~/.local/share/kilo) in a volume shared by all devcontainers.

## Example Usage

```json
"features": {
    "ghcr.io/usermeme/devcontainer-features/kilocode:1": {}
}
```

## Options

| Options Id | Description | Type | Default Value |
|-----|-----|-----|-----|
| version | Kilo Code CLI version to install (e.g. 'latest' or a specific release like '7.8.17') | string | latest |



---

_Note: This file was auto-generated from the [devcontainer-feature.json](devcontainer-feature.json).  Add additional notes to a `NOTES.md`._
