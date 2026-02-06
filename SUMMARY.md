# MCPCFC Summary

MCPCFC is an **MCP (Model Context Protocol)** server implemented in **Adobe ColdFusion 2025**. It exposes ColdFusion-backed tools over **JSON-RPC 2.0** via a unified HTTP endpoint and includes a stdio bridge so local MCP clients (ex: Claude Desktop) can connect.

## Tested environment

- ✅ macOS + Adobe ColdFusion 2025
- ⚠️ Other platforms/CFML engines are welcome, but currently unverified

## Key pieces

- **Unified MCP endpoint**: `endpoints/mcp.cfm`
- **Claude Desktop bridge (stdio ⇄ HTTP)**: `bridge/cf-mcp-bridge.sh`
- **Browser test client**: `client-examples/test-client.cfm`
- **Client configs (Claude, ChatGPT, Codex, Cursor, VS Code, Zed, etc.)**: `CLIENTS.md`
- **Smoke test**: `scripts/verify-stdio.sh`

## Protocol notes

- Transport: HTTP POST (JSON-RPC 2.0)
- Negotiated protocol version defaults to `2025-06-18` (see `config/settings.cfm`)
- Supported methods:
  - `initialize` / `notifications/initialized`
  - `tools/list` / `tools/call`
  - `resources/list` / `resources/read`
  - `prompts/list` / `prompts/get`

## Layout

```text
core/                 MCP handling + tools
core/tools/            Tool implementations (Hello, PDF, DB, etc.)
registry/              Tool/resource/prompt registries
endpoints/mcp.cfm      HTTP entrypoint
bridge/                Stdio bridge for Claude Desktop
client-examples/       Browser test client
scripts/               Local smoke/regression scripts
```
