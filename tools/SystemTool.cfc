component displayname="SystemTool" {
    
    /**
     * System utilities for the MCP server
     */
    
public struct function executeTool(required string toolName, required struct args) {
    // Validate tool name format
    if (!reMatch("^[a-zA-Z][a-zA-Z0-9]*$", arguments.toolName)) {
        throw(type="InvalidToolName", message="Tool name contains invalid characters: #arguments.toolName#");
    }
    
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
        // Get script path from application scope or use default
        var scriptPath = application.restartScriptPath ?: expandPath("../restart-claude.sh");
        
        // Verify script exists and is executable
        if (!fileExists(scriptPath)) {
            throw(type="ScriptNotFound", message="Restart script not found: #scriptPath#");
        }
        
         // Execute the restart script
        var result = "";
         cfexecute(
            name=scriptPath,
             timeout="10"
            variable="result"
         );
        
        // Log the execution result
        writeLog(text="Restart script executed: #result#", type="info", file="SystemTool");
            
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
        // Log the reload operation
        writeLog(text="Tools reload initiated by user", type="info", file="SystemTool");
        
         // Clear the application scope to force reload
         applicationStop();
        
        // Give a moment for cleanup
        sleep(100);
            
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