# MCPCFC - ColdFusion MCP Server Project Documentation

## Project Overview
This is the world's first Model Context Protocol (MCP) server implementation for ColdFusion, enabling ColdFusion applications to serve as tool providers for AI assistants.

## Recent Fixes
1. Fixed incorrect link in index.cfm (test-client.html → test-client.cfm)
2. Fixed JSON-RPC version validation error in messages.cfm
3. Fixed SSE heartbeat integer overflow error in sse.cfm
4. Fixed component path resolution in messages.cfm and JSONRPCProcessor.cfc (now using fully qualified paths like `mcpcfc.components.ClassName`)

## Key Components

### Core Components (/components/)
- **JSONRPCProcessor.cfc**: Handles JSON-RPC 2.0 protocol message processing
- **SessionManager.cfc**: Thread-safe session state management
- **ToolHandler.cfc**: Executes registered tools based on method calls
- **ToolRegistry.cfc**: Manages tool registration and discovery

### Endpoints (/endpoints/)
- **sse.cfm**: Server-Sent Events endpoint for real-time communication
- **messages.cfm**: HTTP POST endpoint for message handling

### Tools (/tools/)
- **EmailTool.cfc**: Email-related functionality
- **PDFTool.cfc**: PDF generation and manipulation

### Application Configuration
- **Application.cfc**: Initializes the MCP server, message queue, and registers default tools

## Registered Tools
1. **hello**: Simple greeting tool
   - Input: name (string)
   - Output: Personalized greeting

2. **queryDatabase**: Database query execution
   - Input: query (string), datasource (string)
   - Output: Query results (SELECT only for security)

## Testing
- Test client available at: `/client-examples/test-client.cfm`
- Main entry point: `/index.cfm`

## Important URLs
- Local server: http://localhost:8500/mcpcfc/
- SSE endpoint: http://localhost:8500/mcpcfc/endpoints/sse.cfm?sessionId={sessionId}
- Messages endpoint: http://localhost:8500/mcpcfc/endpoints/messages.cfm?sessionId={sessionId}

## Development Notes
- ColdFusion 2023 environment
- Thread-safe implementation using Java LinkedBlockingQueue
- JSON-RPC 2.0 compliant
- MCP Protocol Version: 2024-11-05

## File Index
- `/Application.cfc`: Application initialization, tool registration
- `/index.cfm`: Welcome page with links to test client and documentation
- `/components/JSONRPCProcessor.cfc`: JSON-RPC message handling
- `/components/SessionManager.cfc`: Session management
- `/components/ToolHandler.cfc`: Tool execution logic
- `/components/ToolRegistry.cfc`: Tool registration system
- `/endpoints/sse.cfm`: SSE endpoint implementation
- `/endpoints/messages.cfm`: HTTP message endpoint
- `/client-examples/test-client.cfm`: Browser-based test client
- `/tools/EmailTool.cfc`: Email tool implementation
- `/tools/PDFTool.cfc`: PDF tool implementation