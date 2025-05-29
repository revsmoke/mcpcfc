# MCPCFC - CF2023 CLI Enhanced Edition 🚀

## Overview

This is the enhanced CF2023 edition of MCPCFC, leveraging Adobe ColdFusion 2023's capabilities to provide:

- **28 powerful tools** (up from the original 8)
- **Enhanced security** with pattern-based code filtering
- **Database logging** with execution tracking
- **Real-time dashboards** for monitoring tool usage
- **REPL integration** for interactive code execution
- **Server management tools** for dynamic configuration
- **Package management** via CommandBox integration
- **Development workflow tools** for enhanced productivity

## Current Status

### ✅ All Phases Complete!
- [x] Phase 1: Native CFML Stdio Bridge ✅
- [x] Phase 2: REPL Integration Tool ✅
- [x] Phase 3: Server Management Tools ✅
- [x] Phase 4: Package Management Integration ✅
- [x] Phase 5: Development Workflow Tools ✅ (COMPLETED 2025-05-28)
- [x] Database logging and dashboards ✅
- [x] Enhanced security implementation ✅

## Requirements

- **Adobe ColdFusion 2023** or higher
- **MySQL Database** for logging and analytics
- **CommandBox 6.0+** (for package management features)
- **Java 17+** (required by ColdFusion 2023)

## 🔒 Security Enhancements

### Enhanced REPL Security Implementation

The REPL tools now include comprehensive security filtering:

1. **Pattern-Based Blocking with Word Boundaries**
   - Uses regex patterns with `\b` word boundaries to prevent partial matches
   - Blocks over 80 dangerous patterns organized by category
   - Prevents bypass attempts through precise pattern matching

2. **Reflection and Class Loading Protection**
   - Explicit blocking of `.class(`, `.getClass(`, `classloader` patterns
   - Prevents dynamic class loading and reflection attacks
   - Blocks access to Java internals

3. **Comprehensive Operation Blocking**
   - **File operations**: `fileread`, `filewrite`, `cffile`, etc.
   - **System commands**: `cfexecute`, `runtime.exec`, `processbuilder`
   - **Network operations**: `cfhttp`, `cfmail`, `cfsocket`
   - **Database operations**: `cfquery`, `queryexecute`, `cfstoredproc`
   - **Scope modifications**: `application.`, `server.`, `session.`
   - **Serialization**: `objectload`, `objectsave` (RCE vectors)

4. **Thread Isolation and Timeout Protection**
   - Code executes in separate cfthread context
   - Configurable timeout limits (default: 30 seconds)
   - Graceful thread termination on timeout

### Security Recommendations

1. **Development Only**: Use REPL tools only in trusted development environments
2. **Network Isolation**: Run MCP server on isolated network in production
3. **Access Control**: Implement authentication for all endpoints
4. **Audit Logging**: All executions are logged to database
5. **Resource Monitoring**: Use dashboards to monitor usage patterns

## 📊 Monitoring and Analytics

### Database Setup

1. Create MySQL database and configure datasource `mcpcfc_ds`
2. Run `http://localhost:8500/mcpcfc/database-setup.cfm` to create tables:
   - `tools` - Tool registry
   - `tool_executions` - Execution logging with success/error tracking
   - `example_data` - Sample data for testing

### Dashboards

1. **Full Dashboard** (`tool-dashboard.cfm`)
   - Real-time statistics with auto-refresh
   - Filter by time period, tool, or session
   - Tool performance summary with success rates
   - Recent execution details with input preview
   - Visual indicators for success/failure rates

2. **Simple Dashboard** (`tool-dashboard-simple.cfm`)
   - Basic statistics overview
   - Recent executions list
   - Lightweight alternative for quick monitoring

### Log Management

- Automatic log retention with configurable period
- View and manage logs via `tool-log-cleanup.cfm`
- All tool executions tracked with timing and success status

## Quick Start

1. **Clone the repository**:
   ```bash
   git clone https://github.com/revsmoke/mcpcfc.git
   cd mcpcfc
   ```

2. **Set up the database**:
   - Create MySQL database `mcpcfc_db`
   - Configure datasource `mcpcfc_ds` in CF Admin
   - Run `http://localhost:8500/mcpcfc/database-setup.cfm`

3. **Configure Claude Desktop**:
   
   Edit `~/Library/Application Support/Claude/claude_desktop_config.json`:

   ```json
   {
     "mcpServers": {
       "coldfusion-mcp": {
         "command": "/path/to/mcpcfc/cf-mcp-cf2023-cli.sh"
       }
     }
   }
   ```

