# ColdFusion MCP SDK Roadmap

## Vision

Create the first official CFML/CFScript SDK for the Model Context Protocol, enabling ColdFusion developers to easily build MCP servers that integrate with AI applications.

## Current Implementation Status (v2.0)

The MCP server is now **FULLY OPERATIONAL** with MCP Protocol support (negotiates `2025-06-18` by default):

- ✅ JSON-RPC 2.0 message processing
- ✅ **Unified HTTP endpoint** (`endpoints/mcp.cfm`)
- ✅ Tool, Resource, and Prompt registries
- ✅ Session management with cleanup
- ✅ Browser-based test client
- ✅ **Production-ready tools**:
  - HelloTool - Basic greeting
  - PDFTool - Generation, extraction, merging
  - SendGridEmailTool - Email via SendGrid
  - DatabaseTool - Safe query execution
  - FileTool - File operations
  - HttpClientTool - HTTP requests
- ✅ Input validation and SQL safety checking
- ✅ Comprehensive error handling and logging
- ✅ ColdFusion 2025 optimized

### Protocol Notes

**SSE Transport**: This implementation uses a unified HTTP endpoint (`endpoints/mcp.cfm`). If you add other transports in the future, keep MCP clients’ strict JSON key casing in mind (ex: `result.tools`, JSON Schema `type/properties/required`).

## Core SDK Components

### 1. Base Classes

    - `MCPServer.cfc` - Abstract base class for all MCP servers
    - `MCPTransport.cfc` - Abstract transport layer
    - `MCPTool.cfc` - Base class for tool implementations
    - `MCPResource.cfc` - Base class for resource providers
    - `MCPPrompt.cfc` - Base class for prompt templates

### 2. Transport Implementations

    - `HTTPTransport.cfc` - HTTP endpoint (current implementation)
    - `WebSocketTransport.cfc` - WebSocket support (planned)
    - `StdioTransport.cfc` - Standard I/O for CLI tools (via bridge)
    - ~~`SSETransport.cfc`~~ - Deprecated in modern MCP clients

### 3. Protocol Components

    - `JSONRPCHandler.cfc` - Enhanced JSON-RPC 2.0 processor
    - `MCPProtocol.cfc` - Protocol version negotiation
    - `MessageValidator.cfc` - Schema validation
    - `ErrorHandler.cfc` - Standard error responses

### 4. Security Layer

    - `AuthenticationProvider.cfc` - OAuth, API keys, etc.
    - `RateLimiter.cfc` - Request throttling
    - `Sanitizer.cfc` - Input validation
    - `AuditLogger.cfc` - Security event logging

### 5. Developer Tools

    - `MCPTestClient.cfc` - Testing utilities
    - `MockTransport.cfc` - Unit testing support
    - `DebugLogger.cfc` - Development logging
    - `SchemaGenerator.cfc` - Auto-generate tool schemas

### 6. Common Tools Library

    - `DatabaseTool.cfc` - Database operations ✅ (Fully implemented with SQL validation)
    - `FileTool.cfc` - File system access ✅ (Fully implemented with sandboxing)
    - `HttpClientTool.cfc` - External API calls ✅ (Fully implemented)
    - `SendGridEmailTool.cfc` - Email via SendGrid ✅ (Fully implemented)
    - `PDFTool.cfc` - PDF generation/manipulation ✅ (Fully implemented)
    - `ExcelTool.cfc` - Spreadsheet operations (planned)

## Features That Leverage ColdFusion's Strengths

### 1. Native Database Integration

    ```cfscript
component extends="MCPTool" {
    function getCustomers(required string criteria) {
        return queryExecute(
            "SELECT * FROM customers
             WHERE status = :status",
            {status: arguments.criteria}
        );
    }
}
    ```

### 2. Built-in Security Functions

    ```cfscript
component extends="MCPServer" {
    function sanitizeInput(required string input) {
        return encodeForHTML(
            canonicalize(arguments.input, false, false)
        );
    }
}
    ```

### 3. Seamless Java Integration

    ```cfscript
component extends="MCPTransport" {
    function init() {
        variables.messageQueue = createObject(
            "java",
            "java.util.concurrent.LinkedBlockingQueue"
        ).init();
    }
}
    ```

### 4. Government/Enterprise Features

- FIPS compliance helpers
- Section 508 accessibility tools
- FedRAMP documentation generators
- Legacy system connectors

## Installation & Usage

### Via CommandBox (Future)

    ```bash
box install cf-mcp-sdk
    ```

### Basic Server Example

    ```cfscript
component extends="mcp.sdk.MCPServer" {
    function configure() {
        // Register tools
        this.registerTool(new tools.CustomerTool());
        this.registerTool(new tools.ReportTool());
        // Set transport
        this.setTransport(new mcp.sdk.transports.SSETransport());
        // Configure security
        this.requireAuthentication("oauth2");
    }
}
    ```

