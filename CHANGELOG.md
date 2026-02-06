# Changelog

## Unreleased

### Fixed

- JSON responses now preserve **strict MCP key casing** (`result.tools`, JSON Schema `type/properties/required`, etc.) so strict MCP clients (ex: Claude Desktop) can discover tools reliably.

### Added

- `scripts/verify-stdio.sh` stdio smoke/regression test for the Claude Desktop bridge + tool discovery.

## [2.0.0] - 2025-01-28

### Added

- Adobe ColdFusion 2025 MCP server implementation (JSON-RPC 2.0 over HTTP)
- Unified MCP endpoint: `endpoints/mcp.cfm`
- Tool / Resource / Prompt registries:
  - `registry/ToolRegistry.cfc`
  - `registry/ResourceRegistry.cfc`
  - `registry/PromptRegistry.cfc`
- Default tools under `core/tools/`:
  - `HelloTool.cfc`
  - `DatabaseTool.cfc`
  - `PDFTool.cfc`
  - `SendGridEmailTool.cfc`
  - `FileTool.cfc`
  - `HttpClientTool.cfc`
- Claude Desktop stdio bridge: `bridge/cf-mcp-bridge.sh`

### Notes

- Protocol negotiation defaults to `2025-06-18` (see `config/settings.cfm` and `core/CapabilityManager.cfc`).

