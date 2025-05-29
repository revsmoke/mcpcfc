<!DOCTYPE html>
<html>
<head>
    <title>File Watcher Test</title>
    <style>
        body { 
            font-family: Arial, sans-serif; 
            margin: 20px;
            background: #f5f5f5;
        }
        .container {
            max-width: 1200px;
            margin: 0 auto;
        }
        .section {
            background: white;
            padding: 20px;
            margin-bottom: 20px;
            border-radius: 8px;
            box-shadow: 0 2px 5px rgba(0,0,0,0.1);
        }
        h1 {
            color: #333;
            margin-top: 0;
        }
        h2 {
            color: #555;
            margin-top: 0;
        }
        .button-group {
            margin: 10px 0;
        }
        button {
            background: #3498db;
            color: white;
            border: none;
            padding: 10px 20px;
            border-radius: 5px;
            cursor: pointer;
            margin-right: 10px;
        }
        button:hover {
            background: #2980b9;
        }
        button.danger {
            background: #e74c3c;
        }
        button.danger:hover {
            background: #c0392b;
        }
        .success {
            color: #27ae60;
            font-weight: bold;
        }
        .error {
            color: #e74c3c;
            font-weight: bold;
        }
        .warning {
            color: #f39c12;
            font-weight: bold;
        }
        .watcher-card {
            background: #f8f9fa;
            border: 1px solid #dee2e6;
            padding: 15px;
            margin: 10px 0;
            border-radius: 5px;
        }
        .watcher-active {
            border-left: 5px solid #27ae60;
        }
        .watcher-inactive {
            border-left: 5px solid #e74c3c;
        }
        pre {
            background: #f0f0f0;
            padding: 10px;
            border-radius: 5px;
            overflow-x: auto;
        }
        .test-file-section {
            background: #fffbf0;
            border: 1px dashed #f39c12;
            padding: 15px;
            margin: 10px 0;
            border-radius: 5px;
        }
        .log-viewer {
            background: #2c3e50;
            color: #ecf0f1;
            padding: 15px;
            border-radius: 5px;
            font-family: 'Courier New', monospace;
            font-size: 12px;
            max-height: 300px;
            overflow-y: auto;
        }
    </style>
</head>
<body>
    <div class="container">
        <h1>File Watcher Test</h1>
        
        <!-- Start Watcher Section -->
        <div class="section">
            <h2>Start a File Watcher</h2>
