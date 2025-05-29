component displayname="StdioTransport" hint="Handles stdio communication for MCP CLI bridge" {

    property name="inputReader" type="any";
    property name="systemOut" type="any";
    property name="systemErr" type="any";
    property name="isRunning" type="boolean" default="true";
public StdioTransport function init() {
     try {
         // Java I/O handles
         variables.systemOut  = createObject("java", "java.lang.System").out;
         variables.systemErr  = createObject("java", "java.lang.System").err;

         // Buffered UTF-8 reader for stdin
         var systemIn         = createObject("java", "java.lang.System").in;
         var inputStreamReader = createObject("java", "java.io.InputStreamReader")
                                 .init(systemIn, "UTF-8");
         variables.inputReader = createObject("java", "java.io.BufferedReader")
                                 .init(inputStreamReader);

         variables.isRunning  = true;
        
        return this;
    } catch (any e) {
        variables.systemErr.println("Failed to initialize StdioTransport: " & e.message);
        rethrow;
    }
 }

 /**
  * Write a message to stdout
  * @message The message to write
  */
 private void function writeMessage(required string message) {
     variables.systemOut.println(arguments.message);
     variables.systemOut.flush();
 }

 /**
  * Write a JSON response to stdout
  * @response The response structure to serialize and send
  */
 public void function writeResponse(required struct response) {
     try {
         var json = serializeJSON(arguments.response);
         writeMessage(json);
     } catch (any e) {
         logError("Failed to serialize response: " & e.message);
         writeMessage('{"error": "Failed to serialize response"}');
     }
 }

    /**
     * Log a message to stderr
     * @message The message to log
     * @level The log level (DEBUG, INFO, WARN, ERROR)
     */
    public void function log(required string message, string level = "INFO") {
var timestamp = dateTimeFormat(now(), "yyyy-MM-dd HH:nn:ss");
        variables.systemErr.println("[#arguments.level#] #timestamp# - #arguments.message#");
    }

    /**
     * Log an error to stderr
     */
    public void function logError(required string message) {
        log(arguments.message, "ERROR");
        writeLog(text=arguments.message, type="error", file="cf-mcp-cli");
    }

    /**
     * Log debug information to stderr
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
            // Log but don't throw errors on close
            variables.systemErr.println("Warning: Error closing input reader: " & e.message);
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