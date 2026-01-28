/**
 * Logger.cfc
 * Structured logging for MCPCFC server
 * Supports multiple log levels and file output
 */
component output="false" {

    variables.LOG_LEVELS = {
        DEBUG: 1,
        INFO: 2,
        WARN: 3,
        ERROR: 4
    };

    variables.currentLevel = variables.LOG_LEVELS.INFO;
    variables.logDirectory = "";
    variables.logToFile = true;
    variables.logToConsole = true;

    /**
     * Initialize the logger
     * @level The minimum log level (DEBUG, INFO, WARN, ERROR)
     * @logDirectory Directory for log files
     */
    public function init(string level = "INFO", string logDirectory = "") {
        setLogLevel(arguments.level);

        if (len(arguments.logDirectory)) {
            variables.logDirectory = arguments.logDirectory;
        } else if (structKeyExists(application, "config") && structKeyExists(application.config, "logDirectory")) {
            variables.logDirectory = application.config.logDirectory;
        } else {
            variables.logDirectory = expandPath("/mcpcfc.local/logs/");
        }

        // Ensure log directory exists
        if (!directoryExists(variables.logDirectory)) {
            try {
                directoryCreate(variables.logDirectory);
            } catch (any e) {
                variables.logToFile = false;
            }
        }

        return this;
    }

    /**
     * Set the minimum log level
     * @level The log level string
     */
    public void function setLogLevel(required string level) {
        var upperLevel = uCase(arguments.level);
        if (structKeyExists(variables.LOG_LEVELS, upperLevel)) {
            variables.currentLevel = variables.LOG_LEVELS[upperLevel];
        }
    }

    /**
     * Log a DEBUG message
     * @message The log message
     * @data Optional structured data
     */
    public void function debug(required string message, struct data = {}) {
        logMessage("DEBUG", arguments.message, arguments.data);
    }

    /**
     * Log an INFO message
     * @message The log message
     * @data Optional structured data
     */
    public void function info(required string message, struct data = {}) {
        logMessage("INFO", arguments.message, arguments.data);
    }

    /**
     * Log a WARN message
     * @message The log message
     * @data Optional structured data
     */
    public void function warn(required string message, struct data = {}) {
        logMessage("WARN", arguments.message, arguments.data);
    }

    /**
     * Log an ERROR message
     * @message The log message
     * @data Optional structured data
     */
    public void function error(required string message, struct data = {}) {
        logMessage("ERROR", arguments.message, arguments.data);
    }

    /**
     * Internal log method
     */
    private void function logMessage(required string level, required string message, struct data = {}) {
        // Check if we should log at this level
        if (variables.LOG_LEVELS[arguments.level] < variables.currentLevel) {
            return;
        }

        // Build log entry
        var entry = buildLogEntry(arguments.level, arguments.message, arguments.data);

        // Log to file
        if (variables.logToFile && len(variables.logDirectory)) {
            writeToFile(entry, arguments.level);
        }

        // Log to console (cflog for ColdFusion's server log)
        if (variables.logToConsole) {
            writeToConsole(entry, arguments.level);
        }
    }

    /**
     * Build a structured log entry
     */
    private struct function buildLogEntry(required string level, required string message, struct data = {}) {
        var entry = structNew("ordered");
        entry["timestamp"] = dateTimeFormat(now(), "yyyy-mm-dd'T'HH:nn:ss.lll");
        entry["level"] = arguments.level;
        entry["message"] = arguments.message;

        // Add request context if available
        try {
            if (structKeyExists(request, "sessionId")) {
                entry["sessionId"] = request.sessionId;
            }
        } catch (any e) {
            // Ignore if no request scope
        }

        // Add data if provided
        if (!structIsEmpty(arguments.data)) {
            entry["data"] = arguments.data;
        }

        return entry;
    }

    /**
     * Write log entry to file
     */
    private void function writeToFile(required struct entry, required string level) {
        try {
            var logFile = variables.logDirectory & "mcpcfc_" & dateFormat(now(), "yyyy-mm-dd") & ".log";
            var logLine = serializeJson(arguments.entry) & chr(10);

            // Append to file - use fileAppend for proper append behavior
            if (fileExists(logFile)) {
                fileAppend(logFile, logLine, "UTF-8");
            } else {
                fileWrite(logFile, logLine, "UTF-8");
            }

        } catch (any e) {
            // Silently fail - don't let logging errors break the app
        }
    }

    /**
     * Write log entry to console/CF server log
     */
    private void function writeToConsole(required struct entry, required string level) {
        try {
            var logType = "information";

            switch(arguments.level) {
                case "DEBUG":
                    logType = "information";
                    break;
                case "INFO":
                    logType = "information";
                    break;
                case "WARN":
                    logType = "warning";
                    break;
                case "ERROR":
                    logType = "error";
                    break;
            }

            var message = "[MCPCFC] #arguments.entry.message#";
            if (structKeyExists(arguments.entry, "data") && !structIsEmpty(arguments.entry.data)) {
                message &= " | " & serializeJson(arguments.entry.data);
            }

            writeLog(text=message, type=logType, application=true);

        } catch (any e) {
            // Silently fail
        }
    }

    /**
     * Get recent log entries from file
     * @level Filter by level (optional)
     * @limit Maximum entries to return
     * @return Array of log entries
     */
    public array function getRecentLogs(string level = "", numeric limit = 100) {
        var entries = [];
        var logFile = variables.logDirectory & "mcpcfc_" & dateFormat(now(), "yyyy-mm-dd") & ".log";

        if (!fileExists(logFile)) {
            return entries;
        }

        try {
            var lines = fileRead(logFile).split(chr(10));
            var count = 0;

            // Read from end (most recent first)
            for (var i = arrayLen(lines); i >= 1 && count < arguments.limit; i--) {
                var line = trim(lines[i]);
                if (!len(line)) continue;

                try {
                    var entry = deserializeJson(line);

                    // Filter by level if specified
                    if (len(arguments.level) && entry.level != uCase(arguments.level)) {
                        continue;
                    }

                    arrayAppend(entries, entry);
                    count++;

                } catch (any e) {
                    // Skip malformed entries
                }
            }

        } catch (any e) {
            // Return empty array on error
        }

        return entries;
    }

    /**
     * Clear log file for a specific date
     * @date The date to clear (defaults to today)
     */
    public void function clearLogs(date logDate = now()) {
        var logFile = variables.logDirectory & "mcpcfc_" & dateFormat(arguments.logDate, "yyyy-mm-dd") & ".log";

        if (fileExists(logFile)) {
            fileDelete(logFile);
        }
    }

    /**
     * Get current log level
     * @return String
     */
    public string function getLogLevel() {
        for (var level in variables.LOG_LEVELS) {
            if (variables.LOG_LEVELS[level] == variables.currentLevel) {
                return level;
            }
        }
        return "INFO";
    }

    /**
     * Enable/disable file logging
     */
    public void function setFileLogging(required boolean enabled) {
        variables.logToFile = arguments.enabled;
    }

    /**
     * Enable/disable console logging
     */
    public void function setConsoleLogging(required boolean enabled) {
        variables.logToConsole = arguments.enabled;
    }
}