4. **Start using 28 powerful tools!**

## Complete Tool List

### Original Tools (8)
1. `hello` - Connection test
2. `sendEmail` - Plain text emails
3. `sendHTMLEmail` - HTML emails
4. `validateEmailAddress` - Email validation
5. `queryDatabase` - Database queries
6. `generatePDF` - PDF generation
7. `extractPDFText` - PDF text extraction
8. `mergePDFs` - PDF merging

### REPL Tools (4) - With Enhanced Security
9. `executeCode` - Execute CFML with isolation
10. `evaluateExpression` - Evaluate expressions
11. `testSnippet` - Run code with assertions
12. `inspectVariable` - Debug variables

### Server Management (4)
13. `serverStatus` - Server information
14. `configManager` - Configuration management
15. `logStreamer` - Log file access
16. `clearCache` - Cache management

### Package Management (6) - Requires CommandBox
17. `packageInstaller` - Install packages
18. `packageList` - List packages
19. `packageSearch` - Search ForgeBox
20. `packageUpdate` - Update packages
21. `packageRemove` - Remove packages
22. `moduleManager` - ColdBox modules

### Development Workflow (6) - Requires CommandBox
23. `codeFormatter` - Format CFML code
24. `codeLinter` - Code analysis
25. `testRunner` - Run tests
26. `generateDocs` - Generate documentation
27. `watchFiles` - File monitoring
28. `gitOperations` - Git integration

## Project Structure

```
/mcpcfc/
├── Application.cfc              # Main application config with tool registration
├── components/                  # Core MCP components
│   ├── JSONRPCProcessor.cfc    # Protocol handler
│   ├── SessionManager.cfc      # Session management
│   ├── ToolHandler.cfc         # Tool execution with logging
│   └── ToolRegistry.cfc        # Tool registration
├── clitools/                   # CF2023 CLI tools
│   ├── REPLTool.cfc           # REPL with enhanced security
│   ├── ServerManagementTool.cfc # Server management
│   ├── PackageManagerTool.cfc  # Package management
│   └── DevWorkflowTool.cfc    # Development workflow
├── endpoints/                   # HTTP/SSE endpoints
│   ├── sse.cfm                 # SSE transport
│   └── messages.cfm            # HTTP message handler
├── tools/                      # Original 8 tools
├── cli-bridge/                 # Bridge scripts
│   └── cf-mcp-cf2023-cli.sh  # CF2023 CLI bridge
├── client-examples/            # Test clients
├── database-setup.cfm          # Database initialization
├── tool-dashboard.cfm          # Full monitoring dashboard
├── tool-dashboard-simple.cfm   # Simple dashboard
└── tool-log-cleanup.cfm        # Log management
```

## Implementation Highlights

### Security Improvements in REPLTool.cfc
- Comprehensive `isCodeSafe()` function with 80+ dangerous patterns
- Word boundary regex matching prevents bypasses
- Explicit reflection and class loading blocks
- Enhanced error messages with security context

### Database Logging in ToolHandler.cfc
- All executions logged with timing information
- Success/failure tracking with error messages
- Session-based analytics
- Performance metrics collection

### Shell Escaping in PackageManagerTool.cfc
- Proper `shellEscape()` function implementation
- Platform-specific escaping (Windows vs Unix)
- Protection against command injection

## Future Roadmap

### Potential Phase 6: Advanced Features
- [ ] AI-powered code suggestions
- [ ] Distributed execution support
- [ ] Advanced caching strategies
- [ ] GraphQL endpoint support
- [ ] WebSocket transport option

### SDK Development
- [ ] Extract reusable components
- [ ] Create ForgeBox package
- [ ] Develop starter templates
- [ ] Build comprehensive docs site

## Contributing

We welcome contributions! Areas of interest:
- Additional security patterns for REPL
- New tool implementations
- Dashboard enhancements
- Performance optimizations
- Documentation improvements

## Version History

- **v2.5** - Added database logging and dashboards
- **v2.4** - Enhanced security implementation
- **v2.3** - Phase 5 completion with dev workflow tools
- **v2.2** - Package management tools
- **v2.1** - Server management tools
- **v2.0** - REPL integration
- **v1.0** - Original 8 tools

---

*Elevating ColdFusion development with modern AI integration!*