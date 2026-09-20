
# Neovim Developer Tools (neovim)

Installs the official Neovim release binary (arm64 / x86_64) along with essential developer CLI tools (ripgrep, fd, build-essential, and linter daemons).

## Example Usage

```json
"features": {
    "ghcr.io/usermeme/devcontainer-features/neovim:1": {}
}
```

## Options

| Options Id | Description | Type | Default Value |
|-----|-----|-----|-----|
| version | Neovim release version (e.g. 'latest' or 'v0.10.4') | string | latest |
| installLinters | Install global npm linters/formatters (eslint_d, @fsouza/prettierd) | boolean | true |
| installDevTools | Install ripgrep, fd-find, and build-essential | boolean | true |



---

_Note: This file was auto-generated from the [devcontainer-feature.json](devcontainer-feature.json).  Add additional notes to a `NOTES.md`._
