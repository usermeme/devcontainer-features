
# pnpm Package Manager (pnpm)

Enables pnpm with a persistent shared cache/store volume across devcontainers.

## Example Usage

```json
"features": {
    "ghcr.io/usermeme/devcontainer-features/pnpm:1": {}
}
```

## Options

| Options Id | Description | Type | Default Value |
|-----|-----|-----|-----|
| version | pnpm version to install or activate | string | latest |
| runInstall | Run 'pnpm install' automatically during postCreate | boolean | false |
| frozenLockfile | Use --frozen-lockfile when runInstall is true and pnpm-lock.yaml is present | boolean | true |



---

_Note: This file was auto-generated from the [devcontainer-feature.json](devcontainer-feature.json).  Add additional notes to a `NOTES.md`._
