# MCPCFC - ColdFusion MCP Server Project Documentation

## 🎉 Project Status: FANTABULOUS! 

The world's first Model Context Protocol (MCP) server implementation for ColdFusion is now fully operational!

## Project Overview

This groundbreaking project enables ColdFusion applications to serve as tool providers for AI assistants like Claude, ChatGPT, and other LLMs through the standardized MCP protocol.

## Recent Fixes

1. Fixed incorrect link in index.cfm (test-client.html → test-client.cfm)
2. Fixed JSON-RPC version validation error in messages.cfm
3. Fixed SSE heartbeat integer overflow error in sse.cfm
4. Fixed component path resolution in messages.cfm and JSONRPCProcessor.cfc (now using fully qualified paths like `mcpcfc.components.ClassName`)
5. Database query tool now fully working with `mcpcfc_ds` datasource and `mcpcfc_db` MySQL database
6. Implemented stdio bridge for Claude Desktop integration (cf-mcp-clean-bridge.sh)
7. Fixed JSON-RPC field ordering using structNew("ordered") to ensure spec compliance
8. Added `<cfsetting enableCFOutputOnly="true">` and `<cfcontent reset="yes">` to eliminate extra output
9. Implemented proper notification handling (no response for notifications)
10. Added resources/list and prompts/list handlers to eliminate "method not found" errors

## Key Components

### Core Components (/components/)

- **JSONRPCProcessor.cfc**: Handles JSON-RPC 2.0 protocol message processing
- **SessionManager.cfc**: Thread-safe session state management
- **ToolHandler.cfc**: Executes registered tools based on method calls
- **ToolRegistry.cfc**: Manages tool registration and discovery

### Endpoints (/endpoints/)

- **sse.cfm**: Server-Sent Events endpoint for real-time communication
- **messages.cfm**: HTTP POST endpoint for message handling

### Tools (/tools/)

- **EmailTool.cfc**: Email-related functionality
- **PDFTool.cfc**: PDF generation and manipulation

### Application Configuration

- **Application.cfc**: Initializes the MCP server, message queue, and registers default tools

## Registered Tools

1. **hello**: Simple greeting tool (✅ TESTED & WORKING)
   - Input: name (string)
   - Output: Personalized greeting

2. **queryDatabase**: Database query execution (✅ TESTED & WORKING)
   - Input: query (string), datasource (string)
   - Output: Query results (SELECT only for security)
   - Use datasource: `mcpcfc_ds`
   - Database: `mcpcfc_db` (MySQL)
   - Available tables: `tools`, `tool_executions`, `example_data`

3. **generatePDF**: PDF generation from HTML (✅ TESTED & WORKING)
   - Input: html (string), filename (string)
   - Output: Success message with file location
   - Files saved to: `/temp/` directory

4. **extractPDFText**: Extract text from PDF files (✅ TESTED & WORKING)
   - Input: pdfPath (string) - filename or path (relative paths default to temp directory)
   - Output: Extracted text content from the PDF

5. **mergePDFs**: Merge multiple PDFs into one (✅ TESTED & WORKING)
   - Input: sourcePaths (array of strings), outputPath (string)
   - Output: Success message with merged file location
   - Note: Requires at least 2 PDFs to merge

6. **sendEmail**: Send plain text email (✅ TESTED & WORKING - Simulated Mode)
   - Input: to (string), subject (string), body (string)
   - Optional: from, cc, bcc (strings)
   - Output: Email sent confirmation
   - Note: Currently in simulation mode, uncomment `mailService.send()` for production

7. **sendHTMLEmail**: Send HTML formatted email (✅ TESTED & WORKING - Simulated Mode)
   - Input: to (string), subject (string), htmlBody (string)
   - Optional: textBody, from, cc, bcc (strings)
   - Output: Email sent confirmation
   - Note: Currently in simulation mode, uncomment `mailService.send()` for production

8. **validateEmailAddress**: Validate email format (✅ TESTED & WORKING)
   - Input: email (string)
   - Output: Validation result (true/false) and message

## Testing

- Test client available at: `/client-examples/test-client.cfm`
- Main entry point: `/index.cfm`

## Important URLs

- Local server: http://localhost:8500/mcpcfc/
- SSE endpoint: http://localhost:8500/mcpcfc/endpoints/sse.cfm?sessionId={sessionId}
- Messages endpoint: http://localhost:8500/mcpcfc/endpoints/messages.cfm?sessionId={sessionId}

