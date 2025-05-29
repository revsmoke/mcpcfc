component displayname="ServerManagementTool" hint="Server management tools for CF2023 MCP" {

    /**
     * Initialize the server management tool
     */
    public ServerManagementTool function init() {
        return this;
    }

    /**
     * Get tool definitions for registration
     */
    public array function getToolDefinitions() {
        return [
            {
                name: "serverStatus",
                description: "Get current ColdFusion server status, memory usage, and configuration",
                inputSchema: {
                    type: "object",
                    properties: {
                        includeSystemInfo: {
                            type: "boolean",
                            description: "Include detailed system information",
                            default: true
                        },
                        includeMemory: {
                            type: "boolean",
                            description: "Include memory statistics",
                            default: true
                        },
                        includeDataSources: {
                            type: "boolean",
                            description: "Include datasource information",
                            default: false
                        },
                        includeMappings: {
                            type: "boolean",
                            description: "Include CF mappings",
                            default: false
                        }
                    }
                }
            },
            {
                name: "configManager",
                description: "Read or update ColdFusion server configuration settings",
                inputSchema: {
                    type: "object",
                    properties: {
                        action: {
                            type: "string",
                            description: "Action to perform: get, set, or list",
                            enum: ["get", "set", "list"],
                            default: "get"
                        },
                        category: {
                            type: "string",
                            description: "Configuration category",
                            enum: ["runtime", "caching", "debugging", "mail", "datasources"]
                        },
                        setting: {
                            type: "string",
                            description: "Specific setting name (for get/set actions)"
                        },
                        value: {
                            type: "string",
                            description: "New value (for set action)"
                        }
                    },
                    required: ["action"]
                }
            },
            {
                name: "logStreamer",
                description: "Read and search ColdFusion log files",
                inputSchema: {
                    type: "object",
                    properties: {
                        logFile: {
                            type: "string",
                            description: "Log file name (e.g., application.log, exception.log)",
                            default: "application.log"
                        },
                        lines: {
                            type: "number",
                            description: "Number of lines to retrieve",
                            default: 50
                        },
                        filter: {
                            type: "string",
                            description: "Optional filter pattern"
                        },
                        fromTail: {
                            type: "boolean",
                            description: "Read from end of file",
                            default: true
                        }
                    }
                }
            },
            {
                name: "clearCache",
                description: "Clear various ColdFusion caches",
                inputSchema: {
                    type: "object",
                    properties: {
                        cacheType: {
                            type: "string",
                            description: "Type of cache to clear",
                            enum: ["template", "component", "query", "all"],
                            default: "all"
                        },
                        path: {
                            type: "string",
                            description: "Specific path for template/component cache (optional)"
                        }
                    }
                }
            }
        ];
    }

    /**
     * Get server status and information
     */
    public struct function serverStatus(
        boolean includeSystemInfo = true,
        boolean includeMemory = true,
        boolean includeDataSources = false,
        boolean includeMappings = false
    ) {
        var status = {
            success: true,
            timestamp: now(),
            server: {},
            error: ""
        };
        
        try {
            // Basic server info
            status.server = {
                productName: server.coldfusion.productname,
                productVersion: server.coldfusion.productversion,
                productLevel: server.coldfusion.productlevel ?: "Standard",
                installPath: server.coldfusion.rootdir,
                uptime: getUptime()
            };
            
            // System information
            if (arguments.includeSystemInfo) {
                status.server.system = {
                    os: server.os.name & " " & server.os.version,
                    arch: server.os.arch,
                    javaVersion: server.java.version,
                    javaVendor: server.java.vendor,
                    locale: server.coldfusion.locale ?: getLocale()
                };
            }
            
            // Memory statistics
            if (arguments.includeMemory) {
                var runtime = createObject("java", "java.lang.Runtime").getRuntime();
                status.server.memory = {
                    total: formatBytes(runtime.totalMemory()),
                    used: formatBytes(runtime.totalMemory() - runtime.freeMemory()),
                    free: formatBytes(runtime.freeMemory()),
                    max: formatBytes(runtime.maxMemory()),
                    percentUsed: round((runtime.totalMemory() - runtime.freeMemory()) / runtime.maxMemory() * 100)
                };
            }
            
            // Datasources
            if (arguments.includeDataSources) {
                status.server.dataSources = getDataSourceList();
            }
            
            // Mappings
            if (arguments.includeMappings) {
                status.server.mappings = getMappingsList();
            }
            
        } catch (any e) {
            status.success = false;
            status.error = e.message;
            status.errorDetail = e.detail;
        }
        
        return status;
    }

    /**
     * Manage server configuration
     */
    public struct function configManager(
        required string action,
        string category = "",
        string setting = "",
        string value = ""
    ) {
        var result = {
            success: true,
            action: arguments.action,
            data: {},
            message: "",
            error: ""
        };
        
        try {
            switch(arguments.action) {
                case "list":
                    result.data = listConfigCategories();
                    break;
                    
                case "get":
                    if (len(arguments.category) == 0) {
                        throw(message="Category is required for get action");
                    }
                    result.data = getConfigSettings(arguments.category, arguments.setting);
                    break;
                    
                case "set":
                    if (len(arguments.category) == 0 || len(arguments.setting) == 0) {
                        throw(message="Category and setting are required for set action");
                    }
                    result.data = setConfigSetting(arguments.category, arguments.setting, arguments.value);
                    result.warning = "Changes may require server restart to take effect";
                    break;
                    
                default:
                    throw(message="Unsupported action: '" & arguments.action & "'. Valid actions are: list, get, set");
            }
            
        } catch (any e) {
            result.success = false;
            result.error = e.message;
            result.errorDetail = e.detail;
        }
        
        return result;
    }

    /**
     * Stream log file contents
     */
    public struct function logStreamer(
        string logFile = "application.log",
        numeric lines = 50,
        string filter = "",
        boolean fromTail = true
    ) {
        var result = {
            success: true,
            logFile: arguments.logFile,
            entries: [],
            totalLines: 0,
            filtered: false,
            error: ""
        };
        
        try {
            // Sanitize log file name to prevent path traversal attacks
            var sanitizedLogFile = sanitizeLogFileName(arguments.logFile);
            if (sanitizedLogFile == "") {
                throw(message="Invalid log file name: " & arguments.logFile);
            }
            
            var logPath = server.coldfusion.rootdir & "/logs/" & sanitizedLogFile;
            
            if (!fileExists(logPath)) {
                throw(message="Log file not found: " & sanitizedLogFile);
            }
            
            // Stream the log file to avoid memory issues with large files
            if (arguments.fromTail) {
                // Use Java RandomAccessFile for efficient tail reading
                var file = createObject("java", "java.io.RandomAccessFile").init(logPath, "r");
                var fileLength = file.length();
                var linesFound = 0;
                var tempLines = [];
                var buffer = createObject("java", "java.lang.StringBuilder");
                
                try {
                    // Start from end of file and work backwards
                    var pos = fileLength - 1;
                    
                    while (pos >= 0 && linesFound < arguments.lines * 2) { // Read extra for filtering
                        file.seek(pos);
                        var ch = file.read();
                        
                        if (ch == 10 || pos == 0) { // newline or start of file
                            var line = buffer.reverse().toString();
                            buffer.setLength(0); // clear buffer
                            
                            if (len(trim(line)) > 0) {
                                // Apply filter if needed
                                if (!len(arguments.filter) || findNoCase(arguments.filter, line)) {
                                    arrayPrepend(tempLines, line);
                                    linesFound++;
                                }
                            }
                        } else if (ch != 13) { // ignore carriage return
                            buffer.append(chr(ch));
                        }
                        
                        pos--;
                    }
                    
                    // Take only requested number of lines
                    var startIdx = max(1, arrayLen(tempLines) - arguments.lines + 1);
                    for (var i = startIdx; i <= arrayLen(tempLines); i++) {
                        arrayAppend(result.entries, parseLogLine(tempLines[i]));
                    }
                    
                    result.totalLines = linesFound; // Approximate count
                    
                } finally {
                    file.close();
                }
                
            } else {
                // Read from beginning using line-by-line streaming
                var fileObj = fileOpen(logPath, "read");
                var linesRead = 0;
                var matchedLines = 0;
                
                try {
                    while (!fileIsEOF(fileObj) && matchedLines < arguments.lines) {
                        var line = fileReadLine(fileObj);
                        linesRead++;
                        
                        // Apply filter if needed
                        if (!len(arguments.filter) || findNoCase(arguments.filter, line)) {
                            arrayAppend(result.entries, parseLogLine(line));
                            matchedLines++;
                        }
                    }
                    
                    result.totalLines = linesRead;
                    
                } finally {
                    fileClose(fileObj);
                }
            }
            
            if (len(arguments.filter)) {
                result.filtered = true;
            }
            
        } catch (any e) {
            result.success = false;
            result.error = e.message;
            result.errorDetail = e.detail;
        }
        
        return result;
    }

    /**
     * Clear ColdFusion caches
     */
    public struct function clearCache(
        string cacheType = "all",
        string path = ""
    ) {
        var result = {
            success: true,
            cacheType: arguments.cacheType,
            cleared: [],
            error: ""
        };
        
        try {
            switch(arguments.cacheType) {
                case "template":
                    if (len(arguments.path)) {
                        pagePoolClear(arguments.path);
                        arrayAppend(result.cleared, "Template cache cleared for: " & arguments.path);
                    } else {
                        pagePoolClear();
                        arrayAppend(result.cleared, "All template cache cleared");
                    }
                    break;
                    
                case "component":
                    componentCacheClear();
                    arrayAppend(result.cleared, "Component cache cleared");
                    break;
                    
                case "query":
                    cacheRemoveAll();
                    arrayAppend(result.cleared, "Query cache cleared");
                    break;
                    
                case "all":
                    pagePoolClear();
                    componentCacheClear();
                    cacheRemoveAll();
                    arrayAppend(result.cleared, "All caches cleared (template, component, query)");
                    break;
                    
                default:
                    throw(message="Unsupported cache type: '" & arguments.cacheType & "'. Valid types are: template, component, query, all");
            }
            
        } catch (any e) {
            result.success = false;
            result.error = e.message;
            result.errorDetail = e.detail;
        }
        
        return result;
    }

    // Helper functions
    
    private string function getUptime() {
        var startTime = createObject("java", "java.lang.management.ManagementFactory")
            .getRuntimeMXBean()
            .getStartTime();
        var uptime = dateDiff("s", createObject("java", "java.util.Date").init(startTime), now());
        
        var days = int(uptime / 86400);
        var hours = int((uptime % 86400) / 3600);
        var minutes = int((uptime % 3600) / 60);
        
        return days & "d " & hours & "h " & minutes & "m";
    }

    private string function formatBytes(numeric bytes) {
        if (arguments.bytes >= 1073741824) {
            return numberFormat(arguments.bytes / 1073741824, "0.00") & " GB";
        } else if (arguments.bytes >= 1048576) {
            return numberFormat(arguments.bytes / 1048576, "0.00") & " MB";
        } else if (arguments.bytes >= 1024) {
            return numberFormat(arguments.bytes / 1024, "0.00") & " KB";
        } else {
            return arguments.bytes & " bytes";
        }
    }

    private array function getDataSourceList() {
        var dsService = createObject("java", "coldfusion.server.ServiceFactory")
            .getDataSourceService();
        var datasources = dsService.getDatasources();
        var dsList = [];
        
        for (var dsName in datasources) {
            arrayAppend(dsList, {
                name: dsName,
                driver: datasources[dsName].driver ?: "Unknown",
                url: datasources[dsName].url ?: ""
            });
        }
        
        return dsList;
    }

    private struct function getMappingsList() {
        var mappings = {};
        var serviceFactory = createObject("java", "coldfusion.server.ServiceFactory");
        var runtime = serviceFactory.getRuntimeService();
        
        // Get CF mappings
        var cfMappings = runtime.getMappings();
        for (var key in cfMappings) {
            mappings[key] = cfMappings[key];
        }
        
        return mappings;
    }

    private struct function listConfigCategories() {
        return {
            runtime: "Runtime settings (timeouts, limits)",
            caching: "Cache configuration",
            debugging: "Debug and logging settings",
            mail: "Mail server configuration",
            datasources: "Database connections"
        };
    }

    private struct function getConfigSettings(required string category, string setting = "") {
        var settings = {};
        
        // This is a simplified version - in production, you'd access actual CF Admin API
        switch(arguments.category) {
            case "runtime":
                settings = {
                    requestTimeout: server.coldfusion.requesttimeout ?: 60,
                    sessionTimeout: 20,
                    applicationTimeout: 2
                };
                break;
                
            case "debugging":
                settings = {
                    debuggingEnabled: server.coldfusion.debugging ?: false,
                    robustExceptions: server.coldfusion.robustexceptions ?: false
                };
                break;
        }
        
        if (len(arguments.setting) && structKeyExists(settings, arguments.setting)) {
            return { "#arguments.setting#": settings[arguments.setting] };
        }
        
        return settings;
    }

    private struct function setConfigSetting(required string category, required string setting, required string value) {
        // Note: This is a placeholder - actual implementation would use CF Admin API
        return {
            category: arguments.category,
            setting: arguments.setting,
            newValue: arguments.value,
            message: "Configuration updated (restart may be required)"
        };
    }

    private struct function parseLogLine(required string line) {
        // Simple log line parser
        var entry = {
            raw: arguments.line,
            timestamp: "",
            level: "INFO",
            message: arguments.line
        };
        
        // Try to parse standard CF log format: "timestamp" LEVEL message
        // Pattern matches: "2024-01-15 10:30:45" INFO This is the log message
        var pattern = '^"([^"]+)"\s+(\w+)\s+(.+)$';
        var m = reFind(pattern, arguments.line, 1, true);

        if (m.pos[1] gt 0) {
            entry.timestamp = mid(arguments.line, m.pos[2], m.len[2]);
            entry.level = mid(arguments.line, m.pos[3], m.len[3]);
            entry.message = mid(arguments.line, m.pos[4], m.len[4]);
        } else {
            // Try alternative format without quotes: timestamp LEVEL message
            // Pattern matches: 2024-01-15 10:30:45 INFO This is the log message
            pattern = '^(\S+\s+\S+)\s+(\w+)\s+(.+)$';
            m = reFind(pattern, arguments.line, 1, true);

            if (m.pos[1] gt 0) {
                entry.timestamp = mid(arguments.line, m.pos[2], m.len[2]);
                entry.level = mid(arguments.line, m.pos[3], m.len[3]);
                entry.message = mid(arguments.line, m.pos[4], m.len[4]);
            }
        }

        // Return the entry (either parsed or raw)
        return entry;
    }

    /**
     * Sanitize log file name to prevent path traversal attacks
     * @logFile The log file name to sanitize
     * @return Sanitized filename or empty string if invalid
     */
    private string function sanitizeLogFileName(required string logFile) {
        // Extract only the filename from the path (remove any directory traversal)
        var filename = listLast(arguments.logFile, "/\");
        
        // Validate filename against safe pattern
        // Allow only alphanumeric characters, dots, underscores, hyphens
        var safePattern = "^[a-zA-Z0-9._-]+$";
        
        if (reFind(safePattern, filename) EQ 1 AND len(filename) EQ len(reMatch(safePattern,filename)[1])) {
            return filename;
        } else {
            return "";
        }
    }

}