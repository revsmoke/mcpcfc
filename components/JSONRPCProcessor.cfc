component displayname="JSONRPCProcessor" hint="JSON-RPC message processor" {
    
    /**
     * Processes a JSON-RPC request and returns a response.
     * 
     * @param {struct} request The incoming JSON-RPC request object.
     * @param {string} sessionId The unique session identifier for the client.
     * @return {struct} The JSON-RPC response object.
     */
    public struct function processRequest(required struct request, required string sessionId) {
        var response = {
            "jsonrpc": "2.0"
        };
        
        // Add ID if present in request
        if (structKeyExists(arguments.request, "id")) {
            response.id = arguments.request.id;
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
                    
                case "ping":
                    response.result = {};
                    break;
                    
                default:
                    throw(type="MethodNotFound", message="Method not found: #arguments.request.method#");
            }
            
        } catch (MethodNotFound e) {
            response["error"] = {
                "code": -32601,
                "message": e.message
            };
        } catch (InvalidParams e) {
            response["error"] = {
                "code": -32602,
                "message": e.message
            };
        } catch (any e) {
            response["error"] = {
                "code": -32603,
                "message": "Internal error: #e.message#"
            };
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
        return {
            "protocolVersion": "2024-11-05",
            "capabilities": {
                "tools": {
                    "listChanged": true
                },
                "resources": {},
                "prompts": {}
            },
            "serverInfo": {
                "name": "coldfusion-mcp-server",
                "version": "1.0.0"
            }
        };
    }
    /**
     * Handles the tools/list request
     * 
     * @return {struct} The list of tools
     */
    private struct function handleToolsList() {
        return {
            "tools": application.toolRegistry.listTools() //cflint ignore:GLOBAL_VAR
        };
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