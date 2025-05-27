# ColdFusion MCP SDK Roadmap

## Vision

Create the first official CFML/CFScript SDK for the Model Context Protocol, enabling ColdFusion developers to easily build MCP servers that integrate with AI applications.

## Current Implementation Status

The MCP server is now **FULLY OPERATIONAL** with the following achievements:

- ✅ JSON-RPC 2.0 message processing
- ✅ SSE transport for real-time communication
- ✅ Tool registration and execution
- ✅ Session management
- ✅ Browser-based test client
- ✅ **8 production-ready tools all tested and working**
- ✅ PDF generation, extraction, and merging
- ✅ Email sending (plain/HTML) and validation
- ✅ Database query execution
- ✅ Complete error handling and validation

## Core SDK Components

### 1. Base Classes

    - `MCPServer.cfc` - Abstract base class for all MCP servers
    - `MCPTransport.cfc` - Abstract transport layer
    - `MCPTool.cfc` - Base class for tool implementations
    - `MCPResource.cfc` - Base class for resource providers
    - `MCPPrompt.cfc` - Base class for prompt templates

### 2. Transport Implementations

    - `SSETransport.cfc` - Server-Sent Events (current implementation)
    - `WebSocketTransport.cfc` - WebSocket support
    - `HTTPTransport.cfc` - Simple HTTP polling
    - `StdioTransport.cfc` - Standard I/O for CLI tools

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

    - `DatabaseTool.cfc` - Enhanced DB operations ✅ (Basic implementation complete)
    - `FileTool.cfc` - File system access
    - `HTTPTool.cfc` - External API calls
    - `EmailTool.cfc` - Email operations ✅ (Fully implemented)
    - `PDFTool.cfc` - PDF generation/manipulation ✅ (Fully implemented)
    - `ExcelTool.cfc` - Spreadsheet operations

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

## Next Step Requests

- Please review these next step requests and add them to the Next Steps section:

Great question! Based on my testing, here are some enhancements that would make the queryDatabase tool even more useful:

### 🎯 High Priority Additions

#### 1. **Schema Explorer Tool**

    A dedicated tool like `getDatabaseSchema` that returns:
    - All tables with row counts
    - Column details (types, constraints, indexes)
    - Foreign key relationships
    - Views and stored procedures (if any)

This would eliminate the need for complex INFORMATION_SCHEMA queries.

#### 2. **Query Builder/Helper**

    A tool that helps construct common queries:

    ```javascript
    buildQuery({
    table: "example_data",
    select: ["name", "department", "AVG(salary) as avg_salary"],
    where: { is_active: 1 },
    groupBy: ["department"],
    orderBy: ["avg_salary DESC"],
    limit: 10
    })
    ```

#### 3. **Pagination Support**

    For large result sets:
    ```javascript
    queryDatabase({
    datasource: "mcpcfc_ds",
    query: "SELECT * FROM large_table",
    page: 1,
    pageSize: 100
    })
    ```

#### 4. **Multi-Query Execution**

    Execute multiple queries in one call:
    ```javascript
    queryDatabase({
    datasource: "mcpcfc_ds",
    queries: [
        "SELECT COUNT(*) as total FROM example_data",
        "SELECT department, COUNT(*) as cnt FROM example_data GROUP BY department"
    ]
    })
    ```

    ## 🔧 Nice-to-Have Features

#### 5. **Query Metadata**

    Return additional info with results:
    - Execution time
    - Rows affected/returned
    - Query plan (EXPLAIN output)
    - Memory usage

#### 6. **Export Capabilities**

    Options to format results as:
    - CSV
    - JSON (already have this)
    - Markdown table
    - SQL INSERT statements

#### 7. **Parameterized Queries**

    For safer dynamic queries:
    ```javascript
    queryDatabase({
    datasource: "mcpcfc_ds",
    query: "SELECT * FROM example_data WHERE department = ? AND salary > ?",
    params: ["Engineering", 80000]
    })
    ```

#### 8. **Query Validation**

Pre-flight check to validate SQL syntax before execution, with helpful error messages.

#### 9. **Common Query Templates**

    Pre-built queries for common tasks:
    - `getTableStats(tableName)` - row count, size, last modified
    - `findDuplicates(table, columns)` 
    - `getRecentChanges(table, dateColumn, days)`

#### 10. **Connection Pool Info**

    A tool to check database connection health:
    - Active connections
    - Database version
    - Available datasources
    - Connection limits

## 💡 Most Impactful Addition

If I had to pick **one** enhancement, I'd choose the **Schema Explorer Tool**. It would save significant time and make database exploration much more intuitive. Currently, I have to write complex INFORMATION_SCHEMA queries just to understand the database structure.

Would any of these align with your use cases? I'd be happy to elaborate on any of these suggestions or discuss other possibilities!

------

## Next Steps

1. **GitHub Repository** - Set up official repo ✅ ([https://github.com/revsmoke/mcpcfc](https://github.com/revsmoke/mcpcfc))
2. **Production Release** - v1.0.2 ready for deployment! 🎉
3. **Documentation Site** - Comprehensive guides for all 8 tools
4. **Example Servers** - Real-world implementations
5. **Community Feedback** - Share the success story
6. **Adobe Partnership** - Showcase working implementation
7. **ForgeBox Package** - Package the complete solution
8. **SDK Extraction** - Build reusable components from proven code
9. **Additional Tools** - Excel operations, file management, HTTP client

## Contributing

We need contributors for:

- Transport implementations
- Security providers
- Tool libraries
- Documentation
- Testing frameworks
- Example applications

This could truly democratize AI access for the ColdFusion community!
