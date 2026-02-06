# Quick Start (Fork-and-Run)

This guide is written for someone **forking this repo on their own machine**.

## Tested environment

- ✅ **macOS + Adobe ColdFusion 2025**
- ⚠️ Not yet tested on Windows/Linux or other CFML engines (ex: Lucee)

## Prerequisites

- Adobe ColdFusion 2025 running locally
- Ability to place a folder in your ColdFusion **web root** (or create a mapping)
- `bash` + `curl` (for Claude Desktop bridge)
- Optional: Claude Desktop (macOS) for stdio transport testing

## 1) Fork + clone

Clone your fork into your ColdFusion web root.

Example (adjust the path for your setup):

```bash
cd /path/to/your/coldfusion/webroot
git clone https://github.com/<your-user>/<your-fork>.git mcpcfc
```

After this, you should be able to load:

- `http://localhost:8500/mcpcfc/`

> If your ColdFusion server isn’t on port 8500, use whatever base URL applies to your installation.

## 2) Confirm the MCP endpoint responds

Your endpoint should be reachable at:

- `http://localhost:8500/mcpcfc/endpoints/mcp.cfm`

It only accepts **POST** with `Content-Type: application/json`.

## 3) Test in the browser (recommended first)

Open the test client:

- `http://localhost:8500/mcpcfc/client-examples/test-client.cfm`

Then click:

1. **Connect**
2. **List Tools**
3. **Call Hello Tool**

If you see JSON-RPC responses in the log panel, your server is working.

## 4) Run the stdio smoke test (catches common MCP issues)

This repo includes a smoke/regression test that validates the stdio bridge and ensures responses keep the **strict JSON key casing** required by MCP clients:

```bash
cd /path/to/mcpcfc
MCPCFC_URL="http://localhost:8500/mcpcfc" ./scripts/verify-stdio.sh
```

## 5) Connect to Claude Desktop (local MCP server)

Claude Desktop talks to local MCP servers via **stdio**. MCPCFC is HTTP, so the bridge script translates stdio ⇄ HTTP.

1. Make the bridge executable:

   ```bash
   chmod +x bridge/cf-mcp-bridge.sh
   ```

   On macOS, you may also need:

   ```bash
   xattr -d com.apple.quarantine bridge/cf-mcp-bridge.sh
   ```

2. Add to Claude Desktop config:

   `~/Library/Application Support/Claude/claude_desktop_config.json`

   ```json
   {
     "mcpServers": {
       "coldfusion-mcp": {
         "command": "/absolute/path/to/mcpcfc/bridge/cf-mcp-bridge.sh",
         "env": {
           "MCPCFC_URL": "http://localhost:8500/mcpcfc"
         }
       }
     }
   }
   ```

3. **Fully quit and relaunch** Claude Desktop.

### Debugging Claude Desktop

- Logs live at: `~/Library/Logs/Claude/mcp-server-<name>.log`
  - Example: `~/Library/Logs/Claude/mcp-server-coldfusion-mcp.log`
- To enable bridge logging, add:
  - `"MCPCFC_DEBUG": "1"`

## Optional setup

### Database tool (`queryDatabase`)

`queryDatabase` expects a ColdFusion datasource named `mcpcfc_ds` (default; configurable).

1. Create/configure the datasource in ColdFusion Administrator.
2. Load sample tables/data:
   - visit `database-setup.cfm`, or
   - import `mcpcfc_db.sql` into MySQL/MariaDB

### SendGrid email tool (`sendEmail`)

To enable email sending, set `SENDGRID_API_KEY` in the environment where ColdFusion runs, then restart ColdFusion.

If it’s not set, the tool will return an error telling you it’s not configured.

## Restarting the app during development

- `restart-app.cfm`
- or hit any page with `?reload=1` to run `onApplicationStart()` again

## Security warning

This is a dev-focused MCP server that exposes powerful capabilities (filesystem access, outbound HTTP, database querying, email sending).

Do **not** expose it publicly without authentication + strong restrictions.

