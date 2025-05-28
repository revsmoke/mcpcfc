# MCPCFC - CF2023 CLI Enhanced Edition 🚀

## Overview

This branch represents the next evolution of MCPCFC, leveraging Adobe ColdFusion 2023's CLI capabilities to provide:

- **Native stdio communication** (no bash bridges needed!)
- **REPL integration** for interactive code execution
- **Server management tools** for dynamic configuration
- **Package management** via CommandBox integration
- **Development workflow tools** for enhanced productivity

## Key Advantages

### 1. Native CFML Bridge
```bash
# Instead of: ./cf-mcp-clean-bridge.sh
# Now just: cfml cli-bridge/cf-mcp-cli-bridge-v2.cfm
```

### 2. Cross-Platform Support
- Works on Windows, Mac, and Linux without modification
- No shell scripting knowledge required
- Consistent behavior across platforms

### 3. Enhanced Performance
- Direct stdio communication
- No HTTP/curl overhead
- Faster message processing

### 4. New Powerful Tools
- Execute CFML code via REPL
- Manage server configuration
- Install packages on-demand
- Format and lint code
- Run tests automatically

## Requirements

- **Adobe ColdFusion 2023** or higher
- **CommandBox 5.0+** (for package management features)
- **Java 17+**  (required by ColdFusion 2023; CommandBox 5.0+ supports Java 11 but CF2023 mandates Java 17)

## 🔒 Security Considerations

**CRITICAL SECURITY WARNING**: The REPL tools (`executeCode`, `evaluateExpression`, `testSnippet`, `inspectVariable`) execute arbitrary CFML code using the `evaluate()` function. 

### Trust Boundary
- **TRUSTED ENVIRONMENTS ONLY**: Only use these tools in trusted development environments
- **TRUSTED USERS ONLY**: Only allow trusted developers/AI assistants to execute code
- **NO PRODUCTION USE**: Never expose REPL tools in production environments

### Security Measures Implemented
1. **Basic Whitelist Filtering**: Blocks known dangerous functions and patterns
2. **Thread Isolation**: Code executes in separate cfthread context
3. **Timeout Protection**: Code execution limited by timeout controls
4. **Error Containment**: Exceptions are caught and contained

### Blocked Operations
The security filter blocks code containing:
- File operations (`cffile`, `fileRead`, `fileWrite`, etc.)
- System commands (`cfexecute`, `createObject`)
- Network operations (`cfhttp`, `cfmail`)
- Database operations (`cfquery`, `cfstoredproc`)
- System access (`system.`, `runtime.`, Java reflection)
- Scope modifications (`application.`, `server.`, `session.`)

### Limitations
- **Not a complete sandbox**: Determined attackers may find bypasses
- **Pattern-based filtering**: May have false positives/negatives  
- **No resource limits**: Code can still consume CPU/memory within timeout
- **Variable scope access**: Code can access variables in current thread scope

### Recommendations for Production
1. **Disable REPL tools** in production builds
2. **Use ColdFusion sandbox security** for additional protection
3. **Network isolation** - run MCP server on isolated network
4. **User authentication** - implement proper access controls
5. **Audit logging** - log all code execution attempts
6. **Resource monitoring** - monitor CPU/memory usage

## Quick Start

1. **Clone this branch**:
   ```bash
   git clone -b cf2023-cli-enhancement https://github.com/revsmoke/mcpcfc.git
   ```

2. **Configure Claude Desktop**:
   
   Edit your Claude Desktop configuration file (usually located at `~/.config/claude-desktop/config.json` on macOS/Linux or `%APPDATA%\Claude\config.json` on Windows):

   ```json
   {
     "mcpServers": {
       "coldfusion-mcp-cf2023": {
         "command": "cfml",
         "args": ["/path/to/mcpcfc/cli-bridge/cf-mcp-cli-bridge-v2.cfm"]
       }
     }
   }
   ```
   
   > **Note**: This branch uses `cf-mcp-cli-bridge-v2.cfm` which includes enhanced features for CF2023. The original `cf-mcp-cli-bridge.cfm` is also available for compatibility.

3. **Start using enhanced tools!**

## Implementation Status

- [x] Phase 1: Native CFML Stdio Bridge ✅
- [x] Phase 2: REPL Integration Tool ✅
- [x] Phase 3: Server Management Tools ✅
- [x] Phase 4: Package Management Integration ✅
- [x] Phase 5: Development Workflow Tools ✅ (COMPLETED 2025-05-28)
- [ ] Phase 6: Advanced Database Tools

## REPL Tools Available (NEW!)

### 1. **executeCode**
Execute CFML code in an isolated context:
```json
{
  "name": "executeCode",
  "arguments": {
    "code": "x = 10 * 5; writeOutput('Result: ' & x); return x;",
    "returnOutput": true,
    "timeout": 30
  }
}
```

