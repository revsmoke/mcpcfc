# MCPCFC (ColdFusion MCP Server)

MCPCFC is a **Model Context Protocol (MCP)** server implemented in **Adobe ColdFusion 2025**. It exposes a set of ColdFusion-backed tools (PDF, database, file sandbox, etc.) to MCP clients such as **Claude Desktop** via JSON-RPC 2.0.

## Tested environment

- ✅ **macOS + Adobe ColdFusion 2025**
- ⚠️ Not yet tested on Windows/Linux or other CFML engines (ex: Lucee)

## What you get

- **Unified MCP endpoint**: `endpoints/mcp.cfm` (JSON-RPC 2.0 over HTTP POST)
- **Stdio bridge for Claude Desktop**: `bridge/cf-mcp-bridge.sh` (stdio ⇄ HTTP)
- **Browser test client**: `client-examples/test-client.cfm`

### Included tools

| Tool | Description |
|------|-------------|
| `hello` | Simple greeting (useful for connectivity) |
| `fileOperations` | Sandboxed file operations (`read`, `write`, `list`, `delete`, `exists`, `info`) |
| `httpRequest` | Outbound HTTP requests (blocks private/internal IPs) |
| `pdf` | Generate / extract / merge PDFs (uses ColdFusion’s PDF features) |
| `queryDatabase` | Validated **read-only** SQL queries (`SELECT` only) |
| `sendEmail` | Send email via SendGrid (requires `SENDGRID_API_KEY`) |

## Quick start (browser)

1. **Fork** this repo and clone it into your ColdFusion web root (or symlink it there).
2. Visit the test client in your browser:
   - If the project folder is `mcpcfc` under your web root:
     - `http://localhost:8500/mcpcfc/client-examples/test-client.cfm`
3. Click **Connect** → **List Tools** → **Call Hello Tool**.

> Your “base URL” is whatever URL prefix makes this endpoint load:
> `BASE_URL/endpoints/mcp.cfm`

## Claude Desktop (local stdio)

Claude Desktop talks to local MCP servers via **stdio**. MCPCFC is HTTP, so you configure Claude Desktop to launch the bridge script.

Example config (`~/Library/Application Support/Claude/claude_desktop_config.json` on macOS):

```json
{
  "mcpServers": {
    "coldfusion-mcp": {
      "command": "/absolute/path/to/mcpcfc/bridge/cf-mcp-bridge.sh",
      "env": {
        "MCPCFC_URL": "http://localhost:8500/mcpcfc"
      }
    }
  }
}
```

Then **fully quit and relaunch** Claude Desktop.

### Debugging Claude Desktop

- Claude’s MCP logs (macOS): `~/Library/Logs/Claude/mcp-server-<name>.log`
  - Example (if your `mcpServers` key is `coldfusion-mcp`): `~/Library/Logs/Claude/mcp-server-coldfusion-mcp.log`
- Bridge debug logging: set `MCPCFC_DEBUG=1` in the `env` block (logs go to stderr)

## Remote / Streamable HTTP clients

MCPCFC also supports MCP clients that can connect over **Streamable HTTP** directly to:

- `BASE_URL/endpoints/mcp.cfm`

For copy/paste configs and client-specific instructions (Claude Code, ChatGPT, Codex, Cursor, VS Code, Zed, etc.), see:

- `CLIENTS.md`

## Stdio smoke test (recommended)

This repo includes a regression/smoke test that verifies MCP responses keep the **correct JSON key casing** required by strict MCP clients:

```bash
MCPCFC_URL="http://localhost:8500/mcpcfc" ./scripts/verify-stdio.sh
```

## Direct HTTP smoke test (Streamable HTTP)

If you’re connecting a client directly to the HTTP endpoint, this smoke test validates the endpoint over Streamable HTTP (including the `MCP-Session-Id` response header):

```bash
MCPCFC_URL="http://localhost:8500/mcpcfc" ./scripts/verify-http.sh
```

If you’re using local HTTPS with an untrusted cert, set `MCPCFC_INSECURE=1` when running the bridge (or trust the cert in your OS keychain).

## Configuration

Edit `config/settings.cfm`:

- `protocolVersion` (default: `2025-06-18`)
- `defaultDatasource` (default: `mcpcfc_ds`)
- file sandbox paths + size limits
- CORS settings

### Database tool setup (optional)

`queryDatabase` expects a ColdFusion datasource named `mcpcfc_ds`.

- Configure the datasource in ColdFusion Administrator.
- Load the sample schema:
  - run `database-setup.cfm` in your browser, or
  - import `mcpcfc_db.sql` into MySQL/MariaDB (the sample DDL is MySQL-flavored)

## Adding a new tool

1. Create a tool in `core/tools/` (see existing tools for patterns).
2. Register it in `core/MCPServer.cfc` by adding your component to the `toolClasses` array in `registerDefaultTools()`.

## Security warning

This project is a **powerful remote-control surface** (filesystem, HTTP client, database, email, PDF). Don’t expose it publicly without:

- Authentication
- Tight CORS/origin restrictions
- Rate limiting
- Tool-by-tool authorization and sandboxing

## Project layout

```text
Application.cfc
bridge/
  cf-mcp-bridge.sh
client-examples/
  test-client.cfm
config/
  routes.cfm
  settings.cfm
core/
  CapabilityManager.cfc
  JSONRPCHandler.cfc
  MCPServer.cfc
  TransportManager.cfc
  tools/
    AbstractTool.cfc
    DatabaseTool.cfc
    FileTool.cfc
    HelloTool.cfc
    HttpClientTool.cfc
    PDFTool.cfc
    SendGridEmailTool.cfc
endpoints/
  mcp.cfm
logging/
registry/
session/
validators/
scripts/
  verify-stdio.sh
  verify-http.sh
```

## License

MIT. See `LICENSE`.
