# MCPCFC - ColdFusion MCP Server

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![ColdFusion 2016+](https://img.shields.io/badge/ColdFusion-2016+-blue.svg)](https://www.adobe.com/products/coldfusion-family.html)
[![Lucee 5+](https://img.shields.io/badge/Lucee-5+-blue.svg)](https://www.lucee.org/)
[![Status: Working](https://img.shields.io/badge/Status-Working-brightgreen.svg)](https://github.com/revsmoke/mcpcfc)
[![Claude Desktop: Working](https://img.shields.io/badge/Claude%20Desktop-Working-brightgreen.svg)](https://github.com/revsmoke/mcpcfc)

**The world's first Model Context Protocol (MCP) server implementation for ColdFusion!**

This project enables ColdFusion applications to serve as tool providers for AI assistants like Claude, ChatGPT, and other LLM applications through a standardized protocol.

## 🎉 What's New

- **v1.0.3** - Claude Desktop integration FULLY WORKING! All 8 tools tested and confirmed! 🚀
- **Claude Desktop Support** - Connect your ColdFusion tools directly to Claude Desktop
- **v1.0.2** - Full implementation of PDF and Email tools!
- **All 8 Tools Tested** - Every tool confirmed working perfectly in BOTH browser AND Claude Desktop!
- **PDF Tools** - Generate, extract text, and merge PDFs
- **Email Tools** - Send plain/HTML emails and validate addresses
- **100% Feature Complete** - Ready for production use!

## Features

- JSON-RPC 2.0 protocol implementation
- Server-Sent Events (SSE) for real-time communication
- Thread-safe session management
- Extensible tool registry
- **Claude Desktop Integration** via stdio bridge
- **Remote MCP Support** via HTTP/SSE
- **8 Production-Ready Tools**:
  - ✅ Hello World tool
  - ✅ Database query tool (MySQL/SQL Server/etc)
  - ✅ PDF generation from HTML
  - ✅ PDF text extraction
  - ✅ PDF merging
  - ✅ Email sending (plain text)
  - ✅ Email sending (HTML with attachments)
  - ✅ Email address validation

## Directory Structure

```text
/mcpcfc/
├── Application.cfc           # Application configuration
├── /components/
│   ├── JSONRPCProcessor.cfc  # JSON-RPC message processing
│   ├── SessionManager.cfc    # Session state management
│   ├── ToolHandler.cfc       # Tool execution handler
│   └── ToolRegistry.cfc      # Tool registration/management
├── /endpoints/
│   ├── sse.cfm              # SSE endpoint
│   └── messages.cfm         # HTTP POST endpoint
├── /tools/
│   ├── PDFTool.cfc          # PDF operations (generate/extract/merge)
│   └── EmailTool.cfc        # Email operations (send/validate)
├── /client-examples/
│   └── test-client.cfm      # Browser test client
├── /temp/                   # PDF generation output directory
├── cf-mcp-clean-bridge.sh   # Claude Desktop stdio bridge
└── README.md                # This file
```

## Getting Started

**[📚 See the Quick Start Guide for detailed setup instructions](QUICK_START.md)**

### Quick Test (Browser)
1. Clone this repository: `git clone https://github.com/revsmoke/mcpcfc.git`
2. Place in your ColdFusion webroot
3. Navigate to `http://localhost:8500/mcpcfc/`
4. Test with the included client at: <http://localhost:8500/mcpcfc/client-examples/test-client.cfm>
5. Click "Connect" → "Initialize" → Test the tools!

### Claude Desktop Integration
1. Make the bridge script executable: `chmod +x cf-mcp-clean-bridge.sh`
2. Add to your Claude Desktop config:
   ```json
   {
     "mcpServers": {
       "coldfusion-mcp": {
         "command": "/path/to/mcpcfc/cf-mcp-clean-bridge.sh"
       }
     }
   }
   ```
3. Restart Claude Desktop and your ColdFusion tools will be available!

## Adding New Tools

To add a new tool, register it in Application.cfc:

```cfscript
application.toolRegistry.registerTool("myTool", {
    "description": "My custom tool",
    "inputSchema": {
        "type": "object",
        "properties": {
            "param1": {"type": "string"}
        }
    }
});
```

Then implement the handler in ToolHandler.cfc:

```cfscript
case "myTool":
    return executeMyTool(arguments.args);
```

## Configuration

### Database Configuration

Update the datasource names in your tool implementations to match your ColdFusion datasources.

### Security

- Only SELECT queries are allowed by default
- Add authentication/authorization as needed
- Implement rate limiting for production

## API Endpoints

- **SSE Endpoint**: `/mcpcfc/endpoints/sse.cfm?sessionId={sessionId}`
- **Message Endpoint**: `/mcpcfc/endpoints/messages.cfm?sessionId={sessionId}`

## Protocol Support

- MCP Protocol Version: 2024-11-05
- JSON-RPC Version: 2.0
- Transport: SSE + HTTP POST

## Troubleshooting

### Common Issues and Solutions

1. **JSON-RPC Version Error**
   - **Error**: "Invalid JSON-RPC version: missing"
   - **Solution**: The server now handles both string and numeric JSON-RPC versions. Fixed in messages.cfm.

2. **Component Not Found Errors**
   - **Error**: "Could not find the ColdFusion component or interface"
   - **Solution**: Components must use fully qualified paths (e.g., `mcpcfc.components.ClassName`)

3. **SSE Connection Issues**
   - Check that SSE endpoint is accessible at `/mcpcfc/endpoints/sse.cfm`
   - Verify session ID is being passed correctly
   - Check for heartbeat messages in the browser console

4. **Claude Desktop Integration Issues**
   - **Error**: "Server transport closed unexpectedly"
   - **Solution**: Make sure you're using cf-mcp-clean-bridge.sh and it's executable
   - **Error**: JSON parsing errors
   - **Solution**: Ensure ColdFusion output control is properly configured (enableCFOutputOnly="true")
   - Check logs at `~/Library/Logs/Claude/mcp-server-coldfusion.log`

5. **General Debugging**
   - Check ColdFusion logs for errors
   - Ensure Application.cfc is loaded (restart CF if needed)
   - Verify CORS headers are set correctly
   - Check browser console for JavaScript errors
   - Add `?debug=1` to messages.cfm URL for detailed logging

## Next Steps

- Add authentication mechanism
- Implement more tools for your use cases
- Add Redis for distributed session storage
- Implement WebSocket transport for better performance

## Contributing

We welcome contributions! Please see our [Contributing Guide](CONTRIBUTING.md) for details.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Acknowledgments

- Thanks to Anthropic for creating the Model Context Protocol
- The ColdFusion community for keeping the platform alive and thriving
- All contributors who help make this project better

## Links

- [GitHub Repository](https://github.com/revsmoke/mcpcfc)
- [Report Issues](https://github.com/revsmoke/mcpcfc/issues)
- [Model Context Protocol Docs](https://modelcontextprotocol.io)

---

## CFLOVE

**Made with ❤️ for the ColdFusion community!**
