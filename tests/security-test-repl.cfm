<cfscript>
// Security Test for REPLTool.cfc
// This file demonstrates the security issues and tests the fixes

writeOutput("<h1>REPLTool Security Analysis</h1>");

// Issue 1: Variable overwriting vulnerability (lines 192-195, 200-203)
writeOutput("<h2>Issue 1: Variable Overwriting Vulnerability</h2>");
writeOutput("<p>The current implementation copies keys from isolatedScope directly into variables scope, allowing potential overwriting of critical variables.</p>");

writeOutput("<h3>Vulnerable Code Pattern:</h3>");
writeOutput("<pre>");
writeOutput("// Make context variables available
for (var key in isolatedScope) {
    variables[key] = isolatedScope[key];  // DANGEROUS: Can overwrite anything!
}");
writeOutput("</pre>");

writeOutput("<h3>Attack Example:</h3>");
writeOutput("<pre>");
writeOutput("// Attacker could pass executionContext with malicious keys:
executionContext = {
    'isCodeSafe': function() { return true; },  // Override security function
    'evaluate': maliciousFunction,              // Replace evaluate function
    'threadResult': maliciousStruct             // Overwrite result tracking
}");
writeOutput("</pre>");

// Issue 2: Performance issues in isCodeSafe (lines 629-765)
writeOutput("<h2>Issue 2: Performance Issues in isCodeSafe()</h2>");
writeOutput("<p>The function recompiles regex patterns on every call, causing performance degradation.</p>");

// Demonstrate the regex issues
writeOutput("<h3>Current Issues:</h3>");
writeOutput("<ul>");
writeOutput("<li>Regex patterns are created fresh on each function call</li>");
writeOutput("<li>No pattern caching or pre-compilation</li>");
writeOutput("<li>Potential regex escape issues in keyword pattern generation</li>");
writeOutput("<li>Missing coverage for some reflection patterns</li>");
writeOutput("</ul>");

// Show timing test
writeOutput("<h3>Performance Impact Test:</h3>");
try {
    var testCode = "var x = 1 + 1;";
    var iterations = 100;
    var startTime = getTickCount();
    
    // Call isCodeSafe multiple times
    for (var i = 1; i <= iterations; i++) {
        // We can't call isCodeSafe directly as it's private, but we can test through executeCode
        var repl = new mcpcfc.clitools.REPLTool();
        var result = repl.executeCode(code=testCode, returnOutput=false, timeout=1);
    }
    
    var elapsed = getTickCount() - startTime;
    writeOutput("<p>Time for #iterations# security checks: #elapsed#ms (Average: #numberFormat(elapsed/iterations, '0.00')#ms per check)</p>");
} catch (any e) {
    writeOutput("<p>Error testing performance: #e.message#</p>");
}

writeOutput("<h2>Proposed Solutions</h2>");

writeOutput("<h3>Solution 1: Safe Variable Isolation</h3>");
writeOutput("<pre>");
writeOutput("// Create a safe execution context with prefixed or whitelisted variables
var safeContext = structNew();
var allowedKeys = ['input', 'params', 'data']; // Whitelist approach

for (var key in isolatedScope) {
    if (arrayFind(allowedKeys, key) > 0) {
        safeContext[key] = isolatedScope[key];
    } else {
        // Or use prefixing: safeContext['user_' & key] = isolatedScope[key];
    }
}

// Execute with safe context only
evaluate(code); // Variables from safeContext available via closure
");
writeOutput("</pre>");

writeOutput("<h3>Solution 2: Pre-compiled Security Patterns</h3>");
writeOutput("<pre>");
writeOutput("// In component initialization
variables.securityPatterns = {
    dangerous: compilePatterns(dangerousRegexPatterns),
    reflection: compilePatterns(reflectionPatterns),
    keywords: compileKeywordPatterns(suspiciousKeywords)
};

// In isCodeSafe function
for (var pattern in variables.securityPatterns.dangerous) {
    if (pattern.matcher(codeToCheck)) {
        return false;
    }
}
");
writeOutput("</pre>");

writeOutput("<h3>Additional Security Recommendations:</h3>");
writeOutput("<ul>");
writeOutput("<li>Add rate limiting to prevent abuse</li>");
writeOutput("<li>Implement execution quotas (max executions per session)</li>");
writeOutput("<li>Add comprehensive logging of blocked attempts</li>");
writeOutput("<li>Consider AST-based analysis instead of regex</li>");
writeOutput("<li>Implement resource limits (memory, CPU time)</li>");
writeOutput("</ul>");

</cfscript></cfscontent>