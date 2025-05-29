component displayname="JSONRPCProcessor" hint="JSON-RPC message processor" {
    
    // Instance variable to store sessionId for tool logging
    variables.sessionId = "";
    
    /**
     * Processes a JSON-RPC request and returns a response.
     * 
     * @param request {struct} The incoming JSON-RPC request object.
     * @param sessionId {string} The unique session identifier for the client.
     * @return {struct} The JSON-RPC response object.
     */
    public struct function processRequest(required struct request, required string sessionId) {  //cflint ignore:ARG_HINT_MISSING_SCRIPT,FUNCTION_TOO_COMPLEX
        // Store sessionId for use in tool execution
        variables.sessionId = arguments.sessionId;
        // Use ordered struct to maintain JSON-RPC field order
        var response = [:];
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
                    response["result"] = handleInitialize(arguments.request.params);
                    break;
                    
                case "tools/list":
                    response["result"] = handleToolsList();
                    break;
                    
                case "tools/call":
                    response["result"] = handleToolCall(arguments.request.params);
                    break;
                    
                case "resources/list":
                    response["result"] = handleResourcesList();
                    break;
                    
                case "prompts/list":
                    response["result"] = handlePromptsList();
                    break;
                    
                case "ping":
                    response["result"] = {};
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
            var errorStruct = [:];
            errorStruct["code"] = -32601;
            errorStruct["message"] = e.message;
            response["error"] = errorStruct;
        } catch (InvalidParams e) {
            var errorStruct = [:];
            errorStruct["code"] = -32602;
            errorStruct["message"] = e.message;
            response["error"] = errorStruct;
        } catch (any e) {
            var errorStruct = [:];
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
     * @param params {struct} The request parameters
	 */
    private struct function handleInitialize(struct params = {}) { //cflint ignore:ARG_HINT_MISSING_SCRIPT
        var result = [:];
        var capabilities = [:];
        var tools = [:];
        var serverInfo = [:];
        
        tools["listChanged"] = true;
        
        capabilities["tools"] = tools;
        capabilities["resources"] = [:];
        capabilities["prompts"] = [:];
        
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
        var result = [:];
        result["tools"] = application.toolRegistry.listTools(); //cflint ignore:GLOBAL_VAR
        return result;
    }
    /**
     * Handles the tools/call request
     * 
     * @param params {struct} The request parameters
     * @return {struct} The result of the tool call
     */
    private struct function handleToolCall(required struct params) { //cflint ignore:ARG_HINT_MISSING_SCRIPT
        if (!structKeyExists(arguments.params, "name")) {
            throw(type="InvalidParams", message="Missing tool name");
        }
        
        var toolName = arguments.params.name;
        var toolArgs = structKeyExists(arguments.params, "arguments") ? arguments.params.arguments : {};
        
        // Store sessionId in request scope for logging
        if (len(variables.sessionId) > 0) {
            request.sessionId = variables.sessionId;
        }
        
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
        var result = [:];
        result["resources"] = []; // Empty array as we don't have resources yet
        return result;
    }
    /**
     * Handles the prompts/list request
     * 
     * @return {struct} The list of prompts (empty for now)
     */
    private struct function handlePromptsList() {
        var result = [:];
        result["prompts"] = []; // Empty array as we don't have prompts yet
        return result;
    }
    /**
     * Sends an SSE message to the client
     * 
     * @param sessionId {string} The unique session identifier for the client
     * @param message {struct} The message to send
     */
    private void function sendSSEMessage(required string sessionId, required struct message) { //cflint ignore:ARG_HINT_MISSING_SCRIPT
        application.messageQueue.put({  //cflint ignore:GLOBAL_VAR
            "sessionId": arguments.sessionId,
            "content": arguments.message
        });
    }
}