component displayname="ToolHandler" hint="Handles the execution of registered tools and routes to specialized tool handlers." {
    /**
     * Executes a tool based on the provided tool name and arguments.
     * 
     * @param toolName {string} The name of the tool to execute
     * @param args {struct} The arguments to pass to the tool
     * @return {struct} The result of the tool execution
     */
    public struct function executeTool(required string toolName, required struct args) { //cflint ignore:ARG_HINT_MISSING_SCRIPT
        try {
            switch(arguments.toolName) {
                case "hello":
                    return executeHello(arguments.args);
                    
                case "queryDatabase":
                    return executeQueryDatabase(arguments.args);
                    
                case "generatePDF":
                case "extractPDFText":
                case "mergePDFs":
                    // Route PDF tools to PDFTool component
                    var pdfTool = new mcpcfc.tools.PDFTool();
                    return pdfTool.executeTool(arguments.toolName, arguments.args);
                    
                case "sendEmail":
                case "sendHTMLEmail":
                case "validateEmailAddress":
                    // Route email tools to EmailTool component
                    var emailTool = new mcpcfc.tools.EmailTool();
                    return emailTool.executeTool(arguments.toolName, arguments.args);
                    
                case "codeFormatter":
                case "codeLinter":
                case "testRunner":
                case "generateDocs":
                case "watchFiles":
                    // Route development workflow tools to DevWorkflowTool component
                    var devTool = new mcpcfc.clitools.DevWorkflowTool();
                    
                    // Use invoke to call the method dynamically
                    var result = invoke(devTool, arguments.toolName, arguments.args);
                    
                    // Return result (already in MCP format from DevWorkflowTool)
                    return result;
                    
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
    
    /**
     * Executes the hello tool.
     * 
     * @param args {struct} The arguments to pass to the tool
     * @return {struct} The result of the tool execution
     */
    private struct function executeHello(required struct args) { //cflint ignore:ARG_HINT_MISSING_SCRIPT
        validateRequiredParams(arguments.args, ["name"]);
        
        return {
            "content": [{
                "type": "text",
                "text": "Hello, #arguments.args.name#! This is a ColdFusion MCP server."
            }]
        };
    }
    
    /**
     * Executes the queryDatabase tool.
     * 
     * @param args {struct} The arguments to pass to the tool
     * @return {struct} The result of the tool execution
     */
    private struct function executeQueryDatabase(required struct args) { //cflint ignore:ARG_HINT_MISSING_SCRIPT
        validateRequiredParams(arguments.args, ["query", "datasource"]);
        
        // Security check - only allow SELECT queries in this example
        if (!reFindNoCase("^SELECT", trim(arguments.args.query))) {
            throw(type="SecurityError", message="Only SELECT queries are allowed");
        }
        
        // Execute query
        var queryResult = queryExecute(
            arguments.args.query,
            {},
            {"datasource": arguments.args.datasource}
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
    
    /**
     * Validates that all required parameters are present and not empty.
     * 
     * @param args {struct} The arguments to validate
     * @param required {array} The required parameters
     */
    private void function validateRequiredParams(required struct args, required array required) { //cflint ignore:ARG_HINT_MISSING_SCRIPT
        for (var param in arguments.required) {
            if (!structKeyExists(arguments.args, param) || len(trim(arguments.args[param])) == 0) {
                throw(type="InvalidParams", message="Missing required parameter: #param#");
            }
        }
    }
}