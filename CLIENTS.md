# MCP Client Setup (Local + Remote)

This doc explains how to connect **MCPCFC** to popular MCP clients in two ways:

- **Local (stdio)**: the client starts a local process. For MCPCFC, this means running the stdio bridge at `bridge/cf-mcp-bridge.sh`.
- **Remote (Streamable HTTP)**: the client connects directly to MCPCFC over HTTPS at `endpoints/mcp.cfm`.

> Tested only on **macOS + Adobe ColdFusion 2025** so far.

Reference docs used while writing this:

- [MCP specification (Streamable HTTP transport)](https://modelcontextprotocol.io/specification/)
- [Claude Code MCP](https://docs.claude.com/en/docs/claude-code/mcp)
- [OpenAI Codex MCP](https://developers.openai.com/codex/mcp)
- [OpenAI ChatGPT Developer Mode](https://platform.openai.com/docs/developer-mode)
- [VS Code MCP servers](https://code.visualstudio.com/docs/copilot/chat/mcp-servers)
- [Zed MCP](https://zed.dev/docs/assistant/model-context-protocol)
- [Kimi CLI MCP](https://kimi-cli.com/docs/mcp)

---

## URLs you’ll use

MCPCFC has a “base URL” and an “endpoint URL”:

- `BASE_URL` (project root), for example:
  - `http://localhost:8500/mcpcfc`
  - `https://your-domain.example/mcpcfc`
- `MCP_ENDPOINT_URL`:
  - `BASE_URL/endpoints/mcp.cfm`

The stdio bridge expects `MCPCFC_URL=BASE_URL` (it appends `/endpoints/mcp.cfm` internally).

---

## Streamable HTTP notes (remote servers)

- MCPCFC’s Streamable HTTP endpoint is `endpoints/mcp.cfm` and supports **JSON-RPC 2.0 over HTTP POST**.
- MCPCFC **does not** currently provide an SSE event stream (HTTP `GET` returns `405`).
- MCPCFC returns a session id header (`MCP-Session-Id`) on responses; Streamable HTTP clients typically send that header back on subsequent requests.

For most “remote” clients, your server must be reachable over the public internet with a trusted HTTPS certificate (not `localhost` and usually not `.local`).

If you expose MCPCFC publicly, you should add authentication and lock down CORS/allowed origins (see `config/settings.cfm` and the warnings in `README.md`).

---

## Client compatibility quick matrix

| Client | Local (stdio) | Remote (HTTP) | Notes |
|---|---:|---:|---|
| Claude Desktop | ✅ | ✅* | *Remote depends on your plan + “Connectors” UI; local stdio uses `claude_desktop_config.json`. |
| Claude Code | ✅ | ✅ | CLI supports `--transport stdio` and `--transport http`. |
| ChatGPT (Desktop/Web) | ❌ | ✅ | Requires a reachable HTTPS URL (not `localhost`). Uses Developer Mode “Apps”. |
| Codex Desktop (app) | ✅ | ✅ | Uses `~/.codex/config.toml` (shared with Codex CLI + IDE extension). |
| Codex CLI | ✅ | ✅ | Same `~/.codex/config.toml`. |
| Cursor | ✅ | ✅ | Uses `~/.cursor/mcp.json` or `<repo>/.cursor/mcp.json`. |
| Antigravity IDE | ✅ | ✅ | Uses `~/.gemini/antigravity/mcp_config.json` (Google docs). |
| VS Code | ✅ | ✅ | Uses `.vscode/mcp.json` or user profile `mcp.json`. |
| Kimi Code CLI | ✅ | ✅ | CLI supports `kimi mcp add --transport http|stdio`. |
| Zed | ✅ | ✅ | Uses `~/.config/zed/settings.json`. |

---

## Claude Desktop

### Local (stdio via bridge)

Edit:

- `~/Library/Application Support/Claude/claude_desktop_config.json`

Example:

```json
{
  "mcpServers": {
    "mcpcfc": {
      "command": "/absolute/path/to/mcpcfc/bridge/cf-mcp-bridge.sh",
      "env": {
        "MCPCFC_URL": "http://localhost:8500/mcpcfc"
      }
    }
  }
}
```

Then fully quit and relaunch Claude Desktop.

### Remote (Streamable HTTP)

If your Claude plan supports **custom connectors**, add MCPCFC as a remote MCP server by URL:

- `https://your-domain.example/mcpcfc/endpoints/mcp.cfm`

The exact UI varies by version, but look for:

- Settings → Connectors → “Add custom connector”

Docs: [Claude connectors (help center)](https://support.claude.com/en/articles/11583493-connectors-for-claude#h_97187e44cc)

---

## Claude Code

### Remote (Streamable HTTP)

```bash
claude mcp add --transport http mcpcfc https://your-domain.example/mcpcfc/endpoints/mcp.cfm
```

### Local (stdio via bridge)

```bash
claude mcp add --transport stdio --env MCPCFC_URL=http://localhost:8500/mcpcfc mcpcfc -- /absolute/path/to/mcpcfc/bridge/cf-mcp-bridge.sh
```

Docs: [Claude Code MCP](https://docs.claude.com/en/docs/claude-code/mcp)

---

## ChatGPT Desktop / ChatGPT (Developer Mode)

ChatGPT connects to MCP servers over the network, so you’ll need a reachable HTTPS URL (a `.local` hostname or `localhost` won’t work).

High-level setup:

1. Enable Developer Mode in ChatGPT settings (Apps).
2. Add a new MCP “App” using the URL:
   - `https://your-domain.example/mcpcfc/endpoints/mcp.cfm`
3. Enable the app/tools for the chat.

If you don’t see Developer Mode in the desktop app UI, enable it on ChatGPT web first (it’s the same account).

If you want to use MCPCFC specifically as a **ChatGPT Connector for Deep Research**, OpenAI currently requires connector servers to provide `search` + `fetch` tools; MCPCFC does not include those tools by default.

Docs:

- [Developer Mode](https://platform.openai.com/docs/developer-mode)
- [MCP servers for ChatGPT/connectors](https://platform.openai.com/docs/mcp)

---

## Codex Desktop (app) + Codex CLI

Codex MCP config lives in:

- `~/.codex/config.toml`

### Remote (Streamable HTTP)

Add:

```toml
[mcp_servers.mcpcfc]
url = "https://your-domain.example/mcpcfc/endpoints/mcp.cfm"
```

Or add it via CLI:

```bash
codex mcp add mcpcfc --url https://your-domain.example/mcpcfc/endpoints/mcp.cfm
```

### Local (stdio via bridge)

Add:

```toml
[mcp_servers.mcpcfc]
command = "/absolute/path/to/mcpcfc/bridge/cf-mcp-bridge.sh"

[mcp_servers.mcpcfc.env]
MCPCFC_URL = "http://localhost:8500/mcpcfc"
```

Or add it via CLI (then add the `env` block in `~/.codex/config.toml`):

```bash
codex mcp add mcpcfc -- /absolute/path/to/mcpcfc/bridge/cf-mcp-bridge.sh
```

Docs: [OpenAI Codex MCP](https://developers.openai.com/codex/mcp)

---

## Cursor IDE

Cursor reads MCP config from one of:

- `~/.cursor/mcp.json`
- `<your-repo>/.cursor/mcp.json`

### Remote (Streamable HTTP)

```json
{
  "mcpServers": {
    "mcpcfc": {
      "url": "https://your-domain.example/mcpcfc/endpoints/mcp.cfm"
    }
  }
}
```

### Local (stdio via bridge)

```json
{
  "mcpServers": {
    "mcpcfc": {
      "command": "/absolute/path/to/mcpcfc/bridge/cf-mcp-bridge.sh",
      "env": {
        "MCPCFC_URL": "http://localhost:8500/mcpcfc"
      }
    }
  }
}
```

Docs:

- [OpenAI Codex MCP guide (Cursor examples)](https://developers.openai.com/codex/mcp)
- [Firebase CLI docs (Cursor config locations)](https://firebase.google.com/docs/cli/mcp-server)

---

## Antigravity IDE

Antigravity reads MCP config from:

- `~/.gemini/antigravity/mcp_config.json`

### Remote (Streamable HTTP)

```json
{
  "mcpServers": {
    "mcpcfc": {
      "url": "https://your-domain.example/mcpcfc/endpoints/mcp.cfm"
    }
  }
}
```

### Local (stdio via bridge)

```json
{
  "mcpServers": {
    "mcpcfc": {
      "command": "/absolute/path/to/mcpcfc/bridge/cf-mcp-bridge.sh",
      "env": {
        "MCPCFC_URL": "http://localhost:8500/mcpcfc"
      }
    }
  }
}
```

Docs: [Firebase CLI docs (Antigravity MCP config)](https://firebase.google.com/docs/cli/mcp-server)

---

## VS Code

Create a workspace file:

- `.vscode/mcp.json`

### Remote (Streamable HTTP)

```json
{
  "servers": {
    "mcpcfc": {
      "type": "http",
      "url": "https://your-domain.example/mcpcfc/endpoints/mcp.cfm"
    }
  }
}
```

### Local (stdio via bridge)

```json
{
  "servers": {
    "mcpcfc": {
      "type": "stdio",
      "command": "/absolute/path/to/mcpcfc/bridge/cf-mcp-bridge.sh",
      "env": {
        "MCPCFC_URL": "http://localhost:8500/mcpcfc"
      }
    }
  }
}
```

Docs: [VS Code MCP servers](https://code.visualstudio.com/docs/copilot/chat/mcp-servers)

---

## Kimi Code CLI

### Remote (Streamable HTTP)

```bash
kimi mcp add --transport http mcpcfc https://your-domain.example/mcpcfc/endpoints/mcp.cfm
```

### Local (stdio via bridge)

```bash
kimi mcp add --transport stdio --env MCPCFC_URL=http://localhost:8500/mcpcfc mcpcfc -- /absolute/path/to/mcpcfc/bridge/cf-mcp-bridge.sh
```

Docs: [Kimi CLI MCP](https://kimi-cli.com/docs/mcp)

---

## Zed IDE

Edit:

- `~/.config/zed/settings.json`

### Remote (Streamable HTTP)

```json
{
  "context_servers": {
    "mcpcfc": {
      "url": "https://your-domain.example/mcpcfc/endpoints/mcp.cfm"
    }
  }
}
```

### Local (stdio via bridge)

```json
{
  "context_servers": {
    "mcpcfc": {
      "command": "/absolute/path/to/mcpcfc/bridge/cf-mcp-bridge.sh",
      "env": {
        "MCPCFC_URL": "http://localhost:8500/mcpcfc"
      }
    }
  }
}
```

Docs: [Zed MCP](https://zed.dev/docs/assistant/model-context-protocol)
