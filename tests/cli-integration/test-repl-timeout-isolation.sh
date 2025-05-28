#!/bin/bash

# Test script to verify REPLTool timeout and isolation fixes

echo "Testing REPLTool timeout and isolation functionality..."

# Test 1: Quick execution that should complete within timeout
echo "Test 1: Quick execution (should succeed)..."
echo '{
    "jsonrpc": "2.0",
    "id": 1,
    "method": "executeCode",
    "params": {
        "code": "writeOutput(\"Hello from isolated context\"); var result = 42; return result;",
        "returnOutput": true,
        "timeout": 5
    }
}' | curl -s -X POST http://localhost:8500/mcpcfc/endpoints/messages.cfm?sessionId=test-repl-timeout -H "Content-Type: application/json" -d @- | jq .

echo ""
echo "Test 2: Long execution with short timeout (should timeout)..."
echo '{
    "jsonrpc": "2.0",
    "id": 2,
    "method": "executeCode",
    "params": {
        "code": "sleep(10000); writeOutput(\"This should not appear\");",
        "returnOutput": true,
        "timeout": 2
    }
}' | curl -s -X POST http://localhost:8500/mcpcfc/endpoints/messages.cfm?sessionId=test-repl-timeout -H "Content-Type: application/json" -d @- | jq .

echo ""
echo "Test 3: Code with error in isolated context..."
echo '{
    "jsonrpc": "2.0",
    "id": 3,
    "method": "executeCode",
    "params": {
        "code": "var x = undefinedVariable.someProperty;",
        "returnOutput": true,
        "timeout": 5
    }
}' | curl -s -X POST http://localhost:8500/mcpcfc/endpoints/messages.cfm?sessionId=test-repl-timeout -H "Content-Type: application/json" -d @- | jq .

echo ""
echo "Test 4: Test variable isolation (variables should not leak)..."
echo '{
    "jsonrpc": "2.0",
    "id": 4,
    "method": "executeCode",
    "params": {
        "code": "var isolatedVar = \"This should not affect other executions\"; writeOutput(isolatedVar);",
        "returnOutput": true,
        "timeout": 5
    }
}' | curl -s -X POST http://localhost:8500/mcpcfc/endpoints/messages.cfm?sessionId=test-repl-timeout -H "Content-Type: application/json" -d @- | jq .

echo ""
echo "If timeouts work correctly, test 2 should show timedOut:true"
echo "If isolation works correctly, each execution should be independent"