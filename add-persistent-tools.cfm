<!DOCTYPE html>
<html>
<head>
    <title>Add Persistent Instance Tools</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; }
        .success { color: green; }
        .error { color: red; }
        .code { background: #f0f0f0; padding: 10px; border-radius: 5px; font-family: monospace; }
        .section { margin: 20px 0; padding: 15px; border: 1px solid #ddd; border-radius: 5px; }
    </style>
</head>
<body>
    <h1>Add Persistent Instance Tools to Application</h1>
    
    <cfscript>
    try {
        // Check if tools already registered
        var persistentBridgeRegistered = false;
        var persistentChatRegistered = false;
        
        if (structKeyExists(application, "toolRegistry")) {
            var tools = application.toolRegistry.getRegisteredTools();
            
            for (var toolName in tools) {
                if (toolName == "registerInstancePersistent") {
                    persistentBridgeRegistered = true;
                }
                if (toolName == "sendMessagePersistent") {
                    persistentChatRegistered = true;
                }
            }
        }
        
        writeOutput('<div class="section">');
        writeOutput('<h2>Current Status:</h2>');
        writeOutput('<p>Persistent Instance Bridge: ' & (persistentBridgeRegistered ? '<span class="success">Registered</span>' : '<span class="error">Not Registered</span>') & '</p>');
        writeOutput('<p>Persistent Realtime Chat: ' & (persistentChatRegistered ? '<span class="success">Registered</span>' : '<span class="error">Not Registered</span>') & '</p>');
        writeOutput('</div>');
        
        writeOutput('<div class="section">');
        writeOutput('<h2>Instructions to Add Persistent Tools:</h2>');
        writeOutput('<p>Add the following code to Application.cfc after line 451 (after the existing communication tools):</p>');
        
        writeOutput('<div class="code"><pre>
        // Register Persistent Claude-to-Claude communication tools
        try {
            // Register Persistent Instance Bridge
            var instanceBridgePersistent = new mcpcfc.tools.InstanceBridgePersistent();
            var persistBridgeTools = instanceBridgePersistent.getToolDefinitions();
            
            for (var tool in persistBridgeTools) {
                if (!structKeyExists(tool, "name") || !structKeyExists(tool, "description") || !structKeyExists(tool, "inputSchema")) {
                    writeLog(text="Skipping invalid persistent bridge tool definition: missing required properties", type="warning");
                    continue;
                }
                
                // Add "Persistent" suffix to avoid conflicts
                var persistentToolName = tool.name & "Persistent";
                
                application.toolRegistry.registerTool(persistentToolName, {
                    "description": tool.description & " (with database persistence)",
                    "inputSchema": tool.inputSchema
                });
            }
            
            // Register Persistent Realtime Chat
            var realtimeChatPersistent = new mcpcfc.tools.RealtimeChatPersistent();
            var persistChatTools = realtimeChatPersistent.getToolDefinitions();
            
            for (var tool in persistChatTools) {
                if (!structKeyExists(tool, "name") || !structKeyExists(tool, "description") || !structKeyExists(tool, "inputSchema")) {
                    writeLog(text="Skipping invalid persistent chat tool definition: missing required properties", type="warning");
                    continue;
                }
                
                // Add "Persistent" suffix to avoid conflicts
                var persistentToolName = tool.name & "Persistent";
                
                application.toolRegistry.registerTool(persistentToolName, {
                    "description": tool.description & " (with database persistence)",
                    "inputSchema": tool.inputSchema
                });
            }
            
            writeLog(text="Persistent Claude-to-Claude communication tools registered successfully!", type="information");
            
        } catch (any e) {
            writeLog(text="Failed to register persistent communication tools: " & e.message, type="error");
        }
</pre></div>');
        writeOutput('</div>');
        
        writeOutput('<div class="section">');
        writeOutput('<h2>Usage Guide for Claude:</h2>');
        writeOutput('<h3>1. First Time Registration (New Instance):</h3>');
        writeOutput('<div class="code"><pre>
// Use registerInstancePersistent instead of registerInstance
{
    "tool": "registerInstancePersistent",
    "arguments": {
        "instanceId": "claude-desktop-001",
        "instanceName": "Claude Desktop - Bryan",
        "capabilities": {
            "model": "claude-3-opus",
            "context": "desktop"
        }
    }
}

// Response will include:
// - connectionToken (save this for reconnection!)
// - generation: 1 (first generation)
</pre></div>');
        
        writeOutput('<h3>2. Reconnecting After Context Reset:</h3>');
        writeOutput('<div class="code"><pre>
// Use the same instanceId and provide connectionToken if available
{
    "tool": "registerInstancePersistent",
    "arguments": {
        "instanceId": "claude-desktop-001",
        "instanceName": "Claude Desktop - Bryan",
        "connectionToken": "saved-token-from-previous-session",
        "attemptReconnect": true
    }
}

// Response will include:
// - reconnected: true
// - generation: 2 (incremented)
// - messageHistory: array of previous messages
// - previousGeneration: 1
</pre></div>');
        
        writeOutput('<h3>3. Sending Persistent Messages:</h3>');
        writeOutput('<div class="code"><pre>
// Use sendMessagePersistent for database-backed messaging
{
    "tool": "sendMessagePersistent",
    "arguments": {
        "fromInstanceId": "claude-desktop-001",
        "toInstanceId": "claude-code-001",
        "message": "Hello from a new session! I can see our history!",
        "messageType": "text"
    }
}
</pre></div>');
        
        writeOutput('<h3>4. Getting Full Message History:</h3>');
        writeOutput('<div class="code"><pre>
// Use getMessagesPersistent with includeLineage
{
    "tool": "getMessagesPersistent",
    "arguments": {
        "instanceId": "claude-desktop-001",
        "includeLineage": true,  // Gets messages from all generations
        "limit": 100
    }
}
</pre></div>');
        writeOutput('</div>');
        
        writeOutput('<div class="section">');
        writeOutput('<h2>Migration Strategy:</h2>');
        writeOutput('<ol>');
        writeOutput('<li>Both original and persistent tools can coexist</li>');
        writeOutput('<li>Persistent tools have "Persistent" suffix (e.g., registerInstancePersistent)</li>');
        writeOutput('<li>Start using persistent tools for new registrations</li>');
        writeOutput('<li>Existing instances continue working with original tools</li>');
        writeOutput('<li>Messages between persistent and non-persistent instances still work</li>');
        writeOutput('</ol>');
        writeOutput('</div>');
        
        writeOutput('<div class="section">');
        writeOutput('<h2>Benefits of Persistent Tools:</h2>');
        writeOutput('<ul>');
        writeOutput('<li>✅ Survive application restarts</li>');
        writeOutput('<li>✅ Reconnect after context loss</li>');
        writeOutput('<li>✅ Full message history across generations</li>');
        writeOutput('<li>✅ Track instance lineage</li>');
        writeOutput('<li>✅ Connection tokens for security</li>');
        writeOutput('<li>✅ Automatic archival of inactive instances</li>');
        writeOutput('</ul>');
        writeOutput('</div>');
        
    } catch (any e) {
        writeOutput('<p class="error">Error: ' & e.message & '</p>');
        writeDump(e);
    }
    </cfscript>
</body>
</html>