## Development Notes

- ColdFusion 2023 environment
- Thread-safe implementation using Java LinkedBlockingQueue
- JSON-RPC 2.0 compliant
- MCP Protocol Version: 2024-11-05

## Achievement Unlocked! 🏆

- ✅ First ColdFusion MCP Server implementation
- ✅ JSON-RPC 2.0 protocol working
- ✅ SSE real-time communication established
- ✅ Database integration tested and operational
- ✅ All PDF tools implemented and working (generate, extract text, merge)
- ✅ Email tools implemented and tested (validation, plain text, HTML)
- ✅ Browser-based test client fully functional
- ✅ 8 tools registered and ALL tested successfully!
- ✅ Ready for AI assistant integration!
- ✅ Claude Desktop integration WORKING! - stdio bridge fixed with cf-mcp-clean-bridge.sh

## File Index

- `/Application.cfc`: Application initialization, tool registration
- `/index.cfm`: Welcome page with links to test client and documentation
- `/components/JSONRPCProcessor.cfc`: JSON-RPC message handling
- `/components/SessionManager.cfc`: Session management
- `/components/ToolHandler.cfc`: Tool execution logic
- `/components/ToolRegistry.cfc`: Tool registration system
- `/endpoints/sse.cfm`: SSE endpoint implementation
- `/endpoints/messages.cfm`: HTTP message endpoint
- `/client-examples/test-client.cfm`: Browser-based test client
- `/tools/EmailTool.cfc`: Email tool implementation
- `/tools/PDFTool.cfc`: PDF tool implementation
- `/cf-mcp-bridge.sh`: Stdio bridge script for Claude Desktop integration
- `/QUICK_START.md`: Quick start guide for Remote MCP and Claude Desktop setup

## CURRENT STATUS & ISSUES

### What's Working ✅
1. **Remote MCP Server (HTTP/SSE)**: FULLY FUNCTIONAL
   - Browser test client connects successfully
   - All 8 tools tested and working
   - JSON-RPC 2.0 protocol fully implemented
   - SSE real-time communication established
   - Can be used as Remote MCP with Claude API

2. **Local MCP Server (Claude Desktop)**: NOW WORKING! ✅
   - Fixed with `cf-mcp-clean-bridge.sh`
   - Successfully shows in Claude Desktop with all tools listed
   - Handles all required MCP methods: initialize, tools/list, resources/list, prompts/list
   - Proper notification handling (no response for notifications)

### Solution Found
1. **Initial Issue**: The server was returning responses both via HTTP POST response AND SSE, causing duplication
   - **Solution**: Updated simplified bridge (`cf-mcp-simple-bridge.sh`) that only uses HTTP POST/response

2. **JSON-RPC Field Ordering Issue**: ColdFusion structs don't maintain insertion order, causing JSON fields to be in wrong order
   - **Problem**: Claude Desktop's strict JSON-RPC parser requires specific field order (id before error, code before message)
   - **Solution**: Updated JSONRPCProcessor.cfc to use `structNew("ordered")` for all responses

3. **Extra Output Issue**: ColdFusion was outputting HTML error pages and whitespace after JSON responses
   - **Problem**: Default ColdFusion behavior outputs everything not inside CFML tags
   - **Solution**: Added `<cfsetting enableCFOutputOnly="true">` and `<cfcontent reset="yes">` to endpoints
   
4. **Testing**: Complete test sequence verified all MCP methods work correctly with clean JSON output

### Claude Desktop Configuration

#### Option 1: Traditional Bridge (Works with CF2016+)
To use with Claude Desktop, update your config file at `~/Library/Application Support/Claude/claude_desktop_config.json`:

```json
{
  "mcpServers": {
    "coldfusion-mcp": {
      "command": "/Applications/ColdFusion2023/cfusion/wwwroot/mcpcfc/cf-mcp-clean-bridge.sh"
    }
  }
}
```

#### Option 2: Native CF2023 CLI Bridge (Requires CF2023+) 🆕
For ColdFusion 2023 users, use the native CLI bridge for better performance:

```json
{
  "mcpServers": {
    "coldfusion-mcp-cf2023": {
      "command": "cfml",
      "args": [
        "/Applications/ColdFusion2023/cfusion/wwwroot/mcpcfc/cli-bridge/cf-mcp-cli-bridge-v2.cfm"
      ]
    }
  }
}
```

