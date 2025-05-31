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

### ✅ All Phases Complete

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

- **Original Tools (8)**

1. `hello` - Connection test
2. `sendEmail` - Plain text emails
3. `sendHTMLEmail` - HTML emails
4. `validateEmailAddress` - Email validation
5. `queryDatabase` - Database queries
6. `generatePDF` - PDF generation
7. `extractPDFText` - PDF text extraction
8. `mergePDFs` - PDF merging

    - **REPL Tools (4) - With Enhanced Security**

9. `executeCode` - Execute CFML with isolation
10. `evaluateExpression` - Evaluate expressions
11. `testSnippet` - Run code with assertions
12. `inspectVariable` - Debug variables

    - **Server Management (4)**

13. `serverStatus` - Server information
14. `configManager` - Configuration management
15. `logStreamer` - Log file access
16. `clearCache` - Cache management

    - **Package Management (6) - Requires CommandBox**

17. `packageInstaller` - Install packages
18. `packageList` - List packages
19. `packageSearch` - Search ForgeBox
20. `packageUpdate` - Update packages
21. `packageRemove` - Remove packages
22. `moduleManager` - ColdBox modules

    - **Development Workflow (6) - Requires CommandBox**

23. `codeFormatter` - Format CFML code
24. `codeLinter` - Code analysis
25. `testRunner` - Run tests
26. `generateDocs` - Generate documentation
27. `watchFiles` - File monitoring
28. `gitOperations` - Git integration

## Project Structure

```text
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

## 🚀 MCPCFC - ColdFusion MCP Server

-**Bring AI Superpowers to Your ColdFusion Applications**

The world's first Model Context Protocol (MCP) server for ColdFusion!

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![ColdFusion 2016+](https://img.shields.io/badge/ColdFusion-2016+-blue.svg)](https://www.adobe.com/products/coldfusion-family.html)
[![Lucee 5+](https://img.shields.io/badge/Lucee-5+-blue.svg)](https://www.lucee.org/)
[![Status: Working](https://img.shields.io/badge/Status-Working-brightgreen.svg)](https://github.com/revsmoke/mcpcfc)
[![Claude Desktop: Working](https://img.shields.io/badge/Claude%20Desktop-Working-brightgreen.svg)](https://github.com/revsmoke/mcpcfc)

[**Get Started →**](https://github.com/revsmoke/mcpcfc/blob/main/QUICK_START.md) | [**View Demo**](https://github.com/revsmoke/mcpcfc#demo) | [**Documentation**](https://github.com/revsmoke/mcpcfc/wiki)

---

> 🎉 **NEW: Version 1.0.3** - All 8 tools working perfectly with Claude Desktop! [See what's new →](https://github.com/revsmoke/mcpcfc/releases/tag/v1.0.3)

---

## 🌟 What is MCPCFC?

MCPCFC enables ColdFusion applications to serve as tool providers for AI assistants like Claude, ChatGPT, and other LLMs through the standardized Model Context Protocol.

**In simple terms**: Your ColdFusion apps can now talk to AI, and AI can use your CF tools!

### 🎯 Perfect For

- **Government Agencies** - Modernize legacy CF systems with AI capabilities
- **Enterprise Teams** - Add AI features without replacing existing infrastructure  
- **CF Developers** - Build the next generation of intelligent applications
- **Digital Transformation** - Bridge the gap between legacy and cutting-edge tech

---

## ⚡ Features at a Glance

### 🛠️ 8 Production-Ready Tools

✅ **PDF Operations** - Generate, extract text, and merge PDFs  
✅ **Email Automation** - Send HTML/plain emails, validate addresses  
✅ **Database Queries** - Natural language database interactions  
✅ **Extensible Design** - Easy to add your own tools  

### 🔧 Technical Excellence

✅ **JSON-RPC 2.0** Protocol - Industry-standard communication  
✅ **Real-time SSE** Support - Live updates and streaming  
✅ **Thread-Safe** Design - Production-ready architecture  
✅ **Claude Desktop** Ready - Works out of the box  

---

## 🚀 Quick Start

### Option 1: Browser Testing (5 minutes)

```bash
# Clone the repository
git clone https://github.com/revsmoke/mcpcfc.git

# Place in your ColdFusion webroot
# Navigate to http://localhost:8500/mcpcfc/
# Open the test client and start using AI tools!
```

### Option 2: Claude Desktop Integration (10 minutes)

1. **Install MCPCFC** in your CF webroot
2. **Make bridge executable**: `chmod +x cf-mcp-clean-bridge.sh`
3. **Add to Claude Desktop config**:

   ```json
   {
   "mcpServers": {
      "coldfusion-mcp": {
         "command": "/path/to/mcpcfc/cf-mcp-clean-bridge.sh"
      }
   }
   }
   ```

4. **Restart Claude Desktop** - Your CF tools are now available!

**[📚 Full Setup Guide →](https://github.com/revsmoke/mcpcfc/blob/main/QUICK_START.md)**

---

## 🎬 See It In Action

### Working Tools Demo

```text
🤖 Claude: "Generate a PDF invoice for customer John Doe"
📄 MCPCFC: *Creates PDF with CF's built-in PDF tools*

🤖 Claude: "Email it to john@example.com"  
📧 MCPCFC: *Sends email with the PDF attached*

🤖 Claude: "Show me all customers from the database"
🗄️ MCPCFC: *Queries your CF datasource and returns results*
```

### Live Example

```cfscript
// Your existing CF code
component {
    function generateReport(customerId) {
        // Your business logic here
    }
}

