<cfscript>
// Set response headers
cfheader(name="Content-Type", value="application/json");
cfheader(name="Access-Control-Allow-Origin", value="*");

// Initialize variables
request = {};
debugInfo = {};

try {
    // Get HTTP request data
    httpData = getHttpRequestData();
    debugInfo.method = httpData.method;
    debugInfo.headers = httpData.headers;
    
    // Get raw JSON body
    requestBody = toString(httpData.content);
    debugInfo.rawBodyLength = len(requestBody);
    debugInfo.rawBody = requestBody;
    
    if (len(trim(requestBody)) == 0) {
        throw(type="InvalidRequest", message="Empty request body");
    }
    
    // Parse JSON-RPC request
    request = deserializeJson(requestBody);
    debugInfo.parsedRequest = request;
    
    // Validate JSON-RPC format
    if (!structKeyExists(request, "jsonrpc")) {
        throw(type="InvalidRequest", message="Missing jsonrpc field");
    }
    
    if (trim(toString(request.jsonrpc)) != "2.0") {
        throw(type="InvalidRequest", message="Invalid JSON-RPC version: " & request.jsonrpc);
    }
    
    // Success - process normally
    sessionId = structKeyExists(url, "sessionId") ? url.sessionId : "";
    processor = new components.JSONRPCProcessor();
    response = processor.processRequest(request, sessionId);
    
    // Add debug info to successful response
    response.debug = debugInfo;
    writeOutput(serializeJson(response));
    
} catch (any e) {
    // Return JSON-RPC error with debug info
    errorResponse = {
        "jsonrpc": "2.0",
        "id": structKeyExists(request, "id") ? request.id : "",
        "error": {
            "code": -32603,
            "message": "Internal error: #e.message#",
            "data": {
                "errorType": e.type,
                "errorDetail": e.detail,
                "debugInfo": debugInfo
            }
        }
    };
    writeOutput(serializeJson(errorResponse));
}
</cfscript>