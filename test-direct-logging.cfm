<!DOCTYPE html>
<html>
<head>
    <title>Direct Logging Test</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; }
        .success { color: green; }
        .error { color: red; }
    </style>
</head>
<body>
    <h1>Direct Logging Test</h1>
    
    <cfscript>
    try {
        // First, let's check the table structure
        tableCheck = queryExecute("
            SELECT COLUMN_NAME 
            FROM INFORMATION_SCHEMA.COLUMNS 
            WHERE TABLE_SCHEMA = DATABASE() 
            AND TABLE_NAME = 'tool_executions'
            ORDER BY ORDINAL_POSITION
        ", {}, {datasource: "mcpcfc_ds"});
        
        writeOutput('<h2>Table Columns:</h2>');
        writeDump(tableCheck);
        
        // Try a direct insert
        writeOutput('<h2>Testing Direct Insert:</h2>');
        
        testInsert = queryExecute("
            INSERT INTO tool_executions (
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
                toolName: "direct_test",
                inputParams: '{"test": true}',
                outputResult: '{"result": "success"}',
                executionTime: 123,
                sessionId: "direct-test-session",
                success: true,
                errorMessage: ""
            },
            {datasource: "mcpcfc_ds"}
        );
        
        writeOutput('<p class="success">✅ Direct insert successful!</p>');
        
        // Verify it was inserted
        verifyQuery = queryExecute(
            "SELECT * FROM tool_executions WHERE session_id = 'direct-test-session'",
            {},
            {datasource: "mcpcfc_ds"}
        );
        
        writeOutput('<h2>Verification:</h2>');
        writeDump(verifyQuery);
        
    } catch (any e) {
        writeOutput('<p class="error">❌ Error: ' & e.message & '</p>');
        writeDump(e);
    }
    </cfscript>
</body>
</html>