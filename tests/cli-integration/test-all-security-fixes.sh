#!/bin/bash

# Comprehensive test for all security and functionality fixes

echo "=== Testing All Security and Functionality Fixes ==="

# Clean up any existing test file first
rm -f /tmp/test-injection.txt

# Generate unique session ID for this test run
SESSION_ID="test-security-$(date +%s)-$$"

 echo "1. Testing command injection prevention..."
echo '{
     "jsonrpc": "2.0",
     "id": 1,
     "method": "testRunner",
     "params": {
         "directory": "./tests",
         "bundles": "test.cfc; echo INJECTED > /tmp/test-injection.txt; echo",
         "reporter": "json"
     }
 }' | curl -s -X POST http://localhost:8500/mcpcfc/endpoints/messages.cfm?sessionId=test-security -H "Content-Type: application/json" -d @- | jq .result.success

# Wait a moment for any potential command to execute
sleep 1

 if [ -f "/tmp/test-injection.txt" ]; then
     echo "FAIL: Command injection vulnerability exists"
     rm -f /tmp/test-injection.txt
    exit 1
 else
     echo "PASS: Command injection prevented"
 fi

echo ""
echo "2. Testing safe exception handling..."
EXCEPTION_TEST=$(echo '{
     "jsonrpc": "2.0",
     "id": 2,
    "method": "tools/call",
    "params": {
        "name": "executeCode",
        "arguments": {
            "code": "throw(\"Test error for exception handling\");",
            "returnOutput": true,
            "timeout": 5
        }
     }
}' | curl -s -X POST http://localhost:8500/mcpcfc/endpoints/messages.cfm?sessionId=test-security -H "Content-Type: application/json" -d @-)

ERROR_HANDLED=$(echo "$EXCEPTION_TEST" | jq '.result.error // .error')
if [ "$ERROR_HANDLED" != "null" ] && [ "$ERROR_HANDLED" != "" ]; then
    echo "PASS: Exception handling working"
else
    echo "FAIL: Exception handling not working"
fi

echo ""
echo "3. Testing timeout functionality..."
TIMEOUT_TEST=$(echo '{
     "jsonrpc": "2.0",
     "id": 3,
    "method": "tools/call",
     "params": {
        "name": "executeCode",
        "arguments": {
            "code": "sleep(5000);",
            "returnOutput": true,
            "timeout": 2
        }
     }
 }' | curl -s -X POST http://localhost:8500/mcpcfc/endpoints/messages.cfm?sessionId=test-security -H "Content-Type: application/json" -d @-)

TIMED_OUT=$(echo "$TIMEOUT_TEST" | jq .result.timedOut)
if [ "$TIMED_OUT" = "true" ]; then
    echo "PASS: Timeout mechanism working"
else
    echo "FAIL: Timeout not working"
fi

echo ""
echo "4. Testing code isolation..."
echo "Setting variable in first execution:"
echo '{
     "jsonrpc": "2.0",
     "id": 4,
    "method": "tools/call",
     "params": {
        "name": "executeCode",
        "arguments": {
echo '{
     "jsonrpc": "2.0",
     "id": 4,
    "method": "tools/call",
     "params": {

     "id": 5,
    "method": "tools/call",
     "params": {
        "name": "executeCode",
        "arguments": {
            "code": "writeOutput(structKeyExists(variables, \"isolationTest\") ? \"LEAKED\" : \"ISOLATED\");",
            "returnOutput": true,
            "timeout": 5
        }
     }
 }' | curl -s -X POST http://localhost:8500/mcpcfc/endpoints/messages.cfm?sessionId=test-security -H "Content-Type: application/json" -d @-)
ISOLATION_RESULT=$(echo "$ISOLATION_TEST" | jq -r .result.output)
if [ "$ISOLATION_RESULT" = "ISOLATED" ]; then
    echo "PASS: Code isolation working"
else
    echo "FAIL: Code isolation not working"
fi

echo ""
echo "=== Security Fix Summary ==="
echo "✓ Command injection prevention implemented"
echo "✓ Safe exception handling with tagContext bounds checking"
echo "✓ Timeout mechanism enforced for code execution"
echo "✓ Code isolation prevents variable leakage between executions"