component displayname="DevWorkflowTool" hint="Development workflow tools for CF2023 MCP" {

    /**
     * Initialize the development workflow tool
     */
    public DevWorkflowTool function init() {
        return this;
    }

    /**
     * Get tool definitions for registration
     */
    public array function getToolDefinitions() {
        return [
            {
                name = "codeFormatter",
                description = "Format CFML code using cfformat",
                inputSchema = {
                    type = "object",
                    properties = {
                        code = {
                            type = "string",
                            description = "CFML code to format (for string input)"
                        },
                        filePath = {
                            type = "string",
                            description = "Path to file to format (alternative to code)"
                        },
                        settings = {
                            type = "object",
                            description = "Formatting settings",
                            properties = {
                                indentSize = {
                                    type = "number",
                                    default = 4
                                },
                                insertSpaces = {
                                    type = "boolean",
                                    default = true
                                },
                                maxLineLength = {
                                    type = "number",
                                    default = 120
                                }
                            }
                        },
                        overwrite = {
                            type = "boolean",
                            description = "Overwrite the file (for filePath mode)",
                            default = false
                        }
                    }
                }
            },
            {
                name = "codeLinter",
                description = "Analyze CFML code for issues using cflint",
                inputSchema = {
                    type = "object",
                    properties = {
                        filePath = {
                            type = "string",
                            description = "File or directory to lint"
                        },
                        code = {
                            type = "string",
                            description = "Code string to lint (alternative to filePath)"
                        },
                        rules = {
                            type = "string",
                            description = "Linting rules preset",
                            enum = ["default", "strict", "minimal"],
                            default = "default"
                        },
                        format = {
                            type = "string",
                            description = "Output format",
                            enum = ["json", "text", "html"],
                            default = "json"
                        },
                        includeWarnings = {
                            type = "boolean",
                            description = "Include warnings in output",
                            default = true
                        }
                    }
                }
            },
            {
                name = "testRunner",
                description = "Run TestBox tests and return results",
                inputSchema = {
                    type = "object",
                    properties = {
                        directory = {
                            type = "string",
                            description = "Directory containing tests",
                            default = "./tests"
                        },
                        bundles = {
                            type = "string",
                            description = "Specific test bundles to run (comma-separated)"
                        },
                        labels = {
                            type = "string",
                            description = "Run tests with specific labels"
                        },
                        reporter = {
                            type = "string",
                            description = "Test reporter format",
                            enum = ["json", "simple", "junit", "tap"],
                            default = "json"
                        },
                        coverage = {
                            type = "boolean",
                            description = "Generate code coverage report",
                            default = false
                        }
                    }
                }
            },
            {
                name = "generateDocs",
                description = "Generate documentation from CFML components",
                inputSchema = {
                    type = "object",
                    properties = {
                        sourcePath = {
                            type = "string",
                            description = "Path to source code",
                            default = "./components"
                        },
                        outputPath = {
                            type = "string",
                            description = "Output directory for documentation",
                            default = "./docs"
                        },
                        format = {
                            type = "string",
                            description = "Documentation format",
                            enum = ["html", "markdown", "json"],
                            default = "html"
                        },
                        includePrivate = {
                            type = "boolean",
                            description = "Include private methods",
                            default = false
                        }
                    }
                }
            },
            {
                name = "watchFiles",
                description = "Watch files for changes and run actions",
                inputSchema = {
                    type = "object",
                    properties = {
                        paths = {
                            type = "array",
                            description = "Paths to watch",
                            items = {
                                type = "string"
                            },
                            default = ["./"]
                        },
                        extensions = {
                            type = "array",
                            description = "File extensions to watch",
                            items = {
                                type = "string"
                            },
                            default = ["cfc", "cfm"]
                        },
                        action = {
                            type = "string",
                            description = "Action to perform on change",
                            enum = ["test", "lint", "reload"],
                            default = "test"
                        },
                        debounce = {
                            type = "number",
                            description = "Debounce time in milliseconds",
                            default = 1000
                        }
                    }
                }
            },
            {
                name = "stopWatcher",
                description = "Stop a running file watcher",
                inputSchema = {
                    type = "object",
                    properties = {
                        watcherId = {
                            type = "string",
                            description = "The ID of the watcher to stop"
                        }
                    },
                    required = ["watcherId"]
                }
            },
            {
                name = "getWatcherStatus",
                description = "Get status of all active file watchers",
                inputSchema = {
                    type = "object",
                    properties = {}
                }
            }
        ];
    }

    /**
     * Format CFML code
     */
    public struct function codeFormatter(
        string code = "",
        string filePath = "",
        struct settings = {},
        boolean overwrite = false
    ) {
        var result = {
            success: true,
            formatted: "",
            original: "",
            changes: 0,
            error: ""
        };
        
        try {
            // Determine input source
            if (len(arguments.filePath)) {
                if (!fileExists(expandPath(arguments.filePath))) {
                    throw(message="File not found: " & arguments.filePath);
                }
                result.original = fileRead(expandPath(arguments.filePath));
            } else if (len(arguments.code)) {
                result.original = arguments.code;
            } else {
                throw(message="Either code or filePath must be provided");
            }
            
            // Build command arguments array
            var cmdArgs = ["cfformat"];
            
            if (len(arguments.filePath)) {
                arrayAppend(cmdArgs, arguments.filePath);
                if (!arguments.overwrite) {
                    arrayAppend(cmdArgs, "--dryrun");
                }
            } else {
                // For code string, we need to use stdin
                // This is a simplified version - actual implementation would pipe code
                var tempFile = getTempFile(getTempDirectory(), "cfformat");
                fileWrite(tempFile, result.original);
                arrayAppend(cmdArgs, tempFile);
            }
            
            // Add settings
            if (structKeyExists(arguments.settings, "indentSize")) {
                arrayAppend(cmdArgs, "--indent-size=" & arguments.settings.indentSize);
            }
            if (structKeyExists(arguments.settings, "insertSpaces")) {
                arrayAppend(cmdArgs, "--" & (arguments.settings.insertSpaces ? "spaces" : "tabs"));
            }
            if (structKeyExists(arguments.settings, "maxLineLength")) {
                arrayAppend(cmdArgs, "--max-line-length=" & arguments.settings.maxLineLength);
            }
            
            // Execute formatter with secure arguments array
            var exec = executeCommandWithArgs("box", cmdArgs);
            
            if (structKeyExists(exec, "success") && exec.success) {
                result.formatted = exec.output;
                result.changes = countChanges(result.original, result.formatted);
            } else {
                result.success = false;
                result.error = structKeyExists(exec, "error") ? exec.error : "Command execution failed";
            }
            
            // Clean up temp file if used
            if (isDefined("tempFile") && fileExists(tempFile)) {
                fileDelete(tempFile);
            }
            
        } catch (any e) {
            result.success = false;
            result.error = e.message;
            result.errorDetail = e.detail;
        }
        
        return {
            "content": [{
                "type": "text",
                "text": serializeJSON(result)
            }],
            "isError": !result.success
        };
    }

    /**
     * Lint CFML code
     */
    public struct function codeLinter(
        string filePath = "",
        string code = "",
        string rules = "default",
        string format = "json",
        boolean includeWarnings = true
    ) {
        var result = {
            success: true,
            issues: [],
            summary: {
                errors: 0,
                warnings: 0,
                info: 0
            },
            error: ""
        };
        
        try {
            // Build command arguments array
            var cmdArgs = ["cflint"];
            
            if (len(arguments.filePath)) {
                arrayAppend(cmdArgs, arguments.filePath);
            } else if (len(arguments.code)) {
                // Write code to temp file for linting
                var tempFile = getTempFile(getTempDirectory(), "cflint");
                fileWrite(tempFile & ".cfc", arguments.code);
                arrayAppend(cmdArgs, tempFile & ".cfc");
            } else {
                throw(message="Either filePath or code must be provided");
            }
            
            // Add format
            arrayAppend(cmdArgs, "--format=" & arguments.format);
            
            // Add rules configuration
            switch(arguments.rules) {
                case "strict":
                    arrayAppend(cmdArgs, "--strict");
                    break;
                case "minimal":
                    arrayAppend(cmdArgs, "--levels=ERROR");
                    break;
                default:
                    // Use default rules
                    break;
            }
            
            if (!arguments.includeWarnings) {
                arrayAppend(cmdArgs, "--levels=ERROR");
            }
            
            // Execute linter with secure arguments array
            var exec = executeCommandWithArgs("box", cmdArgs);
            
            if (arguments.format == "json" && len(exec.output)) {
                var lintResults = deserializeJSON(exec.output);
                
                // Process results
                if (structKeyExists(lintResults, "issues")) {
                    for (var issue in lintResults.issues) {
                        arrayAppend(result.issues, {
                            severity: issue.severity,
                            message: issue.message,
                            file: issue.file,
                            line: structKeyExists(issue, "line") ? issue.line : 0,
                            column: structKeyExists(issue, "column") ? issue.column : 0,
                            rule: issue.rule
                        });
                        
                        // Update summary
                        switch(issue.severity) {
                            case "ERROR":
                                result.summary.errors++;
                                break;
                            case "WARNING":
                                result.summary.warnings++;
                                break;
                            default:
                                result.summary.info++;
                                break;
                        }
                    }
                }
            } else {
                result.rawOutput = exec.output;
            }
            
            // Clean up temp file if used
            if (isDefined("tempFile") && fileExists(tempFile & ".cfc")) {
                fileDelete(tempFile & ".cfc");
            }
            
        } catch (any e) {
            result.success = false;
            result.error = e.message;
            result.errorDetail = e.detail;
        }
        
        return {
            "content": [{
                "type": "text",
                "text": serializeJSON(result)
            }],
            "isError": !result.success
        };
    }

    /**
     * Run TestBox tests
     */
    public struct function testRunner(
        string directory = "./tests",
        string bundles = "",
        string labels = "",
        string reporter = "json",
        boolean coverage = false
    ) {
        var result = {
            success: true,
            totalSpecs: 0,
            totalPass: 0,
            totalFail: 0,
            totalError: 0,
            totalSkipped: 0,
            duration: 0,
            results: [],
            coverage: {},
            error: ""
        };
        
        try {
           // Validate directory path
// Normalize and validate path
var normalizedPath = expandPath(arguments.directory);
var basePath = expandPath("./");

if (!normalizedPath.startsWith(basePath)) {
    throw(message="Invalid directory path - must be within application directory");
}

// Additional checks for path traversal attempts
if (findNoCase("..", arguments.directory) || 
    findNoCase("~", arguments.directory) || 
    arguments.directory.startsWith("/") ||
    arguments.directory.matches(".*[<>:\"|\\?\\*].*")) {
    throw(message="Invalid directory path - contains disallowed characters");
}
           
           if (!directoryExists(expandPath(arguments.directory))) {
               throw(message="Test directory not found: " & arguments.directory);
           }
           
            // Build command arguments array
            var cmdArgs = ["testbox", "run"];
            
            arrayAppend(cmdArgs, "--directory=" & arguments.directory);
            arrayAppend(cmdArgs, "--reporter=" & arguments.reporter);
            
            if (len(arguments.bundles)) {
                arrayAppend(cmdArgs, "--bundles=" & arguments.bundles);
            }
            
            if (len(arguments.labels)) {
                arrayAppend(cmdArgs, "--labels=" & arguments.labels);
            }
            
            if (arguments.coverage) {
                arrayAppend(cmdArgs, "--coverage");
                arrayAppend(cmdArgs, "--coverageOutputDir=./coverage");
            }
            
            // Execute tests with secure arguments array
            var exec = executeCommandWithArgs("box", cmdArgs);
            
            if (arguments.reporter == "json" && len(exec.output)) {
                var testResults = deserializeJSON(exec.output);
                
                // Process results
                result.totalSpecs = structKeyExists(testResults, "totalSpecs") ? testResults.totalSpecs : 0;
                result.totalPass = structKeyExists(testResults, "totalPass") ? testResults.totalPass : 0;
                result.totalFail = structKeyExists(testResults, "totalFail") ? testResults.totalFail : 0;
                result.totalError = structKeyExists(testResults, "totalError") ? testResults.totalError : 0;
                result.totalSkipped = structKeyExists(testResults, "totalSkipped") ? testResults.totalSkipped : 0;
                result.duration = structKeyExists(testResults, "totalDuration") ? testResults.totalDuration : 0;
                
                // Extract individual test results
                if (structKeyExists(testResults, "bundleStats")) {
                    for (var bundle in testResults.bundleStats) {
                        arrayAppend(result.results, {
                            bundle: bundle.path,
                            totalSpecs: bundle.totalSpecs,
                            totalPass: bundle.totalPass,
                            totalFail: bundle.totalFail,
                            totalError: bundle.totalError,
                            duration: bundle.totalDuration
                        });
                    }
                }
                
                // Check if all tests passed
                result.success = (result.totalFail == 0 && result.totalError == 0);
                
            } else {
                result.rawOutput = exec.output;
            }
            
            // Read coverage report if generated
            if (arguments.coverage && fileExists(expandPath("./coverage/coverage.json"))) {
                result.coverage = deserializeJSON(fileRead(expandPath("./coverage/coverage.json")));
            }
            
        } catch (any e) {
            result.success = false;
            result.error = e.message;
            result.errorDetail = e.detail;
        }
        
        return {
            "content": [{
                "type": "text",
                "text": serializeJSON(result)
            }],
            "isError": !result.success
        };
    }

    /**
     * Generate documentation
     */
    public struct function generateDocs(
        string sourcePath = "./components",
        string outputPath = "./docs",
        string format = "html",
        boolean includePrivate = false
    ) {
        var result = {
            success: true,
            filesProcessed: 0,
            outputPath: arguments.outputPath,
            message: "",
            error: ""
        };
        
        try {
            // Build command arguments array
            var cmdArgs = ["docbox", "generate"];
            
            arrayAppend(cmdArgs, "--source=" & arguments.sourcePath);
            arrayAppend(cmdArgs, "--output=" & arguments.outputPath);
            arrayAppend(cmdArgs, "--format=" & arguments.format);
            
            if (!arguments.includePrivate) {
                arrayAppend(cmdArgs, "--excludePrivate");
            }
            
            // Execute documentation generator with secure arguments array
            var exec = executeCommandWithArgs("box", cmdArgs);
            
            if (exec.success) {
                result.message = "Documentation generated successfully";
                
                // Count generated files
                if (directoryExists(expandPath(arguments.outputPath))) {
                    var files = directoryList(expandPath(arguments.outputPath), true, "path", "*." & arguments.format);
                    result.filesProcessed = arrayLen(files);
                }
            } else {
                result.success = false;
                result.error = exec.error;
            }
            
        } catch (any e) {
            result.success = false;
            result.error = e.message;
            result.errorDetail = e.detail;
        }
        
        return {
            "content": [{
                "type": "text",
                "text": serializeJSON(result)
            }],
            "isError": !result.success
        };
    }

    /**
     * Watch files for changes and trigger actions
     */
    public struct function watchFiles(
        array paths = ["./"],
        array extensions = ["cfc", "cfm"],
        string action = "test",
        numeric debounce = 1000
    ) {
        var result = {
            success: true,
            watching: false,
            watcherId: "",
            paths: arguments.paths,
            extensions: arguments.extensions,
            action: arguments.action,
            message: "",
            error: ""
        };
        
        try {
            // Generate unique and descriptive watcher ID
            var timestamp = dateFormat(now(), "yyyymmdd") & timeFormat(now(), "HHmmss");
            var watcherPath = listFirst(arrayToList(arguments.paths), ",");
            var watcherAction = arguments.action;
            var watcherId = "fileWatcher_" & watcherAction & "_" & timestamp & "_" & left(hash(watcherPath), 8);
            
            // Normalize paths
            var normalizedPaths = [];
            for (var path in arguments.paths) {
                arrayAppend(normalizedPaths, expandPath(path));
            }
            
            // Initialize watcher in application scope
            if (!structKeyExists(application, "fileWatchers")) {
                application.fileWatchers = {};
            }
            
            // Create watcher configuration
            var watcherConfig = {
                id: watcherId,
                paths: normalizedPaths,
                extensions: arguments.extensions,
                action: arguments.action,
                debounce: arguments.debounce,
                active: true,
                lastCheck: now(),
                fileStates: {},
                lastTrigger: 0,
                changesDetected: 0
            };
            
            // Get initial file states
            watcherConfig.fileStates = getFileStates(normalizedPaths, arguments.extensions);
            
            // Store watcher config
            application.fileWatchers[watcherId] = watcherConfig;
            
            // Start the watcher thread
            thread name="#watcherId#" action="run" {
                try {
                    // Get watcher config from application scope
                    var config = application.fileWatchers[thread.name];
                    
                    while (structKeyExists(application.fileWatchers, thread.name) && 
                           application.fileWatchers[thread.name].active) {
                        
                        // Check for file changes
                        var currentStates = getFileStates(config.paths, config.extensions);
                        var changes = detectChanges(config.fileStates, currentStates);
                        
                        if (arrayLen(changes) > 0) {
                            var currentTime = getTickCount();
                            
                            // Check debounce
                            if (currentTime - config.lastTrigger >= config.debounce) {
                                // Log changes
                                application.fileWatchers[thread.name].changesDetected++;
                                application.fileWatchers[thread.name].lastTrigger = currentTime;
                                
                                // Trigger action
                                triggerWatchAction(config.action, changes);
                                
                                // Update file states
                                application.fileWatchers[thread.name].fileStates = currentStates;
                            }
                        }
                        
                        // Update last check time
                        application.fileWatchers[thread.name].lastCheck = now();
                        
                        // Sleep for a short interval
                        sleep(500); // Check every 500ms
                    }
                    
                } catch (any e) {
                    // Log error
                    if (structKeyExists(application.fileWatchers, thread.name)) {
                        application.fileWatchers[thread.name].error = e.message;
                        application.fileWatchers[thread.name].active = false;
                    }
                }
            }
            
            result.watching = true;
            result.watcherId = watcherId;
            result.message = "File watcher started successfully. Monitoring " & 
                           arrayLen(normalizedPaths) & " path(s) for *." & 
                           arrayToList(arguments.extensions, ", *.") & " files.";
            
        } catch (any e) {
            result.success = false;
            result.error = e.message;
            result.errorDetail = e.detail;
        }
        
        return {
            "content": [{
                "type": "text",
                "text": serializeJSON(result)
            }],
            "isError": !result.success
        };
    }
    
    /**
     * Stop watching files
     */
    public struct function stopWatcher(required string watcherId) {
        var result = {
            success: true,
            message: "",
            error: ""
        };
        
        try {
            if (structKeyExists(application, "fileWatchers") && 
                structKeyExists(application.fileWatchers, arguments.watcherId)) {
                
                // Mark as inactive first to signal thread to stop
                application.fileWatchers[arguments.watcherId].active = false;
                
                // Explicitly terminate the thread to ensure immediate cleanup
                try {
                    cfthread(action="terminate", name=arguments.watcherId);
                    result.message = "File watcher thread terminated and ";
                } catch (any threadError) {
                    // Thread might have already stopped
                    result.message = "File watcher thread already stopped and ";
                }
                
                // Remove from application scope
                structDelete(application.fileWatchers, arguments.watcherId);
                
                result.message &= "removed successfully.";
            } else {
                throw(message="Watcher not found: " & arguments.watcherId);
            }
            
        } catch (any e) {
            result.success = false;
            result.error = e.message;
        }
        
        return {
            "content": [{
                "type": "text",
                "text": serializeJSON(result)
            }],
            "isError": !result.success
        };
    }
    
    /**
     * Get status of all active watchers
     */
    public struct function getWatcherStatus() {
        var result = {
            success: true,
            watchers: [],
            error: ""
        };
        
        try {
            if (structKeyExists(application, "fileWatchers")) {
                for (var watcherId in application.fileWatchers) {
                    var watcher = application.fileWatchers[watcherId];
                    arrayAppend(result.watchers, {
                        id: watcher.id,
                        active: watcher.active,
                        paths: watcher.paths,
                        extensions: watcher.extensions,
                        action: watcher.action,
                        lastCheck: dateTimeFormat(watcher.lastCheck, "yyyy-mm-dd HH:nn:ss"),
                        changesDetected: watcher.changesDetected,
                        error: structKeyExists(watcher, "error") ? watcher.error : ""
                    });
                }
            }
            
        } catch (any e) {
            result.success = false;
            result.error = e.message;
        }
        
        return {
            "content": [{
                "type": "text",
                "text": serializeJSON(result)
            }],
            "isError": !result.success
        };
    }

    // Helper functions
    
    /**
     * Execute a command with arguments array to prevent injection
     */
private struct function executeCommandWithArgs(required string command, required array arguments) {
     var result = {
         success: true,
         output: "",
         error: ""
     };
     
    // Escape arguments for shell safety (consistent with PackageManagerTool)
    var escapedArgs = [];
    for (var arg in arguments.arguments) {
        arrayAppend(escapedArgs, shellEscape(arg));
    }
    
     try {
         var executeResult = "";
         var executeError = "";
         
         cfexecute(
             name = arguments.command,
            arguments = arrayToList(escapedArgs, " "),
             variable = "executeResult",
             errorVariable = "executeError",
             timeout = 120
         );
    
    result.output = executeResult;
    
    if (len(executeError)) {
        result.success = false;
        result.error = executeError;
    }
            
        } catch (any e) {
            result.success = false;
            result.error = e.message;
        }
        
        return result;
    }
    


    private numeric function countChanges(required string original, required string formatted) {
        var originalLines = listToArray(arguments.original, chr(10));
        var formattedLines = listToArray(arguments.formatted, chr(10));
        var changes = 0;
        
        // Simple line count difference
        changes = abs(arrayLen(originalLines) - arrayLen(formattedLines));
        
        // Check for content changes in common lines
        var minLines = min(arrayLen(originalLines), arrayLen(formattedLines));
        for (var i = 1; i <= minLines; i++) {
            if (trim(originalLines[i]) != trim(formattedLines[i])) {
                changes++;
            }
        }
        
        return changes;
    }
    
    /**
     * Get the current state of all files in the watched paths
     */
    private struct function getFileStates(required array paths, required array extensions) {
        var states = {};
        
        for (var path in arguments.paths) {
            if (directoryExists(path)) {
                // Create local copy of extensions for closure to ensure reliable scope capture
                var extensionsToFilter = arguments.extensions;
                
                // Get all files recursively
                var files = directoryList(
                    path, 
                    true, 
                    "path", 
                    function(filePath) {
                        var ext = listLast(arguments.filePath, ".");
                        // Use the local copy to avoid closure scope issues
                        return arrayFindNoCase(extensionsToFilter, ext) > 0;
                    }
                );
                
                // Get state for each file
                for (var file in files) {
                    var fileInfo = getFileInfo(file);
                    states[file] = {
                        size = fileInfo.size,
                        lastModified = fileInfo.lastModified,
                        exists = true
                    };
                }
            }
        }
        
        return states;
    }
    
    /**
     * Detect changes between two file state snapshots
     */
    private array function detectChanges(required struct oldStates, required struct newStates) {
        var changes = [];
        
        // Check for modified or deleted files
        for (var file in arguments.oldStates) {
            if (structKeyExists(arguments.newStates, file)) {
                // File still exists - check if modified
                if (arguments.oldStates[file].lastModified != arguments.newStates[file].lastModified ||
                    arguments.oldStates[file].size != arguments.newStates[file].size) {
                    arrayAppend(changes, {
                        type: "modified",
                        file: file,
                        oldModified: arguments.oldStates[file].lastModified,
                        newModified: arguments.newStates[file].lastModified
                    });
                }
            } else {
                // File was deleted
                arrayAppend(changes, {
                    type: "deleted",
                    file: file
                });
            }
        }
        
        // Check for new files
        for (var file in arguments.newStates) {
            if (!structKeyExists(arguments.oldStates, file)) {
                arrayAppend(changes, {
                    type: "added",
                    file: file
                });
            }
        }
        
        return changes;
    }
    
    /**
     * Trigger the appropriate action when file changes are detected
     */
    private void function triggerWatchAction(required string action, required array changes) {
        try {
            // Log the changes
            var changeLog = "File changes detected:\n";
            for (var change in arguments.changes) {
                changeLog &= "  - " & change.type & ": " & change.file & "\n";
            }
            
            // Log to application log
            writeLog(
                text = changeLog & "Triggering action: " & arguments.action,
                type = "information",
                application = true
            );
            
            // Execute the action
            switch(arguments.action) {
                case "test":
                    // Run tests
                    thread name="watchAction_test_#createUUID()#" action="run" {
                        try {
                            var testResult = executeCommandWithArgs("box", ["testbox", "run"]);
                            writeLog(
                                text = "Test execution completed: " & (testResult.success ? "SUCCESS" : "FAILED"),
                                type = testResult.success ? "information" : "error",
                                application = true
                            );
                        } catch (any e) {
                            writeLog(
                                text = "Test execution error: " & e.message,
                                type = "error",
                                application = true
                            );
                        }
                    }
                    break;
                    
                case "lint":
                    // Run linter on changed files
                    thread name="watchAction_lint_#createUUID()#" action="run" {
                        try {
                            for (var change in changes) {
                                if (change.type != "deleted") {
                                    var lintResult = executeCommandWithArgs("box", ["cflint", change.file]);
                                    writeLog(
                                        text = "Lint " & change.file & ": " & (lintResult.success ? "PASSED" : "ISSUES FOUND"),
                                        type = lintResult.success ? "information" : "warning",
                                        application = true
                                    );
                                }
                            }
                        } catch (any e) {
                            writeLog(
                                text = "Lint execution error: " & e.message,
                                type = "error",
                                application = true
                            );
                        }
                    }
                    break;
                    
                case "reload":
                    // Reload the application
                    thread name="watchAction_reload_#createUUID()#" action="run" {
                        try {
                            applicationStop();
                            writeLog(
                                text = "Application reloaded due to file changes",
                                type = "information",
                                application = true
                            );
                        } catch (any e) {
                            writeLog(
                                text = "Reload error: " & e.message,
                                type = "error",
                                application = true
                            );
                        }
                    }
                    break;
                    
                default:
                    writeLog(
                        text = "Unknown watch action: " & arguments.action,
                        type = "warning",
                        application = true
                    );
            }
            
        } catch (any e) {
            writeLog(
                text = "Error triggering watch action: " & e.message,
                type = "error",
                application = true
            );
        }
    }

}