<cfscript>
// Generate CSRF token if not exists
if (!structKeyExists(session, "csrfToken")) {
    session.csrfToken = hash(createUUID() & now(), "SHA-256");
}
</cfscript>

 <form method="post">
     <input type="hidden" name="action" value="start">
    <input type="hidden" name="csrfToken" value="<cfoutput>#session.csrfToken#</cfoutput>">
                
                <p>
                    <label>Paths to watch (comma-separated):</label><br>
                    <input type="text" name="paths" value="./tests" style="width: 500px;">
                </p>
                
                <p>
                    <label>File extensions (comma-separated):</label><br>
                    <input type="text" name="extensions" value="cfc,cfm" style="width: 300px;">
                </p>
                
                <p>
                    <label>Action on change:</label><br>
                    <select name="watchAction">
                        <option value="test">Run Tests</option>
                        <option value="lint">Lint Changed Files</option>
                        <option value="reload">Reload Application</option>
                    </select>
                </p>
                
                <p>
                    <label>Debounce (ms):</label><br>
                    <input type="number" name="debounce" value="1000" min="100" max="10000">
                </p>
                
                <button type="submit">Start Watching</button>
            </form>
        </div>
        
        <cfif structKeyExists(form, "action")>
            <cfscript>
            try {
                toolHandler = new components.ToolHandler();
    // Add CSRF token validation
    if (!structKeyExists(session, "csrfToken") || !structKeyExists(form, "csrfToken") || 
        session.csrfToken != form.csrfToken) {
        throw(type="SecurityError", message="Invalid CSRF token");
    }
    
     // Start a file watcher
    // Validate and sanitize input
    if (!len(trim(form.paths))) {
        throw(type="ValidationError", message="Paths cannot be empty");
    }
    paths = listToArray(form.paths).filter(function(path) {
        return len(trim(path)) > 0 && !find("..", path);
    });
    extensions = listToArray(form.extensions).filter(function(ext) {
        return reMatch("^[a-zA-Z0-9]{1,10}$", trim(ext)).len() > 0;
    });
     
    if (!arrayLen(paths) || !arrayLen(extensions)) {
        throw(type="ValidationError", message="Valid paths and extensions required");
    }
    
    result = toolHandler.executeTool("watchFiles", {
         paths: paths,
         extensions: extensions,
         action: form.watchAction,
        debounce: max(100, min(10000, val(form.debounce)))
     });
     
    if (structKeyExists(result, "content") && arrayLen(result.content) > 0) {
        try {
            watchResult = deserializeJson(result.content[1].text);
        } catch (any jsonError) {
            throw(type="DataError", message="Invalid JSON response from tool");
        }
 
 } catch (any e) {
     writeOutput('<div class="section">');
    writeOutput('<p class="error">❌ Error: ' & encodeForHTML(e.message) & '</p>');
    // Log error securely instead of exposing via writeDump
    writeLog(file="application", text="File watcher error: #e.message# #e.detail#");
     writeOutput('</div>');
 }
                            } else {
                                writeOutput('<p class="error">❌ ' & watchResult.error & '</p>');
                            }
                        }
                        writeOutput('</div>');
                        break;
                        
                    case "stop":
                        // Stop a file watcher
                        result = toolHandler.executeTool("stopWatcher", {
                            watcherId: form.watcherId
                        });
                        
                        writeOutput('<div class="section">');
                        if (structKeyExists(result, "content") && arrayLen(result.content) > 0) {
                            stopResult = deserializeJson(result.content[1].text);
                            if (stopResult.success) {
                                writeOutput('<p class="success">✅ ' & stopResult.message & '</p>');
                            } else {
                                writeOutput('<p class="error">❌ ' & stopResult.error & '</p>');
                            }
                        }
                        writeOutput('</div>');
                        break;
                }
                
            } catch (any e) {
                writeOutput('<div class="section">');
                writeOutput('<p class="error">❌ Error: ' & e.message & '</p>');
                writeDump(e);
                writeOutput('</div>');
            }
            </cfscript>
        </cfif>
        
        <!-- Active Watchers Section -->
        <div class="section">
            <h2>Active File Watchers</h2>
            
            <cfscript>
            try {
                toolHandler = new components.ToolHandler();
                statusResult = toolHandler.executeTool("getWatcherStatus", {});
                
                if (structKeyExists(statusResult, "content") && arrayLen(statusResult.content) > 0) {
                    status = deserializeJson(statusResult.content[1].text);
                    
                    if (status.success && arrayLen(status.watchers) > 0) {
                        for (watcher in status.watchers) {
                            writeOutput('<div class="watcher-card ' & (watcher.active ? 'watcher-active' : 'watcher-inactive') & '">');
                            writeOutput('<h3>Watcher: ' & watcher.id & '</h3>');
                            writeOutput('<p><strong>Status:</strong> ' & (watcher.active ? '<span class="success">Active</span>' : '<span class="error">Inactive</span>') & '</p>');
                            writeOutput('<p><strong>Paths:</strong> ' & arrayToList(watcher.paths, ', ') & '</p>');
                            writeOutput('<p><strong>Extensions:</strong> *.' & arrayToList(watcher.extensions, ', *.') & '</p>');
                            writeOutput('<p><strong>Action:</strong> ' & watcher.action & '</p>');
                            writeOutput('<p><strong>Last Check:</strong> ' & watcher.lastCheck & '</p>');
                            writeOutput('<p><strong>Changes Detected:</strong> ' & watcher.changesDetected & '</p>');
                            
                            if (len(watcher.error)) {
                                writeOutput('<p class="error"><strong>Error:</strong> ' & watcher.error & '</p>');
                            }
                            
                            if (watcher.active) {
                                writeOutput('<form method="post" style="display:inline;">');
                                writeOutput('<input type="hidden" name="action" value="stop">');
                                writeOutput('<input type="hidden" name="watcherId" value="' & watcher.id & '">');
                                writeOutput('<button type="submit" class="danger">Stop Watcher</button>');
                                writeOutput('</form>');
                            }
                            
                            writeOutput('</div>');
                        }
                    } else {
                        writeOutput('<p>No active file watchers.</p>');
                    }
                }
                
            } catch (any e) {
                writeOutput('<p class="error">Error loading watchers: ' & e.message & '</p>');
            }
            </cfscript>
        </div>
        
        <!-- Test File Section -->
        <div class="section">
            <h2>Test File Modification</h2>
            <div class="test-file-section">
                <p>To test the file watcher, you can modify a test file:</p>
                
                <cfscript>
                testFilePath = expandPath("./tests/test-watcher.cfm");
                testFileExists = fileExists(testFilePath);
                </cfscript>
                
                <form method="post">
                    <input type="hidden" name="action" value="modifyTestFile">
                    <p>Test file: <code><cfoutput>#testFilePath#</cfoutput></code></p>
                    <p>Status: <cfif testFileExists><span class="success">Exists</span><cfelse><span class="warning">Does not exist</span></cfif></p>
                    
                    <div class="button-group">
                        <button type="submit" name="testAction" value="create">Create/Update Test File</button>
                        <button type="submit" name="testAction" value="delete" class="danger">Delete Test File</button>
                    </div>
                </form>
                
