# Quick Start Guide - CF2023 Enhanced Edition

## Prerequisites

### For Basic Features (8 Original Tools)

- Adobe ColdFusion 2016+ or Lucee 5+
- A web server (IIS, Apache, or built-in)
- Modern web browser for testing
- MySQL database (for logging features)

### For Enhanced Features (28 Total Tools) 🆕

- Adobe ColdFusion 2023+
- CommandBox 6.0+ (for package/dev tools)
- Modern web browser for testing
- MySQL database (for logging features)

## Installation

### Option 1: Git Clone (Recommended for CF2023 Features)

```bash
cd /path/to/your/webroot
git clone https://github.com/revsmoke/mcpcfc.git
```

This gets you the enhanced CF2023 branch with all 28 tools!

### Option 2: CommandBox (Coming Soon)

```bash
box install mcpcfc
```

## Basic Setup

1. **Set up the database**
   - Create a MySQL database named `mcpcfc_db`
   - Configure datasource `mcpcfc_ds` in ColdFusion Administrator
   - Run the database setup: `http://localhost:8500/mcpcfc/database-setup.cfm`

2. **Navigate to the installation**

   ```
   http://localhost:8500/mcpcfc/
   ```

3. **Test the server**
   - Open the test client: `http://localhost:8500/mcpcfc/client-examples/test-client.cfm`
   - Click "Connect"
   - Click "Initialize"
   - Try the example tools!

4. **Monitor tool usage**
   - View the dashboard: `http://localhost:8500/mcpcfc/tool-dashboard.cfm`
   - Simple dashboard: `http://localhost:8500/mcpcfc/tool-dashboard-simple.cfm`

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

### Quick Setup for CF2023 Enhanced Edition

1. **Make the bridge script executable**:

   ```bash
   chmod +x /Applications/ColdFusion2023/cfusion/wwwroot/mcpcfc/cf-mcp-cf2023-cli.sh
   ```

2. **Add to your Claude Desktop config**:

   Open `~/Library/Application Support/Claude/claude_desktop_config.json` and add:

   ```json
   {
     "mcpServers": {
       "coldfusion-mcp": {
         "command": "/Applications/ColdFusion2023/cfusion/wwwroot/mcpcfc/cf-mcp-cf2023-cli.sh"
       }
     }
   }
   ```

3. **Restart Claude Desktop**

4. **Verify the connection** - You should see all 28 ColdFusion tools available in Claude!

### Available Tools

**Original 8 Tools:**

- `hello` - Simple greeting test
- `sendEmail` - Send plain text emails
- `sendHTMLEmail` - Send HTML formatted emails
- `validateEmailAddress` - Validate email format
- `queryDatabase` - Execute database queries
- `generatePDF` - Generate PDFs from HTML
- `extractPDFText` - Extract text from PDFs
- `mergePDFs` - Merge multiple PDFs

**REPL Integration (4 tools):**

- `executeCode` - Run CFML code in isolated context
- `evaluateExpression` - Quick expression evaluation
- `testSnippet` - Run code with test assertions
- `inspectVariable` - Debug variable contents

**Server Management (4 tools):**

- `serverStatus` - Get server information
- `configManager` - Manage server configuration
- `logStreamer` - Read and filter logs
- `clearCache` - Clear ColdFusion caches

**Package Management (6 tools)** - Requires CommandBox:

- `packageInstaller` - Install ForgeBox packages
- `packageList` - List installed packages
- `packageSearch` - Search ForgeBox
- `packageUpdate` - Update packages
- `packageRemove` - Uninstall packages
- `moduleManager` - Manage ColdBox modules

**Development Workflow (6 tools)** - Requires CommandBox:

- `codeFormatter` - Format CFML code
- `codeLinter` - Analyze code quality
- `testRunner` - Execute TestBox tests
- `generateDocs` - Create documentation
- `watchFiles` - Monitor file changes
- `gitOperations` - Git integration

### Troubleshooting

- **Check ColdFusion is running**: Visit <http://localhost:8500/mcpcfc/>
- **Check database**: Ensure `mcpcfc_ds` datasource is configured
- **Check logs**: Look in `~/Library/Logs/Claude/mcp-server-coldfusion.log`
- **View CF logs**: Use the log streamer tool or check ColdFusion logs directory
- **Test the bridge manually**:

    ```bash
    echo '{"jsonrpc":"2.0","method":"initialize","params":{"protocolVersion":"2024-11-05","capabilities":{},"clientInfo":{"name":"test","version":"1.0.0"}},"id":1}' | ./cf-mcp-cf2023-cli.sh
    ```

### CommandBox Setup

For package and dev tools to work:

```bash
# Install CommandBox (if not installed)
brew install commandbox

# Verify CommandBox version (must be 6.0+)
box version

# Initialize your project
cd /path/to/mcpcfc
box init
box install testbox --saveDev
```

## Security Notes

⚠️ **REPL Tools Security Warning**:

- The REPL tools execute arbitrary CFML code with enhanced security filtering
- Security measures include: pattern-based blocking, word boundary matching, reflection blocking
- Blocked operations: file system access, network operations, system commands, database queries
- **Use only in trusted development environments**
- Never expose REPL tools in production
- See `clitools/REPLTool.cfc` for the complete security implementation

## Monitoring and Dashboards

### Tool Execution Dashboard

- **Full Dashboard**: `http://localhost:8500/mcpcfc/tool-dashboard.cfm`
  - Filter by time period, tool name, or session
  - View tool performance statistics
  - Monitor success rates and execution times
  - Track recent executions with input preview

- **Simple Dashboard**: `http://localhost:8500/mcpcfc/tool-dashboard-simple.cfm`
  - Basic statistics and recent executions
  - Auto-refreshes every 30 seconds

### Log Management

- **View logs**: `http://localhost:8500/mcpcfc/tool-log-cleanup.cfm`
- Automatic log retention management
- Configure retention period in days

## Need Help?

- Check the [CF2023 documentation](README-CF2023.md)
- Check the [full documentation](README.md)
- Open an [issue](https://github.com/revsmoke/mcpcfc/issues)
- Join the discussion!

Happy coding with CF2023 enhancements! 🚀