## Community Benefits

1. **Lower Barrier to Entry** - CF developers can use familiar syntax
2. **Leverage Existing Code** - Wrap existing CFCs as MCP tools
3. **Government Adoption** - Many agencies already use CF
4. **Enterprise Integration** - Connect legacy systems to AI
5. **Rapid Development** - CF's productivity advantages

## Lessons Learned from Implementation

### Technical Discoveries

1. **Component Path Resolution** - ColdFusion requires fully qualified paths for components in certain contexts
2. **JSON Handling** - Need to handle both string and numeric JSON values for protocol fields
3. **Variable Scoping** - Cannot use `var` declarations outside of functions
4. **Error Handling** - Detailed error messages are crucial for debugging MCP implementations
5. **Array Parameter Validation** - Special handling needed for array parameters in validation functions
6. **PDF Operations** - ColdFusion's built-in PDF capabilities integrate seamlessly with MCP
7. **Email Integration** - CF's mail service works perfectly for MCP email tools
8. **Path Handling** - Flexible path resolution improves tool usability

### Critical Claude Desktop Integration Lessons

1. **Output Control** - MUST use `<cfsetting enableCFOutputOnly="true">` and `<cfcontent reset="yes">`
2. **Struct Ordering** - Use `structNew("ordered")` for ALL JSON-RPC responses
3. **Notification Handling** - Messages without `id` must return NO response
4. **Bridge Design** - Stdio bridge must output ONLY JSON to stdout, debug to stderr
5. **Method Implementation** - Implement ALL methods including optional ones (resources/list, prompts/list)
6. **Parser Strictness** - Claude Desktop's JSON-RPC parser is EXTREMELY strict about spec compliance

### Architecture Insights

1. **Protocol Bridge** - Simple bash script with curl successfully bridges HTTP/SSE to stdio
2. **Session Management** - Each Claude Desktop connection maintains independent session
3. **No SSE Required** - For Claude Desktop, simple HTTP POST/response is sufficient
4. **Error Logging** - Use `cflog` instead of outputting errors to response stream

## Next Steps

### 🎉 Release Milestone

1. **GitHub Repository** - ✅ COMPLETE! Repository established at [https://github.com/revsmoke/mcpcfc](https://github.com/revsmoke/mcpcfc)
2. **First Release** - ✅ PUBLISHED! Version available at [https://github.com/revsmoke/mcpcfc/releases](https://github.com/revsmoke/mcpcfc/releases)

### 🎯 High Priority Database Tool Enhancements

1. **Schema Explorer Tool**
   - Dedicated `getDatabaseSchema` tool that returns:
     - All tables with row counts
     - Column details (types, constraints, indexes)
     - Foreign key relationships
     - Views and stored procedures (if any)
   - Eliminates need for complex INFORMATION_SCHEMA queries

2. **Query Builder/Helper**
   - Tool to construct common queries programmatically:

    buildQuery({
        table: "example_data",
        select: ["name", "department", "AVG(salary) as avg_salary"],
        where: { is_active: 1 },
        groupBy: ["department"],
        orderBy: ["avg_salary DESC"],
        limit: 10
    })

3. **Pagination Support**
   - Handle large result sets efficiently:

    queryDatabase({
        datasource: "mcpcfc_ds",
        query: "SELECT * FROM large_table",
        page: 1,
        pageSize: 100
   })

4. **Multi-Query Execution**

    - Execute multiple queries in one call:

    queryDatabase({
        datasource: "mcpcfc_ds",
        queries: [
        "SELECT COUNT(*) as total FROM example_data",
        "SELECT department, COUNT(*) as cnt FROM example_data GROUP BY department"
        ]
    })

   ### 📋 Additional Priorities

5. **Documentation Site** - Comprehensive guides for all 8 tools
6. **Example Servers** - Real-world implementations
7. **Community Feedback** - Share the success story
8. **Adobe Partnership** - Showcase working implementation
9. **ForgeBox Package** - Package the complete solution
10. **SDK Extraction** - Build reusable components from proven code

### 🔧 Nice-to-Have Database Features

- **Query Metadata**: Execution time, rows affected, query plan, memory usage
- **Export Capabilities**: CSV, Markdown table, SQL INSERT statements
- **Parameterized Queries**: Safer dynamic queries with parameter binding
- **Query Validation**: Pre-flight SQL syntax checking
- **Common Query Templates**: Pre-built queries for common tasks
- **Connection Pool Info**: Database health monitoring

## Contributing

We need contributors for:

- Transport implementations
- Security providers
- Tool libraries
- Documentation
- Testing frameworks
- Example applications

This could truly democratize AI access for the ColdFusion community!
