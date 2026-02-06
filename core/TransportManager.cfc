/**
 * TransportManager.cfc
 * Handles Streamable HTTP Transport for MCP Protocol 2025-06-18
 *
 * Note: Streamable HTTP may use SSE, but this implementation only uses HTTP POST with JSON-RPC.
 */
component output="false" {

    /**
     * Parse an incoming HTTP request body as JSON-RPC
     * @requestBody The raw request body string
     * @return The parsed JSON-RPC request struct
     */
    public struct function parseRequest(required string requestBody) {
        if (!len(trim(arguments.requestBody))) {
            if (structKeyExists(application, "logger")) {
                application.logger.warn("Empty request body");
            }
            throw(type="InvalidRequest", message="Empty request body");
        }

        try {
            var request = deserializeJson(arguments.requestBody);

            // Validate basic JSON-RPC structure
            if (!isStruct(request)) {
                if (structKeyExists(application, "logger")) {
                    application.logger.warn("Invalid JSON-RPC payload", { reason: "not_struct" });
                }
                throw(type="InvalidRequest", message="Request must be a JSON object");
            }

            if (!structKeyExists(request, "jsonrpc") || request.jsonrpc != "2.0") {
                if (structKeyExists(application, "logger")) {
                    application.logger.warn("Invalid jsonrpc version", {
                        jsonrpc: request.jsonrpc ?: ""
                    });
                }
                throw(type="InvalidRequest", message="Invalid or missing jsonrpc version");
            }

            if (structKeyExists(application, "logger")) {
                application.logger.debug("Parsed JSON-RPC request", {
                    method: request.method ?: "",
                    hasId: structKeyExists(request, "id")
                });
            }
            return request;

        } catch (any e) {
            if (e.type == "InvalidRequest") {
                rethrow;
            }
            if (structKeyExists(application, "logger")) {
                application.logger.error("Failed to parse JSON", { error: e.message });
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
        if (structKeyExists(application, "logger")) {
            application.logger.debug("Formatting response", {
                hasError: structKeyExists(arguments.response, "error")
            });
        }
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
        if (structKeyExists(application, "logger")) {
            application.logger.debug("Providing response headers");
        }
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
            headers["Access-Control-Allow-Headers"] = "Content-Type, Accept, Authorization, MCP-Session-Id, MCP-Protocol-Version, X-Session-ID";
            headers["Access-Control-Max-Age"] = "86400";
        }

        if (structKeyExists(application, "logger")) {
            application.logger.debug("CORS headers evaluated", {
                origin: origin,
                allowed: len(origin) > 0
            });
        }
        return headers;
    }

    /**
     * Check if the request is a CORS preflight request
     * @return Boolean
     */
    public boolean function isPreflightRequest() {
        if (structKeyExists(application, "logger")) {
            application.logger.debug("Checking preflight request", {
                method: cgi.request_method ?: ""
            });
        }
        return cgi.request_method == "OPTIONS";
    }

    /**
     * Validate the request method
     * @return Boolean indicating if method is allowed
     */
    public boolean function isMethodAllowed() {
        if (structKeyExists(application, "logger")) {
            application.logger.debug("Validating request method", {
                method: cgi.request_method ?: ""
            });
        }
        return cgi.request_method == "POST" || cgi.request_method == "OPTIONS";
    }

    /**
     * Extract session ID from request
     * @return The session ID or a new UUID if not provided
     */
    public string function extractSessionId() {
        // Check URL parameter first
        if (structKeyExists(url, "sessionId") && len(url.sessionId)) {
            if (structKeyExists(application, "logger")) {
                application.logger.debug("Session ID from URL", { sessionId: url.sessionId });
            }
            return url.sessionId;
        }

        // Check header
        var headers = getHttpRequestData().headers;
        if (structKeyExists(headers, "MCP-Session-Id") && len(headers["MCP-Session-Id"])) {
            if (structKeyExists(application, "logger")) {
                application.logger.debug("Session ID from MCP-Session-Id header", {
                    sessionId: headers["MCP-Session-Id"]
                });
            }
            return headers["MCP-Session-Id"];
        }

        if (structKeyExists(headers, "Mcp-Session-Id") && len(headers["Mcp-Session-Id"])) {
            if (structKeyExists(application, "logger")) {
                application.logger.debug("Session ID from Mcp-Session-Id header", {
                    sessionId: headers["Mcp-Session-Id"]
                });
            }
            return headers["Mcp-Session-Id"];
        }

        if (structKeyExists(headers, "X-Session-ID") && len(headers["X-Session-ID"])) {
            if (structKeyExists(application, "logger")) {
                application.logger.debug("Session ID from header", { sessionId: headers["X-Session-ID"] });
            }
            return headers["X-Session-ID"];
        }

        // Generate new session ID
        var newSessionId = createUUID();
        if (structKeyExists(application, "logger")) {
            application.logger.debug("Generated new session ID", { sessionId: newSessionId });
        }
        return newSessionId;
    }

    /**
     * Validate content type header
     * @return Boolean indicating if content type is valid
     */
    public boolean function isValidContentType() {
        var contentType = cgi.content_type ?: "";
        if (structKeyExists(application, "logger")) {
            application.logger.debug("Validating content type", { contentType: contentType });
        }
        return findNoCase("application/json", contentType) > 0;
    }
}
