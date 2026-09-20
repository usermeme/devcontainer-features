
# Yarn Package Manager (yarn)

Enables Yarn (v1 Classic or Modern Berry) with a persistent shared cache volume across devcontainers.

## Example Usage

```json
"features": {
    "ghcr.io/usermeme/devcontainer-features/yarn:1": {}
}
```

## Options

| Options Id | Description | Type | Default Value |
|-----|-----|-----|-----|
| version | Yarn version or channel (e.g. 'latest', 'berry', '1.22.22') | string | latest |
| runInstall | Run 'yarn install' automatically during postCreate | boolean | false |
| immutable | Use --immutable for Yarn Berry during runInstall | boolean | true |



---

_Note: This file was auto-generated from the [devcontainer-feature.json](devcontainer-feature.json).  Add additional notes to a `NOTES.md`._
