<cfscript>
// Test Case: Security Pattern Coverage

writeOutput("<h2>Security Pattern Testing</h2>");

securityTests = [
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
    fixedTool = new mcpcfc.clitools.REPLTool_FIXED();
    
    writeOutput("<h3>Security Pattern Test Results:</h3>");
    writeOutput("<table border='1' cellpadding='5'>");
    writeOutput("<tr><th>Test Code</th><th>Expected</th><th>Actual</th><th>Result</th><th>Reason</th></tr>");
    
    for (test in securityTests) {
        result = fixedTool.executeCode(code=test.code, returnOutput=false, timeout=1);
        blocked = !result.success && findNoCase("unsafe operations", result.error) > 0;
        passed = (blocked == test.shouldBlock);
        
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
