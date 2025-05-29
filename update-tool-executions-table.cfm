<!DOCTYPE html>
<html>
<head>
    <title>Update Tool Executions Table</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; }
        .success { color: green; }
        .error { color: red; }
        .warning { color: orange; }
        pre { background: #f0f0f0; padding: 10px; border-radius: 5px; }
    </style>
</head>
<body>
    <h1>Update Tool Executions Table</h1>
    
    <cfscript>
    // Main execution wrapper
    try {
        datasourceName = "mcpcfc_ds";
        tableName = "tool_executions";
        
        // Step 1: Validate datasource exists
        writeOutput("<h2>Validating Environment...</h2>");
        
        try {
            // Test datasource connectivity
            testQuery = queryExecute("SELECT 1 as test", {}, {datasource: datasourceName, timeout: 5});
            writeOutput('<p class="success">✅ Datasource "' & datasourceName & '" is available</p>');
        } catch (any dsError) {
            writeOutput('<p class="error">❌ Datasource "' & datasourceName & '" is not available</p>');
            writeOutput('<p class="error">Error: ' & dsError.message & '</p>');
            throw(
                type: "DatabaseConnectionError",
                message: "Cannot proceed without valid datasource connection",
                detail: dsError.message
            );
        }
        
        // Step 2: Validate DATABASE() function and schema
        schemaName = "";
        try {
            schemaQuery = queryExecute("SELECT DATABASE() as current_schema", {}, {datasource: datasourceName});
            if (schemaQuery.recordCount && len(schemaQuery.current_schema)) {
                schemaName = schemaQuery.current_schema;
                writeOutput('<p class="success">✅ Current schema: ' & schemaName & '</p>');
            } else {
                throw(message: "DATABASE() returned empty or null value");
            }
        } catch (any schemaError) {
            writeOutput('<p class="warning">⚠️ Could not determine current schema using DATABASE() function</p>');
            // Fallback: try to get schema from datasource configuration
            try {
                // Alternative approach - check if table exists without schema
                tableExistsQuery = queryExecute("
                    SELECT COUNT(*) as table_count 
                    FROM INFORMATION_SCHEMA.TABLES 
                    WHERE TABLE_NAME = :tableName
                ", {tableName: tableName}, {datasource: datasourceName});
                
                if (tableExistsQuery.table_count > 0) {
                    writeOutput('<p class="success">✅ Table "' & tableName & '" exists</p>');
                } else {
                    throw(message: "Table '" & tableName & "' not found in any schema");
                }
            } catch (any tableError) {
                writeOutput('<p class="error">❌ Cannot verify table existence: ' & tableError.message & '</p>');
                throw(
                    type: "TableValidationError",
                    message: "Cannot proceed without confirming table exists",
                    detail: tableError.message
                );
            }
        }
        
        // Step 3: Check existing columns
        writeOutput("<h2>Checking Existing Columns...</h2>");
        
        hasSuccess = false;
        hasErrorMessage = false;
        
        try {
            columnQuery = "
                SELECT COLUMN_NAME 
                FROM INFORMATION_SCHEMA.COLUMNS 
                WHERE TABLE_NAME = :tableName
                AND COLUMN_NAME IN ('success', 'error_message')
            ";
            
            // Add schema condition if we have it
            if (len(schemaName)) {
                columnQuery &= " AND TABLE_SCHEMA = :schemaName";
                columnCheck = queryExecute(columnQuery, {
                    tableName: tableName,
                    schemaName: schemaName
                }, {datasource: datasourceName});
            } else {
                columnCheck = queryExecute(columnQuery, {
                    tableName: tableName
                }, {datasource: datasourceName});
            }
            
            for (row in columnCheck) {
                if (row.COLUMN_NAME == "success") hasSuccess = true;
                if (row.COLUMN_NAME == "error_message") hasErrorMessage = true;
            }
            
            writeOutput('<p>Current status: success column ' & (hasSuccess ? 'exists' : 'missing') & ', error_message column ' & (hasErrorMessage ? 'exists' : 'missing') & '</p>');
            
        } catch (any columnError) {
            writeOutput('<p class="error">❌ Error checking columns: ' & columnError.message & '</p>');
            // Continue anyway - we'll handle errors when trying to add columns
        }
        
        // Step 4: Add missing columns
        writeOutput("<h2>Updating Table Structure...</h2>");
        
        // Add success column if needed
        if (!hasSuccess) {
            try {
                queryExecute("
                    ALTER TABLE #tableName# 
                    ADD COLUMN success BOOLEAN DEFAULT TRUE
                ", {}, {datasource: datasourceName});
                
                writeOutput('<p class="success">✅ Added success column</p>');
            } catch (any alterError) {
                // Check if it's because column already exists
                if (findNoCase("duplicate column", alterError.message) || findNoCase("already exists", alterError.message)) {
                    writeOutput('<p class="warning">⚠️ Success column already exists (detected during ALTER)</p>');
                } else {
                    writeOutput('<p class="error">❌ Failed to add success column: ' & alterError.message & '</p>');
                }
            }
        } else {
            writeOutput('<p>ℹ️ Success column already exists</p>');
        }
        
        // Add error_message column if needed
        if (!hasErrorMessage) {
            try {
                queryExecute("
                    ALTER TABLE #tableName# 
                    ADD COLUMN error_message TEXT
                ", {}, {datasource: datasourceName});
                
                writeOutput('<p class="success">✅ Added error_message column</p>');
            } catch (any alterError) {
                // Check if it's because column already exists
                if (findNoCase("duplicate column", alterError.message) || findNoCase("already exists", alterError.message)) {
                    writeOutput('<p class="warning">⚠️ Error_message column already exists (detected during ALTER)</p>');
                } else {
                    writeOutput('<p class="error">❌ Failed to add error_message column: ' & alterError.message & '</p>');
                }
            }
        } else {
            writeOutput('<p>ℹ️ Error_message column already exists</p>');
        }
        
        // Step 5: Show final table structure
        writeOutput("<h2>Final Table Structure:</h2>");
        
        try {
            structureQuery = "
                SELECT 
                    COLUMN_NAME,
                    DATA_TYPE,
                    IS_NULLABLE,
                    COLUMN_DEFAULT
                FROM 
                    INFORMATION_SCHEMA.COLUMNS
                WHERE 
                    TABLE_NAME = :tableName
            ";
            
            if (len(schemaName)) {
                structureQuery &= " AND TABLE_SCHEMA = :schemaName";
                tableInfo = queryExecute(structureQuery & " ORDER BY ORDINAL_POSITION", {
                    tableName: tableName,
                    schemaName: schemaName
                }, {datasource: datasourceName});
            } else {
                tableInfo = queryExecute(structureQuery & " ORDER BY ORDINAL_POSITION", {
                    tableName: tableName
                }, {datasource: datasourceName});
            }
            
            writeDump(tableInfo);
            
            writeOutput('<p class="success">✅ Table update process completed!</p>');
            
        } catch (any structureError) {
            writeOutput('<p class="warning">⚠️ Could not retrieve final table structure: ' & structureError.message & '</p>');
        }
        
    } catch (any e) {
        writeOutput('<h2 class="error">Update Process Failed</h2>');
        writeOutput('<p class="error">❌ ' & e.type & ': ' & e.message & '</p>');
        if (structKeyExists(e, "detail") && len(e.detail)) {
            writeOutput('<p class="error">Details: ' & e.detail & '</p>');
        }
        writeDump(var=e, label="Full Error Details");
        
        // Log to application log
        writeLog(
            text="Tool executions table update failed: " & e.message,
            type="error",
            application=true
        );
    }
    </cfscript>
</body>
</html>