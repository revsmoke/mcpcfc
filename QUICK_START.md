# Quick Start Guide

## Prerequisites

- Adobe ColdFusion 2016+ or Lucee 5+
- A web server (IIS, Apache, or built-in)
- Modern web browser for testing

## Installation

### Option 1: Git Clone
```bash
cd /path/to/your/webroot
git clone https://github.com/revsmoke/mcpcfc.git
```

### Option 2: CommandBox (Coming Soon)
```bash
box install mcpcfc
```

## Basic Setup

1. **Navigate to the installation**
   ```
   http://localhost:8500/mcpcfc/
   ```

2. **Test the server**
   - Open the test client: `http://localhost:8500/mcpcfc/client-examples/test-client.cfm`
   - Click "Connect"
   - Click "Initialize"
   - Try the example tools!

## Creating Your First Tool

1. Create a new CFC in `/tools`:
```cfscript
component displayname="MyTool" {
    public struct function execute(required struct args) {
        return {
            "content": [{
                "type": "text",
                "text": "Hello from MyTool!"
            }]
        };
    }
}
```

2. Register it in `Application.cfc`:
```cfscript
application.toolRegistry.registerTool("myTool", {
    "description": "My custom tool",
    "inputSchema": {
        "type": "object",
        "properties": {}
    }
});
```

3. Restart your CF application and test!

## Connecting to Claude Desktop (Local)

Claude Desktop requires MCP servers to communicate via stdio (standard input/output), while your ColdFusion MCP server uses HTTP/SSE. A minimal bridge script handles this protocol translation.

### Quick Setup

1. **Make the bridge script executable**:
   ```bash
   chmod +x /Applications/ColdFusion2023/cfusion/wwwroot/mcpcfc/cf-mcp-clean-bridge.sh
   ```

2. **Add to your Claude Desktop config**:

   Open `~/Library/Application Support/Claude/claude_desktop_config.json` and add:

   ```json
   {
     "mcpServers": {
       "coldfusion-mcp": {
         "command": "/Applications/ColdFusion2023/cfusion/wwwroot/mcpcfc/cf-mcp-clean-bridge.sh"
       }
     }
   }
   ```

3. **Restart Claude Desktop**

4. **Verify the connection** - You should see your ColdFusion tools available in Claude!

### Troubleshooting

- **Check ColdFusion is running**: Visit http://localhost:8500/mcpcfc/
- **Check logs**: Look in `~/Library/Logs/Claude/mcp-server-coldfusion.log`
- **Test the bridge manually**: 
  ```bash
  echo '{"jsonrpc":"2.0","method":"initialize","params":{"protocolVersion":"2024-11-05","capabilities":{},"clientInfo":{"name":"test","version":"1.0.0"}},"id":1}' | ./cf-mcp-clean-bridge.sh
  ```
- **Common issues**:
  - If you see "permission denied", make sure the script is executable
  - If you see empty responses, check that ColdFusion output control is properly configured
  - If you see JSON parsing errors, ensure you're using cf-mcp-clean-bridge.sh (not the old versions)

### How it Works

- Your ColdFusion MCP server remains 100% ColdFusion (HTTP/SSE based)
- The bridge script (`cf-mcp-clean-bridge.sh`) uses curl to translate between:
  - Claude Desktop's stdio protocol (line-delimited JSON)
  - ColdFusion MCP's HTTP protocol
- All logging goes to stderr, only JSON responses go to stdout
- This is necessary because Claude Desktop can only spawn command-line processes

### Why a Bridge is Needed

1. **Claude Desktop limitation**: Only supports stdio communication
2. **ColdFusion architecture**: Designed for web applications, not stdio servers
3. **Protocol mismatch**: HTTP/SSE ↔ stdio requires translation

### Key Implementation Details

1. **ColdFusion Output Control**: The endpoints use `<cfsetting enableCFOutputOnly="true">` and `<cfcontent reset="yes">` to ensure clean JSON output
2. **JSON-RPC Field Ordering**: Uses `structNew("ordered")` to maintain proper field order (jsonrpc, id, result/error)
3. **Notification Handling**: Messages without an ID field are notifications and don't require a response
4. **No SSE for Claude Desktop**: The bridge uses simple HTTP POST requests to avoid response duplication

Your ColdFusion MCP server implementation remains pure ColdFusion - the bridge only handles protocol translation!

## Setting Up as a Remote MCP Server

To use your ColdFusion MCP server remotely with Claude via the API (MCP Connector):

### Prerequisites

1. **Public URL**: Your server must be accessible via HTTPS from the internet
2. **Security**: Implement authentication (see Security section below)
3. **SSL Certificate**: Required for production deployment

### Configuration Steps

1. **Deploy to a public server** with HTTPS enabled:
   ```
   https://your-domain.com/mcpcfc/endpoints/sse.cfm
   ```

2. **Add authentication** to your endpoints (recommended):
   ```cfscript
   // In endpoints/sse.cfm and messages.cfm
   if (!structKeyExists(url, "token") || url.token != application.mcpAuthToken) {
       writeOutput("Unauthorized");
       abort;
   }
   ```

3. **Use with Claude API** by including the MCP configuration:
   ```python
   import anthropic
   
   client = anthropic.Anthropic(
       api_key="your-api-key",
       default_headers={"anthropic-beta": "mcp-client-2025-04-04"}
   )
   
   response = client.messages.create(
       model="claude-3-5-sonnet-20241022",
       max_tokens=1024,
       messages=[{"role": "user", "content": "Generate a PDF report"}],
       mcp_servers=[{
           "type": "url",
           "url": "https://your-domain.com/mcpcfc/endpoints/sse.cfm",
           "name": "coldfusion-mcp",
           "authorization_token": "your-secure-token"
       }]
   )
   ```

### Security Considerations

1. **Authentication Token**: Generate a secure token in Application.cfc:
   ```cfscript
   application.mcpAuthToken = hash(createUUID() & now(), "SHA-256");
   ```

2. **HTTPS Only**: Never expose MCP endpoints over HTTP in production

3. **Rate Limiting**: Implement request throttling:
   ```cfscript
   // Example rate limiting
   if (application.requestCount[cgi.remote_addr] > 100) {
       writeOutput("Rate limit exceeded");
       abort;
   }
   ```

4. **IP Whitelisting** (optional):
   ```cfscript
   var allowedIPs = ["1.2.3.4", "5.6.7.8"];
   if (!arrayFind(allowedIPs, cgi.remote_addr)) {
       abort;
   }
   ```

### Testing Your Remote Server

1. **Verify HTTPS access**:
   ```bash
   curl https://your-domain.com/mcpcfc/endpoints/sse.cfm?token=your-token
   ```

2. **Test with Claude API** using the example code above

3. **Monitor logs** for any connection issues

### Limitations

- Currently only tool calls are supported via MCP Connector
- Not available on Amazon Bedrock or Google Vertex
- Requires public HTTPS endpoint

Your ColdFusion MCP server is now available as a remote service!

## Need Help?

- Check the [full documentation](README.md)
- Open an [issue](https://github.com/revsmoke/mcpcfc/issues)
- Join the discussion!

Happy coding! 🚀
