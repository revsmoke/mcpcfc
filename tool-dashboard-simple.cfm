<!DOCTYPE html>
<html>
<head>
    <title>Tool Execution Dashboard</title>
    <meta http-equiv="refresh" content="30">
    <style>
        body { 
            font-family: Arial, sans-serif; 
            margin: 0;
            padding: 20px;
            background: #f5f5f5;
        }
        .header {
            background: #2c3e50;
            color: white;
            padding: 20px;
            margin: -20px -20px 20px -20px;
            box-shadow: 0 2px 5px rgba(0,0,0,0.1);
        }
        .header h1 {
            margin: 0;
        }
        .dashboard-grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(300px, 1fr));
            gap: 20px;
            margin-bottom: 20px;
        }
        .stat-card {
            background: white;
            padding: 20px;
            border-radius: 8px;
            box-shadow: 0 2px 5px rgba(0,0,0,0.1);
        }
        .stat-card h3 {
            margin-top: 0;
            color: #34495e;
        }
        .stat-value {
            font-size: 2em;
            font-weight: bold;
            color: #3498db;
        }
        .success-rate {
            color: #27ae60;
        }
        .failure-rate {
            color: #e74c3c;
        }
        .execution-table {
            background: white;
            padding: 20px;
            border-radius: 8px;
            box-shadow: 0 2px 5px rgba(0,0,0,0.1);
            overflow-x: auto;
        }
        table {
            width: 100%;
            border-collapse: collapse;
        }
        th, td {
            padding: 10px;
            text-align: left;
            border-bottom: 1px solid #ecf0f1;
        }
        th {
            background: #34495e;
            color: white;
            font-weight: bold;
        }
        tr:hover {
            background: #f8f9fa;
        }
        .success-badge {
            background: #27ae60;
            color: white;
            padding: 3px 8px;
            border-radius: 3px;
            font-size: 0.8em;
        }
        .failure-badge {
            background: #e74c3c;
            color: white;
            padding: 3px 8px;
            border-radius: 3px;
            font-size: 0.8em;
        }
        .refresh-note {
            text-align: right;
            color: #7f8c8d;
            font-size: 0.9em;
            margin-top: 10px;
        }
        .error-box {
            background: #fee;
            border: 1px solid #fcc;
            padding: 20px;
            border-radius: 8px;
            margin: 20px 0;
        }
    </style>
</head>
<body>
    <div class="header">
        <h1>Tool Execution Dashboard</h1>
        <p style="margin: 5px 0 0 0; opacity: 0.8;">Real-time monitoring of MCPCFC tool executions</p>
    </div>

