<cfsetting enableCFOutputOnly="true" showDebugOutput="false">
<!---
    CF2023 MCP CLI Bridge
    This script handles stdio communication for the MCP protocol
    Usage: cfml cf-mcp-cli-bridge.cfm
--->

<cfscript>
// Initialize components
messageProcessor = createObject("component", "mcpcfc.components.JSONRPCProcessor").init();
sessionManager = createObject("component", "mcpcfc.components.SessionManager").init();
toolHandler = createObject("component", "mcpcfc.components.ToolHandler").init();
toolRegistry = createObject("component", "mcpcfc.components.ToolRegistry").init();

// Create unique session for this CLI instance
sessionId = createUUID();
sessionManager.createSession(sessionId);

// Initialize tools (same as Application.cfc)
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

// Register PDF tools
pdfTool = createObject("component", "mcpcfc.tools.PDFTool").init();
toolRegistry.registerComponent(pdfTool);

// Register Email tools
emailTool = createObject("component", "mcpcfc.tools.EmailTool").init();
toolRegistry.registerComponent(emailTool);

// Function to read from stdin
function readStdin() {
    try {
        // Create Java System.in reader
        systemIn = createObject("java", "java.lang.System").in;
        inputStreamReader = createObject("java", "java.io.InputStreamReader").init(systemIn);
        bufferedReader = createObject("java", "java.io.BufferedReader").init(inputStreamReader);
        
        // Read line from stdin
        line = bufferedReader.readLine();
        if (isNull(line)) {
            return "";
        }
        return line;
    } catch (any e) {
        logError("Error reading stdin: " & e.message);
        return "";
    }
}

// Function to write to stdout
function writeStdout(message) {
    // Use writeOutput to send to stdout
    writeOutput(message & chr(10));
    // Ensure output is flushed
    getPageContext().getOut().flush();
}

// Function to write to stderr for logging
function writeStderr(message) {
    createObject("java", "java.lang.System").err.println("[CF-MCP] " & message);
}

// Function to log errors
function logError(message) {
    writeStderr("ERROR: " & message);
    writeLog(text=message, type="error", file="cf-mcp-cli");
}

// Function to log debug info
function logDebug(message) {
    writeStderr("DEBUG: " & message);
    writeLog(text=message, type="information", file="cf-mcp-cli");
}

// Main processing loop
try {
    logDebug("CF MCP CLI Bridge started. Session ID: " & sessionId);
    
    // Process messages from stdin
    while (true) {
        // Read message from stdin
        input = readStdin();
        
        // Check for empty input (EOF)
        if (len(trim(input)) == 0) {
            logDebug("Empty input received, continuing...");
            continue;
        }
        
        logDebug("Received input: " & input);
        
        try {
            // Parse JSON
            message = deserializeJSON(input);
            
            // Process the message
            response = messageProcessor.processMessage(
                message = message,
                sessionId = sessionId,
                sessionManager = sessionManager,
                toolHandler = toolHandler,
                toolRegistry = toolRegistry
            );
            
            // Send response to stdout (only if there is one)
            if (!structIsEmpty(response)) {
                responseJson = serializeJSON(response);
                writeStdout(responseJson);
                logDebug("Sent response: " & responseJson);
            } else {
                logDebug("No response for notification");
            }
            
        } catch (any e) {
            // Send error response
            errorResponse = structNew("ordered");
            errorResponse["jsonrpc"] = "2.0";
            if (isDefined("message.id")) {
                errorResponse["id"] = message.id;
            }
            errorResponse["error"] = structNew("ordered");
            errorResponse["error"]["code"] = -32603;
            errorResponse["error"]["message"] = "Internal error: " & e.message;
            
            writeStdout(serializeJSON(errorResponse));
            logError("Message processing error: " & e.message);
        }
    }
    
} catch (any e) {
    logError("Fatal error in CLI bridge: " & e.message & " - " & e.detail);
    // Exit with error code
    createObject("java", "java.lang.System").exit(1);
}

// Clean exit
createObject("java", "java.lang.System").exit(0);
</cfscript>