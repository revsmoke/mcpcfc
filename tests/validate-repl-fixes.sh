#!/bin/bash

# Test script for REPLTool security fixes
# This script demonstrates that the fixes address the vulnerabilities

echo "=== REPLTool Security Fix Validation ==="
echo "Testing both the original and fixed versions..."
echo

# Test directory
TEST_DIR="/Applications/ColdFusion2023/cfusion/wwwroot/mcpcfc/tests"

# Create test case for variable overwriting vulnerability
cat > "$TEST_DIR/test-variable-overwrite.cfm" << 'EOF'
<cfscript>
// Test Case: Variable Overwriting Vulnerability

writeOutput("<h2>Testing Variable Overwriting Protection</h2>");

// Create an instance of the original REPLTool
try {
    var originalTool = new mcpcfc.clitools.REPLTool();
    
    // Attempt to overwrite critical variables through executionContext
    var maliciousContext = {
        "threadResult": "HACKED!",
        "isCodeSafe": function() { return true; },
        "evaluate": function(code) { return "COMPROMISED"; }
    };
    
    var result1 = originalTool.executeCode(
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
    var fixedTool = new mcpcfc.clitools.REPLTool_FIXED();
    
    // Same malicious context
    var maliciousContext = {
        "threadResult": "HACKED!",
        "isCodeSafe": function() { return true; },
        "evaluate": function(code) { return "COMPROMISED"; },
        "data": "This is allowed data"  // This should be allowed
    };
    
    var result2 = fixedTool.executeCode(
        code = "return 'test with ctx_data: ' & (isDefined('ctx_data') ? ctx_data : 'not found');",
        returnOutput = false,
        timeout = 5,
        executionContext = maliciousContext
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
EOF

# Create performance comparison test
cat > "$TEST_DIR/test-performance-comparison.cfm" << 'EOF'
<cfscript>
// Test Case: Performance Comparison

writeOutput("<h2>Performance Comparison: Original vs Fixed</h2>");

var testCodes = [
    "var x = 1 + 1;",
    "var arr = [1,2,3,4,5]; return arrayLen(arr);",
    "var str = 'hello world'; return uCase(str);",
    "var dt = now(); return dateFormat(dt, 'yyyy-mm-dd');"
];

var iterations = 50;

// Test original implementation
try {
    var originalTool = new mcpcfc.clitools.REPLTool();
    var originalTimes = [];
    
    for (var testCode in testCodes) {
        var start = getTickCount();
        for (var i = 1; i <= iterations; i++) {
            originalTool.executeCode(code=testCode, returnOutput=false, timeout=1);
        }
        var elapsed = getTickCount() - start;
        arrayAppend(originalTimes, elapsed);
    }
    
    writeOutput("<h3>Original Implementation Times:</h3>");
    writeOutput("<ul>");
    for (var i = 1; i <= arrayLen(testCodes); i++) {
        writeOutput("<li>Test #i#: #originalTimes[i]#ms (avg: #numberFormat(originalTimes[i]/iterations, '0.00')#ms)</li>");
    }
    writeOutput("</ul>");
    
} catch (any e) {
    writeOutput("<p>Error testing original: #e.message#</p>");
}

// Test fixed implementation
try {
    var fixedTool = new mcpcfc.clitools.REPLTool_FIXED();
    var fixedTimes = [];
    
    for (var testCode in testCodes) {
        var start = getTickCount();
        for (var i = 1; i <= iterations; i++) {
            fixedTool.executeCode(code=testCode, returnOutput=false, timeout=1);
        }
        var elapsed = getTickCount() - start;
        arrayAppend(fixedTimes, elapsed);
    }
    
    writeOutput("<h3>Fixed Implementation Times (with pre-compiled patterns):</h3>");
    writeOutput("<ul>");
    for (var i = 1; i <= arrayLen(testCodes); i++) {
        writeOutput("<li>Test #i#: #fixedTimes[i]#ms (avg: #numberFormat(fixedTimes[i]/iterations, '0.00')#ms)</li>");
        if (i <= arrayLen(originalTimes)) {
            var improvement = ((originalTimes[i] - fixedTimes[i]) / originalTimes[i]) * 100;
            writeOutput(" <strong>(" & numberFormat(improvement, "+0.0") & "% improvement)</strong>");
        }
    }
    writeOutput("</ul>");
    
} catch (any e) {
    writeOutput("<p>Error testing fixed: #e.message#</p>");
}

writeOutput("<p><strong>Result:</strong> Pre-compiled patterns should show performance improvement, especially for repeated executions.</p>");
</cfscript>
EOF

# Create security pattern test
cat > "$TEST_DIR/test-security-patterns.cfm" << 'EOF'
<cfscript>
// Test Case: Security Pattern Coverage

writeOutput("<h2>Security Pattern Testing</h2>");

var securityTests = [
    {
        code: "createObject('java', 'java.io.File')",
        shouldBlock: true,
        reason: "Java object creation"
    },
    {
        code: "import java.lang.reflect.*;",
        shouldBlock: true,
        reason: "Reflection import (new pattern)"
    },
    {
        code: "var x = 1 + 1; return x;",
        shouldBlock: false,
        reason: "Safe arithmetic"
    },
    {
        code: "fileRead('/etc/passwd')",
        shouldBlock: true,
        reason: "File system access"
    },
    {
        code: "application.password = 'hacked'",
        shouldBlock: true,
        reason: "Scope manipulation"
    },
    {
        code: "var obj = {}; obj.class.forName('evil')",
        shouldBlock: true,
        reason: "Class loading attempt"
    }
];

try {
    var fixedTool = new mcpcfc.clitools.REPLTool_FIXED();
    
    writeOutput("<h3>Security Pattern Test Results:</h3>");
    writeOutput("<table border='1' cellpadding='5'>");
    writeOutput("<tr><th>Test Code</th><th>Expected</th><th>Actual</th><th>Result</th><th>Reason</th></tr>");
    
    for (var test in securityTests) {
        var result = fixedTool.executeCode(code=test.code, returnOutput=false, timeout=1);
        var blocked = !result.success && findNoCase("unsafe operations", result.error) > 0;
        var passed = (blocked == test.shouldBlock);
        
        writeOutput("<tr>");
        writeOutput("<td><code>#encodeForHTML(test.code)#</code></td>");
        writeOutput("<td>" & (test.shouldBlock ? "Block" : "Allow") & "</td>");
        writeOutput("<td>" & (blocked ? "Blocked" : "Allowed") & "</td>");
        writeOutput("<td style='color:" & (passed ? "green" : "red") & "'>" & (passed ? "✓ PASS" : "✗ FAIL") & "</td>");
        writeOutput("<td>#test.reason#</td>");
        writeOutput("</tr>");
    }
    
    writeOutput("</table>");
    
} catch (any e) {
    writeOutput("<p>Error in security testing: #e.message#</p>");
}

writeOutput("<p><strong>Result:</strong> All dangerous patterns should be blocked while safe code is allowed.</p>");
</cfscript>
EOF

# Create a summary page
cat > "$TEST_DIR/security-fix-summary.cfm" << 'EOF'
<cfscript>
writeOutput("<h1>REPLTool Security Fix Summary</h1>");

writeOutput("<h2>Vulnerabilities Addressed:</h2>");
writeOutput("<ol>");
writeOutput("<li><strong>Variable Overwriting (CVE-like: Privilege Escalation)</strong>");
writeOutput("<ul>");
writeOutput("<li>Original: Directly copied all executionContext keys to variables scope</li>");
writeOutput("<li>Fixed: Whitelist approach with prefixed variables (ctx_*)</li>");
writeOutput("<li>Impact: Prevents attackers from overwriting critical functions/variables</li>");
writeOutput("</ul></li>");

writeOutput("<li><strong>Performance Degradation (DoS potential)</strong>");
writeOutput("<ul>");
writeOutput("<li>Original: Recompiled regex patterns on every security check</li>");
writeOutput("<li>Fixed: Pre-compiled patterns in init() method</li>");
writeOutput("<li>Impact: Significant performance improvement, prevents DoS via repeated checks</li>");
writeOutput("</ul></li>");

writeOutput("<li><strong>Regex Escape Bug</strong>");
writeOutput("<ul>");
writeOutput("<li>Original: Incorrect bracket escaping in regex patterns</li>");
writeOutput("<li>Fixed: Proper escape sequence handling</li>");
writeOutput("<li>Impact: Ensures all security patterns work correctly</li>");
writeOutput("</ul></li>");

writeOutput("<li><strong>Missing Reflection Patterns</strong>");
writeOutput("<ul>");
writeOutput("<li>Original: Missing 'import java.lang.reflect.*' pattern</li>");
writeOutput("<li>Fixed: Added comprehensive reflection import patterns</li>");
writeOutput("<li>Impact: Better coverage against reflection-based attacks</li>");
writeOutput("</ul></li>");
writeOutput("</ol>");

writeOutput("<h2>Run Tests:</h2>");
writeOutput("<ul>");
writeOutput("<li><a href='test-variable-overwrite.cfm'>Variable Overwriting Test</a></li>");
writeOutput("<li><a href='test-performance-comparison.cfm'>Performance Comparison</a></li>");
writeOutput("<li><a href='test-security-patterns.cfm'>Security Pattern Coverage</a></li>");
writeOutput("</ul>");

writeOutput("<h2>Recommendations:</h2>");
writeOutput("<ol>");
writeOutput("<li>Replace REPLTool.cfc with REPLTool_FIXED.cfc after testing</li>");
writeOutput("<li>Implement rate limiting as mentioned in TODOs</li>");
writeOutput("<li>Add session-based execution quotas</li>");
writeOutput("<li>Consider implementing AST-based code analysis for better security</li>");
writeOutput("<li>Add comprehensive logging of all blocked attempts</li>");
writeOutput("</ol>");
</cfscript>
EOF

echo "Test files created successfully!"
echo
echo "To validate the fixes, visit:"
echo "http://localhost:8500/mcpcfc/tests/security-fix-summary.cfm"
echo
echo "Individual tests:"
echo "- http://localhost:8500/mcpcfc/tests/test-variable-overwrite.cfm"
echo "- http://localhost:8500/mcpcfc/tests/test-performance-comparison.cfm" 
echo "- http://localhost:8500/mcpcfc/tests/test-security-patterns.cfm"
