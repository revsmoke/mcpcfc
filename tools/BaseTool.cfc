component displayname="BaseTool" hint="Base class for all MCP tools" {
    
    /**
     * Base class that provides common functionality for all MCP tools
     * This centralizes shared functionality like parameter validation
     */
    
    /**
     * Validate that all required parameters are present and non-empty
     * 
     * @param args The arguments struct to validate
     * @param required Array of required parameter names
     * @throws InvalidParams when a required parameter is missing or empty
     */
private void function validateRequiredParams(
    required struct args,
    required array requiredParams
) {
    for (var param in arguments.requiredParams) {
            if (!structKeyExists(arguments.args, param)) {
                throw(type="InvalidParams", message="Missing required parameter: #param#");
            }
            
            // Handle different data types appropriately
            var paramValue = arguments.args[param];

            // Treat explicit null as missing
            if ( isNull( paramValue ) ) {
                throw( type = "InvalidParams"
                     , message = "Null value for parameter: #param#" );
            }
            
            if (isArray(paramValue)) {
                // For arrays, check if empty
                if (arrayLen(paramValue) == 0) {
                    throw(type="InvalidParams", message="Empty array for parameter: #param#");
                }
            } else if (isStruct(paramValue)) {
                // For structs, check if empty
                if (structCount(paramValue) == 0) {
                    throw(type="InvalidParams", message="Empty struct for parameter: #param#");
                }
            } else if (isSimpleValue(paramValue)) {
                // For simple values, check if empty string
                if (len(trim(paramValue)) == 0) {
                    throw(type="InvalidParams", message="Empty value for parameter: #param#");
                }
            }
            // Other complex types (like queries, components) are considered valid if they exist
        }
    }
    
    /**
     * Convert a tool execution result to MCP format
     * This provides a consistent response format across all tools
     * 
     * @param content The content to return (string or array of content items)
     * @param isError Whether this is an error response
     * @return struct in MCP response format
     */
    private struct function createMCPResponse(required any content, boolean isError = false) {
        var response = {
            "isError": arguments.isError
        };
        
        // Handle different content types
        if (isArray(arguments.content)) {
            response["content"] = arguments.content;
        } else if (isStruct(arguments.content)) {
            // If it's already a properly formatted content item
            if (structKeyExists(arguments.content, "type") && structKeyExists(arguments.content, "text")) {
                response["content"] = [arguments.content];
            } else {
                // Convert struct to text representation
                response["content"] = [{
                    "type": "text",
                    "text": serializeJSON(arguments.content)
                }];
            }
        } else {
            // Simple values become text content
            response["content"] = [{
                "type": "text",
                "text": toString(arguments.content)
            }];
        }
        
        return response;
    }
    
    /**
     * Create an error response in MCP format
     * 
     * @param errorMessage The error message to return
     * @param errorDetail Optional additional error details
     * @return struct in MCP error response format
     */
    private struct function createErrorResponse(required string errorMessage, string errorDetail = "") {
        var message = arguments.errorMessage;
        if (len(arguments.errorDetail)) {
            message &= " - " & arguments.errorDetail;
        }
        
        return createMCPResponse(message, true);
    }
    
    /**
     * Abstract method that must be implemented by subclasses
     * 
     * @param toolName The name of the tool to execute
     * @param args The arguments to pass to the tool
     * @return struct containing the execution result
     */
    public struct function executeTool(required string toolName, required struct args) {
        throw(type="MethodNotImplemented", 
              message="The executeTool method must be implemented by the subclass",
              detail="Tool classes extending BaseTool must provide their own executeTool implementation");
    }
    
    /**
     * Get a safe file path within the application's temp directory
     * 
     * @param filename The filename to create a path for
     * @param subdirectory Optional subdirectory within temp
     * @return string The full safe file path
     */
    private string function getSafeTempPath(required string filename, string subdirectory = "") {
        var tempDir = expandPath("/mcpcfc/temp/");
        
        if (len(arguments.subdirectory)) {
            tempDir &= arguments.subdirectory & "/";
            // Ensure subdirectory exists
            if (!directoryExists(tempDir)) {
                directoryCreate(tempDir);
            }
        }
        
// Strip all traversal sequences such as ../, ..\, ....//, %2e%2e%2f, etc.
var safeFilename = rereplacenocase(
    urldecode( arguments.filename ),
    "[^A-Za-z0-9_.-]",      // allow only safe filename chars
    "",
    "all"
);
// defensive: remove any remaining slashes/back-slashes
safeFilename = replace( safeFilename, "/", "", "all" );
safeFilename = replace( safeFilename, "\", "", "all" );
        
        return tempDir & safeFilename;
    }
    
    /**
     * Log tool execution for debugging and monitoring
     * 
     * @param toolName The name of the tool being executed
     * @param args The arguments passed to the tool
     * @param result The result of the execution
     * @param executionTime Time taken to execute in milliseconds
     */
    private void function logToolExecution(
        required string toolName, 
        required struct args, 
        struct result = {}, 
        numeric executionTime = 0
    ) {
        try {
            cflog(
                application = true,
                file = "mcpcfc_tools",
                text = "Tool: #arguments.toolName#, Time: #arguments.executionTime#ms, Args: #serializeJSON(arguments.args)#"
            );
        } catch (any e) {
            // Logging should not cause tool execution to fail
        }
    }
}