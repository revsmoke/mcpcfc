<cfscript>
// Debug test for REPLTool variable isolation

writeOutput("<h1>REPLTool Variable Isolation Debug</h1>");

try {
    replTool = new mcpcfc.clitools.REPLTool();
    
    writeOutput("<h2>Test 1: Simple Variable Access</h2>");
    
    // Test without any context
    result1 = replTool.executeCode(
        code = "return 'Hello World';",
        returnOutput = false,
        timeout = 5
    );
    
    writeOutput("<p>Simple test without context:</p>");
    writeOutput("<ul>");
    writeOutput("<li>Success: #result1.success#</li>");
    writeOutput("<li>Return Value: #result1.returnValue#</li>");
    writeOutput("<li>Error: #result1.error#</li>");
    writeOutput("</ul>");
    
    // Test with context
    writeOutput("<h2>Test 2: Context Variable Access</h2>");
    
    result2 = replTool.executeCode(
        code = "return 'ctx_data exists: ' & isDefined('ctx_data');",
        returnOutput = false,
        timeout = 5,
        executionContext = {
            data: "Test Data"
        }
    );
    
    writeOutput("<p>Check if ctx_data is defined:</p>");
    writeOutput("<ul>");
    writeOutput("<li>Success: #result2.success#</li>");
    writeOutput("<li>Return Value: #result2.returnValue#</li>");
    writeOutput("<li>Error: #result2.error#</li>");
    writeOutput("</ul>");
    
    // Test accessing the actual value
    writeOutput("<h2>Test 3: Access Context Value</h2>");
    
    result3 = replTool.executeCode(
        code = "if (isDefined('ctx_data')) { return ctx_data; } else { return 'ctx_data not found'; }",
        returnOutput = false,
        timeout = 5,
        executionContext = {
            data: "This is the test data"
        }
    );
    
    writeOutput("<p>Try to return ctx_data value:</p>");
    writeOutput("<ul>");
    writeOutput("<li>Success: #result3.success#</li>");
    writeOutput("<li>Return Value: #result3.returnValue#</li>");
    writeOutput("<li>Error: #result3.error#</li>");
    writeOutput("</ul>");
    
    // Test security check
    writeOutput("<h2>Test 4: Verify isDefined() is Safe</h2>");
    
    result4 = replTool.executeCode(
        code = "isDefined('test')",
        returnOutput = false,
        timeout = 5
    );
    
    writeOutput("<p>Simple isDefined test:</p>");
    writeOutput("<ul>");
    writeOutput("<li>Success: #result4.success#</li>");
    writeOutput("<li>Return Value: #result4.returnValue#</li>");
    writeOutput("<li>Error: #result4.error#</li>");
    writeOutput("</ul>");
    
} catch (any e) {
    writeOutput("<h2>Error During Testing</h2>");
    writeOutput("<p style='color: red;'>Error: #e.message#</p>");
    writeOutput("<pre>");
    writeDump(var=e, format="text");
    writeOutput("</pre>");
}

writeOutput("<hr>");
writeOutput("<p><a href='/mcpcfc/'>Back to MCPCFC Home</a></p>");
</cfscript>