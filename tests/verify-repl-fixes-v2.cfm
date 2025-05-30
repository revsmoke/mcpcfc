<cfscript>
// Fixed test to verify REPLTool security fixes are working

writeOutput("<h1>REPLTool Security Fix Verification</h1>");

try {
    // Test 1: Check if pre-compiled patterns exist
    writeOutput("<h2>Test 1: Pattern Pre-compilation</h2>");
    replTool = new mcpcfc.clitools.REPLTool();
    writeOutput("<p>✅ REPLTool initialized successfully</p>");
    
    // Test 2: Variable isolation test
    writeOutput("<h2>Test 2: Variable Isolation</h2>");
    
    // Try with safe context - no return statement in evaluate
    result1 = replTool.executeCode(
        code = "'ctx_data value: ' & (isDefined('ctx_data') ? ctx_data : 'not found')",
        returnOutput = false,
        timeout = 5,
        executionContext = {
            data: "This is allowed data",
            malicious: "This should NOT be accessible"
        }
    );
    
    writeOutput("<p>Safe context test:</p>");
    writeOutput("<ul>");
    writeOutput("<li>Success: #result1.success#</li>");
    writeOutput("<li>Return Value: #result1.returnValue#</li>");
    writeOutput("<li>Expected: 'ctx_data value: This is allowed data'</li>");
    writeOutput("</ul>");
    
    // Try to access non-whitelisted variable
    result2 = replTool.executeCode(
        code = "'malicious value: ' & (isDefined('malicious') ? malicious : 'not found')",
        returnOutput = false,
        timeout = 5,
        executionContext = {
            data: "This is allowed data",
            malicious: "This should NOT be accessible"
        }
    );
    
    writeOutput("<p>Malicious context test:</p>");
    writeOutput("<ul>");
    writeOutput("<li>Success: #result2.success#</li>");
    writeOutput("<li>Return Value: #result2.returnValue#</li>");
    writeOutput("<li>Expected: 'malicious value: not found' (variable not accessible)</li>");
    writeOutput("</ul>");
    
    // Test 3: Security pattern blocking
    writeOutput("<h2>Test 3: Security Pattern Blocking</h2>");
    
    // Test dangerous pattern
    result3 = replTool.executeCode(
        code = "createObject('java', 'java.io.File')",
        returnOutput = false,
        timeout = 5
    );
    
    writeOutput("<p>Dangerous pattern test (createObject):</p>");
    writeOutput("<ul>");
    writeOutput("<li>Success: #result3.success#</li>");
    writeOutput("<li>Error: #result3.error#</li>");
    writeOutput("<li>Should be blocked with 'unsafe operations' message</li>");
    writeOutput("</ul>");
    
    // Test reflection import pattern
    result4 = replTool.executeCode(
        code = "import java.lang.reflect.*;",
        returnOutput = false,
        timeout = 5
    );
    
    writeOutput("<p>Reflection import test:</p>");
    writeOutput("<ul>");
    writeOutput("<li>Success: #result4.success#</li>");
    writeOutput("<li>Error: #result4.error#</li>");
    writeOutput("<li>Should be blocked (new pattern added)</li>");
    writeOutput("</ul>");
    
    // Test safe code
    result5 = replTool.executeCode(
        code = "(1 + 1) * 10",
        returnOutput = false,
        timeout = 5
    );
    
    writeOutput("<p>Safe code test:</p>");
    writeOutput("<ul>");
    writeOutput("<li>Success: #result5.success#</li>");
    writeOutput("<li>Return Value: #result5.returnValue#</li>");
    writeOutput("<li>Expected: '20'</li>");
    writeOutput("</ul>");
    
    // Test variable isolation with simple assignment
    writeOutput("<h2>Test 4: Simple Context Variable Test</h2>");
    
    result6 = replTool.executeCode(
        code = "ctx_data",
        returnOutput = false,
        timeout = 5,
        executionContext = {
            data: "Simple test data"
        }
    );
    
    writeOutput("<p>Direct context variable access:</p>");
    writeOutput("<ul>");
    writeOutput("<li>Success: #result6.success#</li>");
    writeOutput("<li>Return Value: #result6.returnValue#</li>");
    writeOutput("<li>Expected: 'Simple test data'</li>");
    writeOutput("</ul>");
    
    writeOutput("<h2>Overall Status</h2>");
    
    allTestsPassed = result1.success && result2.success && !result3.success && !result4.success && result5.success && result6.success;
    
    if (allTestsPassed) {
        writeOutput("<p style='color: green; font-weight: bold;'>✅ All security fixes appear to be working correctly!</p>");
    } else {
        writeOutput("<p style='color: red; font-weight: bold;'>❌ Some tests failed - check the results above</p>");
    }
    
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