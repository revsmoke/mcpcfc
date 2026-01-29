# Contributing to MCPCFC

First off, thank you for considering contributing to MCPCFC - the world's first ColdFusion MCP server! It's people like you that will make this a great tool for the ColdFusion community.

## How Can I Contribute?

### Reporting Bugs

- **Ensure the bug was not already reported** by searching on GitHub under [Issues](https://github.com/revsmoke/mcpcfc/issues).
- If you're unable to find an open issue addressing the problem, [open a new one](https://github.com/revsmoke/mcpcfc/issues/new).

### Suggesting Enhancements

- Open a new issue with a clear title and detailed description.
- Explain why this enhancement would be useful to most MCPCFC users.

### Pull Requests

1. Fork the repo and create your branch from `main`.
2. If you've added code that should be tested, add tests.
3. Ensure your code follows the existing code style.
4. Make sure your code works with both Adobe ColdFusion 2025 and Lucee 5+.
5. Issue that pull request!

## Code Style

- Use CFScript where possible
- Follow existing naming conventions
- Comment your code, especially complex logic
- Keep functions focused and single-purpose

## Project Architecture (v2.0)

Understanding the project structure will help you contribute effectively:

```
/mcpcfc/
├── core/                    # Core MCP components
│   ├── MCPServer.cfc       # Main server orchestration
│   ├── JSONRPCHandler.cfc  # Protocol handling
│   ├── CapabilityManager.cfc
│   └── TransportManager.cfc
├── registry/                # Registration systems
│   ├── ToolRegistry.cfc    # Tool registration
│   ├── ResourceRegistry.cfc # Resource registration
│   └── PromptRegistry.cfc  # Prompt registration
├── session/                 # Session management
├── tools/                   # Tool implementations
├── validators/              # Input validation
├── logging/                 # Logging utilities
├── endpoints/               # HTTP endpoints
│   └── mcp.cfm             # Unified MCP endpoint
└── bridge/                  # Protocol bridges
```

## Adding New Tools

When adding a new tool:

1. **Create a new CFC** in the `/tools` directory that extends `AbstractTool`:

```cfscript
component extends="tools.AbstractTool" {

    public function init() {
        variables.name = "myNewTool";
        variables.description = "What this tool does";
        variables.inputSchema = {
            "type": "object",
            "properties": {
                "param1": {"type": "string", "description": "Parameter description"}
            },
            "required": ["param1"]
        };
        return this;
    }

    public struct function execute(required struct args) {
        // Implement your tool logic
        return {
            "content": [{
                "type": "text",
                "text": "Result of the tool"
            }]
        };
    }
}
```

2. **Register in Application.cfc**:

```cfscript
application.toolRegistry.registerTool(new tools.MyNewTool());
```

3. **Add tests** in `/tests` directory

4. **Document the tool** in the README

## Adding Resources

Resources follow a similar pattern using `ResourceRegistry`:

1. Create a resource class
2. Register via `application.resourceRegistry.registerResource()`
3. Implement `read()` method for resource content

## Adding Prompts

Prompts use `PromptRegistry`:

1. Create a prompt class
2. Register via `application.promptRegistry.registerPrompt()`
3. Implement `get()` method for prompt content

## Testing

- Test with Adobe ColdFusion 2025 (primary target)
- Test with Lucee 5+ if possible
- Include error cases in your testing
- Test with the included test client at `/client-examples/test-client.cfm`
- Test via Claude Desktop integration if applicable

## Validation

If your tool accepts user input:

1. Use `validators/InputValidator.cfc` for general validation
2. Use `validators/SQLValidator.cfc` if handling database queries
3. Never trust input - always validate and sanitize

## Community

- Be welcoming and inclusive
- Help others who are trying to contribute
- Share your use cases and success stories

Thank you for helping make ColdFusion part of the AI revolution!
