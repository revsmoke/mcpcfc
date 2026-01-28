<cfsetting enableCFOutputOnly="true" requesttimeout="120">
<cfscript>
/**
 * MCP Protocol Endpoint
 * Single Streamable HTTP endpoint for MCP Protocol 2025-11-25
 *
 * This endpoint handles all JSON-RPC 2.0 requests for the MCP server.
 * SSE transport is deprecated in MCP 2025-11-25.
 */

// Initialize transport manager (using local scope for template-level variables)
local.transport = new core.TransportManager();

// Set CORS headers
local.corsHeaders = local.transport.getCORSHeaders(application.config.allowedOrigins);
for (local.header in local.corsHeaders) {
    cfheader(name=local.header, value=local.corsHeaders[local.header]);
}

// Handle CORS preflight
if (local.transport.isPreflightRequest()) {
    cfheader(statuscode=204);
    abort;
}

// Set response headers
local.responseHeaders = local.transport.getResponseHeaders();
for (local.header in local.responseHeaders) {
    cfheader(name=local.header, value=local.responseHeaders[local.header]);
}

// Only POST allowed for JSON-RPC
if (!local.transport.isMethodAllowed()) {
    cfheader(statuscode=405);
    cfheader(name="Allow", value="POST, OPTIONS");
    writeOutput(serializeJson({
        jsonrpc: "2.0",
        error: { code: -32600, message: "Method not allowed. Use POST." },
        id: javacast("null", "")
    }));
    abort;
}

// Validate content type
if (!local.transport.isValidContentType()) {
    cfheader(statuscode=415);
    writeOutput(serializeJson({
        jsonrpc: "2.0",
        error: { code: -32600, message: "Content-Type must be application/json" },
        id: javacast("null", "")
    }));
    abort;
}

try {
    // Get request body
    local.requestBody = toString(getHttpRequestData().content);

    // Parse request
    local.request = local.transport.parseRequest(local.requestBody);

    // Get/create session
    local.sessionId = local.transport.extractSessionId();
    local.request.sessionId = local.sessionId;  // Store in request struct

    if (!application.sessionManager.sessionExists(local.sessionId)) {
        application.sessionManager.createSession(local.sessionId);
    }
    application.sessionManager.updateActivity(local.sessionId);

    // Add session header to response
    cfheader(name="X-Session-ID", value=local.sessionId);

    // Process request
    local.response = application.mcpServer.processRequest(local.request, local.sessionId);

    // Handle response
    if (structIsEmpty(local.response)) {
        // Notification - no response body
        cfheader(statuscode=204);
    } else {
        // Set appropriate status code
        local.statusCode = local.transport.getStatusCode(local.response);
        if (local.statusCode != 200) {
            cfheader(statuscode=local.statusCode);
        }

        writeOutput(local.transport.formatResponse(local.response));
    }

} catch (ParseError e) {
    if (structKeyExists(application, "logger")) {
        application.logger.warn("Parse error", { error: e.message });
    }

    cfheader(statuscode=400);
    writeOutput(serializeJson({
        jsonrpc: "2.0",
        error: { code: -32700, message: "Parse error: #e.message#" },
        id: javacast("null", "")
    }));

} catch (InvalidRequest e) {
    if (structKeyExists(application, "logger")) {
        application.logger.warn("Invalid request", { error: e.message });
    }

    cfheader(statuscode=400);
    writeOutput(serializeJson({
        jsonrpc: "2.0",
        error: { code: -32600, message: "Invalid request: #e.message#" },
        id: javacast("null", "")
    }));

} catch (any e) {
    if (structKeyExists(application, "logger")) {
        application.logger.error("Endpoint error", {
            error: e.message,
            detail: e.detail ?: "",
            type: e.type ?: ""
        });
    }

    cfheader(statuscode=500);

    local.errorId = (structKeyExists(local, "request") && isStruct(local.request) && structKeyExists(local.request, "id"))
        ? local.request.id
        : javacast("null", "");

    writeOutput(serializeJson({
        jsonrpc: "2.0",
        error: { code: -32603, message: "Internal error" },
        id: local.errorId
    }));
}
</cfscript>
