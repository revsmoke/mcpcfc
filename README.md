# MCPCFC - ColdFusion MCP Server

**Bring AI Superpowers to Your ColdFusion Applications**

The world's first Model Context Protocol (MCP) server for ColdFusion!

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![ColdFusion 2025](https://img.shields.io/badge/ColdFusion-2025-blue.svg)](https://www.adobe.com/products/coldfusion-family.html)
[![Lucee 5+](https://img.shields.io/badge/Lucee-5+-blue.svg)](https://www.lucee.org/)
[![MCP Protocol](https://img.shields.io/badge/MCP-2025--11--25-green.svg)](https://modelcontextprotocol.io/)
[![Status: Working](https://img.shields.io/badge/Status-Working-brightgreen.svg)](https://github.com/revsmoke/mcpcfc)
[![Claude Desktop: Working](https://img.shields.io/badge/Claude%20Desktop-Working-brightgreen.svg)](https://github.com/revsmoke/mcpcfc)

[**Get Started →**](https://github.com/revsmoke/mcpcfc/blob/main/QUICK_START.md) | [**View Demo**](https://github.com/revsmoke/mcpcfc#demo) | [**Documentation**](https://github.com/revsmoke/mcpcfc/wiki)

---

> **Version 2.0** - Major refactor for MCP Protocol 2025-11-25 and ColdFusion 2025! [See what's new →](CHANGELOG.md)

---

## What is MCPCFC?

MCPCFC enables ColdFusion applications to serve as tool providers for AI assistants like Claude, ChatGPT, and other LLMs through the standardized Model Context Protocol.

**In simple terms**: Your ColdFusion apps can now talk to AI, and AI can use your CF tools!

### Perfect For

- **Government Agencies** - Modernize legacy CF systems with AI capabilities
- **Enterprise Teams** - Add AI features without replacing existing infrastructure
- **CF Developers** - Build the next generation of intelligent applications
- **Digital Transformation** - Bridge the gap between legacy and cutting-edge tech

---

## Features at a Glance

### Production-Ready Tools

- **PDF Operations** - Generate, extract text, and merge PDFs
- **Email Automation** - Send HTML/plain emails via SendGrid
- **Database Queries** - Safe, validated database interactions
- **File Operations** - Secure file system access
- **HTTP Client** - Make external API calls
- **Extensible Design** - Easy to add your own tools

### Technical Excellence

- **MCP Protocol 2025-11-25** - Latest protocol specification
- **JSON-RPC 2.0** - Industry-standard communication
- **Unified HTTP Endpoint** - Single `endpoints/mcp.cfm` for all communication
- **Thread-Safe Design** - Production-ready architecture
- **Claude Desktop Ready** - Works out of the box
- **ColdFusion 2025** - Optimized for latest CF version

---

## Quick Start

### Option 1: Browser Testing

```bash
# Clone the repository
git clone https://github.com/revsmoke/mcpcfc.git

# Place in your ColdFusion webroot
# Navigate to http://localhost:8500/mcpcfc/
# Open the test client and start using AI tools!
```

### Option 2: Claude Desktop Integration

1. **Install MCPCFC** in your CF webroot
2. **Make bridge executable**: `chmod +x bridge/cf-mcp-bridge.sh`
3. **Add to Claude Desktop config** (`~/Library/Application Support/Claude/claude_desktop_config.json`):

   ```json
   {
     "mcpServers": {
       "coldfusion-mcp": {
         "command": "/path/to/mcpcfc/bridge/cf-mcp-bridge.sh",
         "env": {
           "MCPCFC_URL": "https://your-cf-server.local"
         }
       }
     }
   }
   ```

4. **Restart Claude Desktop** - Your CF tools are now available!

**[Full Setup Guide →](https://github.com/revsmoke/mcpcfc/blob/main/QUICK_START.md)**

---

## See It In Action

### Working Tools Demo

```text
Claude: "Generate a PDF invoice for customer John Doe"
MCPCFC: *Creates PDF with CF's built-in PDF tools*

Claude: "Email it to john@example.com"
MCPCFC: *Sends email via SendGrid integration*

Claude: "Show me all customers from the database"
MCPCFC: *Queries your CF datasource and returns results*
```

### Live Example

```cfscript
// Your existing CF code
component extends="tools.AbstractTool" {
    function init() {
        variables.name = "generateReport";
        variables.description = "Generate a report for a customer";
        return this;
    }

    function execute(required struct args) {
        // Your business logic here
        return {"content": [{"type": "text", "text": "Report generated!"}]};
    }
}

// Now accessible to AI assistants!
// Claude can call: "Generate a report for customer 123"
```

---

## Why MCPCFC?

| Challenge | MCPCFC Solution |
|-----------|----------------|
| Legacy CF systems can't use modern AI | Bridge CF to any AI assistant |
| Complex integration requirements | Drop-in solution, minimal setup |
| Security concerns | Built-in validation and query limits |
| Limited CF community tools | Open source and extensible |

---

## Architecture

```text
┌─────────────┐     ┌──────────────┐     ┌─────────────┐
│   Claude    │────▶│    MCPCFC    │────▶│ Your CF App │
│  Desktop    │◀────│  MCP Server  │◀────│   & Tools   │
└─────────────┘     └──────────────┘     └─────────────┘
       ↓                    ↓                     ↓
   AI Assistant      JSON-RPC 2.0          PDF, Email,
                   HTTP Transport           Database
```

### Directory Structure

```text
/mcpcfc/
├── Application.cfc           # Application configuration
├── config/
│   ├── settings.cfm         # Server settings
│   └── routes.cfm           # Route configuration
├── core/
│   ├── MCPServer.cfc        # Main MCP server
│   ├── JSONRPCHandler.cfc   # Protocol handler
│   ├── CapabilityManager.cfc # Capability negotiation
│   └── TransportManager.cfc  # Transport layer
├── registry/
│   ├── ToolRegistry.cfc     # Tool registration
│   ├── ResourceRegistry.cfc # Resource registration
│   └── PromptRegistry.cfc   # Prompt registration
├── session/
│   ├── SessionManager.cfc   # Session management
│   └── SessionCleanup.cfc   # Session cleanup
├── tools/
│   ├── AbstractTool.cfc     # Base tool class
│   ├── HelloTool.cfc        # Example tool
│   ├── PDFTool.cfc          # PDF operations
│   ├── SendGridEmailTool.cfc # Email via SendGrid
│   ├── DatabaseTool.cfc     # Database queries
│   ├── FileTool.cfc         # File operations
│   └── HttpClientTool.cfc   # HTTP requests
├── validators/
│   ├── InputValidator.cfc   # Input validation
│   └── SQLValidator.cfc     # SQL safety validation
├── logging/
│   └── Logger.cfc           # Logging utilities
├── endpoints/
│   └── mcp.cfm              # Unified MCP endpoint
├── bridge/
│   └── cf-mcp-bridge.sh     # Claude Desktop bridge
├── client-examples/         # Test clients
└── README.md                # You are here!
```

---

## Available Tools

### Current Tools (v2.0)

| Tool | Description | Status |
|------|-------------|--------|
| **hello** | Simple greeting tool | Working |
| **queryDatabase** | Execute validated SELECT queries | Working |
| **pdf** | PDF operations (generate, extract, merge) via `action` parameter | Working |
| **sendEmail** | Send emails via SendGrid | Working |
| **fileOperations** | Sandboxed file operations (read, write, list, delete) via `action` parameter | Working |
| **httpRequest** | Make HTTP requests | Working |

### Adding Custom Tools

1. **Create a new tool class** extending `AbstractTool`:

```cfscript
// tools/MyCustomTool.cfc
component extends="tools.AbstractTool" {

    public function init() {
        variables.name = "myCustomTool";
        variables.description = "Does something useful";
        variables.inputSchema = {
            "type": "object",
            "properties": {
                "input": {"type": "string", "description": "Input value"}
            },
            "required": ["input"]
        };
        return this;
    }

    public struct function execute(required struct args) {
        // Your implementation
        return {
            "content": [{
                "type": "text",
                "text": "Result: " & arguments.args.input
            }]
        };
    }
}
```

2. **Register in Application.cfc**:

```cfscript
application.toolRegistry.registerTool(new tools.MyCustomTool());
```

---

## Security & Configuration

### Database Security

- Only SELECT queries allowed by default
- SQL validation prevents injection attacks
- Configure datasources in your tool implementations

### Input Validation

- All inputs validated before processing
- Type checking and sanitization built-in
- Configurable validation rules

### Recommended Settings

- Add authentication layer for production
- Implement rate limiting
- Use environment variables for sensitive data
- Enable audit logging

---

## Contributing

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

## Resources

- **[Quick Start Guide](https://github.com/revsmoke/mcpcfc/blob/main/QUICK_START.md)** - Get running in minutes
- **[API Documentation](https://github.com/revsmoke/mcpcfc/wiki/API-Documentation)** - Detailed API reference
- **[Troubleshooting](https://github.com/revsmoke/mcpcfc/wiki/Troubleshooting)** - Common issues and solutions
- **[Examples](https://github.com/revsmoke/mcpcfc/tree/main/examples)** - Sample implementations

### Community

- **[GitHub Discussions](https://github.com/revsmoke/mcpcfc/discussions)** - Ask questions, share ideas
- **[Issues](https://github.com/revsmoke/mcpcfc/issues)** - Report bugs or request features
- **Email**: hello@mcpcfc.dev

---

## Acknowledgments

- **[Anthropic](https://anthropic.com)** - For creating the Model Context Protocol
- **The ColdFusion Community** - For keeping CF alive and thriving
- **Early Adopters** - For testing and providing feedback
- **You** - For being part of this journey!

---

## License

MCPCFC is open source software licensed under the [MIT License](https://github.com/revsmoke/mcpcfc/blob/main/LICENSE).

---

## Ready to Get Started?

### [**Download MCPCFC**](https://github.com/revsmoke/mcpcfc/archive/refs/heads/main.zip) | [**View on GitHub**](https://github.com/revsmoke/mcpcfc) | [**Read the Docs**](https://github.com/revsmoke/mcpcfc/wiki)

### Show Your Support

If MCPCFC helps your project, please consider:

- Starring the repository
- Sharing with your network
- Contributing to the project

---

## CFLOVE

**Made with love for the ColdFusion community**

[mcpcfc.dev](https://mcpcfc.dev) | hello@mcpcfc.dev
