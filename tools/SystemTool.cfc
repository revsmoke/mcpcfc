component displayname="SystemTool" extends="mcpcfc.tools.BaseTool" {
    
    /**
     * System utilities for the MCP server
     */
    
public struct function executeTool(required string toolName, required struct args) {
// Validate tool name format
if ( arrayLen( reMatch("^[a-zA-Z][a-zA-Z0-9]{0,50}$", arguments.toolName) ) EQ 0 ) {
    throw(type="InvalidToolName", message="Tool name contains invalid characters: #arguments.toolName#");
}

// Additional security check - whitelist known tools
var allowedTools = ["restartClaude", "reloadTools"];
if (!arrayFind(allowedTools, arguments.toolName)) {
    throw(type="ToolNotFound", message="Unknown system tool: #arguments.toolName#");
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
       // Use absolute path and validate it's within expected directory
       var basePath = expandPath("/");
       var scriptPath = application.restartScriptPath ?: (basePath & "restart-claude.sh");
       
       // Ensure script is within allowed directory
       if (!scriptPath.startsWith(basePath)) {
           throw(type="SecurityError", message="Script path outside allowed directory");
       }
        
        // Verify script exists and is executable
        if (!fileExists(scriptPath)) {
            throw(type="ScriptNotFound", message="Restart script not found: #scriptPath#");
        }
       
       // Additional security checks
       var fileInfo = getFileInfo(scriptPath);
       if (fileInfo.size > 10000) { // Reasonable size limit
           throw(type="SecurityError", message="Script file too large");
       }
       
       // Validate script name contains only safe characters
       var fileName = listLast(scriptPath, "/\");
       if (!reMatch("^[a-zA-Z0-9\-_.]+\.sh$", fileName)) {
           throw(type="SecurityError", message="Invalid script filename");
       }
        
        // Execute the restart script
        var result = "";
        cfexecute(
            name=scriptPath,
            timeout="10",
            arguments="",
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
        
       // Check if this is safe to do (e.g., not in production)
       if (application.environment == "production") {
           throw(type="UnsafeOperation", message="Tool reload not allowed in production");
       }
       
        // Clear the application scope to force reload
        applicationStop();
        
        // Give a moment for cleanup
        sleep(100);
            
        return {
            "content": [{
                "type": "text",
               "text": "Application reloaded! Tools have been refreshed. Note: This affects all active sessions. You may need to restart Claude Desktop for full MCP reload."
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