<!DOCTYPE html>
<html>
<head>
    <title>Test Tool Execution Logging</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; }
        .success { color: green; font-weight: bold; }
        .error { color: red; font-weight: bold; }
        .section { 
            margin: 20px 0; 
            padding: 15px; 
            border: 1px solid #ddd; 
            border-radius: 5px; 
            background: #f9f9f9;
        }
        h2 { color: #333; }
        pre { background: #f0f0f0; padding: 10px; border-radius: 5px; }
    </style>
</head>
<body>
    <h1>Test Tool Execution Logging</h1>
    
    <div class="section">
        <h2>1. Run the Database Update Script First</h2>
        <p>Make sure to run <a href="update-tool-executions-table.cfm">update-tool-executions-table.cfm</a> to add the missing columns.</p>
    </div>
    
    <cfscript>
    try {
        // Set up session ID for testing
        request.sessionId = "test-session-" & dateTimeFormat(now(), "yyyymmddHHnnss");
        
        writeOutput('<div class="section">');
        writeOutput('<h2>2. Test Successful Tool Execution</h2>');
        
        // Create ToolHandler instance
        toolHandler = new components.ToolHandler();
        
        // Test successful execution
        result1 = toolHandler.executeTool("hello", {name: "Test User"});
        writeOutput('<p class="success">✅ Executed hello tool successfully</p>');
        writeOutput('<pre>' & serializeJson(result1) & '</pre>');
        
        writeOutput('</div>');
        
        writeOutput('<div class="section">');
        writeOutput('<h2>3. Test Failed Tool Execution</h2>');
        
        // Test failed execution (missing required parameter)
        try {
            result2 = toolHandler.executeTool("hello", {});
        } catch (any e) {
            writeOutput('<p class="success">✅ Tool correctly failed with missing parameter</p>');
            writeOutput('<pre>Error: ' & e.message & '</pre>');
        }
        
        writeOutput('</div>');
        
        writeOutput('<div class="section">');
        writeOutput('<h2>4. Test Database Query Tool</h2>');
        
        // Test database query
        result3 = toolHandler.executeTool("queryDatabase", {
            query: "SELECT COUNT(*) as total FROM tool_executions",
            datasource: "mcpcfc_ds"
        });
        writeOutput('<p class="success">✅ Executed queryDatabase tool successfully</p>');
        writeOutput('<pre>' & serializeJson(result3) & '</pre>');
        
        writeOutput('</div>');
        
        // Wait a moment to ensure all logs are written
        sleep(100);
        
        writeOutput('<div class="section">');
        writeOutput('<h2>5. Check Logged Executions</h2>');
        
        // Query the logs
        logs = queryExecute(
            "SELECT 
                id,
                tool_name,
                input_params,
                output_result,
                execution_time,
                session_id,
                success,
                error_message,
                executed_at
            FROM tool_executions 
            WHERE session_id = :sessionId 
            ORDER BY id DESC",
            {sessionId: request.sessionId},
            {datasource: "mcpcfc_ds"}
        );
        
        writeOutput('<p>Found <strong>' & logs.recordCount & '</strong> log entries for this session</p>');
        
        if (logs.recordCount > 0) {
            writeOutput('<h3>Log Entries:</h3>');
            for (log in logs) {
                writeOutput('<div style="margin: 10px 0; padding: 10px; border: 1px solid #ccc; border-radius: 3px;">');
                writeOutput('<strong>Tool:</strong> ' & log.tool_name & '<br>');
                writeOutput('<strong>Success:</strong> ' & (log.success ? '<span class="success">YES</span>' : '<span class="error">NO</span>') & '<br>');
                writeOutput('<strong>Execution Time:</strong> ' & log.execution_time & 'ms<br>');
                if (!isNull(log.error_message) && len(log.error_message)) {
                    writeOutput('<strong>Error:</strong> <span class="error">' & log.error_message & '</span><br>');
                }
                writeOutput('<strong>Input:</strong> <pre>' & log.input_params & '</pre>');
                writeOutput('<strong>Output:</strong> <pre>' & left(log.output_result, 200) & (len(log.output_result) > 200 ? '...' : '') & '</pre>');
                writeOutput('</div>');
            }
        }
        
        writeOutput('</div>');
        
        writeOutput('<div class="section">');
        writeOutput('<h2>6. Recent Tool Executions (All Sessions)</h2>');
        
        // Show recent executions across all sessions
        recentLogs = queryExecute(
            "SELECT 
                tool_name,
                COUNT(*) as execution_count,
                AVG(execution_time) as avg_time,
                SUM(CASE WHEN success = 1 THEN 1 ELSE 0 END) as success_count,
                SUM(CASE WHEN success = 0 THEN 1 ELSE 0 END) as failure_count
            FROM tool_executions 
            WHERE executed_at > DATE_SUB(NOW(), INTERVAL 1 HOUR)
            GROUP BY tool_name
            ORDER BY execution_count DESC",
            {},
            {datasource: "mcpcfc_ds"}
        );
        
        writeOutput('<h3>Tool Usage Statistics (Last Hour):</h3>');
        writeDump(recentLogs);
        
        writeOutput('</div>');
        
    } catch (any e) {
        writeOutput('<div class="section">');
        writeOutput('<p class="error">❌ Error during testing: ' & e.message & '</p>');
        writeDump(e);
        writeOutput('</div>');
    }
    </cfscript>
</body>
</html>