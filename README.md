# MCPCFC - ColdFusion MCP Server

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![ColdFusion 2016+](https://img.shields.io/badge/ColdFusion-2016+-blue.svg)](https://www.adobe.com/products/coldfusion-family.html)
[![Lucee 5+](https://img.shields.io/badge/Lucee-5+-blue.svg)](https://www.lucee.org/)

**The world's first Model Context Protocol (MCP) server implementation for ColdFusion!**

This project enables ColdFusion applications to serve as tool providers for AI assistants like Claude, ChatGPT, and other LLM applications through a standardized protocol.

## Features

- JSON-RPC 2.0 protocol implementation
- Server-Sent Events (SSE) for real-time communication
- Thread-safe session management
- Extensible tool registry
- Example tools:
  - Hello World tool
  - Database query tool

## Directory Structure

```
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
├── /client-examples/
│   └── test-client.cfm      # Browser test client
└── README.md                # This file
```

## Getting Started

**[📚 See the Quick Start Guide for detailed setup instructions](QUICK_START.md)**

1. Clone this repository: `git clone https://github.com/revsmoke/mcpcfc.git`
2. Place in your ColdFusion webroot
3. Navigate to `http://localhost:8500/mcpcfc/`
4. Test with the included client at: http://localhost:8500/mcpcfc/client-examples/test-client.cfm
5. Click "Connect" → "Initialize" → Test the tools!

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

1. Check ColdFusion logs for errors
2. Ensure Application.cfc is loaded (restart CF if needed)
3. Verify CORS headers are set correctly
4. Check browser console for JavaScript errors

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

**Made with ❤️ for the ColdFusion community**