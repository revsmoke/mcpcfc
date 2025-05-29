<!DOCTYPE html>
<html>
<head>
    <title>Update Tool Executions Table</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; }
        .success { color: green; }
        .error { color: red; }
        pre { background: #f0f0f0; padding: 10px; border-radius: 5px; }
    </style>
</head>
<body>
    <h1>Update Tool Executions Table</h1>
    
    <cfscript>
    try {
        // Add success column
        queryExecute("
            ALTER TABLE tool_executions 
            ADD COLUMN IF NOT EXISTS success BOOLEAN DEFAULT TRUE
        ", {}, {datasource: "mcpcfc_ds"});
        
        writeOutput('<p class="success">✅ Added success column</p>');
        
        // Add error_message column
        queryExecute("
            ALTER TABLE tool_executions 
            ADD COLUMN IF NOT EXISTS error_message TEXT
        ", {}, {datasource: "mcpcfc_ds"});
        
        writeOutput('<p class="success">✅ Added error_message column</p>');
        
        // Show updated table structure
        tableInfo = queryExecute("
            SELECT 
                COLUMN_NAME,
                DATA_TYPE,
                IS_NULLABLE,
                COLUMN_DEFAULT
            FROM 
                INFORMATION_SCHEMA.COLUMNS
            WHERE 
                TABLE_SCHEMA = DATABASE() 
                AND TABLE_NAME = 'tool_executions'
            ORDER BY 
                ORDINAL_POSITION
        ", {}, {datasource: "mcpcfc_ds"});
        
        writeOutput('<h2>Updated Table Structure:</h2>');
        writeDump(tableInfo);
        
    } catch (any e) {
        writeOutput('<p class="error">❌ Error: ' & e.message & '</p>');
        writeDump(e);
    }
    </cfscript>
</body>
</html></content>
</invoke>