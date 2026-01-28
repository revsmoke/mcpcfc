<cfsetting enableCFOutputOnly="true">
<cfscript>
// Set SSE headers
cfheader(name="Content-Type", value="text/event-stream; charset=utf-8");
cfheader(name="Cache-Control", value="no-cache, no-store, must-revalidate");
cfheader(name="Access-Control-Allow-Origin", value="*");
cfheader(name="X-Accel-Buffering", value="no");

// Set request timeout
cfsetting(requesttimeout=300);

// Get session ID from query parameters
param name="url.sessionId" default="";

if (len(url.sessionId) == 0) {
    url.sessionId = createUUID();
}

// Register session
application.sessionManager.createSession(url.sessionId);

// Constants
newline = chr(10);
stopPollingAt = getTickCount() + (290 * 1000); // 290 seconds
TimeUnit = createObject("java", "java.util.concurrent.TimeUnit");
lastHeartbeat = 0; // Initialize heartbeat timer

// Send initial connection event
writeOutput("event: connection" & newline);
writeOutput("id: " & createUUID() & newline);
writeOutput("data: " & serializeJson({
    "type": "connection",
    "sessionId": url.sessionId
}) & newline);
writeOutput(newline);
getPageContext().getOut().flush();

// Main SSE loop
while (getTickCount() < stopPollingAt) {
    try {
        // Poll for messages with 1-second timeout
        message = application.messageQueue.poll(1, TimeUnit.Seconds);
        
        if (!isNull(message) && message.sessionId == url.sessionId) {
            // Send MCP message via SSE
            writeOutput("event: mcp" & newline);
            writeOutput("id: " & createUUID() & newline);
            writeOutput("data: " & serializeJson(message.content) & newline);
            writeOutput(newline);
            getPageContext().getOut().flush();
        }        
        // Send periodic heartbeat every 30 seconds
        if (!isDefined("lastHeartbeat") || (getTickCount() - lastHeartbeat) > 30000) {
            writeOutput("event: heartbeat" & newline);
            writeOutput("data: " & now() & newline);
            writeOutput(newline);
            getPageContext().getOut().flush();
            lastHeartbeat = getTickCount();
        }
        
    } catch (any e) {
        // Log error but continue
        writeLog(text="SSE Error: #e.message#", type="error");
    }
}

// Clean up session on disconnect
application.sessionManager.removeSession(url.sessionId);
</cfscript>