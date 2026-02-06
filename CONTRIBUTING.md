# Contributing to MCPCFC

Thank you for your interest in contributing to MCPCFC — the world's first ColdFusion MCP Server! This is an early-stage project and contributions of all kinds are welcome, from bug reports and documentation improvements to new tools and feature implementations.

## Development Environment Setup

### Prerequisites

MCPCFC currently requires:
- **macOS** (Windows/Linux support not yet tested)
- **Adobe ColdFusion 2025** (Lucee, BoxLang, and other CFML engines not yet tested)
- **Git** for version control

### Getting Started

1. **Clone the repository:**
   ```bash
   git clone https://github.com/revsmoke/mcpcfc.git
   cd mcpcfc
   ```

2. **Install into your ColdFusion web root:**
   Either copy the entire project to your web root, or create a symlink:
   ```bash
   ln -s /path/to/mcpcfc /path/to/cf-web-root/mcpcfc
   ```

3. **Configure ColdFusion datasource (optional):**
   If you want to test the `queryDatabase` tool, create a datasource named `mcpcfc_ds` in ColdFusion Administrator, then visit `database-setup.cfm` to load the sample schema.

4. **Test the installation:**
   Visit `http://localhost:8500/mcpcfc/client-examples/test-client.cfm` and verify you can connect and list tools.

## Running Tests

MCPCFC includes two smoke test scripts to verify the server is working correctly:

### Stdio Test (for Claude Desktop integration)
```bash
MCPCFC_URL="http://localhost:8500/mcpcfc" ./scripts/verify-stdio.sh
```

### HTTP Test (for remote MCP clients)
```bash
MCPCFC_URL="http://localhost:8500/mcpcfc" ./scripts/verify-http.sh
```

Both scripts should complete without errors. If you encounter issues, check:
- ColdFusion server is running
- MCPCFC is accessible at the specified URL
- All required environment variables are set

## Code Style Guidelines

### CFML/CFScript Conventions

Follow these patterns when contributing CFML/CFScript code:

**JSON Key Ordering:**
Use `structNew("ordered")` to maintain consistent JSON key order:
```cfscript
var inputSchema = structNew("ordered");
inputSchema["type"] = "object";
inputSchema["properties"] = structNew("ordered");
```

**Component Inheritance:**
Use the `extends` pattern for tool creation:
```cfscript
component extends="AbstractTool" output="false" {
    // implementation
}
```

**Variable Declarations:**
Use `var` for local variables and prefer explicit scoping:
```cfscript
var city = trim(arguments.toolArgs.city);
var result = structNew("ordered");
```

**Error Handling:**
Wrap external calls in try/catch blocks and return structured errors:
```cfscript
try {
    // external operation
    return jsonResult(data);
} catch (any e) {
    return errorResult("Operation failed: #e.message#");
}
```

**Method Signatures:**
Be explicit about required parameters:
```cfscript
public struct function execute(required struct toolArgs) {
    validateRequired(arguments.toolArgs, ["requiredParam"]);
    // implementation
}
```

## Adding a Custom Tool

Every tool follows the same three-step pattern:

1. **Create a `.cfc` file** in `core/tools/` that extends `AbstractTool`
2. **Define the tool** in `init()` — set name, description, and input schema
3. **Register it** by adding the class name to the `toolClasses` array in `core/MCPServer.cfc`

### Tool Structure

```cfscript
component extends="AbstractTool" output="false" {
    
    public function init() {
        setName("toolName");
        setTitle("Tool Display Name");
        setDescription("What this tool does");
        
        // Define input schema
        var inputSchema = structNew("ordered");
        inputSchema["type"] = "object";
        inputSchema["properties"] = structNew("ordered");
        
        // Add parameter definitions here
        
        setInputSchema(inputSchema);
        return this;
    }
    
    public struct function execute(required struct toolArgs) {
        // Validate inputs
        validateRequired(arguments.toolArgs, ["param1", "param2"]);
        
        // Implement your logic here
        
        // Return structured result
        return jsonResult(yourData);
    }
}
```

See the existing tools in `core/tools/` for complete examples, especially `HelloTool.cfc` for a simple reference implementation.

## Pull Request Process

1. **Fork the repository** and create a feature branch:
   ```bash
   git checkout -b feature/your-feature-name
   ```

2. **Make your changes** following the code style guidelines above

3. **Test your changes:**
   - Run both smoke tests (`verify-stdio.sh` and `verify-http.sh`)
   - Test your changes in the browser client
   - If adding a new tool, verify it appears in tool listings and executes correctly

4. **Commit your changes:**
   ```bash
   git add .
   git commit -m "feat: add your feature description"
   ```

5. **Push and create a pull request:**
   ```bash
   git push origin feature/your-feature-name
   ```
   Then open a pull request against the `main` branch with:
   - Clear description of what you've changed
   - Why the change is needed
   - How to test the changes

### Commit Message Format

Follow conventional commits format:
- `feat:` for new features
- `fix:` for bug fixes
- `docs:` for documentation changes
- `refactor:` for code refactoring
- `test:` for adding/updating tests

## Reporting Bugs

Found a bug? Please help us improve MCPCFC by reporting it!

### Before Reporting

1. Check if the issue already exists in [GitHub Issues](https://github.com/revsmoke/mcpcfc/issues)
2. Try the latest version of the code
3. Run the smoke tests to isolate the problem

### Bug Report Template

Include the following information:

- **Environment:** macOS version, ColdFusion version, browser (if applicable)
- **Steps to reproduce:** Clear, numbered steps
- **Expected behavior:** What should happen
- **Actual behavior:** What actually happens
- **Error messages:** Any console errors or CF errors
- **Test results:** Output from `verify-stdio.sh` and `verify-http.sh`

## Requesting Features

We welcome feature requests! Please open an issue with:

- **Use case:** What problem does this solve?
- **Proposed solution:** How would you like it to work?
- **Alternatives considered:** Other approaches you've thought about
- **Additional context:** Screenshots, examples, related tools

## Areas We Need Help

As an early-stage project, we especially welcome contributions in these areas:

- **Testing on other platforms:** Windows, Linux compatibility
- **Other CFML engines:** Lucee, BoxLang compatibility testing
- **Documentation:** More examples, tutorials, troubleshooting guides
- **Tool development:** New tools that showcase CFML capabilities
- **Security hardening:** Authentication, authorization, input validation
- **Performance optimization:** Caching, connection pooling, request handling
- **Error handling:** Better error messages, recovery strategies

## Getting Help

- **Discussions:** Use [GitHub Discussions](https://github.com/revsmoke/mcpcfc/discussions) for questions
- **Real-time help:** Join our community channels (links coming soon)
- **Documentation:** Check the README and inline code comments

## Code of Conduct

Be respectful and constructive in all interactions. We're building something new together and every contribution — no matter how small — moves us forward.

---

Thank you for helping make ColdFusion a first-class citizen in the AI ecosystem! 🚀
