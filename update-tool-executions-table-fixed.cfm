<!DOCTYPE html>
<html>
<head>
    <title>Update Tool Executions Table - Fixed</title>
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
        // First, check if columns exist
        var columnCheck = queryExecute("
            SELECT COLUMN_NAME 
            FROM INFORMATION_SCHEMA.COLUMNS 
            WHERE TABLE_SCHEMA = DATABASE() 
            AND TABLE_NAME = 'tool_executions'
            AND COLUMN_NAME IN ('success', 'error_message')
        ", {}, {datasource: "mcpcfc_ds"});
        
        var hasSuccess = false;
        var hasErrorMessage = false;
        
        for (var row in columnCheck) {
            if (row.COLUMN_NAME == "success") hasSuccess = true;
            if (row.COLUMN_NAME == "error_message") hasErrorMessage = true;
        }
        
        // Add success column if it doesn't exist
        if (!hasSuccess) {
            queryExecute("
                ALTER TABLE tool_executions 
                ADD COLUMN success BOOLEAN DEFAULT TRUE
            ", {}, {datasource: "mcpcfc_ds"});
            
            writeOutput('<p class="success">✅ Added success column</p>');
        } else {
            writeOutput('<p>ℹ️ Success column already exists</p>');
        }
        
        // Add error_message column if it doesn't exist
        if (!hasErrorMessage) {
            queryExecute("
                ALTER TABLE tool_executions 
                ADD COLUMN error_message TEXT
            ", {}, {datasource: "mcpcfc_ds"});
            
            writeOutput('<p class="success">✅ Added error_message column</p>');
        } else {
            writeOutput('<p>ℹ️ Error_message column already exists</p>');
        }
        
        // Show updated table structure
        var tableInfo = queryExecute("
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
        
        writeOutput('<h2>Current Table Structure:</h2>');
        writeDump(tableInfo);
        
        writeOutput('<p class="success">✅ Table update completed successfully!</p>');
        
    } catch (any e) {
        writeOutput('<p class="error">❌ Error: ' & e.message & '</p>');
        writeDump(e);
    }
    </cfscript>
</body>
</html>