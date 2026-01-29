# Changelog

All notable changes to MCPCFC will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [2.0.0] - 2025-01-28

### Added
- **MCP Protocol 2025-11-25** - Full compliance with latest MCP specification
- **ColdFusion 2025 Support** - Optimized for Adobe ColdFusion 2025
- **Unified HTTP Endpoint** - Single `endpoints/mcp.cfm` for all MCP communication
- **AbstractTool Base Class** - New base class for creating tools (`tools/AbstractTool.cfc`)
- **Registry System** - Separate registries for tools, resources, and prompts
  - `registry/ToolRegistry.cfc`
  - `registry/ResourceRegistry.cfc`
  - `registry/PromptRegistry.cfc`
- **Input Validation** - Comprehensive input validation system
  - `validators/InputValidator.cfc`
  - `validators/SQLValidator.cfc`
- **Logging System** - Centralized logging via `logging/Logger.cfc`
- **Configuration System** - Centralized config in `config/` directory
- **New Tools**:
  - `FileTool.cfc` - Secure file operations
  - `HttpClientTool.cfc` - HTTP request capabilities
  - `SendGridEmailTool.cfc` - Email via SendGrid API

### Changed
- **Architecture Refactor** - Complete restructuring of codebase
  - Core components moved to `core/` directory
  - Session management moved to `session/` directory
  - Tools now extend `AbstractTool` base class
- **Endpoint Consolidation** - SSE and messages endpoints merged into single `mcp.cfm`
- **Bridge Script** - Consolidated into single `bridge/cf-mcp-bridge.sh`
- **Tool Registration** - Tools now self-register via their `init()` method
- **Session Management** - Enhanced with cleanup routines

### Deprecated
- **SSE Transport** - Deprecated per MCP Protocol 2025-11-25 (moved to `_deprecated/`)
- **Separate Endpoints** - `sse.cfm` and `messages.cfm` replaced by unified `mcp.cfm`
- **ToolHandler.cfc** - Replaced by individual tool classes
- **Old Bridge Scripts** - Multiple bridge scripts consolidated into one

### Removed
- Direct access to old endpoint paths (redirects to new endpoint)

### Security
- SQL injection protection via dedicated `SQLValidator.cfc`
- Input sanitization for all tool parameters
- File operation sandboxing in `FileTool.cfc`

### Migration Guide
If upgrading from v1.x:
1. Update Claude Desktop config to use `bridge/cf-mcp-bridge.sh`
2. Update any direct endpoint references to `endpoints/mcp.cfm`
3. Migrate custom tools to extend `tools/AbstractTool.cfc`
4. Review `config/settings.cfm` for new configuration options

---

## [0.1.0] - 2025-01-26

### Added
- Initial release of the world's first ColdFusion MCP server!
- JSON-RPC 2.0 protocol implementation
- Server-Sent Events (SSE) transport layer
- Thread-safe session management using Java concurrent utilities
- Extensible tool registry system
- Example tools:
  - Hello World tool demonstrating basic structure
  - Database query tool showing CF's native DB capabilities
  - Email tool (example)
  - PDF tool (example) leveraging CF's built-in PDF features
- Browser-based test client for easy testing
- Comprehensive documentation
- MIT License

### Security
- Input validation and sanitization
- SQL injection protection via cfqueryparam
- CORS headers for cross-origin requests

### Known Issues
- WebSocket transport not yet implemented
- No authentication mechanism (planned for next release)
- Limited to single-server deployment (Redis support coming)

---

[2.0.0]: https://github.com/revsmoke/mcpcfc/releases/tag/v2.0.0
[0.1.0]: https://github.com/revsmoke/mcpcfc/releases/tag/v0.1.0
