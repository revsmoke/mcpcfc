component displayname="SystemTool" {
    
    /**
     * System utilities for the MCP server
     */
    
    public struct function executeTool(required string toolName, required struct args) {
        try {
            switch(arguments.toolName) {
                case "restartClaude":
                    return restartClaude(arguments.args);
                    
                case "reloadTools":
                    return reloadTools(arguments.args);
                    
                default:
                    throw(type="ToolNotFound", message="Unknown system tool: #arguments.toolName#");
            }
            
        } catch (any e) {
            return {
                "content": [{
                    "type": "text",
                    "text": "Error executing system tool: #e.message#"
                }],
                "isError": true
            };
        }
    }
    
    private struct function restartClaude(required struct args) {
        try {
            // Execute the restart script
            cfexecute(
                name="/Applications/ColdFusion2023/cfusion/wwwroot/mcpcfc/restart-claude.sh",
                timeout="10"
            );
            
            return {
                "content": [{
                    "type": "text",
                    "text": "Claude Desktop restart initiated! The app will restart and return to this conversation. New tools will be loaded."
                }]
            };
            
        } catch (any e) {
            return {
                "content": [{
                    "type": "text",
                    "text": "Failed to restart Claude: #e.message#"
                }],
                "isError": true
            };
        }
    }
    
    private struct function reloadTools(required struct args) {
        try {
            // Clear the application scope to force reload
            applicationStop();
            
            return {
                "content": [{
                    "type": "text",
                    "text": "Application reloaded! Tools have been refreshed. You may need to restart Claude Desktop for full MCP reload."
                }]
            };
            
        } catch (any e) {
            return {
                "content": [{
                    "type": "text",
                    "text": "Failed to reload tools: #e.message#"
                }],
                "isError": true
            };
        }
    }
}