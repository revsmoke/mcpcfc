/**
 * TransportManager.cfc
 * Handles Streamable HTTP Transport for MCP Protocol 2025-11-25
 *
 * Note: SSE transport is DEPRECATED in MCP 2025-11-25
 * This implementation uses standard HTTP POST with JSON-RPC
 */
component output="false" {

    /**
     * Parse an incoming HTTP request body as JSON-RPC
     * @requestBody The raw request body string
     * @return The parsed JSON-RPC request struct
     */
    public struct function parseRequest(required string requestBody) {
        if (!len(trim(arguments.requestBody))) {
            throw(type="InvalidRequest", message="Empty request body");
        }

        try {
            var request = deserializeJson(arguments.requestBody);

            // Validate basic JSON-RPC structure
            if (!isStruct(request)) {
                throw(type="InvalidRequest", message="Request must be a JSON object");
            }

            if (!structKeyExists(request, "jsonrpc") || request.jsonrpc != "2.0") {
                throw(type="InvalidRequest", message="Invalid or missing jsonrpc version");
            }

            return request;

        } catch (any e) {
            if (e.type == "InvalidRequest") {
                rethrow;
            }
            throw(type="ParseError", message="Invalid JSON: #e.message#");
        }
    }

    /**
     * Format a JSON-RPC response for HTTP output
     * @response The response struct to serialize
     * @return The JSON string
     */
    public string function formatResponse(required struct response) {
        return serializeJson(arguments.response);
    }

    /**
     * Get the appropriate HTTP status code for a response
     * @response The JSON-RPC response struct
     * @return The HTTP status code
     */
    public numeric function getStatusCode(required struct response) {
        if (structKeyExists(arguments.response, "error")) {
            var code = arguments.response.error.code;

            switch(code) {
                case -32700: // Parse error
                case -32600: // Invalid request
                    return 400;
                case -32601: // Method not found
                    return 404;
                case -32602: // Invalid params
                    return 400;
                case -32603: // Internal error
                    return 500;
                default:
                    return 500;
            }
        }

        return 200;
    }

    /**
     * Set standard response headers
     * @return Struct of headers to set
     */
    public struct function getResponseHeaders() {
        return {
            "Content-Type": "application/json",
            "Cache-Control": "no-cache, no-store, must-revalidate",
            "Pragma": "no-cache",
            "Expires": "0"
        };
    }

    /**
     * Set CORS headers for cross-origin requests
     * @allowedOrigins Array or string of allowed origins
     * @return Struct of CORS headers
     */
    public struct function getCORSHeaders(any allowedOrigins = "*") {
        var origin = "*";

        if (isArray(arguments.allowedOrigins)) {
            if (arrayLen(arguments.allowedOrigins) == 1 && arguments.allowedOrigins[1] == "*") {
                origin = "*";
            } else {
                // Check if request origin is in allowed list
                var requestOrigin = cgi.http_origin ?: "";
                if (arrayFindNoCase(arguments.allowedOrigins, requestOrigin) > 0) {
                    origin = requestOrigin;
                } else {
                    origin = "";  // Don't set header if not allowed
                }
            }
        } else {
            origin = arguments.allowedOrigins;
        }

        var headers = {};

        if (len(origin)) {
            headers["Access-Control-Allow-Origin"] = origin;
            headers["Access-Control-Allow-Methods"] = "POST, OPTIONS";
            headers["Access-Control-Allow-Headers"] = "Content-Type, Authorization, X-Session-ID";
            headers["Access-Control-Max-Age"] = "86400";
        }

        return headers;
    }

    /**
     * Check if the request is a CORS preflight request
     * @return Boolean
     */
    public boolean function isPreflightRequest() {
        return cgi.request_method == "OPTIONS";
    }

    /**
     * Validate the request method
     * @return Boolean indicating if method is allowed
     */
    public boolean function isMethodAllowed() {
        return cgi.request_method == "POST" || cgi.request_method == "OPTIONS";
    }

    /**
     * Extract session ID from request
     * @return The session ID or a new UUID if not provided
     */
    public string function extractSessionId() {
        // Check URL parameter first
        if (structKeyExists(url, "sessionId") && len(url.sessionId)) {
            return url.sessionId;
        }

        // Check header
        var headers = getHttpRequestData().headers;
        if (structKeyExists(headers, "X-Session-ID") && len(headers["X-Session-ID"])) {
            return headers["X-Session-ID"];
        }

        // Generate new session ID
        return createUUID();
    }

    /**
     * Validate content type header
     * @return Boolean indicating if content type is valid
     */
    public boolean function isValidContentType() {
        var contentType = cgi.content_type ?: "";
        return findNoCase("application/json", contentType) > 0;
    }
}
