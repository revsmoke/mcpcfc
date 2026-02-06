# Contributing

Thanks for contributing! This project is an MCP server implemented in **Adobe ColdFusion 2025**.

## Tested environment

- ✅ macOS + Adobe ColdFusion 2025
- ⚠️ Other platforms/CFML engines are welcome, but currently unverified

## Quick dev loop

1. Make changes
2. Restart the app:
   - `restart-app.cfm`
   - or hit any page with `?reload=1`
3. Validate:
   - Browser test client: `client-examples/test-client.cfm`
   - Stdio smoke test: `MCPCFC_URL="http://localhost:8500/mcpcfc" ./scripts/verify-stdio.sh`

## Project structure (high level)

```text
core/                 MCP request handling + tools
endpoints/mcp.cfm      Unified JSON-RPC HTTP endpoint
registry/              Tool/resource/prompt registries
session/               Session manager
bridge/                Claude Desktop stdio ⇄ HTTP bridge
client-examples/       Browser test client
config/                Settings + routing config
```

## Adding a tool

1. Create a new tool component in `core/tools/` that extends `AbstractTool` (see existing tools).
2. Register it by adding the component path to the `toolClasses` array in:
   - `core/MCPServer.cfc` → `registerDefaultTools()`

### Tool checklist

- Input validation: use `validateRequired()` and/or `validateTypes()`
- Return values: use `textResult()`, `jsonResult()`, or `errorResult()`
- Keep JSON keys **lowercase** in schemas/results (strict MCP clients depend on it)

## Resources & prompts

This repo currently registers resources/prompts as structs:

- Resources: `application.resourceRegistry.register({ ... })`
- Prompts: `application.promptRegistry.register({ ... })`

If you add new registries or more dynamic resources/prompts, keep responses aligned with MCP key casing (`resources`, `prompts`, `contents`, etc.).

## Reporting issues

When filing a bug, include:

- ColdFusion version + OS
- Whether you’re using browser client vs Claude Desktop
- Relevant logs:
  - Claude Desktop (macOS): `~/Library/Logs/Claude/mcp-server-<name>.log`
  - MCPCFC server logs: `logs/` (see `config/settings.cfm`)