### 2. **evaluateExpression**
Quick expression evaluation:
```json
{
  "name": "evaluateExpression",
  "arguments": {
    "expression": "dateFormat(now(), 'yyyy-mm-dd')",
    "format": "string"
  }
}
```

### 3. **testSnippet**
Run code with assertions:
```json
{
  "name": "testSnippet",
  "arguments": {
    "code": "result = calculateTax(100, 0.08);",
    "assertions": [
      {"expression": "result == 8", "message": "Tax should be 8"}
    ],
    "measurePerformance": true
  }
}
```

### 4. **inspectVariable**
Debug variable contents:
```json
{
  "name": "inspectVariable",
  "arguments": {
    "setupCode": "user = {id: 1, name: 'John', roles: ['admin', 'user']};",
    "variableName": "user",
    "depth": 3
  }
}
```

## Server Management Tools (NEW!)

### 1. **serverStatus**
Get comprehensive server information:
```json
{
  "name": "serverStatus",
  "arguments": {
    "includeSystemInfo": true,
    "includeMemory": true,
    "includeDataSources": false,
    "includeMappings": false
  }
}
```

### 2. **configManager**
Read and manage server configuration:
```json
{
  "name": "configManager",
  "arguments": {
    "action": "get",
    "category": "runtime"
  }
}
```

### 3. **logStreamer**
Read and filter log files:
```json
{
  "name": "logStreamer",
  "arguments": {
    "logFile": "application.log",
    "lines": 50,
    "filter": "error",
    "fromTail": true
  }
}
```

### 4. **clearCache**
Clear various CF caches:
```json
{
  "name": "clearCache",
  "arguments": {
    "cacheType": "template",
    "path": "/specific/path"
  }
}
```

## Package Management Tools (NEW!)

### 1. **packageInstaller**
Install packages from ForgeBox:
```json
{
  "name": "packageInstaller",
  "arguments": {
    "packageName": "testbox@5.0.0",
    "saveDev": true,
    "force": false
  }
}
```

### 2. **packageList**
List installed packages:
```json
{
  "name": "packageList",
  "arguments": {
    "showDependencies": true,
    "format": "tree"
  }
}
```

### 3. **packageSearch**
Search ForgeBox repository:
```json
{
  "name": "packageSearch",
  "arguments": {
    "query": "coldbox modules",
    "type": "modules",
    "limit": 10
  }
}
```

### 4. **packageUpdate**
Update packages to latest versions:
```json
{
  "name": "packageUpdate",
  "arguments": {
    "packageName": "specific-package",
    "force": false
  }
}
```

### 5. **packageRemove**
Remove installed packages:
```json
{
  "name": "packageRemove",
  "arguments": {
    "packageName": "unwanted-package",
    "removeDependencies": true
  }
}
```

### 6. **moduleManager**
Manage ColdBox modules:
```json
{
  "name": "moduleManager",
  "arguments": {
    "action": "reload",
    "moduleName": "myModule"
  }
}
```

## Development Workflow Tools (NEW!)

> **Note**: These tools require CommandBox to be installed. Currently running in simulation mode until CommandBox is installed.

### 1. **codeFormatter**
Format CFML code using cfformat:
```json
{
  "name": "codeFormatter",
  "arguments": {
    "code": "component{function test(){var x=1;return x;}}",
    "settings": {
      "indentSize": 4,
      "insertSpaces": true,
      "maxLineLength": 120
    }
  }
}
```

### 2. **codeLinter**
Analyze code for issues using cflint:
```json
{
  "name": "codeLinter",
  "arguments": {
    "filePath": "./components/MyComponent.cfc",
    "rules": "strict",
    "format": "json",
    "includeWarnings": true
  }
}
```

### 3. **testRunner**
Run TestBox tests with coverage:
```json
{
  "name": "testRunner",
  "arguments": {
    "directory": "./tests",
    "bundles": "specs.unit.UserTest",
    "reporter": "json",
    "coverage": true
  }
}
```

### 4. **generateDocs**
Generate documentation from components:
```json
{
  "name": "generateDocs",
  "arguments": {
    "sourcePath": "./components",
    "outputPath": "./docs",
    "format": "html",
    "includePrivate": false
  }
}
```

### 5. **watchFiles**
Watch files for changes and run actions:
```json
{
  "name": "watchFiles",
  "arguments": {
    "paths": ["./components", "./tests"],
    "extensions": ["cfc", "cfm"],
    "action": "test",
    "debounce": 1000
  }
}
```

## Backward Compatibility

The main branch maintains support for ColdFusion 2016+ using the HTTP/SSE approach. This CF2023 branch is for users who want to leverage the latest CLI capabilities.

## Contributing

We welcome contributions! Please see our [implementation plan](CF2023-CLI-IMPLEMENTATION-PLAN.md) for detailed technical information.

## Version Strategy

- **v1.x (main branch)**: HTTP/SSE implementation for CF2016+
- **v2.x (this branch)**: CLI-enhanced version for CF2023+

---

*Elevating ColdFusion development with modern AI integration!*