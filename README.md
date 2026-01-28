# MCPCFC - ColdFusion MCP Server

-**Bring AI Superpowers to Your ColdFusion Applications**

The world's first Model Context Protocol (MCP) server for ColdFusion!

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![ColdFusion 2016+](https://img.shields.io/badge/ColdFusion-2016+-blue.svg)](https://www.adobe.com/products/coldfusion-family.html)
[![Lucee 5+](https://img.shields.io/badge/Lucee-5+-blue.svg)](https://www.lucee.org/)
[![Status: Working](https://img.shields.io/badge/Status-Working-brightgreen.svg)](https://github.com/revsmoke/mcpcfc)
[![Claude Desktop: Working](https://img.shields.io/badge/Claude%20Desktop-Working-brightgreen.svg)](https://github.com/revsmoke/mcpcfc)

[**Get Started →**](https://github.com/revsmoke/mcpcfc/blob/main/QUICK_START.md) | [**View Demo**](https://github.com/revsmoke/mcpcfc#demo) | [**Documentation**](https://github.com/revsmoke/mcpcfc/wiki)

---

> **NEW: Version 1.0.3** - All 8 tools working perfectly with Claude Desktop! [See what's new →](https://github.com/revsmoke/mcpcfc/releases/tag/v1.0.3)

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

### 8 Production-Ready Tools

- **PDF Operations** - Generate, extract text, and merge PDFs  
- **Email Automation** - Send HTML/plain emails, validate addresses  
- **Database Queries** - Natural language database interactions  
- **Extensible Design** - Easy to add your own tools  

### Technical Excellence

- **JSON-RPC 2.0** Protocol - Industry-standard communication  
- **Real-time SSE** Support - Live updates and streaming  
- **Thread-Safe** Design - Production-ready architecture  
- **Claude Desktop** Ready - Works out of the box  

---

## Quick Start

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

**[Full Setup Guide →](https://github.com/revsmoke/mcpcfc/blob/main/QUICK_START.md)**

---

## See It In Action

### Working Tools Demo

```text
Claude: "Generate a PDF invoice for customer John Doe"
MCPCFC: *Creates PDF with CF's built-in PDF tools*

Claude: "Email it to john@example.com"  
MCPCFC: *Sends email with the PDF attached*

Claude: "Show me all customers from the database"
MCPCFC: *Queries your CF datasource and returns results*
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

## Why MCPCFC?

| Challenge | MCPCFC Solution |
|-----------|----------------|
| Legacy CF systems can't use modern AI | Bridge CF to any AI assistant |
| Complex integration requirements | Drop-in solution, minimal setup |
| Security concerns | Built-in controls and query limits |
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

## Available Tools

### Current Tools (v1.0.3)

| Tool | Description | Status |
|------|-------------|--------|
| **hello** | Simple greeting tool | Working |
| **queryDatabase** | Execute SELECT queries | Working |
| **generatePDF** | Create PDFs from HTML | Working |
| **extractPDFText** | Extract text from PDFs | Working |
| **mergePDFs** | Combine multiple PDFs | Working |
| **sendEmail** | Send plain text emails | Working |
| **sendHTMLEmail** | Send HTML emails | Working |
| **validateEmailAddress** | Validate email format | Working |

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

## Security & Configuration

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
- **Email**: <hello@mcpcfc.dev>

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

-**Made with love for the ColdFusion community**

[mcpcfc.dev](https://mcpcfc.dev) | <hello@mcpcfc.dev>
