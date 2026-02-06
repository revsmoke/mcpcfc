/**
 * HttpClientTool.cfc
 * Make HTTP requests to external APIs
 * Supports GET, POST, PUT, DELETE, PATCH methods
 */
component extends="AbstractTool" output="false" {

    /**
     * Initialize the tool
     */
    public function init() {
        setName("httpRequest");
        setTitle("HTTP Request");
        setDescription("Make HTTP requests to external URLs. Supports various methods and custom headers.");

        var inputSchema = structNew("ordered");
        inputSchema["type"] = "object";
        inputSchema["properties"] = structNew("ordered");

        var urlSchema = structNew("ordered");
        urlSchema["type"] = "string";
        urlSchema["description"] = "The URL to request (must be HTTP or HTTPS)";
        inputSchema.properties["url"] = urlSchema;

        var methodSchema = structNew("ordered");
        methodSchema["type"] = "string";
        methodSchema["enum"] = ["GET", "POST", "PUT", "DELETE", "PATCH", "HEAD", "OPTIONS"];
        methodSchema["description"] = "HTTP method (default: GET)";
        inputSchema.properties["method"] = methodSchema;

        var headersSchema = structNew("ordered");
        headersSchema["type"] = "object";
        headersSchema["description"] = "Request headers as key-value pairs";
        inputSchema.properties["headers"] = headersSchema;

        var bodySchema = structNew("ordered");
        bodySchema["type"] = "string";
        bodySchema["description"] = "Request body (for POST, PUT, PATCH)";
        inputSchema.properties["body"] = bodySchema;

        var contentTypeSchema = structNew("ordered");
        contentTypeSchema["type"] = "string";
        contentTypeSchema["description"] = "Content-Type header (e.g., 'application/json')";
        inputSchema.properties["contentType"] = contentTypeSchema;

        var timeoutSchema = structNew("ordered");
        timeoutSchema["type"] = "number";
        timeoutSchema["description"] = "Request timeout in seconds (default: 30)";
        inputSchema.properties["timeout"] = timeoutSchema;

        var followRedirectsSchema = structNew("ordered");
        followRedirectsSchema["type"] = "boolean";
        followRedirectsSchema["description"] = "Whether to follow redirects (default: true)";
        inputSchema.properties["followRedirects"] = followRedirectsSchema;

        inputSchema["required"] = ["url"];
        setInputSchema(inputSchema);

        var outputSchema = structNew("ordered");
        outputSchema["type"] = "object";
        outputSchema["properties"] = structNew("ordered");

        var statusCodeSchema = structNew("ordered");
        statusCodeSchema["type"] = "number";
        statusCodeSchema["description"] = "HTTP status code";
        outputSchema.properties["statusCode"] = statusCodeSchema;

        var statusTextSchema = structNew("ordered");
        statusTextSchema["type"] = "string";
        statusTextSchema["description"] = "HTTP status text";
        outputSchema.properties["statusText"] = statusTextSchema;

        var responseHeadersSchema = structNew("ordered");
        responseHeadersSchema["type"] = "object";
        responseHeadersSchema["description"] = "Response headers";
        outputSchema.properties["headers"] = responseHeadersSchema;

        var responseBodySchema = structNew("ordered");
        responseBodySchema["type"] = "string";
        responseBodySchema["description"] = "Response body (truncated if large)";
        outputSchema.properties["body"] = responseBodySchema;

        setOutputSchema(outputSchema);

        return this;
    }

    /**
     * Execute the HTTP request
     * @toolArgs The tool arguments
     * @return The request result
     */
    public struct function execute(required struct toolArgs) {
        validateRequired(arguments.toolArgs, ["url"]);

        var url = trim(arguments.toolArgs.url);
        var method = uCase(getParam(arguments.toolArgs, "method", "GET"));
        logExecution("HTTP request received", { url: url, method: method });

        // Validate URL scheme
        if (!reFindNoCase("^https?://", url)) {
            logExecution("HTTP request rejected (invalid scheme)", { url: url });
            return errorResult("Only HTTP and HTTPS URLs are allowed");
        }

        // Block requests to internal/private IPs
        if (isPrivateUrl(url)) {
            logExecution("HTTP request blocked (private IP)", { url: url });
            return errorResult("Requests to internal/private IP addresses are not allowed");
        }

        // Get timeout (in seconds)
        var timeout = val(getParam(arguments.toolArgs, "timeout", 30));
        var maxTimeout = application.config.httpClientTimeout / 1000;
        if (timeout > maxTimeout) {
            timeout = maxTimeout;
        }

        // Follow redirects
        var followRedirects = getParam(arguments.toolArgs, "followRedirects", true);
        logExecution("HTTP request configured", {
            timeoutSeconds: timeout,
            followRedirects: followRedirects
        });

        try {
            cfhttp(
                url: url,
                method: method,
                result: "httpResult",
                timeout: timeout,
                redirect: followRedirects,
                getAsBinary: "auto",
                throwOnError: false
            ) {
                // Add custom headers
                if (structKeyExists(arguments.toolArgs, "headers") && isStruct(arguments.toolArgs.headers)) {
                    for (var headerName in arguments.toolArgs.headers) {
                        cfhttpparam(type: "header", name: headerName, value: arguments.toolArgs.headers[headerName]);
                    }
                }

                // Add Content-Type if specified
                if (structKeyExists(arguments.toolArgs, "contentType") && len(arguments.toolArgs.contentType)) {
                    cfhttpparam(type: "header", name: "Content-Type", value: arguments.toolArgs.contentType);
                }

                // Add body for appropriate methods
                if (arrayFindNoCase(["POST", "PUT", "PATCH"], method) && structKeyExists(arguments.toolArgs, "body")) {
                    cfhttpparam(type: "body", value: arguments.toolArgs.body);
                }
            }

            // Build response
            var response = buildResponse(httpResult);

            logExecution("HTTP request completed", {
                url: url,
                method: method,
                statusCode: response.statusCode
            });

            return jsonResult(response);

        } catch (any e) {
            logExecution("HTTP request failed", {
                url: url,
                error: e.message
            });
            return errorResult("HTTP request failed: #e.message#");
        }
    }

    /**
     * Build a clean response object
     */
    private struct function buildResponse(required struct httpResult) {
        var response = structNew("ordered");

        // Parse status code
        var statusParts = listToArray(arguments.httpResult.statusCode, " ");
        response["statusCode"] = val(statusParts[1]);
        response["statusText"] = arrayLen(statusParts) > 1
            ? arraySlice(statusParts, 2).toList(" ")
            : "";

        // Clean headers (remove sensitive info)
        response["headers"] = {};
        if (isStruct(arguments.httpResult.responseHeader)) {
            for (var header in arguments.httpResult.responseHeader) {
                // Skip some internal headers
                if (!listFindNoCase("Set-Cookie,Cookie", header)) {
                    var value = arguments.httpResult.responseHeader[header];
                    if (isSimpleValue(value)) {
                        response.headers[header] = value;
                    }
                }
            }
        }

        // Handle response body
        if (isBinary(arguments.httpResult.fileContent)) {
            var binaryLen = len(arguments.httpResult.fileContent);
            response["body"] = "[Binary content: #binaryLen# bytes]";
            response["isBinary"] = true;
            response["contentLength"] = binaryLen;
            logExecution("HTTP response is binary", { length: binaryLen });
        } else {
            var body = arguments.httpResult.fileContent ?: "";
            var maxBodySize = 50000;  // Limit response body size

            if (len(body) > maxBodySize) {
                response["body"] = left(body, maxBodySize);
                response["truncated"] = true;
                response["fullLength"] = len(body);
                logExecution("HTTP response truncated", {
                    fullLength: len(body),
                    maxBodySize: maxBodySize
                });
            } else {
                response["body"] = body;
            }
        }

        return response;
    }

    /**
     * Check if URL points to a private/internal IP
     */
    private boolean function isPrivateUrl(required string url) {
        // Extract host from URL
        var host = reReplace(arguments.url, "^https?://([^/:]+).*$", "\1");

        // Check for localhost
        if (host == "localhost" || host == "127.0.0.1" || host == "::1") {
            return true;
        }

        // Check for private IP ranges
        // 10.x.x.x
        if (reFindNoCase("^10\.\d+\.\d+\.\d+$", host)) {
            return true;
        }

        // 172.16.x.x - 172.31.x.x
        if (reFindNoCase("^172\.(1[6-9]|2[0-9]|3[0-1])\.\d+\.\d+$", host)) {
            return true;
        }

        // 192.168.x.x
        if (reFindNoCase("^192\.168\.\d+\.\d+$", host)) {
            return true;
        }

        // 169.254.x.x (link-local)
        if (reFindNoCase("^169\.254\.\d+\.\d+$", host)) {
            return true;
        }

        return false;
    }
}
