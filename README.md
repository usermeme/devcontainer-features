# Dev Container Features

A modular collection of personal and productivity-focused [Dev Container Features](https://containers.dev/implementors/features/) by [@usermeme](https://github.com/usermeme).

## Motivation

Team projects often come with a shared `.devcontainer/devcontainer.json`. However, personal workflows vary:
- You work with **Git worktrees** where `.git` is located in the parent directory.
- You maintain personal **dotfiles** managed with GNU Stow.
- You want cross-container persistent caches for package managers (**pnpm**, **yarn**).
- You want your **Neovim** editor and developer toolchain (ripgrep, fd, linters) ready on every container.
- You use **Google Antigravity CLI** (`agy`) and want your global skills (`~/.agents/skills`) and Google Cloud credentials mounted seamlessly.
- You want high-speed **Docker volumes for `node_modules`** without polluting or slowing down macOS/Windows bind mounts.

Rather than polluting the team's versioned `devcontainer.json`, you can define a **`.devcontainer/devcontainer.override.json`** in any project, add it to `.gitignore`, and plug in exactly the features you need.

---

## Available Features

| Feature | ID | Description |
|---|---|---|
| [**Git Worktree**](src/worktree/README.md) | `worktree` | Mounts parent `.git` for worktree support, configures Git `safe.directory`, repairs container `gitdir` pointers, and fixes Nx cache permissions. |
| [**Dotfiles (GNU Stow)**](src/dotfiles/README.md) | `dotfiles` | Mounts host `~/dotfiles`, installs GNU Stow, and stows configuration packages into `$HOME`. |
| [**pnpm**](src/pnpm/README.md) | `pnpm` | Enables Corepack/pnpm, sets up cross-container `pnpm-store` named volume, configures `store-dir`, exports `PNPM_HOME`, and optional auto-install. |
| [**Yarn**](src/yarn/README.md) | `yarn` | Enables Corepack/yarn (v1 Classic or Modern Berry), configures persistent `yarn-cache` volume, and optional auto-install. |
| [**Antigravity**](src/antigravity/README.md) | `antigravity` | Installs Google Antigravity CLI (`agy`), mounts host `~/.gemini`, `~/.agents/skills`, `~/.config/gcloud`, and symlinks global skills. |
| [**Neovim**](src/neovim/README.md) | `neovim` | Installs official Neovim binary (arm64/x86_64) or compatible release, `ripgrep`, `fd`, `build-essential`, and formatters/linters (`eslint_d`, `prettierd`). |
| [**Node Modules Volume**](src/node-modules-volume/README.md) | `node-modules-volume` | Isolates `node_modules` into a dedicated Docker named volume for dramatically faster I/O on macOS/Windows. |

---

## How to Use in Any Project

### 1. Add Override to `.gitignore`

In your target project repository (or in your global `~/.config/git/ignore`):
```gitignore
.devcontainer/devcontainer.override.json
```

### 2. Create `.devcontainer/devcontainer.override.json`

Pick the features needed for your project:

#### For a TypeScript / PNPM Project with Worktrees and Antigravity:
```json
{
  "$schema": "https://raw.githubusercontent.com/devcontainers/spec/main/schemas/devContainer.schema.json",
  "features": {
    "ghcr.io/usermeme/devcontainer-features/worktree:1": {},
    "ghcr.io/usermeme/devcontainer-features/dotfiles:1": {},
    "ghcr.io/usermeme/devcontainer-features/pnpm:1": {},
    "ghcr.io/usermeme/devcontainer-features/antigravity:1": {},
    "ghcr.io/usermeme/devcontainer-features/neovim:1": {},
    "ghcr.io/usermeme/devcontainer-features/node-modules-volume:1": {}
  }
}
```

#### For a Yarn Berry Project:
```json
{
  "$schema": "https://raw.githubusercontent.com/devcontainers/spec/main/schemas/devContainer.schema.json",
  "features": {
    "ghcr.io/usermeme/devcontainer-features/worktree:1": {},
    "ghcr.io/usermeme/devcontainer-features/dotfiles:1": {},
    "ghcr.io/usermeme/devcontainer-features/yarn:1": {},
    "ghcr.io/usermeme/devcontainer-features/antigravity:1": {},
    "ghcr.io/usermeme/devcontainer-features/neovim:1": {},
    "ghcr.io/usermeme/devcontainer-features/node-modules-volume:1": {}
  }
}
```

---

## Feature Details

### `worktree`
- **Mounts**: `source=${localWorkspaceFolder}/../.git,target=/workspaces/.git,type=bind`
- **Options**:
  - `safeDirectory` (boolean, default: `true`): Runs `git config --global --add safe.directory "*"` to avoid dubious ownership issues.
  - `setupNx` (boolean, default: `true`): Ensures `/workspaces/.nx` cache permissions for the container user.
- **Auto-Repair**: If your worktree's `.git` file contains absolute host paths (common on macOS), the runtime hook detects it and automatically points it to `/workspaces/.git/worktrees/<branch>` or runs `git worktree repair`.

### `dotfiles`
- **Mounts**: `source=${localEnv:HOME}/dotfiles,target=/opt/dotfiles,type=bind,readonly`
- **Options**:
  - `packages` (string, default: `""`): Comma-separated list of packages (e.g. `"nvim,tmux,gemini"`). If empty, all directories are stowed.
  - `target` (string, default: `""`): Target directory (defaults to user's `$HOME`).
- **Build**: Pre-installs GNU Stow into the image.

### `pnpm`
- **Mounts**: `source=pnpm-store,target=/home/node/.local/share/pnpm/store,type=volume`
- **Environment**: Exports `PNPM_HOME`, `PNPM_CONFIG_STORE_DIR`, and updates `$PATH`.
- **Options**:
  - `version` (string, default: `"latest"`): pnpm version.
  - `runInstall` (boolean, default: `false`): Automatically run `pnpm install` in `postCreate`.
  - `frozenLockfile` (boolean, default: `true`): Use `--frozen-lockfile` if `pnpm-lock.yaml` exists.

### `yarn`
- **Mounts**: `source=yarn-cache,target=/home/node/.cache/yarn,type=volume`
- **Environment**: Exports `YARN_CACHE_FOLDER`.
- **Options**:
  - `version` (string, default: `"latest"`): Yarn version (e.g. `stable`, `berry`, `1.22.22`).
  - `runInstall` (boolean, default: `false`): Automatically run `yarn install` in `postCreate`.
  - `immutable` (boolean, default: `true`): Use `--immutable` for Yarn Berry.

### `antigravity`
- **Mounts**:
  - `${localEnv:HOME}/.gemini` -> `/home/node/.gemini`
  - `${localEnv:HOME}/.agents/skills` -> `/home/node/.agents/skills` (readonly)
  - `${localEnv:HOME}/.config/gcloud` -> `/home/node/.config/gcloud` (readonly)
- **Options**:
  - `symlinkSkills` (boolean, default: `true`): Links `~/.agents/skills` to `~/.gemini/skills`.
- **CLI**: Automatically verifies or installs the Antigravity CLI (`agy`).

### `neovim`
- **Tools**: Downloads official Neovim release (arm64 / x86_64), `ripgrep`, `fd-find`, `build-essential`.
- **Linters**: Installs `eslint_d` and `@fsouza/prettierd` if npm is present.
- **Options**:
  - `version` (string, default: `"latest"`): Specific Neovim release version.
  - `installLinters` (boolean, default: `true`).
  - `installDevTools` (boolean, default: `true`).

### `node-modules-volume`
- **Mounts**: `source=${localWorkspaceFolderBasename}-node_modules,target=/workspaces/${localWorkspaceFolderBasename}/node_modules,type=volume`
- Prevents cross-OS filesystem sync performance degradation on macOS and Windows by keeping `node_modules` inside Docker storage.

---

## Local Development & Testing

Run tests locally using the Dev Container CLI:

```bash
# Test a single feature
devcontainer features test -f pnpm .
devcontainer features test -f dotfiles .
devcontainer features test -f yarn .
devcontainer features test -f antigravity .
devcontainer features test --skip-autogenerated -f worktree .

# Generate documentation for all features
devcontainer features generate-docs -p src -r ghcr.io -n usermeme/devcontainer-features
```

## Publishing

When pushed to the `main` branch, the included GitHub Actions workflow (`.github/workflows/release.yaml`) automatically publishes features to the GitHub Container Registry (`ghcr.io/usermeme/devcontainer-features/<feature>:1`).
