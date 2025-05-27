<cfsetting enableCFOutputOnly="true">
<cfcontent type="application/json" reset="yes">
<cfscript>
// Set response headers
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
    
    // Send response only if not empty (notifications return empty struct)
    if (!structIsEmpty(response)) {
        writeOutput(serializeJson(response));
    }
    
} catch (any e) {
    // Log error to file instead of outputting
    cflog(file="mcp_error", application="true", type="Error", 
          text="Error in messages.cfm: #e.message# - #e.detail# - Request: #requestBody#");
    
    // Return JSON-RPC error with ordered struct
    errorResponse = structNew("ordered");
    errorResponse["jsonrpc"] = "2.0";
    errorResponse["id"] = structKeyExists(jsonRequest, "id") ? jsonRequest.id : javacast("null", "");
    
    errorStruct = structNew("ordered");
    errorStruct["code"] = -32603;
    errorStruct["message"] = "Internal error: #e.message#";
    errorResponse["error"] = errorStruct;
    
    writeOutput(serializeJson(errorResponse));
}
</cfscript>