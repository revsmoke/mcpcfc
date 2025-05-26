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