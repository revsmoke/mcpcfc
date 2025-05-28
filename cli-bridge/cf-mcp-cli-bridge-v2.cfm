<cfsetting enableCFOutputOnly="true" showDebugOutput="false">
<!---
    CF2023 MCP CLI Bridge v2
    Enhanced version using StdioTransport component
    Usage: cfml cf-mcp-cli-bridge-v2.cfm
--->

<cfscript>
try {
    // Initialize transport
    transport = createObject("component", "mcpcfc.cli-bridge.StdioTransport").init();
    transport.logDebug("CF2023 MCP CLI Bridge v2 starting...");
    
    // Initialize core components
    messageProcessor = createObject("component", "mcpcfc.components.JSONRPCProcessor").init();
    sessionManager = createObject("component", "mcpcfc.components.SessionManager").init();
    toolHandler = createObject("component", "mcpcfc.components.ToolHandler").init();
    toolRegistry = createObject("component", "mcpcfc.components.ToolRegistry").init();
    
    // Create unique session for this CLI instance
    sessionId = createUUID();
    sessionManager.createSession(sessionId);
    transport.logDebug("Session created: " & sessionId);
    
    // Register tools
    registerTools(toolRegistry);
    transport.logDebug("Tools registered: " & arrayToList(toolRegistry.listTools()));
    
    // Main message processing loop
    while (transport.isRunning()) {
        // Read message from stdin
        input = transport.readLine();
        
        // Skip empty lines
        if (len(trim(input)) == 0) {
            continue;
        }
        
        transport.logDebug("Received: " & input);
        
        try {
            // Parse JSON message
            message = deserializeJSON(input);
            
            // Process the message
            response = messageProcessor.processMessage(
                message = message,
                sessionId = sessionId,
                sessionManager = sessionManager,
                toolHandler = toolHandler,
                toolRegistry = toolRegistry
            );
            
            // Send response (only for non-notifications)
            if (!structIsEmpty(response)) {
                transport.writeResponse(response);
                transport.logDebug("Sent response for: " & (isDefined("message.method") ? message.method : "unknown"));
            } else {
                transport.logDebug("No response for notification: " & message.method);
            }
            
        } catch (any e) {
            // Handle parsing or processing errors
            transport.logError("Error processing message: " & e.message);
            
            // Send error response if message had an ID
            if (isDefined("message.id")) {
                errorResponse = structNew("ordered");
                errorResponse["jsonrpc"] = "2.0";
                errorResponse["id"] = message.id;
                errorResponse["error"] = structNew("ordered");
                errorResponse["error"]["code"] = -32603;
                errorResponse["error"]["message"] = "Internal error: " & e.message;
                
                transport.writeResponse(errorResponse);
            }
        }
    }
    
    transport.logDebug("CLI Bridge shutting down normally");
    transport.exit(0);
    
} catch (any e) {
    if (isDefined("transport")) {
        transport.logError("Fatal error: " & e.message & " - " & e.detail);
        transport.exit(1);
    } else {
        writeLog(text="Fatal error before transport init: " & e.message, type="error", file="cf-mcp-cli");
        createObject("java", "java.lang.System").exit(1);
    }
}

/**
 * Register all available tools
 */
function registerTools(toolRegistry) {
    // Register simple hello tool
    toolRegistry.registerTool("hello", {
        description: "A simple greeting tool",
        inputSchema: {
            type: "object",
            properties: {
                name: {
                    type: "string",
                    description: "The name to greet"
                }
            },
            required: ["name"]
        }
    });
    
    // Register database tool
    toolRegistry.registerTool("queryDatabase", {
        description: "Execute a database query (SELECT only for security)",
        inputSchema: {
            type: "object",
            properties: {
                query: {
                    type: "string",
                    description: "The SELECT query to execute"
                },
                datasource: {
                    type: "string",
                    description: "The datasource name",
                    default: "mcpcfc_ds"
                }
            },
            required: ["query"]
        }
    });
    
    // Register PDF tools component
    pdfTool = createObject("component", "mcpcfc.tools.PDFTool").init();
    toolRegistry.registerComponent(pdfTool);
    
    // Register Email tools component
    emailTool = createObject("component", "mcpcfc.tools.EmailTool").init();
    toolRegistry.registerComponent(emailTool);
    
    // Register REPL tools component (CF2023+ only)
    try {
        replTool = createObject("component", "mcpcfc.cli-tools.REPLTool").init();
        toolRegistry.registerComponent(replTool);
    } catch (any e) {
        // REPL tools not available in this environment
        transport.logDebug("REPL tools not available: " & e.message);
    }
    
    // Register Server Management tools component (CF2023+ only)
    try {
        serverTool = createObject("component", "mcpcfc.cli-tools.ServerManagementTool").init();
        toolRegistry.registerComponent(serverTool);
    } catch (any e) {
        // Server tools not available in this environment
        transport.logDebug("Server management tools not available: " & e.message);
    }
}
</cfscript>