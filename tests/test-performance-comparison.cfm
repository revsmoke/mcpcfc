<cfscript>
// Test Case: Performance Comparison

writeOutput("<h2>Performance Comparison: Original vs Fixed</h2>");

testCodes = [
    "var x = 1 + 1;",
    "var arr = [1,2,3,4,5]; return arrayLen(arr);",
    "var str = 'hello world'; return uCase(str);",
    "var dt = now(); return dateFormat(dt, 'yyyy-mm-dd');"
];

iterations = 50;

// Test original implementation
try {
    originalTool = new mcpcfc.clitools.REPLTool();
    originalTimes = [];
    
    for (testCode in testCodes) {
        start = getTickCount();
        for (i = 1; i <= iterations; i++) {
            originalTool.executeCode(code=testCode, returnOutput=false, timeout=1);
        }
        elapsed = getTickCount() - start;
        arrayAppend(originalTimes, elapsed);
    }
    
    writeOutput("<h3>Original Implementation Times:</h3>");
    writeOutput("<ul>");
    for (i = 1; i <= arrayLen(testCodes); i++) {
        writeOutput("<li>Test #i#: #originalTimes[i]#ms (avg: #numberFormat(originalTimes[i]/iterations, '0.00')#ms)</li>");
    }
    writeOutput("</ul>");
    
} catch (any e) {
    writeOutput("<p>Error testing original: #e.message#</p>");
}

// Test fixed implementation
try {
    fixedTool = new mcpcfc.clitools.REPLTool_FIXED();
    fixedTimes = [];
    
    for (testCode in testCodes) {
        start = getTickCount();
        for (i = 1; i <= iterations; i++) {
            fixedTool.executeCode(code=testCode, returnOutput=false, timeout=1);
        }
        elapsed = getTickCount() - start;
        arrayAppend(fixedTimes, elapsed);
    }
    
    writeOutput("<h3>Fixed Implementation Times (with pre-compiled patterns):</h3>");
    writeOutput("<ul>");
    for (i = 1; i <= arrayLen(testCodes); i++) {
        writeOutput("<li>Test #i#: #fixedTimes[i]#ms (avg: #numberFormat(fixedTimes[i]/iterations, '0.00')#ms)</li>");
        if (i <= arrayLen(originalTimes)) {
            improvement = ((originalTimes[i] - fixedTimes[i]) / originalTimes[i]) * 100;
            writeOutput(" <strong>(" & numberFormat(improvement, "+0.0") & "% improvement)</strong>");
        }
    }
    writeOutput("</ul>");
    
} catch (any e) {
    writeOutput("<p>Error testing fixed: #e.message#</p>");
}

writeOutput("<p><strong>Result:</strong> Pre-compiled patterns should show performance improvement, especially for repeated executions.</p>");
</cfscript>
