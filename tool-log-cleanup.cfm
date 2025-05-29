<!DOCTYPE html>
<html>
<head>
    <title>Tool Execution Log Cleanup</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; }
        .success { color: green; font-weight: bold; }
        .error { color: red; font-weight: bold; }
        .warning { color: orange; font-weight: bold; }
        .section { 
            margin: 20px 0; 
            padding: 15px; 
            border: 1px solid #ddd; 
            border-radius: 5px; 
            background: #f9f9f9;
        }
        form { margin: 20px 0; }
        input[type="number"] { width: 100px; padding: 5px; }
        button { 
            padding: 10px 20px; 
            background: #3498db; 
            color: white; 
            border: none; 
            border-radius: 4px;
            cursor: pointer;
        }
        button:hover { background: #2980b9; }
        .danger-button {
            background: #e74c3c;
        }
        .danger-button:hover {
            background: #c0392b;
        }
    </style>
</head>
<body>
    <h1>Tool Execution Log Cleanup</h1>
    
    <cfscript>
    // Check if form was submitted
    if (structKeyExists(form, "action")) {
        try {
            var deletedCount = 0;
            
            switch(form.action) {
                case "cleanup_old":
                    var daysToKeep = val(form.daysToKeep);
                    if (daysToKeep < 1) daysToKeep = 30;
                    
                    // Delete old records
                    var result = queryExecute("
                        DELETE FROM tool_executions 
                        WHERE executed_at < DATE_SUB(NOW(), INTERVAL :days DAY)
                    ", {
                        days: daysToKeep
                    }, {
                        datasource: "mcpcfc_ds",
                        result: "deleteResult"
                    });
                    
                    deletedCount = deleteResult.recordCount;
                    writeOutput('<div class="section"><p class="success">✅ Deleted ' & deletedCount & ' records older than ' & daysToKeep & ' days</p></div>');
                    break;
                    
                case "cleanup_errors":
                    // Delete failed executions
                    var result = queryExecute("
                        DELETE FROM tool_executions 
                        WHERE success = 0
                    ", {}, {
                        datasource: "mcpcfc_ds",
                        result: "deleteResult"
                    });
                    
                    deletedCount = deleteResult.recordCount;
                    writeOutput('<div class="section"><p class="success">✅ Deleted ' & deletedCount & ' failed execution records</p></div>');
                    break;
                    
                case "cleanup_session":
                    // Delete specific session
                    if (len(trim(form.sessionId))) {
                        var result = queryExecute("
                            DELETE FROM tool_executions 
                            WHERE session_id = :sessionId
                        ", {
                            sessionId: form.sessionId
                        }, {
                            datasource: "mcpcfc_ds",
                            result: "deleteResult"
                        });
                        
                        deletedCount = deleteResult.recordCount;
                        writeOutput('<div class="section"><p class="success">✅ Deleted ' & deletedCount & ' records for session: ' & encodeForHtml(form.sessionId) & '</p></div>');
                    }
                    break;
            }
            
        } catch (any e) {
            writeOutput('<div class="section"><p class="error">❌ Error: ' & e.message & '</p></div>');
        }
    }
    
    // Get current statistics
    var stats = queryExecute("
        SELECT 
            COUNT(*) as total_records,
            MIN(executed_at) as oldest_record,
            MAX(executed_at) as newest_record,
            SUM(CASE WHEN success = 0 THEN 1 ELSE 0 END) as failed_count,
            COUNT(DISTINCT session_id) as session_count
        FROM tool_executions
    ", {}, {datasource: "mcpcfc_ds"});
    
    // Get size by age
    var ageStats = queryExecute("
        SELECT 
            CASE 
                WHEN executed_at > DATE_SUB(NOW(), INTERVAL 1 DAY) THEN '< 1 day'
                WHEN executed_at > DATE_SUB(NOW(), INTERVAL 7 DAY) THEN '1-7 days'
                WHEN executed_at > DATE_SUB(NOW(), INTERVAL 30 DAY) THEN '7-30 days'
                WHEN executed_at > DATE_SUB(NOW(), INTERVAL 90 DAY) THEN '30-90 days'
                ELSE '> 90 days'
            END as age_group,
            COUNT(*) as record_count
        FROM tool_executions
        GROUP BY age_group
        ORDER BY 
            CASE age_group
                WHEN '< 1 day' THEN 1
                WHEN '1-7 days' THEN 2
                WHEN '7-30 days' THEN 3
                WHEN '30-90 days' THEN 4
                ELSE 5
            END
    ", {}, {datasource: "mcpcfc_ds"});
    </cfscript>
    
    <div class="section">
        <h2>Current Statistics</h2>
        <p><strong>Total Records:</strong> <cfoutput>#numberFormat(stats.total_records)#</cfoutput></p>
        <p><strong>Failed Executions:</strong> <cfoutput>#numberFormat(stats.failed_count)#</cfoutput></p>
        <p><strong>Unique Sessions:</strong> <cfoutput>#numberFormat(stats.session_count)#</cfoutput></p>
        <cfif stats.total_records gt 0>
            <p><strong>Oldest Record:</strong> <cfoutput>#dateTimeFormat(stats.oldest_record, "mm/dd/yyyy HH:nn:ss")#</cfoutput></p>
            <p><strong>Newest Record:</strong> <cfoutput>#dateTimeFormat(stats.newest_record, "mm/dd/yyyy HH:nn:ss")#</cfoutput></p>
        </cfif>
    </div>
    
    <div class="section">
        <h2>Records by Age</h2>
        <table style="width: 100%; border-collapse: collapse;">
            <tr style="background: #34495e; color: white;">
                <th style="padding: 10px; text-align: left;">Age Group</th>
                <th style="padding: 10px; text-align: right;">Record Count</th>
            </tr>
            <cfoutput query="ageStats">
                <tr style="border-bottom: 1px solid ##ddd;">
                    <td style="padding: 8px;">#age_group#</td>
                    <td style="padding: 8px; text-align: right;">#numberFormat(record_count)#</td>
                </tr>
            </cfoutput>
        </table>
    </div>
    
    <div class="section">
        <h2>Cleanup Options</h2>
        
        <form method="post" onsubmit="return confirm('Are you sure you want to delete these records?');">
            <h3>Delete Old Records</h3>
            <p>Delete records older than 
                <input type="number" name="daysToKeep" value="30" min="1" max="365"> days
            </p>
            <input type="hidden" name="action" value="cleanup_old">
            <button type="submit">Delete Old Records</button>
        </form>
        
        <form method="post" onsubmit="return confirm('Are you sure you want to delete all failed execution records?');">
            <h3>Delete Failed Executions</h3>
            <p>Delete all <cfoutput>#numberFormat(stats.failed_count)#</cfoutput> failed execution records</p>
            <input type="hidden" name="action" value="cleanup_errors">
            <button type="submit" class="danger-button">Delete Failed Records</button>
        </form>
        
        <form method="post" onsubmit="return confirm('Are you sure you want to delete all records for this session?');">
            <h3>Delete by Session ID</h3>
            <p>Session ID: <input type="text" name="sessionId" placeholder="Enter session ID" style="width: 300px;"></p>
            <input type="hidden" name="action" value="cleanup_session">
            <button type="submit">Delete Session Records</button>
        </form>
    </div>
    
    <div class="section">
        <p class="warning">⚠️ Warning: Deletion operations cannot be undone. Always backup your data before performing cleanup operations.</p>
    </div>
    
</body>
</html>