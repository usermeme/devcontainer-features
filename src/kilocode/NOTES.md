## Host requirements

The host path `~/.config/kilo` must exist, or the container fails to start (bind mounts are not created on demand):

```json
"initializeCommand": "mkdir -p ~/.config/kilo"
```

## What is shared with the host

Only `~/.config/kilo` is mounted: `config.json` (global config, provider defaults, MCP servers) and the rest of the CLI config directory. Edit it once on the host and every container sees it.

Logins and sessions are **not** shared with the host. `~/.local/share/kilo` holds `auth.json` (the `/connect` login and provider API keys), sessions, logs and cloned repos. It lives in the `kilocode-data` Docker volume, shared by all devcontainers and kept across rebuilds. SQLite-style state is not safe on a bind mount across the macOS / Windows to Linux VM boundary: two writers (host and container) corrupt it, so the host keeps its own, separate login.

- **Log in once for all containers**: run `kilo` and use `/connect` in any container.
- The Kilo VS Code / JetBrains extension stores its own config under `~/.kilocode` on the host; that directory is not mounted. The CLI in the container reads `~/.config/kilo`.

## Security

- Any process in any container using this feature can read the logins in the volume: `auth.json` stores tokens in plain text and the volume is read-write (Kilo refreshes tokens there). For example, a malicious `postinstall` script in one project's npm dependencies can copy your provider tokens and spend on your account, or tamper with the login every other project's container uses. Your host's `~/.local/share/kilo` is out of reach. Prefer API keys with a spending limit.
- The CLI is installed root-owned into `/usr/local/lib/kilocode` and its self-update is disabled (`KILO_DISABLE_AUTOUPDATE=1`): a binary on `PATH` the container user can rewrite would let any process in the container replace `kilo` with something else. Change the `version` option and rebuild to update.
- The download is checked against the sha512 published in the npm registry (`openssl` is installed if missing); a mismatch fails the build, and nothing unverified is installed.
- `/usr/local/bin/kilo` is a small shim that passes the system CA bundle (`NODE_EXTRA_CA_CERTS`) and the bundled tree-sitter WASM directory (`KILO_TREE_SITTER_WASM_DIR`) to the CLI, as the official npm wrapper does, so company CAs added to the image are trusted.

## Notes

- Prebuilt binaries exist for linux arm64/x64, glibc and musl; x64 CPUs without AVX2 get the `-baseline` build automatically (the default one crashes with "Illegal instruction"). The unpacked install is ~300 MB. Where no prebuilt fits, install with `npm install -g @kilocode/cli`.
- Kilo's state (`~/.local/state/kilo`) and cache (`~/.cache/kilo`) stay inside the container.
- The mounts are your real host directory and a shared volume. The feature never changes the host directory's ownership; if it is not writable inside the container, fix the ownership on the host.
- To start over with container logins: `docker volume rm kilocode-data` (with all devcontainers using it stopped).
