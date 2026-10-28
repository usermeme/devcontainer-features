# Dev Container Features

A modular collection of personal and productivity-focused [Dev Container Features](https://containers.dev/implementors/features/) by [@usermeme](https://github.com/usermeme).

## Motivation

Team projects often come with a shared `.devcontainer/devcontainer.json`. However, personal workflows vary:
- You work with **Git worktrees** where `.git` is located in the parent directory.
- You maintain personal **dotfiles** managed with GNU Stow.
- You want cross-container persistent caches for package managers (**pnpm**, **yarn**).
- You want your **Neovim** editor and developer toolchain (ripgrep, fd, linters) ready on every container.
- You use **Google Antigravity CLI** (`agy`) and want your global skills (`~/.agents/skills`) and Google Cloud credentials mounted seamlessly.
- You use **OpenCode** and want your global config, agents, and skills in every container, and to log in once for all containers.
- You use **Cline CLI** and want your provider keys, `cline auth` login, and MCP servers available in every container.
- You use **Kilo Code CLI** (`kilo`) and want your global config, login, and sessions available in every container.
- You want high-speed **Docker volumes for `node_modules`** without polluting or slowing down macOS/Windows bind mounts.
- You want a **restricted GitHub token** (`DEVCONTAINER_GITHUB_TOKEN`) passed into the container for committing, pushing, and opening PRs with `gh` without exposing your full-access host credentials.

Rather than polluting the team's versioned `devcontainer.json`, you can define a **`.devcontainer/devcontainer.override.json`** in any project, add it to `.gitignore`, and plug in exactly the features you need.

---

## Available Features

| Feature | ID | Description |
|---|---|---|
| [**Git Worktree**](src/worktree/README.md) | `worktree` | Mounts parent `.git` for worktree support, trusts `/workspaces` in Git `safe.directory`, makes the worktree `gitdir` pointer relative (valid on host and container), and fixes Nx cache permissions. |
| [**Dotfiles (GNU Stow)**](src/dotfiles/README.md) | `dotfiles` | Mounts host `~/dotfiles`, installs GNU Stow, and stows configuration packages into `$HOME`. |
| [**pnpm**](src/pnpm/README.md) | `pnpm` | Enables Corepack/pnpm, sets up cross-container `pnpm-store` named volume, configures `store-dir`, exports `PNPM_HOME`, and optional auto-install. |
| [**Yarn**](src/yarn/README.md) | `yarn` | Enables Corepack/yarn (v1 Classic or Modern Berry), configures persistent `yarn-cache` volume, and optional auto-install. |
| [**Antigravity**](src/antigravity/README.md) | `antigravity` | Installs Google Antigravity CLI (`agy`), mounts host `~/.gemini`, `~/.agents/skills`, `~/.config/gcloud`, and symlinks global skills. |
| [**OpenCode**](src/opencode/README.md) | `opencode` | Installs the OpenCode CLI (official binary, arm64/x64, glibc/musl), mounts host `~/.config/opencode`, keeps logins and sessions in a shared `opencode-data` volume. |
| [**Cline**](src/cline/README.md) | `cline` | Installs the Cline CLI (prebuilt binary, arm64/x64, glibc), mounts host `~/.cline/data/settings` (provider credentials, MCP servers). |
| [**Kilo Code**](src/kilocode/README.md) | `kilocode` | Installs the Kilo Code CLI (prebuilt binary, arm64/x64, glibc/musl, baseline-aware), mounts host `~/.config/kilo`, keeps logins and sessions in a shared `kilocode-data` volume. |
| [**Neovim**](src/neovim/README.md) | `neovim` | Installs official Neovim binary (arm64/x86_64) or compatible release, `ripgrep`, `fd`, `build-essential`, and formatters/linters (`eslint_d`, `prettierd`). |
| [**Node Modules Volume**](src/node-modules-volume/README.md) | `node-modules-volume` | Isolates `node_modules` into a dedicated Docker named volume for dramatically faster I/O on macOS/Windows. |
| [**GitHub CLI & Restricted Token Auth**](src/github/README.md) | `github` | Installs GitHub CLI (`gh`) if not present, forwards host `DEVCONTAINER_GITHUB_TOKEN` into `GH_TOKEN`/`GITHUB_TOKEN`, and configures Git HTTPS auth to use that token. |

### Remote user

`antigravity`, `opencode`, `cline`, `kilocode`, `pnpm` and `yarn` mount into `/home/node` (a feature's mounts cannot reference the remote user), so they support `"remoteUser": "node"` only, as in the `mcr.microsoft.com/devcontainers/typescript-node` and `javascript-node` images. Under another user (e.g. `vscode`) the build prints a warning and the mounted config is not visible in that user's home. `worktree`, `dotfiles`, `neovim`, `node-modules-volume` and `github` work with any user.

### Host paths must exist

Bind mounts are not created on demand: if a host path a feature mounts is missing, the container fails to start. Create them once, or let the project do it before every start:

```json
"initializeCommand": "mkdir -p ~/dotfiles ~/.gemini ~/.agents/skills ~/.config/gcloud ~/.config/opencode ~/.config/kilo ~/.cline/data/settings"
```

| Feature | Host paths |
|---|---|
| `worktree` | `<workspace>/../.git` |
| `dotfiles` | `~/dotfiles` |
| `antigravity` | `~/.gemini`, `~/.agents/skills`, `~/.config/gcloud` |
| `opencode` | `~/.config/opencode` |
| `cline` | `~/.cline/data/settings` |
| `kilocode` | `~/.config/kilo` |

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
    "ghcr.io/usermeme/devcontainer-features/opencode:1": {},
    "ghcr.io/usermeme/devcontainer-features/cline:1": {},
    "ghcr.io/usermeme/devcontainer-features/kilocode:1": {},
    "ghcr.io/usermeme/devcontainer-features/neovim:1": {},
    "ghcr.io/usermeme/devcontainer-features/node-modules-volume:1": {},
    "ghcr.io/usermeme/devcontainer-features/github:1": {}
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
    "ghcr.io/usermeme/devcontainer-features/opencode:1": {},
    "ghcr.io/usermeme/devcontainer-features/cline:1": {},
    "ghcr.io/usermeme/devcontainer-features/kilocode:1": {},
    "ghcr.io/usermeme/devcontainer-features/neovim:1": {},
    "ghcr.io/usermeme/devcontainer-features/node-modules-volume:1": {},
    "ghcr.io/usermeme/devcontainer-features/github:1": {}
  }
}
```

---

## Feature Details

### `worktree`
- **Mounts**: `source=${localWorkspaceFolder}/../.git,target=/workspaces/.git,type=bind`
- **Options**:
  - `safeDirectory` (boolean, default: `true`): Trusts `/workspaces/*` (git >= 2.46) or the exact workspace paths in the container's system Git config. Never `*`, which would disable Git's ownership check for every repository.
  - `setupNx` (boolean, default: `true`): Ensures `/workspaces/.nx` cache permissions for the container user.
- **Auto-Repair**: If your worktree's `.git` file contains an absolute host path, the runtime hook rewrites it to the relative `gitdir: ../.git/worktrees/<name>`, which resolves on both the host and the container.
- **Caveat**: Don't run `git worktree prune` inside the container: the recorded paths are host paths, so every sibling worktree looks stale and its metadata is deleted on the host. Automatic pruning by `git gc` is disabled in the container.

### `dotfiles`
- **Mounts**: `source=${localEnv:HOME}/dotfiles,target=/opt/dotfiles,type=bind`
- **Options**:
  - `packages` (string, default: `""`): Comma-separated list of packages (e.g. `"nvim,tmux,gemini"`). If empty, all directories are stowed.
  - `target` (string, default: `""`): Target directory (defaults to user's `$HOME`).
- **Build**: Pre-installs GNU Stow into the image. Packages are stowed with `--no-folding`, so only files are linked and tools writing to `~/.config` never write into your dotfiles repository. Exception: `cline` is stowed with a folded `~/.cline/hooks` directory symlink, because the Cline CLI skips file-level symlinks when discovering hooks. Also appends `~/.local/bin` to the target's `~/.bashrc` PATH so bare-name hook commands resolve.

### `pnpm`
- **Mounts**: `source=pnpm-store,target=/home/node/.local/share/pnpm/store,type=volume`
- **Environment**: Exports `PNPM_HOME`, `PNPM_CONFIG_STORE_DIR`, `COREPACK_HOME`, and updates `$PATH`.
- **Options**:
  - `version` (string, default: `"latest"`): pnpm version.
  - `runInstall` (boolean, default: `false`): Automatically run `pnpm install` in `postCreate`.
  - `frozenLockfile` (boolean, default: `true`): Use `--frozen-lockfile` if `pnpm-lock.yaml` exists.

### `yarn`
- **Mounts**: `source=yarn-cache,target=/home/node/.cache/yarn,type=volume`
- **Environment**: Exports `YARN_CACHE_FOLDER`, `YARN_GLOBAL_FOLDER` (Yarn Berry's global cache, inside the same volume), and `COREPACK_HOME`.
- **Options**:
  - `version` (string, default: `"latest"`): Yarn version (e.g. `stable`, `berry`, `1.22.22`).
  - `runInstall` (boolean, default: `false`): Automatically run `yarn install` in `postCreate`.
  - `immutable` (boolean, default: `true`): Fail instead of rewriting an out-of-date lockfile (`--immutable` for Yarn Berry, `--frozen-lockfile` for Yarn Classic).

### `antigravity`
- **Mounts**:
  - `${localEnv:HOME}/.gemini` -> `/home/node/.gemini`
  - `${localEnv:HOME}/.agents/skills` -> `/home/node/.agents/skills`
  - `${localEnv:HOME}/.config/gcloud` -> `/home/node/.config/gcloud` (read-write: `gcloud` writes its token caches there, so any process in the container can read your gcloud credentials)
- **Options**:
  - `symlinkSkills` (boolean, default: `true`): Links `~/.gemini/skills` to `../.agents/skills` (relative, so the link is valid on the host too). An existing `~/.gemini/skills` is left untouched.
- **CLI**: Automatically verifies or installs the Antigravity CLI (`agy`).

### `opencode`
- **Mounts**:
  - `${localEnv:HOME}/.config/opencode` -> `/home/node/.config/opencode` (global config, `cli.json`, agents, commands, skills)
  - `opencode-data` volume -> `/home/node/.local/share/opencode` (`opencode.db` with logins and sessions, logs, storage). Shared by all devcontainers, kept across rebuilds, **not** shared with the host: SQLite locking does not work across the host to VM bind mount, and concurrent sessions corrupted the host database (up to 1.1.0).
- **Options**:
  - `version` (string, default: `"latest"`): OpenCode release to install (e.g. `"2.0.29"`).
- **CLI**: Official binary is downloaded at build time into `/usr/local/bin` (arm64/x64, glibc/musl, baseline-aware); `postCreate` falls back to the official installer (`https://opencode.ai/v2/install`) when the binary is missing.
- **Skills**: Combine with the `antigravity` feature to also mount `~/.agents/skills`, which OpenCode discovers natively.
- **Logins**: run `opencode auth login` once in any container. API keys can be shared with the host through `remoteEnv` (e.g. `"ANTHROPIC_API_KEY": "${localEnv:ANTHROPIC_API_KEY}"`). Any process in any container can read the logins in the volume, e.g. a malicious `postinstall` in one project can steal the tokens every container uses.

### `cline`
- **Mounts**: `${localEnv:HOME}/.cline/data/settings` -> `/home/node/.cline/data/settings` (`providers.json` with provider API keys and the `cline auth` login, `global-settings.json`, `cline_mcp_settings.json`). Read-write and plain text: any process in the container can read your API keys, e.g. a malicious `postinstall` in a project dependency could exfiltrate them and spend on your provider account.
- **Not shared**: sessions (SQLite), task history and the hub daemon's PID/port records stay in the container, so history is lost on rebuild. Sharing them breaks both sides: a host PID is meaningless in the container's process namespace, and SQLite locking is unreliable across Docker Desktop / Colima bind mounts.
- **Options**:
  - `version` (string, default: `"latest"`): Cline CLI release to install (e.g. `"3.0.72"`).
- **CLI**: The prebuilt `@cline/cli-linux-<arch>` package is downloaded from the npm registry (no Node required), checked against its registry sha512 (fails closed), and installed root-owned into `/usr/local/lib/cline` behind a shim that passes the system CA bundle (`NODE_EXTRA_CA_CERTS`), as the official npm wrapper does. Self-update is disabled (`CLINE_NO_AUTO_UPDATE=1`); change `version` and rebuild instead. `postCreate` retries the install when the build had no network.
- **Skills**: Combine with the `antigravity` feature to also mount `~/.agents/skills`, which Cline discovers natively.

### `kilocode`
- **Mounts**:
  - `${localEnv:HOME}/.config/kilo` -> `/home/node/.config/kilo` (global config: `config.json`, provider defaults, MCP servers). Read-write and plain text: config values can contain secrets.
  - `kilocode-data` volume -> `/home/node/.local/share/kilo` (`auth.json` with the `/connect` login and provider keys, sessions, logs, repos). Shared by all devcontainers, kept across rebuilds, **not** shared with the host: SQLite-style state is not safe on a bind mount across the host to VM boundary, and concurrent writers corrupt it.
- **Options**:
  - `version` (string, default: `"latest"`): Kilo Code CLI release to install (e.g. `"7.8.17"`).
- **CLI**: The prebuilt `@kilocode/cli-linux-<arch>` package (arm64/x64, glibc/musl, `-baseline` for x64 CPUs without AVX2) is downloaded from the npm registry (no Node required), checked against its registry sha512 (fails closed), and installed root-owned into `/usr/local/lib/kilocode` behind a shim that passes the system CA bundle (`NODE_EXTRA_CA_CERTS`) and the bundled tree-sitter WASM dir (`KILO_TREE_SITTER_WASM_DIR`), as the official npm wrapper does. Self-update is disabled (`KILO_DISABLE_AUTOUPDATE=1`); change `version` and rebuild instead. `postCreate` retries the install when the build had no network. Both `kilo` and `kilocode` commands are available.
- **Logins**: run `kilo` and use `/connect` once in any container; the login lands in the shared volume. Your host keeps its own, separate login. Any process in any container can read the tokens in the volume, e.g. a malicious `postinstall` in one project can steal them.

### `neovim`
- **Tools**: Downloads official Neovim release (arm64 / x86_64), `ripgrep`, `fd-find`, `build-essential`.
- **Linters**: Installs `eslint_d` and `@fsouza/prettierd` if npm is present.
- **Options**:
  - `version` (string, default: `"latest"`): Specific Neovim release version.
  - `installLinters` (boolean, default: `true`).
  - `installDevTools` (boolean, default: `true`).

### `node-modules-volume`
- **Mounts**: `source=${devcontainerId}-node_modules,target=/workspaces/${localWorkspaceFolderBasename}/node_modules,type=volume` (one volume per dev container, so same-named folders no longer share `node_modules`)
- Prevents cross-OS filesystem sync performance degradation on macOS and Windows by keeping `node_modules` inside Docker storage.

### `github`
- **Environment (`remoteEnv`)**: Maps host `${localEnv:DEVCONTAINER_GITHUB_TOKEN}` to `GH_TOKEN`, `GITHUB_TOKEN`, and `DEVCONTAINER_GITHUB_TOKEN` inside the container (not baked into container layers).
- **CLI**: Installs the official GitHub CLI (`gh`) binary (verified against `gh_<version>_checksums.txt`) when not already installed.
- **Git Authentication**: Configures system Git (`/etc/gitconfig`) to use `gh auth git-credential` for `https://github.com` and `https://gist.github.com`, and rewrites `git@github.com:` / `ssh://git@github.com/` remotes to `https://github.com/` inside the container so `git push` and `gh pr create` strictly use the restricted token instead of forwarded host SSH keys.
- **Options**:
  - `version` (string, default: `"latest"`): GitHub CLI version to install if `gh` is not already present.
  - `gitProtocol` (string, default: `"https"`): Set to `"https"` to rewrite SSH GitHub remotes to HTTPS in system Git config, or `"ssh"` to leave SSH remotes untouched.

---

## Local Development & Testing

Every feature is self-contained: `install.sh` (build time, root) and at most one lifecycle script, each readable top to bottom, with no shared library. The safety rules are CI checks instead: CI fails when a script uses `chmod 777`, pipes a download into a shell, or calls `curl` without `--proto '=https'`, and when a feature's files change in a PR without a version bump (publishing skips versions that already exist).

Each feature that touches `$HOME` has a scenario running as the non-root `node` user: the autogenerated test runs as root, where ownership bugs are invisible.

Run tests locally using the Dev Container CLI:

```bash
# Test a single feature
devcontainer features test -f pnpm .
devcontainer features test -f dotfiles .
devcontainer features test -f yarn .
devcontainer features test -f antigravity .
devcontainer features test -f opencode .
devcontainer features test -f cline .
devcontainer features test -f kilocode .
devcontainer features test --skip-autogenerated -f worktree .

# Note: when Docker runs in a Colima VM, only $HOME is shared with containers.
# Point TMPDIR at a shared location or test runs fail to mount their workspace:
mkdir -p "$HOME/.cache/devcontainer-tmp"
TMPDIR="$HOME/.cache/devcontainer-tmp" devcontainer features test -f opencode .

# Generate documentation for all features
devcontainer features generate-docs -p src -r ghcr.io -n usermeme/devcontainer-features
```

## Publishing

When pushed to the `main` branch, the included GitHub Actions workflow (`.github/workflows/release.yaml`) automatically publishes features to the GitHub Container Registry (`ghcr.io/usermeme/devcontainer-features/<feature>:1`).
