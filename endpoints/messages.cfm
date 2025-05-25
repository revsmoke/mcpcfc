<cfscript>
// Set response headers
cfheader(name="Content-Type", value="application/json");
cfheader(name="Access-Control-Allow-Origin", value="*");

// Initialize variables
jsonRequest = {};
requestBody = "";

try {
    // Get raw JSON body
    requestBody = toString(getHttpRequestData().content);
    
    // Debug: Log raw request
    if (structKeyExists(url, "debug")) {
        writeDump(var=requestBody, output="console");
    }
    
    // Parse JSON-RPC request
    jsonRequest = deserializeJson(requestBody);
    
    // Debug: Log parsed request
    if (structKeyExists(url, "debug")) {
        writeDump(var=jsonRequest, output="console");
    }
    
    // Validate JSON-RPC format
    if (!structKeyExists(jsonRequest, "jsonrpc")) {
        throw(type="InvalidRequest", message="Missing jsonrpc field");
    }
    
    // Handle both string and numeric jsonrpc values
    jsonrpcValue = jsonRequest.jsonrpc;
    if (isNumeric(jsonrpcValue)) {
        jsonrpcValue = toString(jsonrpcValue);
    }
    
    if (trim(toString(jsonrpcValue)) != "2.0") {
        throw(type="InvalidRequest", message="Invalid JSON-RPC version: " & jsonrpcValue);
    }
    
    // Get session ID
    sessionId = structKeyExists(url, "sessionId") ? url.sessionId : "";
    
    // Process request
    processor = new mcpcfc.components.JSONRPCProcessor();
    response = processor.processRequest(jsonRequest, sessionId);
    
    // Send response
    writeOutput(serializeJson(response));
    
} catch (any e) {
    // Return JSON-RPC error
    errorResponse = {
        "jsonrpc": "2.0",
        "id": structKeyExists(jsonRequest, "id") ? jsonRequest.id : "",
        "error": {
            "code": -32603,
            "message": "Internal error: #e.message#"
        }
    };
    writeOutput(serializeJson(errorResponse));
}
</cfscript>