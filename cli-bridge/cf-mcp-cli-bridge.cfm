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

// Initialize stdin reader once for reuse - prevents performance issues and blocking
try {
    // Create a single BufferedReader for the process lifetime with UTF-8 encoding
    systemIn = createObject("java", "java.lang.System").in;
    inputStreamReader = createObject("java", "java.io.InputStreamReader").init(systemIn, "UTF-8");
    bufferedReader = createObject("java", "java.io.BufferedReader").init(inputStreamReader);
} catch (any e) {
    logError("Failed to initialize stdin reader: " & e.message);
    createObject("java", "java.lang.System").exit(1);
}

function readStdin() {
    try {
        // Read line from the pre-initialized buffered reader
        var line = bufferedReader.readLine();
        // Return null to signal EOF to the caller
        if (isNull(line)) {
            return javacast("null", "");
        }
        return line;
        return line;
    } catch (any e) {
        logError("Error reading stdin: " & e.message);
        return "";
    }
}

// Function to write to stdout
function writeStdout(message) {
    // Use Java's System.out.println for CLI-safe output
    // This auto-flushes and works correctly in CLI mode
    createObject("java", "java.lang.System").out.println(message);
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
        
        // EOF – shut down gracefully
        if (isNull(input)) {
            logDebug("EOF detected, shutting down.");
            break; // graceful shutdown on EOF
        }

        if (len(trim(input)) == 0) {
             // Blank line – but if the reader previously errored out we should exit.
             if (input EQ "") {
                 logError("Stdin returned empty string repeatedly – terminating.");
                 break;
             }
             continue;
        }
        
        logDebug("Received input: " & input);
        
        // First, try to parse the JSON in a separate try-catch
        var message = "";
        var parseError = false;
        
        try {
            // Parse JSON - this is the only place where message gets defined
            message = deserializeJSON(input);
            logDebug("JSON parsed successfully");
        } catch (any parseException) {
            // JSON parsing failed - create parse error response
            parseError = true;
            var errorResponse = structNew("ordered");
            errorResponse["jsonrpc"] = "2.0";
            errorResponse["id"] = javacast("null", ""); // Parse errors always have null ID per JSON-RPC spec
            errorResponse["error"] = structNew("ordered");
            errorResponse["error"]["code"] = -32700; // Parse error code
            errorResponse["error"]["message"] = "Parse error: " & parseException.message;
            
            writeStdout(serializeJSON(errorResponse));
            logError("JSON parse error: " & parseException.message);
        }
        
        // Only proceed if parsing was successful
        if (!parseError) {
            try {
                // Process the message
                var response = messageProcessor.processMessage(
                    message = message,
                    sessionId = sessionId,
                    sessionManager = sessionManager,
                    toolHandler = toolHandler,
                    toolRegistry = toolRegistry
                );
                
                // Send response to stdout (only if there is one)
                if (!structIsEmpty(response)) {
                    var responseJson = serializeJSON(response);
                    writeStdout(responseJson);
                    logDebug("Sent response: " & responseJson);
                } else {
                    logDebug("No response for notification");
                }
                
            } catch (any processingException) {
                // Message processing failed - create internal error response
                // Only reference message.id if message was successfully parsed
                var msgId = (isStruct(message) && structKeyExists(message, "id")) ? message.id : javacast("null", "");
                var errorResponse = structNew("ordered");
                errorResponse["jsonrpc"] = "2.0";
                errorResponse["id"] = msgId;
                errorResponse["error"] = structNew("ordered");
                errorResponse["error"]["code"] = -32603; // Internal error code
                errorResponse["error"]["message"] = "Internal error: " & processingException.message;
                
                writeStdout(serializeJSON(errorResponse));
                logError("Message processing error: " & processingException.message);
            }
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