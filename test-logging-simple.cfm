<!DOCTYPE html>
<html>
<head>
    <title>Simple Logging Test</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; }
        .success { color: green; }
        .error { color: red; }
    </style>
</head>
<body>
    <h1>Simple Tool Logging Test</h1>
    
    <cfscript>
    try {
        // Test direct logging
        request.sessionId = "simple-test-" & dateTimeFormat(now(), "yyyymmddHHnnss");
        
        // Create handler and test
        toolHandler = new components.ToolHandler();
        result = toolHandler.executeTool("hello", {name: "Simple Test"});
        
        writeOutput('<p class="success">✅ Tool executed successfully!</p>');
        writeOutput('<pre>Result: ' & serializeJson(result) & '</pre>');
        
        // Check if it was logged
        sleep(100); // Wait for log to be written
        
        logCheck = queryExecute(
            "SELECT * FROM tool_executions WHERE session_id = :sessionId",
            {sessionId: request.sessionId},
            {datasource: "mcpcfc_ds"}
        );
        
        writeOutput('<h2>Log Entries Found: ' & logCheck.recordCount & '</h2>');
        
        if (logCheck.recordCount > 0) {
            writeOutput('<p class="success">✅ Logging is working!</p>');
            writeDump(logCheck);
        } else {
            writeOutput('<p class="error">❌ No log entries found</p>');
        }
        
    } catch (any e) {
        writeOutput('<p class="error">❌ Error: ' & e.message & '</p>');
        writeDump(e);
    }
    </cfscript>
</body>
</html>