// Now accessible to AI assistants!
// Claude can call: "Generate a report for customer 123"
```

---

## 📊 Why MCPCFC?

| Challenge | MCPCFC Solution |
|-----------|----------------|
| Legacy CF systems can't use modern AI | ✅ Bridge CF to any AI assistant |
| Complex integration requirements | ✅ Drop-in solution, minimal setup |
| Security concerns | ✅ Built-in controls and query limits |
| Limited CF community tools | ✅ Open source and extensible |

---

## 🏗️ Architecture

```text
┌─────────────┐     ┌──────────────┐     ┌─────────────┐
│   Claude    │────▶│    MCPCFC    │────▶│ Your CF App │
│  Desktop    │◀────│  MCP Server  │◀────│   & Tools   │
└─────────────┘     └──────────────┘     └─────────────┘
       ↓                    ↓                     ↓
   AI Assistant      JSON-RPC 2.0          PDF, Email,
                    + SSE Transport          Database
```

### Directory Structure

```text
/mcpcfc/
├── Application.cfc           # Application configuration
├── /components/             # Core MCP components
├── /endpoints/              # HTTP/SSE endpoints
├── /tools/                  # Tool implementations
├── /client-examples/        # Test clients
├── cf-mcp-clean-bridge.sh   # Claude Desktop bridge
└── README.md               # You are here!
```

---

## 🔧 Available Tools

### Current Tools (v1.0.3)

| Tool | Description | Status |
|------|-------------|--------|
| **hello** | Simple greeting tool | ✅ Working |
| **queryDatabase** | Execute SELECT queries | ✅ Working |
| **generatePDF** | Create PDFs from HTML | ✅ Working |
| **extractPDFText** | Extract text from PDFs | ✅ Working |
| **mergePDFs** | Combine multiple PDFs | ✅ Working |
| **sendEmail** | Send plain text emails | ✅ Working |
| **sendHTMLEmail** | Send HTML emails | ✅ Working |
| **validateEmailAddress** | Validate email format | ✅ Working |

### Adding Custom Tools

```cfscript
// 1. Register in Application.cfc
application.toolRegistry.registerTool("myTool", {
    "description": "My custom tool",
    "inputSchema": {
        "type": "object",
        "properties": {
            "param1": {"type": "string"}
        }
    }
});

// 2. Implement in ToolHandler.cfc
case "myTool":
    return executeMyTool(arguments.args);
```

---

## 🛡️ Security & Configuration

### Database Security

- Only SELECT queries allowed by default
- Parameterized queries prevent SQL injection
- Configure datasources in your tool implementations

### Recommended Settings

- Add authentication layer
- Implement rate limiting  
- Use environment variables for sensitive data
- Enable audit logging

---

## 🤝 Contributing

We need your help to make MCPCFC even better!

### How to Contribute

1. **Star the repo** - Help others discover MCPCFC
2. **Report issues** - Found a bug? Let us know!
3. **Submit PRs** - Add features or fix issues
4. **Share your use cases** - Tell us how you're using it
5. **Write documentation** - Help others get started

**[Contributing Guide →](https://github.com/revsmoke/mcpcfc/blob/main/CONTRIBUTING.md)**

### Roadmap

- [ ] Authentication providers (OAuth, SAML)
- [ ] More tool templates (Excel, FTP, SOAP)
- [ ] WebSocket transport option
- [ ] Docker container support
- [ ] Tool marketplace

---

## 📚 Resources

- **[Quick Start Guide](https://github.com/revsmoke/mcpcfc/blob/main/QUICK_START.md)** - Get running in minutes
- **[API Documentation](https://github.com/revsmoke/mcpcfc/wiki/API-Documentation)** - Detailed API reference
- **[Troubleshooting](https://github.com/revsmoke/mcpcfc/wiki/Troubleshooting)** - Common issues and solutions
- **[Examples](https://github.com/revsmoke/mcpcfc/tree/main/examples)** - Sample implementations

### Community

- **[GitHub Discussions](https://github.com/revsmoke/mcpcfc/discussions)** - Ask questions, share ideas
- **[Issues](https://github.com/revsmoke/mcpcfc/issues)** - Report bugs or request features
- **Email**: <hello@mcpcfc.dev>

---

## 🙏 Acknowledgments

- **[Anthropic](https://anthropic.com)** - For creating the Model Context Protocol
- **The ColdFusion Community** - For keeping CF alive and thriving
- **Early Adopters** - For testing and providing feedback
- **You** - For being part of this journey!

---

## 📄 License

MCPCFC is open source software licensed under the [MIT License](https://github.com/revsmoke/mcpcfc/blob/main/LICENSE).

---

## 🚀 Ready to Get Started?

### [**Download MCPCFC**](https://github.com/revsmoke/mcpcfc/archive/refs/heads/main.zip) | [**View on GitHub**](https://github.com/revsmoke/mcpcfc) | [**Read the Docs**](https://github.com/revsmoke/mcpcfc/wiki)

### Show Your Support

If MCPCFC helps your project, please consider:

- ⭐ Starring the repository
- 📢 Sharing with your network  
- 🤝 Contributing to the project

---

## CFLOVE

-**Made with ❤️ for the ColdFusion community**

🌐 [mcpcfc.dev](https://mcpcfc.dev) | 📧 <hello@mcpcfc.dev>
