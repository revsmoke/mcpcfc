# Quick Start Guide

## Prerequisites

- Adobe ColdFusion 2025 (or Lucee 5+)
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
   https://localhost:8443/mcpcfc/
   ```

2. **Test the server**
   - Open the test client: `https://localhost:8443/mcpcfc/client-examples/test-client.cfm`
   - Click "Connect"
   - Click "Initialize"
   - Try the example tools!

## Creating Your First Tool

1. Create a new CFC in `/tools` that extends `AbstractTool`:

    ```cfscript
    component extends="tools.AbstractTool" displayname="MyTool" {

        public function init() {
            variables.name = "myTool";
            variables.description = "My custom tool";
            variables.inputSchema = {
                "type": "object",
                "properties": {
                    "message": {"type": "string", "description": "A message to process"}
                },
                "required": ["message"]
            };
            return this;
        }

        public struct function execute(required struct args) {
            return {
                "content": [{
                    "type": "text",
                    "text": "Hello from MyTool! You said: " & arguments.args.message
                }]
            };
        }
    }
    ```

2. Register it in `Application.cfc`:

    ```cfscript
    // In onApplicationStart()
    application.toolRegistry.registerTool(new tools.MyTool());
    ```

3. Restart your CF application and test!

## Connecting to Claude Desktop (Local)

Claude Desktop requires local MCP servers to communicate via stdio (standard input/output), while MCPCFC uses HTTP. The bridge script (`bridge/cf-mcp-bridge.sh`) translates between the two — no external dependencies required (just `curl` and `bash`).

### Quick Setup

1. **Make the bridge script executable**:

   ```bash
   chmod +x /path/to/mcpcfc/bridge/cf-mcp-bridge.sh
   ```

   On macOS, also clear the quarantine flag if needed:

   ```bash
   xattr -d com.apple.quarantine /path/to/mcpcfc/bridge/cf-mcp-bridge.sh
   ```

2. **Add to your Claude Desktop config**:

   Open `~/Library/Application Support/Claude/claude_desktop_config.json` (macOS) or `%APPDATA%\Claude\claude_desktop_config.json` (Windows) and add:

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

   Replace the path and URL for your environment. The `MCPCFC_URL` env var tells the bridge where your ColdFusion server is running.

3. **Restart Claude Desktop** — fully quit and relaunch.

4. **Verify** — You should see the MCP server indicator in the input area. Click it to see your ColdFusion tools.

### Bridge Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `MCPCFC_URL` | `https://mcpcfc.local` | Base URL of your ColdFusion server |
| `MCPCFC_DEBUG` | `0` | Set to `1` for debug logging to stderr |
| `MCPCFC_TIMEOUT` | `60` | Request timeout in seconds |
| `MCPCFC_INSECURE` | `0` | Set to `1` to skip SSL verification (dev only) |

### Test the Bridge Manually

```bash
echo '{"jsonrpc":"2.0","method":"initialize","params":{"protocolVersion":"2025-11-25","capabilities":{},"clientInfo":{"name":"test","version":"1.0.0"}},"id":1}' | ./bridge/cf-mcp-bridge.sh
```

You should see a JSON response with `protocolVersion`, `capabilities`, and `serverInfo`.

### Troubleshooting

- **Bridge not starting**: Check `~/Library/Logs/Claude/mcp*.log` for errors
- **Permission denied**: Run `chmod +x bridge/cf-mcp-bridge.sh`
- **SSL errors**: Set `"MCPCFC_INSECURE": "1"` in the env block (dev only), or ensure your cert is trusted
- **Connection refused**: Verify ColdFusion is running — visit your server URL in a browser
- **Empty responses**: Check that ColdFusion output control is configured (`<cfsetting enableCFOutputOnly="true">`)
- **Debug mode**: Set `"MCPCFC_DEBUG": "1"` in the env block, then check `~/Library/Logs/Claude/mcp-server-coldfusion-mcp.log`

### How It Works

```text
Claude Desktop  ──stdio──▸  cf-mcp-bridge.sh  ──HTTP POST──▸  endpoints/mcp.cfm
   (JSON-RPC)                  (curl + bash)                   (ColdFusion)
```

- The bridge reads JSON-RPC requests from stdin, POSTs them to your ColdFusion endpoint via `curl`, and writes responses to stdout
- Notifications (no `id` field) produce no stdout output, as required by JSON-RPC
- All diagnostic logging goes to stderr only — stdout is reserved for protocol data
- Your ColdFusion server is 100% standard HTTP — the bridge is the only non-CF component
- No Node.js, Python, or other runtime dependencies — just `bash` and `curl`

## Setting Up as a Remote MCP Server

To use your ColdFusion MCP server remotely with Claude via the API (MCP Connector):

### Prerequisites for Remote MCP Server

1. **Public URL**: Your server must be accessible via HTTPS from the internet
2. **Security**: Implement authentication (see Security section below)
3. **SSL Certificate**: Required for production deployment

### Configuration Steps

1. **Deploy to a public server** with HTTPS enabled:

   ```text
   https://your-domain.com/mcpcfc/endpoints/mcp.cfm
   ```

2. **Add authentication** to your endpoint (recommended):

   ```cfscript
   // In endpoints/mcp.cfm
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
       model="claude-sonnet-4-20250514",
       max_tokens=1024,
       messages=[{"role": "user", "content": "Generate a PDF report"}],
       mcp_servers=[{
           "type": "url",
           "url": "https://your-domain.com/mcpcfc/endpoints/mcp.cfm",
           "name": "coldfusion-mcp",
           "authorization_token": "your-secure-token"
       }]
   )
   ```

### Security Considerations for Remote MCP Server

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
   curl https://your-domain.com/mcpcfc/endpoints/mcp.cfm?token=your-token
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

Happy coding!
