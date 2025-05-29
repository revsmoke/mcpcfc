component displayname="ToolHandler" hint="Handles the execution of registered tools and routes to specialized tool handlers." {
    /**
     * Executes a tool based on the provided tool name and arguments.
     * 
     * @param toolName {string} The name of the tool to execute
     * @param args {struct} The arguments to pass to the tool
     * @return {struct} The result of the tool execution
     */
    public struct function executeTool(required string toolName, required struct args) { //cflint ignore:ARG_HINT_MISSING_SCRIPT
        var startTime = getTickCount();
        var result = {};
        var executionTime = 0;
        var sessionId = structKeyExists(request, "sessionId") ? request.sessionId : "";
        
        try {
            switch(arguments.toolName) {
                case "hello":
                    result = executeHello(arguments.args);
                    break;
                    
                case "queryDatabase":
                    result = executeQueryDatabase(arguments.args);
                    break;
                    
                case "generatePDF":
                case "extractPDFText":
                case "mergePDFs":
                    // Route PDF tools to PDFTool component
                    var pdfTool = new mcpcfc.tools.PDFTool();
                    result = pdfTool.executeTool(arguments.toolName, arguments.args);
                    break;
                    
                case "sendEmail":
                case "sendHTMLEmail":
                case "validateEmailAddress":
                    // Route email tools to EmailTool component
                    var emailTool = new mcpcfc.tools.EmailTool();
                    result = emailTool.executeTool(arguments.toolName, arguments.args);
                    break;
                    
                case "executeCode":
                case "evaluateExpression":
                case "inspectVariable":
                case "testSnippet":
                    // Route REPL tools to REPLTool component
                    var replTool = new mcpcfc.clitools.REPLTool();
                    result = invoke(replTool, arguments.toolName, arguments.args);
                    result = convertToMCPResponse(result);
                    break;
                    
                case "serverStatus":
                case "configManager":
                case "clearCache":
                case "logStreamer":
                case "moduleManager":
                    // Route server management tools to ServerManagementTool component
                    var serverTool = new mcpcfc.clitools.ServerManagementTool();
                    result = invoke(serverTool, arguments.toolName, arguments.args);
                    result = convertToMCPResponse(result);
                    break;
                    
                case "packageInstaller":
                case "packageList":
                case "packageSearch":
                case "packageUpdate":
                case "packageRemove":
                    // Route package management tools to PackageManagerTool component
                    var packageTool = new mcpcfc.clitools.PackageManagerTool();
                    result = invoke(packageTool, arguments.toolName, arguments.args);
                    result = convertToMCPResponse(result);
                    break;
                    
                case "codeFormatter":
                case "codeLinter":
                case "testRunner":
                case "generateDocs":
                case "watchFiles":
                case "stopWatcher":
                case "getWatcherStatus":
                    // Route development workflow tools to DevWorkflowTool component
                    var devTool = new mcpcfc.clitools.DevWorkflowTool();
                    
                    // Use invoke to call the method dynamically
                    result = invoke(devTool, arguments.toolName, arguments.args);
                    
                    // Return result (already in MCP format from DevWorkflowTool)
                    break;
                    
                default:
                    throw(type="ToolNotFound", message="Unknown tool: #arguments.toolName#");
            }
            
            // Calculate execution time
            executionTime = getTickCount() - startTime;
            
            // Log successful execution
            logToolExecution(
                toolName: arguments.toolName,
                inputParams: arguments.args,
                outputResult: result,
                executionTime: executionTime,
                sessionId: sessionId,
                success: true
            );
            
            return result;
            
        } catch (any e) {
            // Calculate execution time even for errors
            executionTime = getTickCount() - startTime;
            
            result = {
                "content": [{
                    "type": "text",
                    "text": "Error executing tool: #e.message#"
                }],
                "isError": true
            };
            
            // Log failed execution
            logToolExecution(
                toolName: arguments.toolName,
                inputParams: arguments.args,
                outputResult: result,
                executionTime: executionTime,
                sessionId: sessionId,
                success: false,
                errorMessage: e.message
            );
            
            return result;
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
// Parameter-ise and only allow a restricted set of clauses.
// Example: whitelist columns & table, or accept a placeholder query
// and supply parameters via args.params (array/struct), e.g.:
if (reFindNoCase("[;]", arguments.args.query)) {
    throw(type="SecurityError", message="Multiple statements are not allowed");
}
var queryResult = queryExecute(
    arguments.args.query,
    arguments.args.params ?: {},           // named / positional params
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
    
    /**
     * Converts a tool's native response format to MCP response format
     * 
     * @param result {struct} The tool's response
     * @return {struct} The MCP-formatted response
     */
    private struct function convertToMCPResponse(required struct result) {
        // If it already has the correct format, return as-is
        if (structKeyExists(arguments.result, "content") && isArray(arguments.result.content)) {
            return arguments.result;
        }
        
        // Convert to MCP format
        var text = "";
        
        // If there's an error, format the error message
        if (structKeyExists(arguments.result, "error") && len(arguments.result.error)) {
            text = "Error: " & arguments.result.error;
            if (structKeyExists(arguments.result, "errorDetail") && len(arguments.result.errorDetail)) {
                text &= chr(10) & "Details: " & arguments.result.errorDetail;
            }
        } else {
            // Convert the result to a formatted text representation
            text = serializeJson(arguments.result);
        }
        
        return {
            "content": [{
                "type": "text",
                "text": text
            }],
            "isError": structKeyExists(arguments.result, "error") && len(arguments.result.error)
        };
    }
    
    /**
     * Logs tool execution to the database
     * 
     * @param toolName {string} The name of the tool
     * @param inputParams {struct} The input parameters
     * @param outputResult {struct} The output result
     * @param executionTime {numeric} The execution time in milliseconds
     * @param sessionId {string} The session ID
     * @param success {boolean} Whether the execution was successful
     * @param errorMessage {string} Error message if execution failed
     */
    private void function logToolExecution(
        required string toolName,
        required struct inputParams,
        required struct outputResult,
        required numeric executionTime,
        string sessionId = "",
        boolean success = true,
        string errorMessage = ""
    ) {
        try {
            // Serialize input and output for storage
            var inputJson = serializeJson(arguments.inputParams);
            var outputJson = serializeJson(arguments.outputResult);
            
            // Insert log entry
            queryExecute(
                "INSERT INTO tool_executions (
                    tool_name,
                    input_params,
                    output_result,
                    execution_time,
                    session_id,
                    success,
                    error_message,
                    executed_at
                ) VALUES (
                    :toolName,
                    :inputParams,
                    :outputResult,
                    :executionTime,
                    :sessionId,
                    :success,
                    :errorMessage,
                    NOW()
                )",
                {
                    toolName: arguments.toolName,
                    inputParams: inputJson,
                    outputResult: outputJson,
                    executionTime: arguments.executionTime,
                    sessionId: arguments.sessionId,
                    success: arguments.success ? 1 : 0,
                    errorMessage: arguments.errorMessage
                },
                {datasource: "mcpcfc_ds"}
            );
            
        } catch (any e) {
            // Log the error but don't throw - we don't want logging failures to break tool execution
            writeLog(
                text="Failed to log tool execution: #e.message# - Tool: #arguments.toolName#",
                type="error",
                application=true
            );
        }
    }
}