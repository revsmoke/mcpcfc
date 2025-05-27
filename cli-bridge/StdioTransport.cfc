component displayname="StdioTransport" hint="Handles stdio communication for MCP CLI bridge" {

    property name="inputReader" type="any";
    property name="systemOut" type="any";
    property name="systemErr" type="any";
    property name="isRunning" type="boolean" default="true";

    /**
     * Initialize the stdio transport
     */
    public StdioTransport function init() {
        // Initialize Java objects for stdio
        variables.systemOut = createObject("java", "java.lang.System").out;
        variables.systemErr = createObject("java", "java.lang.System").err;
        
        // Create buffered reader for stdin
        var systemIn = createObject("java", "java.lang.System").in;
        var inputStreamReader = createObject("java", "java.io.InputStreamReader").init(systemIn);
        variables.inputReader = createObject("java", "java.io.BufferedReader").init(inputStreamReader);
        
        variables.isRunning = true;
        
        return this;
    }

    /**
     * Read a line from stdin
     * @return The line read from stdin, or empty string if EOF
     */
    public string function readLine() {
        try {
            var line = variables.inputReader.readLine();
            if (isNull(line)) {
                variables.isRunning = false;
                return "";
            }
            return line;
        } catch (any e) {
            logError("Error reading from stdin: " & e.message);
            return "";
        }
    }

    /**
     * Write a message to stdout
     * @message The message to write
     */
    public void function writeMessage(required string message) {
        variables.systemOut.println(arguments.message);
        variables.systemOut.flush();
    }

    /**
     * Write a JSON response to stdout
     * @response The response struct to serialize and send
     */
    public void function writeResponse(required struct response) {
        var json = serializeJSON(arguments.response);
        writeMessage(json);
    }

    /**
     * Log a message to stderr
     * @message The message to log
     * @level The log level (DEBUG, INFO, WARN, ERROR)
     */
    public void function log(required string message, string level = "INFO") {
        var timestamp = dateTimeFormat(now(), "yyyy-mm-dd HH:nn:ss");
        variables.systemErr.println("[#arguments.level#] #timestamp# - #arguments.message#");
    }

    /**
     * Log an error to stderr
     * @message The error message
     */
    public void function logError(required string message) {
        log(arguments.message, "ERROR");
        writeLog(text=arguments.message, type="error", file="cf-mcp-cli");
    }

    /**
     * Log debug information to stderr
     * @message The debug message
     */
    public void function logDebug(required string message) {
        log(arguments.message, "DEBUG");
    }

    /**
     * Check if the transport is still running
     * @return True if still running, false if EOF reached
     */
    public boolean function isRunning() {
        return variables.isRunning;
    }

    /**
     * Close the transport and cleanup resources
     */
    public void function close() {
        variables.isRunning = false;
        try {
            variables.inputReader.close();
        } catch (any e) {
            // Ignore errors on close
        }
    }

    /**
     * Exit the process with a status code
     * @code The exit code (0 for success, non-zero for error)
     */
    public void function exit(numeric code = 0) {
        close();
        createObject("java", "java.lang.System").exit(arguments.code);
    }

}