Then restart Claude Desktop. Your ColdFusion tools will be available!

### Bridge Scripts Available

1. **cf-mcp-clean-bridge.sh** (RECOMMENDED) ✅
   - Cleanest implementation with no extra output
   - Uses `enableCFOutputOnly` and `cfcontent reset` to ensure pure JSON
   - Logs debug info to stderr (not stdout)
   - This is what Claude Desktop config should use

2. **cf-mcp-simple-bridge.sh**
   - Simple implementation that works
   - No SSE subscription (avoids duplication)
   - macOS compatible

3. **cf-mcp-bridge-debug.sh** 
   - Debug version with extensive logging
   - Writes to `/tmp/cf-mcp-bridge-debug.log`

### Test Scripts

- **test-complete-sequence.sh**: Tests all MCP protocol methods
- **test-bridge-interactive.sh**: Interactive testing with named pipes
- **test-stdio-simple.sh**: Basic connectivity tests
- **test-jsonrpc-format.sh**: Validates JSON-RPC response formatting

## Lessons Learned - CRITICAL FOR FUTURE PROJECTS

### 1. ColdFusion Output Control is CRITICAL
- **Problem**: ColdFusion outputs EVERYTHING by default - whitespace, HTML error pages, debug info
- **Solution**: MUST use `<cfsetting enableCFOutputOnly="true">` (not enableCFOutput)
- **Also Required**: `<cfcontent type="application/json" reset="yes">` to clear any buffered content
- **Key Insight**: Even a single space or newline breaks JSON-RPC parsing

### 2. JSON-RPC Field Order MATTERS
- **Problem**: ColdFusion structs don't maintain insertion order
- **Solution**: Use `structNew("ordered")` for ALL JSON responses
- **Required Order**: `jsonrpc`, then `id`, then `result`/`error`
- **Error Objects**: Must have `code` before `message`
- **Why**: Claude Desktop's parser is EXTREMELY strict about JSON-RPC spec

### 3. Notifications Have Special Rules
- **Problem**: Sending responses to notifications causes parser errors
- **Key Rule**: Messages without an `id` field are notifications
- **Solution**: Return empty struct `{}` and output NOTHING for notifications
- **Example**: `notifications/initialized` must not receive any response

### 4. Bridge Script Design
- **Requirement**: stdout must contain ONLY valid JSON responses
- **Solution**: Log all debug info to stderr: `echo "debug" >&2`
- **Never**: Mix debug output with JSON responses on stdout
- **Handle**: Empty responses properly (don't output empty strings)

### 5. Implement ALL Methods (Even Optional Ones)
- **Problem**: Claude Desktop repeatedly calls `resources/list` and `prompts/list`
- **Solution**: Implement these methods even if they return empty arrays
- **Why**: Reduces error noise and improves stability

### 6. ColdFusion-Specific Gotchas
- **Attribute Names**: Use `enableCFOutputOnly` not `enableCFOutput`
- **Component Paths**: Must use fully qualified paths like `mcpcfc.components.ClassName`
- **Error Handling**: Use `cflog` for errors, never output to response stream
- **Java Integration**: `createObject("java", "java.util.concurrent.LinkedBlockingQueue")` works great

### 7. Testing Strategy
- **Start Simple**: Test each component in isolation first
- **Use Clean Bridge**: Create multiple bridge versions for debugging
- **Check Logs**: Both CF logs and Claude Desktop logs are essential
- **Manual Testing**: `echo '{"jsonrpc":"2.0","id":1,"method":"initialize"}' | ./bridge.sh`

### 8. What Made It Finally Work
1. Strict output control with proper CF settings
2. Ordered structs for JSON field ordering
3. Proper notification handling (no response)
4. Clean bridge script with stderr logging
5. Implementation of all expected methods

### 9. Architecture Insights
- **Protocol Mismatch**: ColdFusion is HTTP-based, Claude Desktop needs stdio
- **Bridge Solution**: Simple bash script with curl works perfectly
- **No SSE Needed**: For Claude Desktop, simple HTTP POST/response is sufficient
- **Session Management**: Each bridge instance maintains its own session

### 10. Debugging Approach
- **Isolate Issues**: Test CF server directly with curl first
- **Check Output**: Look for ANY extra characters in responses
- **Validate JSON**: Ensure strict JSON-RPC compliance
- **Read Error Logs**: ZodError messages indicate parser validation failures
