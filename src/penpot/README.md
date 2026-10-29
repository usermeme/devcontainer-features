
# Penpot Kit & Host Environment (penpot)

Mounts host Penpot AI Kit directory (~/.penpot-ai-kit) and configures Penpot AI Kit inside devcontainer.

## Example Usage

```json
"features": {
    "ghcr.io/usermeme/devcontainer-features/penpot:1": {}
}
```

## Options

| Options Id | Description | Type | Default Value |
|-----|-----|-----|-----|
| symlinkPenpot | Symlink /home/node/.penpot to /home/node/.penpot-ai-kit inside the container | boolean | true |

## Host requirements

The host path `~/.penpot-ai-kit` must exist, or the container fails to start (bind mounts are not created on demand):

```json
"initializeCommand": "mkdir -p ~/.penpot-ai-kit"
```

If you also want `~/.penpot` available on the host, symlink it to `~/.penpot-ai-kit`:

```bash
ln -sfn ~/.penpot-ai-kit ~/.penpot
```

## How it works

- **Mount**: Mounts the host's `~/.penpot-ai-kit` directory into `/home/node/.penpot-ai-kit` in the container, using the exact same folder name on both host and devcontainer.
- **Symlink**: When `symlinkPenpot` is enabled (default: `true`), `setup-penpot.sh` creates a relative symlink `/home/node/.penpot -> .penpot-ai-kit` inside the container if `/home/node/.penpot` does not already exist. This ensures agents and tools (such as OpenCode or Claude Code) configured with either path work seamlessly.
- **Permissions**: `~/.penpot-ai-kit` is your real host directory. The feature never changes its ownership; if it is not writable inside the container, fix the ownership on the host.

## Manual MCP Configuration

When installing with `mode=none`, you configure the Penpot MCP endpoint manually for each agent:

- **OpenCode** (`~/.config/opencode/opencode.json`):
  ```json
  {
    "mcp": {
      "penpot": {
        "type": "remote",
        "url": "https://design.penpot.app/mcp/stream?userToken=YOUR_MCP_KEY",
        "enabled": true
      }
    }
  }
  ```
- **Cursor** (`~/.cursor/mcp.json`):
  ```json
  {
    "mcpServers": {
      "penpot": {
        "url": "https://design.penpot.app/mcp/stream?userToken=YOUR_MCP_KEY"
      }
    }
  }
  ```
- **Claude Desktop / Claude Code** (`claude_desktop_config.json` / `~/.claude.json`):
  ```json
  {
    "mcpServers": {
      "penpot": {
        "command": "npx",
        "args": ["-y", "mcp-remote", "https://design.penpot.app/mcp/stream?userToken=YOUR_MCP_KEY"]
      }
    }
  }
  ```
- **Local Penpot Instance**:
  Replace the hosted URL with your self-hosted endpoint (e.g., `http://localhost:4444/mcp/stream`).


---

_Note: This file was auto-generated from the [devcontainer-feature.json](devcontainer-feature.json).  Add additional notes to a `NOTES.md`._
