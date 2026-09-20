
# Git Worktree & Monorepo Support (worktree)

Configures devcontainer to work seamlessly with Git worktrees by mounting the parent repository .git directory, configuring Git safe directories, and fixing monorepo cache permissions.

## Example Usage

```json
"features": {
    "ghcr.io/usermeme/devcontainer-features/worktree:1": {}
}
```

## Options

| Options Id | Description | Type | Default Value |
|-----|-----|-----|-----|
| safeDirectory | Configure Git safe.directory for all paths | boolean | true |
| setupNx | Ensure /workspaces/.nx cache directory exists with appropriate permissions | boolean | true |



---

_Note: This file was auto-generated from the [devcontainer-feature.json](devcontainer-feature.json).  Add additional notes to a `NOTES.md`._
