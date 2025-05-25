component displayname="JSONRPCProcessor" {
    
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
            response.error = {
                "code": -32601,
                "message": e.message
            };
        } catch (InvalidParams e) {
            response.error = {
                "code": -32602,
                "message": e.message
            };
        } catch (any e) {
            response.error = {
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
    
    private struct function handleInitialize(struct params = {}) {
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
    
    private struct function handleToolsList() {
        return {
            "tools": application.toolRegistry.listTools()
        };
    }
    
    private struct function handleToolCall(required struct params) {
        if (!structKeyExists(arguments.params, "name")) {
            throw(type="InvalidParams", message="Missing tool name");
        }
        
        var toolName = arguments.params.name;
        var toolArgs = structKeyExists(arguments.params, "arguments") ? arguments.params.arguments : {};
        
        // Execute tool
        var toolHandler = new mcpcfc.components.ToolHandler();
        return toolHandler.executeTool(toolName, toolArgs);
    }
    
    private void function sendSSEMessage(required string sessionId, required struct message) {
        application.messageQueue.put({
            "sessionId": arguments.sessionId,
            "content": arguments.message
        });
    }
}