<cfscript>
try {
    // Get parameters with defaults
    hoursBack = structKeyExists(url, "hours") ? val(url.hours) : 24;
    if (hoursBack <= 0) hoursBack = 24;
    
    // Get overall statistics
    stats = queryExecute("
        SELECT 
            COUNT(*) as total_executions,
            COUNT(DISTINCT tool_name) as unique_tools,
            COUNT(DISTINCT session_id) as unique_sessions,
            AVG(execution_time) as avg_execution_time,
            MAX(execution_time) as max_execution_time,
            SUM(CASE WHEN success = 1 THEN 1 ELSE 0 END) as success_count,
            SUM(CASE WHEN success = 0 THEN 1 ELSE 0 END) as failure_count
        FROM tool_executions
        WHERE executed_at > DATE_SUB(NOW(), INTERVAL :hours HOUR)
    ", {hours: hoursBack}, {datasource: "mcpcfc_ds"});
    
    // Calculate success rate
    successRate = stats.total_executions > 0 
        ? (stats.success_count / stats.total_executions * 100) 
        : 0;
    
    // Display statistics cards
    writeOutput('<div class="dashboard-grid">');
    
    writeOutput('<div class="stat-card">');
    writeOutput('<h3>Total Executions</h3>');
    writeOutput('<div class="stat-value">' & numberFormat(stats.total_executions) & '</div>');
    writeOutput('</div>');
    
    writeOutput('<div class="stat-card">');
    writeOutput('<h3>Success Rate</h3>');
    writeOutput('<div class="stat-value success-rate">' & numberFormat(successRate, "99.9") & '%</div>');
    writeOutput('<div style="margin-top: 10px; font-size: 0.9em; color: ##7f8c8d;">');
    writeOutput('<span style="color: ##27ae60;">✓ ' & numberFormat(stats.success_count) & ' Success</span> | ');
    writeOutput('<span style="color: ##e74c3c;">✗ ' & numberFormat(stats.failure_count) & ' Failed</span>');
    writeOutput('</div>');
    writeOutput('</div>');
    
    writeOutput('<div class="stat-card">');
    writeOutput('<h3>Average Execution Time</h3>');
    avgTime = isNull(stats.avg_execution_time) ? 0 : stats.avg_execution_time;
    writeOutput('<div class="stat-value">' & numberFormat(avgTime, "999") & 'ms</div>');
    maxTime = isNull(stats.max_execution_time) ? 0 : stats.max_execution_time;
    writeOutput('<div style="margin-top: 10px; font-size: 0.9em; color: ##7f8c8d;">');
    writeOutput('Max: ' & numberFormat(maxTime) & 'ms');
    writeOutput('</div>');
    writeOutput('</div>');
    
    writeOutput('<div class="stat-card">');
    writeOutput('<h3>Active Tools/Sessions</h3>');
    writeOutput('<div class="stat-value">' & stats.unique_tools & ' / ' & stats.unique_sessions & '</div>');
    writeOutput('</div>');
    
    writeOutput('</div>');
    
    // Get recent executions
    recentExecutions = queryExecute("
        SELECT 
            tool_name,
            execution_time,
            session_id,
            success,
            error_message,
            executed_at
        FROM tool_executions
        WHERE executed_at > DATE_SUB(NOW(), INTERVAL :hours HOUR)
        ORDER BY executed_at DESC
        LIMIT 20
    ", {hours: hoursBack}, {datasource: "mcpcfc_ds"});
    
    // Display recent executions table
    writeOutput('<div class="execution-table">');
    writeOutput('<h2>Recent Executions</h2>');
    writeOutput('<table>');
    writeOutput('<thead><tr>');
    writeOutput('<th>Time</th>');
    writeOutput('<th>Tool</th>');
    writeOutput('<th>Status</th>');
    writeOutput('<th>Execution Time</th>');
    writeOutput('<th>Session</th>');
    writeOutput('</tr></thead>');
    writeOutput('<tbody>');
    
    for (exec in recentExecutions) {
        writeOutput('<tr>');
        writeOutput('<td>' & dateTimeFormat(exec.executed_at, "mm/dd HH:nn:ss") & '</td>');
        writeOutput('<td><strong>' & exec.tool_name & '</strong></td>');
        writeOutput('<td>');
        if (exec.success) {
            writeOutput('<span class="success-badge">Success</span>');
        } else {
            writeOutput('<span class="failure-badge">Failed</span>');
        }
        writeOutput('</td>');
        writeOutput('<td>' & numberFormat(exec.execution_time) & 'ms</td>');
writeOutput('<td><strong>' & encodeForHtml( exec.tool_name ) & '</strong></td>');
…
writeOutput('<td style="font-size: 0.85em; color: ##7f8c8d;">' & encodeForHtml( left(exec.session_id,20) ) & '...</td>');
    
    writeOutput('</tbody>');
    writeOutput('</table>');
    writeOutput('</div>');
    
    writeOutput('<div class="refresh-note">');
    writeOutput('Page auto-refreshes every 30 seconds | Last updated: ' & timeFormat(now(), "HH:nn:ss"));
    writeOutput('</div>');
    
} catch (any e) {
    writeOutput('<div class="error-box">');
    writeOutput('<h3 style="color: ##c00; margin-top: 0;">Error Loading Dashboard</h3>');
    writeOutput('<p>' & e.message & '</p>');
    writeDump(e);
    writeOutput('</div>');
}
</cfscript>

</body>
</html>