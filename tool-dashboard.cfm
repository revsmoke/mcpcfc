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
        .filter-section {
            background: white;
            padding: 15px;
            border-radius: 8px;
            box-shadow: 0 2px 5px rgba(0,0,0,0.1);
            margin-bottom: 20px;
        }
        .filter-section input, .filter-section select {
            padding: 8px;
            margin-right: 10px;
            border: 1px solid #ddd;
            border-radius: 4px;
        }
    </style>
</head>
<body>
    <div class="header">
        <h1>Tool Execution Dashboard</h1>
        <p style="margin: 5px 0 0 0; opacity: 0.8;">Real-time monitoring of MCPCFC tool executions</p>
    </div>
    
    <cftry>
    <cfscript>
        // Get filter parameters
        param name="url.hours" default="24";
        param name="url.tool" default="";
        param name="url.session" default="";
        
        hoursBack = val(url.hours);
        if (hoursBack <= 0) hoursBack = 24;
        
        // Calculate statistics
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
            #len(url.tool) ? "AND tool_name = :tool" : ""#
            #len(url.session) ? "AND session_id = :session" : ""#
        ", {
            hours: hoursBack,
            tool: url.tool,
            session: url.session
        }, {datasource: "mcpcfc_ds"});
        
        // Get tool-specific statistics
        toolStats = queryExecute("
            SELECT 
                tool_name,
                COUNT(*) as execution_count,
                AVG(execution_time) as avg_time,
                MAX(execution_time) as max_time,
                SUM(CASE WHEN success = 1 THEN 1 ELSE 0 END) as success_count,
                SUM(CASE WHEN success = 0 THEN 1 ELSE 0 END) as failure_count
            FROM tool_executions
            WHERE executed_at > DATE_SUB(NOW(), INTERVAL :hours HOUR)
            #len(url.tool) ? "AND tool_name = :tool" : ""#
            #len(url.session) ? "AND session_id = :session" : ""#
            GROUP BY tool_name
            ORDER BY execution_count DESC
        ", {
            hours: hoursBack,
            tool: url.tool,
            session: url.session
        }, {datasource: "mcpcfc_ds"});
        
        // Calculate success rate
        successRate = stats.total_executions > 0 
            ? (stats.success_count / stats.total_executions * 100) 
            : 0;
    </cfscript>
    
    <!-- Filter Section -->
    <div class="filter-section">
        <form method="get" style="display: inline;">
            <label>Time Period: 
                <select name="hours" onchange="this.form.submit()">
                    <option value="1" <cfif url.hours eq 1>selected</cfif>>Last 1 Hour</option>
                    <option value="6" <cfif url.hours eq 6>selected</cfif>>Last 6 Hours</option>
                    <option value="24" <cfif url.hours eq 24>selected</cfif>>Last 24 Hours</option>
                    <option value="48" <cfif url.hours eq 48>selected</cfif>>Last 48 Hours</option>
                    <option value="168" <cfif url.hours eq 168>selected</cfif>>Last 7 Days</option>
                </select>
            </label>
            
            <label>Tool: 
                <input type="text" name="tool" value="<cfoutput>#encodeForHtmlAttribute(url.tool)#</cfoutput>" 
                       placeholder="Filter by tool name">
            </label>
            
            <label>Session: 
                <input type="text" name="session" value="<cfoutput>#encodeForHtmlAttribute(url.session)#</cfoutput>" 
                       placeholder="Filter by session ID">
            </label>
            
            <button type="submit">Apply Filters</button>
            <a href="tool-dashboard.cfm" style="margin-left: 10px;">Clear Filters</a>
        </form>
    </div>
    
    <!-- Statistics Cards -->
    <div class="dashboard-grid">
        <div class="stat-card">
            <h3>Total Executions</h3>
            <div class="stat-value"><cfoutput>#numberFormat(stats.total_executions)#</cfoutput></div>
        </div>
        
        <div class="stat-card">
            <h3>Success Rate</h3>
            <div class="stat-value success-rate"><cfoutput>#numberFormat(successRate, "99.9")#%</cfoutput></div>
            <div style="margin-top: 10px; font-size: 0.9em; color: ##7f8c8d;">
                <cfoutput>
                    <span style="color: ##27ae60;">✓ #numberFormat(stats.success_count)# Success</span> | 
                    <span style="color: ##e74c3c;">✗ #numberFormat(stats.failure_count)# Failed</span>
                </cfoutput>
            </div>
        </div>
        
        <div class="stat-card">
            <h3>Average Execution Time</h3>
            <div class="stat-value"><cfoutput>#numberFormat(stats.avg_execution_time, "999")#ms</cfoutput></div>
            <div style="margin-top: 10px; font-size: 0.9em; color: ##7f8c8d;">
                Max: <cfoutput>#numberFormat(stats.max_execution_time)#ms</cfoutput>
            </div>
        </div>
        
        <div class="stat-card">
            <h3>Active Tools/Sessions</h3>
            <div class="stat-value"><cfoutput>#stats.unique_tools# / #stats.unique_sessions#</cfoutput></div>
        </div>
    </div>
    
    <!-- Tool Statistics Table -->
    <div class="execution-table">
        <h2>Tool Performance Summary</h2>
        <table>
            <thead>
                <tr>
                    <th>Tool Name</th>
                    <th>Executions</th>
                    <th>Success Rate</th>
                    <th>Avg Time (ms)</th>
                    <th>Max Time (ms)</th>
                </tr>
            </thead>
            <tbody>
                <cfoutput query="toolStats">
                    <cfsilent>
                        <cfset toolSuccessRate = execution_count > 0 ? (success_count / execution_count * 100) : 0>
                    </cfsilent>
                    <tr>
                        <td><strong>#tool_name#</strong></td>
                        <td>#numberFormat(execution_count)#</td>
                        <td>
                            <cfif toolSuccessRate gte 95>
                                <span class="success-badge">#numberFormat(toolSuccessRate, "99.9")#%</span>
                            <cfelseif toolSuccessRate gte 80>
                                <span style="color: ##f39c12; font-weight: bold;">#numberFormat(toolSuccessRate, "99.9")#%</span>
                            <cfelse>
                                <span class="failure-badge">#numberFormat(toolSuccessRate, "99.9")#%</span>
                            </cfif>
                        </td>
                        <td>#numberFormat(avg_time, "999")#</td>
                        <td>#numberFormat(max_time)#</td>
                    </tr>
                </cfoutput>
            </tbody>
        </table>
    </div>
    
    <!-- Recent Executions -->
    <cfscript>
        recentExecutions = queryExecute("
            SELECT 
                id,
                tool_name,
                execution_time,
                session_id,
                success,
                error_message,
                executed_at,
                LEFT(input_params, 100) as input_preview
            FROM tool_executions
            WHERE executed_at > DATE_SUB(NOW(), INTERVAL :hours HOUR)
            #len(url.tool) ? "AND tool_name = :tool" : ""#
            #len(url.session) ? "AND session_id = :session" : ""#
            ORDER BY executed_at DESC
            LIMIT 50
        ", {
            hours: hoursBack,
            tool: url.tool,
            session: url.session
        }, {datasource: "mcpcfc_ds"});
    </cfscript>
    
    <div class="execution-table" style="margin-top: 20px;">
        <h2>Recent Executions</h2>
        <table>
            <thead>
                <tr>
                    <th>Time</th>
                    <th>Tool</th>
                    <th>Status</th>
                    <th>Execution Time</th>
                    <th>Session</th>
                    <th>Input Preview</th>
                </tr>
            </thead>
            <tbody>
                <cfoutput query="recentExecutions">
                    <tr>
                        <td>#dateTimeFormat(executed_at, "mm/dd HH:nn:ss")#</td>
                        <td><strong>#tool_name#</strong></td>
                        <td>
                            <cfif success>
                                <span class="success-badge">Success</span>
                            <cfelse>
                                <span class="failure-badge">Failed</span>
                            </cfif>
                        </td>
                        <td>#numberFormat(execution_time)#ms</td>
                        <td style="font-size: 0.85em; color: ##7f8c8d;">#left(session_id, 20)#...</td>
                        <td style="font-size: 0.85em; color: ##7f8c8d;">
                            #encodeForHtml(input_preview)#...
                        </td>
                    </tr>
                </cfoutput>
            </tbody>
        </table>
    </div>
    
    <div class="refresh-note">
        Page auto-refreshes every 30 seconds | Last updated: <cfoutput>#timeFormat(now(), "HH:nn:ss")#</cfoutput>
    </div>
    
    <cfcatch>
        <div class="stat-card" style="background: #fee; border: 1px solid #fcc;">
            <h3 style="color: #c00;">Error Loading Dashboard</h3>
            <p><cfoutput>#cfcatch.message#</cfoutput></p>
            <cfdump var="#cfcatch#">
        </div>
    </cfcatch>
    </cftry>
</body>
</html>