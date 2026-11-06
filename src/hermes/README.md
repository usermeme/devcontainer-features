
# Hermes Agent CLI & Host Environment (hermes)

Installs the Hermes Agent CLI (hermes) by Nous Research and mounts host configuration, API keys, skills, and memories (~/.hermes) for autonomous AI workflows inside devcontainer.

## Example Usage

```json
"features": {
    "ghcr.io/usermeme/devcontainer-features/hermes:1": {}
}
```

## Options

| Options Id | Description | Type | Default Value |
|-----|-----|-----|-----|
| version | Hermes Agent version or channel to install ('latest', 'stable', 'main', or a git commit/branch) | string | latest |

## Host requirements

The host path `~/.hermes` must exist, or the container fails to start (bind mounts are not created on demand):

```json
"initializeCommand": "mkdir -p ~/.hermes"
```

## What is shared with the host

The host's `~/.hermes` directory is mounted into `/home/node/.hermes`:

- `config.yaml`: model selection, provider settings, tools, and memory options.
- `.env`: API keys and environment variables (e.g. `OPENROUTER_API_KEY`, `ANTHROPIC_API_KEY`).
- `auth.json`: OAuth authentication credentials.
- `SOUL.md`: agent identity, guidelines, and behavioral traits.
- `memories/`: persistent long-term memories (`MEMORY.md`, `USER.md`).
- `skills/`: custom and installed agent skills (`SKILL.md` format).
- `sessions/` and `state.db`: chat history, message records, and state database.

Configure your provider API keys and agent personality once on the host, and every container sees them immediately.

## How it works

- **Mount**: Mounts `${localEnv:HOME}/.hermes` directly into `/home/node/.hermes` in the container.
- **Environment**: Sets `HERMES_HOME=/home/node/.hermes` and ensures `/home/node/.local/bin` is on `PATH`.
- **CLI & Isolation**: Installs the Hermes Agent CLI (`hermes`) and alias `hermes-agent` into `/usr/local/bin`, with the runtime and locked dependencies kept in `/usr/local/lib/hermes-agent` so the host bind mount never shadows the runtime files.
- **Setup**: `setup-hermes.sh` runs at container startup (`postCreateCommand`) to verify host mount permissions and install the CLI if the image was built offline.

## Security

- `~/.hermes` is your real host directory. The feature never changes its ownership; if it is not writable inside the container, fix the ownership on the host.
- `.env` in `~/.hermes` stores provider API keys in plain text. Any process in the container, including dependency install scripts (`postinstall`), can read these credentials. Only use this feature in projects whose dependencies you trust. Prefer scoped API keys with spending limits.
- The CLI is installed root-owned into `/usr/local/lib/hermes-agent` and is not world-writable.

## Notes

- Supports `"remoteUser": "node"`, the default in standard Microsoft TypeScript and Node devcontainer images.
- Run `hermes setup` to configure models and providers interactively, or `hermes` to launch the agent.
