<cfscript>
// Set response headers
cfheader(name="Content-Type", value="application/json");
cfheader(name="Access-Control-Allow-Origin", value="*");

// Get raw JSON body
requestBody = toString(getHttpRequestData().content);

try {
    // Parse JSON-RPC request
    request = deserializeJson(requestBody);
    
    // Validate JSON-RPC format
    if (!structKeyExists(request, "jsonrpc") || request.jsonrpc != "2.0") {
        throw(type="InvalidRequest", message="Invalid JSON-RPC version");
    }
    
    // Get session ID
    sessionId = structKeyExists(url, "sessionId") ? url.sessionId : "";
    
    // Process request
    processor = new components.JSONRPCProcessor();
    response = processor.processRequest(request, sessionId);
    
    // Send response
    writeOutput(serializeJson(response));
    
} catch (any e) {
    // Return JSON-RPC error
    errorResponse = {
        "jsonrpc": "2.0",
        "id": structKeyExists(request, "id") ? request.id : null,
        "error": {
            "code": -32603,
            "message": "Internal error: #e.message#"
        }
    };
    writeOutput(serializeJson(errorResponse));
}
</cfscript>