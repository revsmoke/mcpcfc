<cfscript>
// Test Case: Variable Overwriting Vulnerability

writeOutput("<h2>Testing Variable Overwriting Protection</h2>");

// Create an instance of the original REPLTool
try {
    originalTool = new mcpcfc.clitools.REPLTool();
    
    // Attempt to overwrite critical variables through executionContext
    maliciousContext = {
        "threadResult": "HACKED!",
        "isCodeSafe": function() { return true; },
        "evaluate": function(code) { return "COMPROMISED"; }
    };
    
    result1 = originalTool.executeCode(
        code = "return 'test result';",
        returnOutput = false,
        timeout = 5,
        executionContext = maliciousContext
    );
    
    writeOutput("<h3>Original Implementation:</h3>");
    writeOutput("<pre>");
    writeDump(var=result1, format="text");
    writeOutput("</pre>");
    
} catch (any e) {
    writeOutput("<p>Error with original: #e.message#</p>");
}

// Now test the fixed version
try {
    fixedTool = new mcpcfc.clitools.REPLTool_FIXED();
    
    // Same malicious context
    maliciousContext2 = {
        "threadResult": "HACKED!",
        "isCodeSafe": function() { return true; },
        "evaluate": function(code) { return "COMPROMISED"; },
        "data": "This is allowed data"  // This should be allowed
    };
    
    result2 = fixedTool.executeCode(
        code = "return 'test with ctx_data: ' & (isDefined('ctx_data') ? ctx_data : 'not found');",
        returnOutput = false,
        timeout = 5,
        executionContext = maliciousContext2
    );
    
    writeOutput("<h3>Fixed Implementation:</h3>");
    writeOutput("<pre>");
    writeDump(var=result2, format="text");
    writeOutput("</pre>");
    
    writeOutput("<p><strong>Result:</strong> The fixed version only allows whitelisted keys with 'ctx_' prefix, preventing variable overwriting.</p>");
    
} catch (any e) {
    writeOutput("<p>Error with fixed version: #e.message#</p>");
}
</cfscript>
