# MCPCFC — The World's First ColdFusion MCP Server

**Your ColdFusion apps can now talk to AI. And AI can use your CF tools.**

MCPCFC connects Adobe ColdFusion to Claude, ChatGPT, Cursor, VS Code, and any other AI assistant that supports the [Model Context Protocol](https://modelcontextprotocol.io). It turns your existing CFML code into AI-callable tools — no rewrite required.

Got a ColdFusion function that generates invoices? That's an MCP tool now. One that queries your proprietary database? Tool. One that kicks off an internal workflow? Tool. If ColdFusion can do it, AI can call it.

```
┌─────────────┐      ┌──────────────┐      ┌──────────────────┐
│   Claude /   │─────▶│    MCPCFC     │─────▶│  Your CF App     │
│   ChatGPT /  │◀─────│  MCP Server   │◀─────│  & Business Logic│
│   Cursor     │      └──────────────┘      └──────────────────┘
└─────────────┘       JSON-RPC 2.0          PDF, Email, DB,
                      + Stdio Bridge        Files, HTTP, ...
```

## Why this matters

Millions of lines of ColdFusion are still running in production — at government agencies, financial institutions, healthcare systems, and enterprises worldwide. That code works. But it's increasingly isolated from the AI-powered tools reshaping how people work.

MCPCFC bridges that gap. Instead of rewriting your CF business logic in Python or TypeScript, you wrap it as an MCP tool and let AI assistants call it directly. Your legacy codebase becomes an AI-connected asset overnight.

**Who this is for:**

- **Enterprise teams** sitting on years of CF business logic who want AI capabilities without a rewrite
- **Government agencies** modernizing legacy CF systems incrementally
- **CF developers** who want to build the next generation of intelligent applications on top of what already works
- **Digital transformation leads** looking for a low-risk path from legacy to cutting-edge

## What's included

MCPCFC ships with six proof-of-concept tools that demonstrate the pattern:

| Tool | What it does |
| --- | --- |
| `hello` | Simple greeting — useful for verifying connectivity |
| `fileOperations` | Sandboxed file I/O (`read`, `write`, `list`, `delete`, `exists`, `info`) |
| `httpRequest` | Outbound HTTP requests (blocks private/internal IPs) |
| `pdf` | Generate, extract text from, and merge PDFs using ColdFusion's built-in PDF engine |
| `queryDatabase` | Validated read-only SQL queries (`SELECT` only) |
| `sendEmail` | Send email via SendGrid (requires `SENDGRID_API_KEY`) |

These are intentionally simple. The real power is in adding your own tools — see [Adding a custom tool](#adding-a-custom-tool) below.

## Tested environment

- ✅ **macOS + Adobe ColdFusion 2025**
- ⚠️ Not yet tested on Windows/Linux or other CFML engines (Lucee, BoxLang, etc.)

## Quick start

### Option 1: Browser test client

1. Clone this repo into your ColdFusion web root (or symlink it).
2. Visit: `http://localhost:8500/mcpcfc/client-examples/test-client.cfm`
3. Click **Connect** → **List Tools** → **Call Hello Tool**.

### Option 2: Claude Desktop (local stdio)

Claude Desktop talks to local MCP servers via stdio. MCPCFC is HTTP-based, so it ships with a bridge script that translates between the two.

Edit `~/Library/Application Support/Claude/claude_desktop_config.json` (macOS):

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

Then **fully quit and relaunch** Claude Desktop.

### Option 3: Remote / Streamable HTTP

MCPCFC also supports direct HTTP connections from any MCP client at:

```
BASE_URL/endpoints/mcp.cfm
```

For copy-paste configs for Claude Code, ChatGPT, Codex, Cursor, VS Code, Zed, Kimi, and Antigravity, see **[CLIENTS.md](CLIENTS.md)**.

## Adding a custom tool

This is where MCPCFC becomes yours. Every tool is a ColdFusion Component (`.cfc`) that extends `AbstractTool`. The base class gives you input validation, structured result helpers, and automatic registration with the MCP protocol. You write the business logic; MCPCFC handles the plumbing.

### The pattern

Every tool follows three steps:

1. **Create a `.cfc` file** in `core/tools/` that extends `AbstractTool`
2. **Define the tool** in `init()` — name, description, and input schema
3. **Register it** by adding one line to `MCPServer.cfc`

That's it. Let's walk through a complete example.

### Example: Building a `WeatherTool`

Say you want to give your AI assistant the ability to check weather via an external API. Here's the complete tool:

**Step 1 — Create `core/tools/WeatherTool.cfc`:**

```cfscript
/**
 * WeatherTool.cfc
 * Returns current weather for a given city
 */
component extends="AbstractTool" output="false" {

    public function init() {
        // 1. Identity — how the tool appears in MCP
        setName("getWeather");
        setTitle("Get Weather");
        setDescription("Returns current weather conditions for a given city name.");

        // 2. Input schema — tells the AI what parameters to send
        var inputSchema = structNew("ordered");
        inputSchema["type"] = "object";
        inputSchema["properties"] = structNew("ordered");

        var citySchema = structNew("ordered");
        citySchema["type"] = "string";
        citySchema["description"] = "City name (e.g., 'Pittsburgh', 'New York')";
        inputSchema.properties["city"] = citySchema;

        inputSchema["required"] = ["city"];
        setInputSchema(inputSchema);

        return this;
    }

    public struct function execute(required struct toolArgs) {
        // Validate the required parameter exists
        validateRequired(arguments.toolArgs, ["city"]);

        var city = trim(arguments.toolArgs.city);
        logExecution("Weather requested", { city: city });

        try {
            // Call an external weather API
            var apiUrl = "https://wttr.in/#encodeForURL(city)#?format=j1";

            var httpService = new http(method="GET", url=apiUrl, timeout=10);
            var response = httpService.send().getPrefix();

            if (response.statusCode contains "200") {
                var data = deserializeJson(response.fileContent);
                var current = data.current_condition[1];

                var result = {
                    "city": city,
                    "temperature_f": current.temp_F,
                    "temperature_c": current.temp_C,
                    "condition": current.weatherDesc[1].value,
                    "humidity": current.humidity & "%",
                    "wind_mph": current.windspeedMiles
                };

                // Return structured JSON — the AI will interpret it
                return jsonResult(result);
            } else {
                return errorResult("Weather API returned status: #response.statusCode#");
            }
        } catch (any e) {
            return errorResult("Failed to fetch weather: #e.message#");
        }
    }
}
```

**Step 2 — Register it in `core/MCPServer.cfc`:**

Open `core/MCPServer.cfc` and add your tool class to the `toolClasses` array in the `registerDefaultTools()` method:

```cfscript
var toolClasses = [
    "core.tools.HelloTool",
    "core.tools.PDFTool",
    "core.tools.SendGridEmailTool",
    "core.tools.DatabaseTool",
    "core.tools.FileTool",
    "core.tools.HttpClientTool",
    "core.tools.WeatherTool"          // <-- add your tool here
];
```

**Step 3 — Restart and test:**

Restart your ColdFusion application (visit `restart-app.cfm` or restart the CF service), then relaunch your MCP client. Your new tool will appear in the tool list and the AI can call it immediately.

### What the base class gives you

`AbstractTool.cfc` provides helper methods so you can focus on business logic:

| Method | Purpose |
| --- | --- |
| `textResult(string)` | Return a plain text response |
| `jsonResult(data)` | Return structured JSON data |
| `errorResult(message)` | Return an error with `isError` flag |
| `imageResult(base64Data, mimeType)` | Return a base64-encoded image |
| `resourceResult(uri, text, mimeType)` | Return an embedded MCP resource |
| `validateRequired(args, paramArray)` | Throw if required params are missing |
| `validateTypes(args, typeMap)` | Validate parameter types (string, numeric, boolean, array, struct) |
| `getParam(args, name, default)` | Get a parameter with a fallback default |
| `logExecution(message, data)` | Log tool activity (if logger is configured) |

### Real-world tool ideas

Once you understand the pattern, think about what ColdFusion already does well at your organization:

- **Invoice generator** — wrap your existing `cfpdf` report logic
- **Customer lookup** — query your CRM database and return results to the AI
- **Document converter** — leverage CF's built-in Word/Excel/PDF capabilities
- **Email drafter** — compose and send through your existing mail infrastructure
- **Report runner** — execute stored procedures and return formatted results
- **File processor** — parse uploaded CSVs, transform data, write outputs
- **Legacy API wrapper** — expose SOAP services or internal REST endpoints to AI

Each of these is a single `.cfc` file and one line of registration.

## Smoke tests

### Stdio (recommended for Claude Desktop)

```bash
MCPCFC_URL="http://localhost:8500/mcpcfc" ./scripts/verify-stdio.sh
```

### Streamable HTTP (for remote clients)

```bash
MCPCFC_URL="http://localhost:8500/mcpcfc" ./scripts/verify-http.sh
```

## Configuration

Edit `config/settings.cfm` to customize:

- `protocolVersion` (default: `2025-06-18`)
- `defaultDatasource` (default: `mcpcfc_ds`)
- File sandbox paths and size limits
- CORS settings

### Database setup (optional)

The `queryDatabase` tool expects a ColdFusion datasource named `mcpcfc_ds`:

1. Configure the datasource in ColdFusion Administrator
2. Load the sample schema by visiting `database-setup.cfm` in your browser, or import `mcpcfc_db.sql` into MySQL/MariaDB

## Debugging

- **Claude Desktop MCP logs (macOS):** `~/Library/Logs/Claude/mcp-server-coldfusion-mcp.log`
- **Bridge debug mode:** set `MCPCFC_DEBUG=1` in the `env` block of your config
- **Self-signed HTTPS:** set `MCPCFC_INSECURE=1` if using untrusted local certs

## Security warning

MCPCFC is a powerful remote-control surface — it can access the filesystem, make HTTP requests, query databases, send email, and generate documents. **Do not expose it publicly without:**

- Authentication
- Tight CORS/origin restrictions
- Rate limiting
- Tool-by-tool authorization and sandboxing

## Project layout

```text
Application.cfc
bridge/
  cf-mcp-bridge.sh           # Stdio ⇄ HTTP bridge for Claude Desktop
client-examples/
  test-client.cfm             # Browser-based test interface
config/
  routes.cfm
  settings.cfm                # Server configuration
core/
  CapabilityManager.cfc
  JSONRPCHandler.cfc
  MCPServer.cfc                # Tool registration happens here
  TransportManager.cfc
  tools/
    AbstractTool.cfc           # Base class — extend this for custom tools
    DatabaseTool.cfc
    FileTool.cfc
    HelloTool.cfc              # Good reference for new tools
    HttpClientTool.cfc
    PDFTool.cfc
    SendGridEmailTool.cfc
endpoints/
  mcp.cfm                     # Unified MCP endpoint (JSON-RPC 2.0)
logging/
registry/
session/
scripts/
  verify-stdio.sh
  verify-http.sh
```

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

## License

MIT. See [LICENSE](LICENSE).

---

Built with ColdFusion 2025 by [@revsmoke](https://github.com/revsmoke). Contributions welcome.
