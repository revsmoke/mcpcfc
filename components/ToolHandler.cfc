component displayname="ToolHandler" {
    
    public struct function executeTool(required string toolName, required struct args) {
        try {
            switch(arguments.toolName) {
                case "hello":
                    return executeHello(arguments.args);
                    
                case "queryDatabase":
                    return executeQueryDatabase(arguments.args);
                    
                default:
                    throw(type="ToolNotFound", message="Unknown tool: #arguments.toolName#");
            }
            
        } catch (any e) {
            return {
                "content": [{
                    "type": "text",
                    "text": "Error executing tool: #e.message#"
                }],
                "isError": true
            };
        }
    }
    
    private struct function executeHello(required struct args) {
        validateRequiredParams(arguments.args, ["name"]);
        
        return {
            "content": [{
                "type": "text",
                "text": "Hello, #arguments.args.name#! This is a ColdFusion MCP server."
            }]
        };
    }
    
    private struct function executeQueryDatabase(required struct args) {
        validateRequiredParams(arguments.args, ["query", "datasource"]);
        
        // Security check - only allow SELECT queries in this example
        if (!reFindNoCase("^SELECT", trim(arguments.args.query))) {
            throw(type="SecurityError", message="Only SELECT queries are allowed");
        }
        
        // Execute query
        var queryResult = queryExecute(
            arguments.args.query,
            {},
            {datasource: arguments.args.datasource}
        );        
        // Convert query to array of structs
        var results = [];
        for (var row in queryResult) {
            arrayAppend(results, row);
        }
        
        return {
            "content": [{
                "type": "text",
                "text": serializeJson({
                    "recordCount": queryResult.recordCount,
                    "columns": queryResult.columnList,
                    "data": results
                })
            }]
        };
    }
    
    private void function validateRequiredParams(required struct args, required array required) {
        for (var param in arguments.required) {
            if (!structKeyExists(arguments.args, param) || len(trim(arguments.args[param])) == 0) {
                throw(type="InvalidParams", message="Missing required parameter: #param#");
            }
        }
    }
}