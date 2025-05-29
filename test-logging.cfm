<cfscript>
// Test logging functionality
try {
    // Direct test of logging
    var testTime = getTickCount();
    
    // Insert test record
    queryExecute(
        "INSERT INTO tool_executions (
            tool_name,
            input_params,
            output_result,
            execution_time,
            session_id,
            executed_at
        ) VALUES (
            :toolName,
            :inputParams,
            :outputResult,
            :executionTime,
            :sessionId,
            NOW()
        )",
        {
            toolName: "test_logging",
            inputParams: '{"test": "direct insert"}',
            outputResult: '{"success": true}',
            executionTime: 100,
            sessionId: "test-session-123"
        },
        {datasource: "mcpcfc_ds"}
    );
    
    writeOutput("Test record inserted successfully!");
    
    // Query to verify
    var check = queryExecute(
        "SELECT * FROM tool_executions WHERE tool_name = :toolName ORDER BY id DESC LIMIT 1",
        {toolName: "test_logging"},
        {datasource: "mcpcfc_ds"}
    );
    
    writeDump(check);
    
} catch (any e) {
    writeOutput("Error: " & e.message);
    writeDump(e);
}
</cfscript>