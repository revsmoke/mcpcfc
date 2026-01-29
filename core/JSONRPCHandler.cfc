/**
 * JSONRPCHandler.cfc
 * JSON-RPC 2.0 Request Processor for MCP Protocol 2025-11-25
 */
component output="false" {

    /**
     * Process a JSON-RPC 2.0 request
     * @request The parsed request struct
     * @sessionId The session identifier
     * @return The JSON-RPC response struct
     */
    public struct function process(required struct request, required string sessionId) {
        var response = structNew("ordered");
        response["jsonrpc"] = "2.0";

        // Check if this is a notification (no id field)
        var isNotification = !structKeyExists(arguments.request, "id");

        if (!isNotification) {
            response["id"] = arguments.request.id;
        }

        try {
            // Validate request structure
            if (!structKeyExists(arguments.request, "method")) {
                throw(type="InvalidRequest", message="Missing 'method' field");
            }

            var method = arguments.request.method;
            var params = arguments.request.params ?: {};

            // Check session initialization for methods that require it
            var routeConfig = application.routes.methods[method] ?: {};
            if ((routeConfig.requiresSession ?: false)) {
                var session = application.sessionManager.getSession(arguments.sessionId);
                if (isNull(session) || !session.initialized) {
                    throw(type="InvalidRequest", message="Server not initialized. Call 'initialize' first.");
                }
            }

            // Check if this is a notification
            if (arrayFindNoCase(application.routes.notifications, method)) {
                // Notifications don't return responses
                handleNotification(method, params, arguments.sessionId);
                return {};
            }

            // Route to appropriate handler
            switch(method) {
                case "initialize":
                    response["result"] = handleInitialize(params, arguments.sessionId);
                    break;

                case "tools/list":
                    response["result"] = handleToolsList(params);
                    break;

                case "tools/call":
                    response["result"] = handleToolCall(params, arguments.sessionId);
                    break;

                case "resources/list":
                    response["result"] = handleResourcesList(params);
                    break;

                case "resources/read":
                    response["result"] = handleResourcesRead(params);
                    break;

                case "prompts/list":
                    response["result"] = handlePromptsList(params);
                    break;

                case "prompts/get":
                    response["result"] = handlePromptsGet(params);
                    break;

                case "ping":
                    response["result"] = handlePing();
                    break;

                case "completion/complete":
                    response["result"] = handleCompletion(params);
                    break;

                default:
                    throw(type="MethodNotFound", message="Method not found: #method#");
            }

        } catch (MethodNotFound e) {
            response["error"] = createError(-32601, e.message);
        } catch (InvalidRequest e) {
            response["error"] = createError(-32600, e.message);
        } catch (InvalidParams e) {
            response["error"] = createError(-32602, e.message);
        } catch (any e) {
            application.logger.error("Request processing failed", {
                error: e.message,
                detail: e.detail ?: "",
                method: arguments.request.method ?: "unknown"
            });
            response["error"] = createError(-32603, "Internal error: #e.message#");
        }

        // Return empty for notifications
        if (isNotification) {
            return {};
        }

        return response;
    }

    /**
     * Handle initialize request
     */
    public struct function handleInitialize(struct params = {}, required string sessionId) {
        var capMgr = new core.CapabilityManager();

        var result = structNew("ordered");
        result["protocolVersion"] = application.config.protocolVersion;
        result["capabilities"] = capMgr.getServerCapabilities();
        result["serverInfo"] = structNew("ordered");
        result.serverInfo["name"] = application.config.serverName;
        result.serverInfo["version"] = application.config.serverVersion;

        application.sessionManager.markInitialized(arguments.sessionId);

        application.logger.info("Client initialized", {
            clientInfo: arguments.params.clientInfo ?: {}
        });

        return result;
    }

    /**
     * Handle tools/list request
     */
    private struct function handleToolsList(struct params = {}) {
        var tools = application.toolRegistry.listTools();

        // Handle pagination cursor if provided
        var cursor = arguments.params.cursor ?: "";
        // For now, return all tools (pagination can be added later)

        return { tools: tools };
    }

    /**
     * Handle tools/call request
     */
    public struct function handleToolCall(required struct params, required string sessionId) {
        if (!structKeyExists(arguments.params, "name")) {
            throw(type="InvalidParams", message="Missing required parameter: name");
        }

        var toolName = arguments.params.name;
        var tool = application.toolRegistry.getTool(toolName);

        if (isNull(tool)) {
            throw(type="InvalidParams", message="Unknown tool: #toolName#");
        }

        var toolArgs = arguments.params.arguments ?: {};

        application.logger.debug("Executing tool", {
            tool: toolName,
            sessionId: arguments.sessionId
        });

        var startTime = getTickCount();
        var result = tool.execute(toolArgs);
        var duration = getTickCount() - startTime;

        application.logger.info("Tool executed", {
            tool: toolName,
            duration: duration,
            isError: result.isError ?: false
        });

        return result;
    }

    /**
     * Handle resources/list request
     */
    private struct function handleResourcesList(struct params = {}) {
        return { resources: application.resourceRegistry.list() };
    }

    /**
     * Handle resources/read request
     */
    private struct function handleResourcesRead(required struct params) {
        if (!structKeyExists(arguments.params, "uri")) {
            throw(type="InvalidParams", message="Missing required parameter: uri");
        }

        return application.resourceRegistry.read(arguments.params.uri);
    }

    /**
     * Handle prompts/list request
     */
    private struct function handlePromptsList(struct params = {}) {
        return { prompts: application.promptRegistry.list() };
    }

    /**
     * Handle prompts/get request
     */
    private struct function handlePromptsGet(required struct params) {
        if (!structKeyExists(arguments.params, "name")) {
            throw(type="InvalidParams", message="Missing required parameter: name");
        }

        var promptArgs = structKeyExists(arguments.params, "arguments") ? arguments.params["arguments"] : {};
        return application.promptRegistry.get(arguments.params.name, promptArgs);
    }

    /**
     * Handle ping request
     */
    public struct function handlePing() {
        return {};
    }

    /**
     * Handle completion/complete request
     */
    public struct function handleCompletion(required struct params) {
        // Argument completion for tool parameters
        var completions = [];

        if (structKeyExists(arguments.params, "ref")) {
            var ref = arguments.params.ref;

            if (ref.type == "ref/argument" && structKeyExists(ref, "name")) {
                // Get tool and provide argument completions
                var tool = application.toolRegistry.getTool(ref.name);
                if (!isNull(tool)) {
                    // Could provide dynamic completions based on tool schema
                    completions = [];
                }
            }
        }

        return {
            completion: {
                values: completions,
                hasMore: false
            }
        };
    }

    /**
     * Handle notification messages (no response)
     */
    private void function handleNotification(required string method, struct params = {}, string sessionId = "") {
        switch(arguments.method) {
            case "notifications/initialized":
                application.logger.info("Client completed initialization", {
                    sessionId: arguments.sessionId
                });
                break;

            case "notifications/progress":
                // Handle progress updates
                break;

            case "notifications/cancelled":
                // Handle cancellation
                application.logger.info("Request cancelled", {
                    requestId: arguments.params.requestId ?: ""
                });
                break;
        }
    }

    /**
     * Create a JSON-RPC error structure
     */
    private struct function createError(required numeric code, required string message, any data = "") {
        var err = structNew("ordered");
        err["code"] = arguments.code;
        err["message"] = arguments.message;

        if (len(arguments.data)) {
            err["data"] = arguments.data;
        }

        return err;
    }
}
