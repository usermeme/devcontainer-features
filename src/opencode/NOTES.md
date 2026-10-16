## Host requirements

The host path `~/.config/opencode` must exist, or the container fails to start (bind mounts are not created on demand):

```json
"initializeCommand": "mkdir -p ~/.config/opencode"
```

## Logins and sessions

`~/.local/share/opencode` holds `opencode.db`, a SQLite database with your provider logins and your sessions. It lives in the `opencode-data` Docker volume, shared by all devcontainers and kept across rebuilds. It is **not** shared with the host.

Up to 1.1.0 it was a bind mount of the host's `~/.local/share/opencode`. SQLite locking does not work across the macOS / Windows to Linux VM boundary, so two sessions (host and container, or two containers) wrote the same file unaware of each other and corrupted it. Containers sharing the volume run on the same VM kernel, where SQLite locking works.

- **Log in once for all containers**: run `opencode auth login` (or `/connect`) in any container. Your host keeps its own, separate login.
- **API keys from the host**: opencode reads provider keys from environment variables, so a key can be shared with the host without any database. In the project's `devcontainer.override.json`:

  ```json
  "remoteEnv": { "ANTHROPIC_API_KEY": "${localEnv:ANTHROPIC_API_KEY}" }
  ```

  This does not cover OAuth subscription logins (Claude Pro, ChatGPT, Copilot); their refresh tokens rotate, so they cannot be copied between host and container.
- Upgrading from 1.1.0: containers start logged out once. The host database is no longer touched.

## Security

- Any process in any container using this feature can read the logins in the volume. For example, a malicious `postinstall` script in one project's npm dependencies can copy your provider tokens and spend on your account, or tamper with the login every other project's container uses. Your host's `opencode.db` is out of reach. Prefer API keys with a spending limit.
- `~/.config/opencode` is your real host directory. The feature never changes its ownership; if it is not writable inside the container, fix the ownership on the host.

## Notes

- OpenCode's state (`~/.local/state/opencode`) and cache (`~/.cache/opencode`) stay inside the container.
- To start over with container logins: `docker volume rm opencode-data` (with all devcontainers using it stopped).
