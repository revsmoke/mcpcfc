#!/bin/bash
set -euo pipefail

# Test script to verify command injection fixes in DevWorkflowTool

echo "Testing DevWorkflowTool command injection fixes..."

# Test 1: testRunner with injection attempt in bundles parameter
echo "Testing testRunner with injection attempt in bundles parameter..."
TEST_PAYLOAD='test.cfc"; echo "INJECTED" > /tmp/devtools-injection1.txt; echo "'

echo '{
    "jsonrpc": "2.0",
    "id": 1,
    "method": "testRunner",
    "params": {
        "directory": "./tests",
        "bundles": "'"$TEST_PAYLOAD"'",
        "reporter": "json",
        "labels": "",
        "coverage": false
    }
}' | curl -s -X POST http://localhost:8500/mcpcfc/endpoints/messages.cfm?sessionId=test-devtools-injection -H "Content-Type: application/json" -d @-

# Check if injection was successful (file should NOT exist)
if [ -f "/tmp/devtools-injection1.txt" ]; then
    echo "FAIL: Command injection via bundles parameter!"
    rm -f /tmp/devtools-injection1.txt
    exit 1
else
    echo "PASS: bundles parameter injection was prevented"
fi

# Test 2: codeLinter with injection attempt in filePath parameter
echo ""
echo "Testing codeLinter with injection attempt in filePath parameter..."
TEST_PAYLOAD='test.cfc"; echo "INJECTED" > /tmp/devtools-injection2.txt; echo "'

echo '{
    "jsonrpc": "2.0",
    "id": 2,
    "method": "codeLinter",
    "params": {
        "filePath": "'"$TEST_PAYLOAD"'",
        "rules": "default",
        "format": "json",
        "includeWarnings": true
    }
}' | curl -s -X POST http://localhost:8500/mcpcfc/endpoints/messages.cfm?sessionId=test-devtools-injection -H "Content-Type: application/json" -d @-

# Check if injection was successful (file should NOT exist)
if [ -f "/tmp/devtools-injection2.txt" ]; then
    echo "FAIL: Command injection via filePath parameter!"
    rm -f /tmp/devtools-injection2.txt
    exit 1
else
    echo "PASS: filePath parameter injection was prevented"
fi

# Test 3: generateDocs with injection attempt in sourcePath parameter
echo ""
echo "Testing generateDocs with injection attempt in sourcePath parameter..."
TEST_PAYLOAD='./src"; echo "INJECTED" > /tmp/devtools-injection3.txt; echo "'

echo '{
    "jsonrpc": "2.0",
    "id": 3,
    "method": "generateDocs",
    "params": {
        "sourcePath": "'"$TEST_PAYLOAD"'",
        "outputPath": "./docs",
        "format": "html",
        "includePrivate": false
    }
}' | curl -s -X POST http://localhost:8500/mcpcfc/endpoints/messages.cfm?sessionId=test-devtools-injection -H "Content-Type: application/json" -d @-

# Check if injection was successful (file should NOT exist)
if [ -f "/tmp/devtools-injection3.txt" ]; then
    echo "FAIL: Command injection via sourcePath parameter!"
    rm -f /tmp/devtools-injection3.txt
    exit 1
else
    echo "PASS: sourcePath parameter injection was prevented"
fi

echo ""
echo "All DevWorkflowTool command injection tests passed!"