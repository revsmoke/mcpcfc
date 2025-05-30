<cfscript>
// Debug safe code execution

writeOutput("<h1>Debug Safe Code Execution</h1>");

try {
    replTool = new mcpcfc.clitools.REPLTool();
    
    writeOutput("<h2>Test Various Safe Code Patterns</h2>");
    
    // Test 1: Simple math
    result1 = replTool.executeCode(
        code = "1 + 1",
        returnOutput = false,
        timeout = 5
    );
    
    writeOutput("<p>Test 1: Simple math (1 + 1):</p>");
    writeOutput("<ul>");
    writeOutput("<li>Success: #result1.success#</li>");
    writeOutput("<li>Return Value: #result1.returnValue#</li>");
    writeOutput("<li>Error: #result1.error#</li>");
    writeOutput("</ul>");
    
    // Test 2: Variable assignment and return
    result2 = replTool.executeCode(
        code = "x = 1 + 1; x",
        returnOutput = false,
        timeout = 5
    );
    
    writeOutput("<p>Test 2: Variable assignment (x = 1 + 1; x):</p>");
    writeOutput("<ul>");
    writeOutput("<li>Success: #result2.success#</li>");
    writeOutput("<li>Return Value: #result2.returnValue#</li>");
    writeOutput("<li>Error: #result2.error#</li>");
    writeOutput("</ul>");
    
    // Test 3: String concatenation
    result3 = replTool.executeCode(
        code = "'Hello' & ' ' & 'World'",
        returnOutput = false,
        timeout = 5
    );
    
    writeOutput("<p>Test 3: String concatenation:</p>");
    writeOutput("<ul>");
    writeOutput("<li>Success: #result3.success#</li>");
    writeOutput("<li>Return Value: #result3.returnValue#</li>");
    writeOutput("<li>Error: #result3.error#</li>");
    writeOutput("</ul>");
    
    // Test 4: Check if 'x' or 'key' are blocked keywords
    result4 = replTool.executeCode(
        code = "myVar = 42; myVar",
        returnOutput = false,
        timeout = 5
    );
    
    writeOutput("<p>Test 4: Variable with different name (myVar = 42):</p>");
    writeOutput("<ul>");
    writeOutput("<li>Success: #result4.success#</li>");
    writeOutput("<li>Return Value: #result4.returnValue#</li>");
    writeOutput("<li>Error: #result4.error#</li>");
    writeOutput("</ul>");
    
    // Test 5: Check if the word 'Result' is blocked
    result5 = replTool.executeCode(
        code = "'Test: 2'",
        returnOutput = false,
        timeout = 5
    );
    
    writeOutput("<p>Test 5: Simple string without 'Result':</p>");
    writeOutput("<ul>");
    writeOutput("<li>Success: #result5.success#</li>");
    writeOutput("<li>Return Value: #result5.returnValue#</li>");
    writeOutput("<li>Error: #result5.error#</li>");
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