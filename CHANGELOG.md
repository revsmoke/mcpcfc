# Changelog

All notable changes to MCPCFC will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.1.0] - 2025-01-26

### Added
- Initial release of the world's first ColdFusion MCP server! 🎉
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

[0.1.0]: https://github.com/revsmoke/mcpcfc/releases/tag/v0.1.0