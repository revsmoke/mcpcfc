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
# Now just: cfml cf-mcp-cli-bridge.cfm
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
- **Java 11+**

## Quick Start

1. **Clone this branch**:
   ```bash
   git clone -b cf2023-cli-enhancement https://github.com/revsmoke/mcpcfc.git
   ```

2. **Configure Claude Desktop**:
   ```json
   {
     "mcpServers": {
       "coldfusion-mcp-cf2023": {
         "command": "cfml",
         "args": ["/path/to/mcpcfc/cli-bridge/cf-mcp-cli-bridge.cfm"]
       }
     }
   }
   ```

3. **Start using enhanced tools!**

## Implementation Status

- [x] Phase 1: Native CFML Stdio Bridge ✅
- [x] Phase 2: REPL Integration Tool ✅
- [x] Phase 3: Server Management Tools ✅
- [ ] Phase 4: Package Management Integration
- [ ] Phase 5: Development Workflow Tools
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

## Backward Compatibility

The main branch maintains support for ColdFusion 2016+ using the HTTP/SSE approach. This CF2023 branch is for users who want to leverage the latest CLI capabilities.

## Contributing

We welcome contributions! Please see our [implementation plan](CF2023-CLI-IMPLEMENTATION-PLAN.md) for detailed technical information.

## Version Strategy

- **v1.x (main branch)**: HTTP/SSE implementation for CF2016+
- **v2.x (this branch)**: CLI-enhanced version for CF2023+

---

*Elevating ColdFusion development with modern AI integration!*