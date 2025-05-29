<cfscript>
try {
    // Try to instantiate DevWorkflowTool
    devTool = new mcpcfc.clitools.DevWorkflowTool();
    
    writeOutput("<h2>DevWorkflowTool instantiated successfully!</h2>");
    
    // Get tool definitions
    toolDefs = devTool.getToolDefinitions();
    
    writeOutput("<p>Number of tools defined: " & arrayLen(toolDefs) & "</p>");
    
    // List all tools
    writeOutput("<ul>");
    for (tool in toolDefs) {
        writeOutput("<li><strong>" & tool.name & "</strong>: " & tool.description & "</li>");
    }
    writeOutput("</ul>");
    
} catch (any e) {
    writeOutput("<h2>Error loading DevWorkflowTool:</h2>");
    writeOutput("<p><strong>Message:</strong> " & e.message & "</p>");
    writeOutput("<p><strong>Detail:</strong> " & e.detail & "</p>");
    writeOutput("<p><strong>Type:</strong> " & e.type & "</p>");
    
    if (structKeyExists(e, "tagContext") && isArray(e.tagContext) && arrayLen(e.tagContext) > 0) {
        writeOutput("<h3>Stack Trace:</h3>");
        writeOutput("<ul>");
        for (context in e.tagContext) {
            if (isStruct(context)) {
                writeOutput("<li>Line " & (structKeyExists(context, "line") ? context.line : "?") & 
                           " in " & (structKeyExists(context, "template") ? context.template : "?") & "</li>");
            }
        }
        writeOutput("</ul>");
    }
}
</cfscript>