<!DOCTYPE html>
<html>
<head>
    <title>Debug Watcher Status</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; }
        pre { background: #f0f0f0; padding: 15px; border-radius: 5px; overflow-x: auto; }
    </style>
</head>
<body>
    <h1>Debug Watcher Status Tool</h1>
    
    <cfscript>
    try {
        toolHandler = new components.ToolHandler();
        
        writeOutput('<h2>Raw Tool Result:</h2>');
        result = toolHandler.executeTool("getWatcherStatus", {});
        writeDump(result);
        
        writeOutput('<h2>Content Array:</h2>');
        if (structKeyExists(result, "content") && arrayLen(result.content) > 0) {
            writeDump(result.content);
            
            writeOutput('<h2>First Content Text:</h2>');
            writeOutput('<pre>' & encodeForHtml(result.content[1].text) & '</pre>');
            
            writeOutput('<h2>Attempting JSON Parse:</h2>');
            try {
                parsed = deserializeJson(result.content[1].text);
                writeDump(parsed);
            } catch (any jsonError) {
                writeOutput('<p style="color: red;">JSON Parse Error: ' & jsonError.message & '</p>');
            }
        }
        
    } catch (any e) {
        writeOutput('<h2>Error:</h2>');
        writeDump(e);
    }
    </cfscript>
</body>
</html>