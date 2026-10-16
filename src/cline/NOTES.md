## Host requirements

The host path `~/.cline/data/settings` must exist, or the container fails to start (bind mounts are not created on demand):

```json
"initializeCommand": "mkdir -p ~/.cline/data/settings"
```

## What is shared with the host

Only `~/.cline/data/settings` is mounted. It holds `providers.json` (provider API keys and the `cline auth` login), `global-settings.json` and `cline_mcp_settings.json` (MCP servers). Log in once with `cline auth`, on the host or in any container, and every container sees it.

The rest of `~/.cline` stays inside the container on purpose:

- `~/.cline/data/locks` holds the Cline hub daemon's PID and port. A host PID means nothing in the container's process namespace: a shared record makes the container retire the host's hub as "stale" and the host then dials a port that only exists inside the container.
- Sessions and task history are SQLite databases. SQLite locking is not reliable across a Docker Desktop / Colima bind mount, so host and container writing the same file can corrupt your history.
- As a consequence, session and task history live in the container and are lost when it is rebuilt.
- Global rules, workflows, hooks and plugins under `~/.cline` are not shared. Skills are, when combined with the `antigravity` feature, which mounts `~/.agents/skills`.

## Security

- `providers.json` stores API keys and tokens **in plain text**, and the mount is read-write (Cline updates tokens there). Any process in the container can read it. For example, a malicious `postinstall` script in one of the project's npm dependencies can copy your Anthropic/OpenRouter key and run up charges on your account, or use your Cline account. Only add this feature to projects whose dependencies you trust, and prefer keys with a spending limit.
- The CLI is installed root-owned into `/usr/local/lib/cline` and its self-update is disabled (`CLINE_NO_AUTO_UPDATE=1`): a binary on `PATH` the container user can rewrite would let any process in the container replace `cline` with something else. Change the `version` option and rebuild to update.
- The download is checked against the sha512 published in the npm registry (`openssl` is installed if missing); a mismatch fails the build, and nothing unverified is installed.
- `/usr/local/bin/cline` is a small shim that passes the system CA bundle to the CLI (`NODE_EXTRA_CA_CERTS`), as the official npm wrapper does, so company CAs added to the image are trusted.

## Notes

- The prebuilt CLI needs a glibc-based image on x86_64 or arm64. On Alpine (musl), install it with `npm install -g cline` instead.
- The mount is your real host directory. The feature never changes its ownership; if it is not writable inside the container, fix the ownership on the host.
