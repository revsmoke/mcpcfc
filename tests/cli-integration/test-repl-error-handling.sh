#!/bin/bash
set -euo pipefail

# Test script to verify REPLTool error handling fixes

echo "Testing REPLTool error handling safety..."

# Test 1: Execute code that causes an error to test safe tagContext handling
echo "Testing executeCode with syntax error..."
echo '{
    "jsonrpc": "2.0",
    "id": 1,
    "method": "executeCode",
    "params": {
        "code": "this is invalid CFML syntax that will cause an error",
        "returnOutput": true
    }
}' | curl -s -X POST http://localhost:8500/mcpcfc/endpoints/messages.cfm?sessionId=test-repl-error -H "Content-Type: application/json" -d @- | jq .

echo ""
echo "Testing executeCode with runtime error..."
echo '{
    "jsonrpc": "2.0",
    "id": 2,
    "method": "executeCode",
    "params": {
        "code": "var x = undefinedVariable.someProperty;",
        "returnOutput": true
    }
}' | curl -s -X POST http://localhost:8500/mcpcfc/endpoints/messages.cfm?sessionId=test-repl-error -H "Content-Type: application/json" -d @- | jq .

echo ""
echo "Testing evaluateExpression with invalid expression..."
echo '{
    "jsonrpc": "2.0",
    "id": 3,
    "method": "evaluateExpression",
    "params": {
        "expression": "1/0",
        "format": "string"
    }
}' | curl -s -X POST http://localhost:8500/mcpcfc/endpoints/messages.cfm?sessionId=test-repl-error -H "Content-Type: application/json" -d @- | jq .

echo ""
echo "If all responses contain proper error handling without secondary exceptions, the fix is working correctly."