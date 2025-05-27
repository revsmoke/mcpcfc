component displayname="JSONRPCProcessor" hint="JSON-RPC message processor" {
    
    /**
     * Processes a JSON-RPC request and returns a response.
     * 
     * @param {struct} request The incoming JSON-RPC request object.
     * @param {string} sessionId The unique session identifier for the client.
     * @return {struct} The JSON-RPC response object.
     */
    public struct function processRequest(required struct request, required string sessionId) {
        // Use ordered struct to maintain JSON-RPC field order
        var response = structNew("ordered");
        response["jsonrpc"] = "2.0";
        
        // Check if this is a notification (no id means it's a notification)
        var isNotification = !structKeyExists(arguments.request, "id");
        
        // Add ID if present in request (must come before result/error)
        if (!isNotification) {
            response["id"] = arguments.request.id;
        }
        
        try {
            // Route to appropriate handler
            switch(arguments.request.method) {
                case "initialize":
                    response.result = handleInitialize(arguments.request.params);
                    break;
                    
                case "tools/list":
                    response.result = handleToolsList();
                    break;
                    
                case "tools/call":
                    response.result = handleToolCall(arguments.request.params);
                    break;
                    
                case "resources/list":
                    response.result = handleResourcesList();
                    break;
                    
                case "prompts/list":
                    response.result = handlePromptsList();
                    break;
                    
                case "ping":
                    response.result = {};
                    break;
                    
                case "notifications/initialized":
                    // This is a notification, no response needed
                    if (isNotification) {
                        return {}; // Return empty struct for notifications
                    }
                    break;
                    
                default:
                    throw(type="MethodNotFound", message="Method not found: #arguments.request.method#");
            }
            
        } catch (MethodNotFound e) {
            var errorStruct = structNew("ordered");
            errorStruct["code"] = -32601;
            errorStruct["message"] = e.message;
            response["error"] = errorStruct;
        } catch (InvalidParams e) {
            var errorStruct = structNew("ordered");
            errorStruct["code"] = -32602;
            errorStruct["message"] = e.message;
            response["error"] = errorStruct;
        } catch (any e) {
            var errorStruct = structNew("ordered");
            errorStruct["code"] = -32603;
            errorStruct["message"] = "Internal error: #e.message#";
            response["error"] = errorStruct;
        }        
        // For notifications, return empty response (no output)
        if (isNotification) {
            return {};
        }
        
        // Send response via SSE if needed
        if (len(arguments.sessionId) > 0 && structKeyExists(response, "result")) {
            sendSSEMessage(arguments.sessionId, response);
        }
        
        return response;
    }
    /**
	 * Handles the initialize request
     * 
     * @param {struct} params The request parameters
	 */
    private struct function handleInitialize(struct params = {}) { //cflint ignore:ARG_HINT_MISSING_SCRIPT
        var result = structNew("ordered");
        var capabilities = structNew("ordered");
        var tools = structNew("ordered");
        var serverInfo = structNew("ordered");
        
        tools["listChanged"] = true;
        
        capabilities["tools"] = tools;
        capabilities["resources"] = structNew("ordered");
        capabilities["prompts"] = structNew("ordered");
        
        serverInfo["name"] = "coldfusion-mcp-server";
        serverInfo["version"] = "1.0.0";
        
        result["protocolVersion"] = "2024-11-05";
        result["capabilities"] = capabilities;
        result["serverInfo"] = serverInfo;
        
        return result;
    }
    /**
     * Handles the tools/list request
     * 
     * @return {struct} The list of tools
     */
    private struct function handleToolsList() {
        var result = structNew("ordered");
        result["tools"] = application.toolRegistry.listTools(); //cflint ignore:GLOBAL_VAR
        return result;
    }
    /**
     * Handles the tools/call request
     * 
     * @param {struct} params The request parameters
     * @return {struct} The result of the tool call
     */
    private struct function handleToolCall(required struct params) { //cflint ignore:ARG_HINT_MISSING_SCRIPT
        if (!structKeyExists(arguments.params, "name")) {
            throw(type="InvalidParams", message="Missing tool name");
        }
        
        var toolName = arguments.params.name;
        var toolArgs = structKeyExists(arguments.params, "arguments") ? arguments.params.arguments : {};
        
        // Execute tool
        var toolHandler = new mcpcfc.components.ToolHandler();
        return toolHandler.executeTool(toolName, toolArgs);
    }
    /**
     * Handles the resources/list request
     * 
     * @return {struct} The list of resources (empty for now)
     */
    private struct function handleResourcesList() {
        var result = structNew("ordered");
        result["resources"] = []; // Empty array as we don't have resources yet
        return result;
    }
    /**
     * Handles the prompts/list request
     * 
     * @return {struct} The list of prompts (empty for now)
     */
    private struct function handlePromptsList() {
        var result = structNew("ordered");
        result["prompts"] = []; // Empty array as we don't have prompts yet
        return result;
    }
    /**
     * Sends an SSE message to the client
     * 
     * @param {string} sessionId The unique session identifier for the client
     * @param {struct} message The message to send
     */
    private void function sendSSEMessage(required string sessionId, required struct message) { //cflint ignore:ARG_HINT_MISSING_SCRIPT
        application.messageQueue.put({  //cflint ignore:GLOBAL_VAR
            "sessionId": arguments.sessionId,
            "content": arguments.message
        });
    }
}