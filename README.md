# ColdFusion MCP Server

This is a Remote Model Context Protocol (MCP) server implementation using Adobe ColdFusion CFML/CFScript with Server-Sent Events (SSE) transport.

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
│   └── test-client.html     # Browser test client
└── README.md                # This file
```

## Getting Started

1. Ensure your ColdFusion server is running
2. Access the test client at: http://localhost:8500/mcpcfc/client-examples/test-client.html
3. Click "Connect" to establish SSE connection
4. Click "Initialize" to initialize the MCP session
5. Test the available tools

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
- Implement more tools for planned use cases
- Add Redis for distributed session storage
- Implement WebSocket transport for better performance