<cfscript>
// Set response headers
cfheader(name="Content-Type", value="application/json");
cfheader(name="Access-Control-Allow-Origin", value="*");

// Initialize request variable
request = {};
debugInfo = {};

try {
    // Get raw JSON body
    requestBody = toString(getHttpRequestData().content);
    debugInfo.rawBody = requestBody;
    
    // Parse JSON-RPC request
    request = deserializeJson(requestBody);
    debugInfo.parsedRequest = request;
    debugInfo.requestKeys = structKeyList(request);
    debugInfo.hasJsonrpc = structKeyExists(request, "jsonrpc");
    debugInfo.jsonrpcValue = structKeyExists(request, "jsonrpc") ? request.jsonrpc : "NOT_FOUND";
    debugInfo.jsonrpcType = structKeyExists(request, "jsonrpc") ? request.jsonrpc.getClass().getName() : "N/A";
    
    // Debug response
    writeOutput(serializeJson({
        "debug": true,
        "debugInfo": debugInfo,
        "request": request
    }));
    
} catch (any e) {
    // Return error with debug info
    writeOutput(serializeJson({
        "error": e.message,
        "detail": e.detail,
        "debugInfo": debugInfo
    }));
}
</cfscript>