<cfif structKeyExists(form, "action") AND form.action EQ "modifyTestFile">
     <cfscript>
     try {
        // Validate CSRF token
        if (!structKeyExists(session, "csrfToken") || form.csrfToken != session.csrfToken) {
            throw(type="SecurityError", message="Invalid request");
        }
        
        // Validate file path is within allowed directory
        allowedDir = expandPath("./tests/");
        if (!testFilePath.startsWith(allowedDir)) {
            throw(type="SecurityError", message="Invalid file path");
        }
        
         if (form.testAction EQ "create") {
             // Ensure directory exists
             testDir = getDirectoryFromPath(testFilePath);
             if (!directoryExists(testDir)) {
                 directoryCreate(testDir);
             }
             
             // Write test file with timestamp
            var safeContent = '<!--- Test file modified at: ' & encodeForHTML(dateTimeFormat(now(), "yyyy-mm-dd HH:nn:ss")) & ' --->' & chr(10) & 
                             '<cfoutput>Test file content</cfoutput>';
            fileWrite(testFilePath, safeContent);
             writeOutput('<p class="success">✅ Test file created/updated!</p>');
         } else if (form.testAction EQ "delete" AND testFileExists) {
             fileDelete(testFilePath);
             writeOutput('<p class="success">✅ Test file deleted!</p>');
         }
     } catch (any e) {
        writeOutput('<p class="error">❌ Error: ' & encodeForHTML(e.message) & '</p>');
        writeLog(file="application", text="Test file operation error: #e.message#");
     }
     </cfscript>
 </cfif>
            </div>
        </div>
        
        <!-- Application Log Viewer -->
        <div class="section">
            <h2>Recent File Watcher Logs</h2>
            <div class="log-viewer">
<cfscript>
 try {
    // Add basic access control
    if (!structKeyExists(session, "isAdmin") || !session.isAdmin) {
        writeOutput('<p class="error">Access denied: Admin privileges required</p>');
        return;
    }
    
     // Read the application log
    // Use server-relative path instead of hardcoded absolute path
    logFile = server.coldfusion.rootdir & "/logs/application.log";
    
     if (fileExists(logFile)) {
         // Read last 50 lines
        try {
            logContent = fileRead(logFile);
            allLines = logContent.split(chr(10));
        } catch (any fileError) {
            writeOutput('<p class="error">Unable to read log file</p>');
            return;
        }
        
         startLine = max(1, arrayLen(allLines) - 50);
         
         writeOutput('<pre>');
         for (i = startLine; i <= arrayLen(allLines); i++) {
            line = encodeForHTML(allLines[i]);
             // Highlight file watcher related logs
            // Filter out sensitive information
            if (!findNoCase("password", line) && !findNoCase("secret", line) && 
                !findNoCase("token", line) && !findNoCase("key", line)) {
                if (findNoCase("File changes detected", line) || 
                    findNoCase("watch", line) ||
                    findNoCase("Test execution", line) ||
                    findNoCase("Lint", line) ||
                    findNoCase("Application reloaded", line)) {
                    writeOutput('<span style="color: ##f39c12;">' & line & '</span>' & chr(10));
                } else {
                    writeOutput(line & chr(10));
                }
             } else {
                writeOutput('[SENSITIVE DATA FILTERED]' & chr(10));
             }
         }
         writeOutput('</pre>');
     } else {
         writeOutput('<p>Log file not found.</p>');
     }
 } catch (any e) {
    writeOutput('<p class="error">Error reading logs: ' & encodeForHTML(e.message) & '</p>');
 }
 </cfscript>
            </div>
        </div>
        
        <div class="section" style="background: #e8f4f8;">
            <h3>How to Test:</h3>
            <ol>
                <li>Start a file watcher using the form above</li>
                <li>Modify a file in the watched directory (or use the test file section)</li>
                <li>Watch the logs to see the watcher detect changes and trigger actions</li>
                <li>Stop the watcher when done</li>
            </ol>
            <p><strong>Note:</strong> The watcher checks for changes every 500ms and respects the debounce setting to avoid rapid repeated triggers.</p>
        </div>
    </div>
</body>
</html>