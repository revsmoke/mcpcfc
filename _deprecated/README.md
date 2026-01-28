# Deprecated Files

This directory contains files that were deprecated during the MCPCFC v2.0 refactor (January 2026).

## Why These Files Were Deprecated

The MCPCFC server was refactored to:
1. Support MCP Protocol Version 2025-11-25 (SSE transport deprecated)
2. Use ColdFusion 2025 features
3. Implement a cleaner architecture with proper separation of concerns

## Files Moved Here

### components/
- `JSONRPCProcessor.cfc` - Replaced by `core/JSONRPCHandler.cfc`
- `SessionManager.cfc` - Replaced by `session/SessionManager.cfc`
- `ToolHandler.cfc` - Functionality merged into individual tool classes
- `ToolRegistry.cfc` - Replaced by `registry/ToolRegistry.cfc`

### endpoints/
- `messages.cfm` - Replaced by `endpoints/mcp.cfm`
- `sse.cfm` - SSE transport deprecated in MCP 2025-11-25

### Root
- `EmailTool.cfc` - Replaced by `tools/SendGridEmailTool.cfc`
- `cf-mcp-*.sh` - Replaced by `bridge/cf-mcp-bridge.sh`

## Restoration

If you need to restore the old v1.x behavior, these files can be moved back to their original locations. However, the new v2.0 architecture is recommended for better maintainability and protocol compliance.

## Date Deprecated

January 28, 2026
