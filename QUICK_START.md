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
   - Open the test client: `http://localhost:8500/mcpcfc/client-examples/test-client.html`
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

## Connecting to Claude Desktop

1. Add to your Claude Desktop config:
```json
{
  "mcpServers": {
    "coldfusion": {
      "url": "http://localhost:8500/mcpcfc/endpoints/sse.cfm"
    }
  }
}
```

2. Restart Claude Desktop
3. Your ColdFusion tools are now available!

## Need Help?

- Check the [full documentation](README.md)
- Open an [issue](https://github.com/revsmoke/mcpcfc/issues)
- Join the discussion!

Happy coding! 🚀