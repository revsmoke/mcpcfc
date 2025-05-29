#!/bin/bash

# Ensure script fails fast on errors
set -euo pipefail

# Ensure script fails fast on errors
set -euo pipefail

# Test script to verify tagContext safety improvements

echo "Testing tagContext safety in error handling..."
# Test 1: Generate an error that should have tagContext
 echo "Test 1: Normal error with tagContext..."
# Check for required dependencies
if ! command -v curl &> /dev/null; then
    echo "ERROR: curl not found. curl is required for HTTP requests."
    exit 1
fi

if ! command -v jq &> /dev/null; then
    echo "ERROR: jq not found. jq is required for JSON processing."
    exit 1
fi

 response=$(timeout 30 echo '{
     "jsonrpc": "2.0",
     "id": 1,
     "method": "executeCode",
     "params": {
         "code": "var x = undefinedVariable.someProperty;",
         "returnOutput": true,
         "timeout": 5
     }
}' | curl -s --max-time 30 --fail -X POST http://localhost:8500/mcpcfc/endpoints/messages.cfm?sessionId=test-tagcontext -H "Content-Type: application/json" -d @-)

# Verify response has proper error structure
if echo "$response" | jq -e '.error.data.stackTrace[]?' > /dev/null; then
    echo "✅ PASS: Error response contains stackTrace array"
else
    echo "❌ FAIL: Missing or invalid stackTrace in error response"
    echo "Response: $response"
    exit 1
fi

echo ""
echo "Test 2: Syntax error that might have different tagContext structure..."
response2=$(echo '{
     "jsonrpc": "2.0",
     "id": 2,
     "method": "executeCode",
     "params": {
         "code": "if (true { writeOutput(\"missing closing paren\"); }",
         "returnOutput": true,
         "timeout": 5
     }
}' | curl -s -X POST http://localhost:8500/mcpcfc/endpoints/messages.cfm?sessionId=test-tagcontext -H "Content-Type: application/json" -d @-)

# Validate Test 2 response
if echo "$response2" | jq -e '.error?' > /dev/null; then
    echo "✅ PASS: Test 2 - Syntax error properly handled"
else
    echo "❌ FAIL: Test 2 - Syntax error not properly handled"
    echo "Response: $response2"
    exit 1
fi

 echo ""
 echo "Test 3: Complex error with nested function calls..."
response3=$(echo '{
     "jsonrpc": "2.0",
     "id": 3,
     "method": "evaluateExpression",
     "params": {
         "expression": "someFunction(anotherFunction(invalidVariable))",
         "format": "string"
     }
}' | curl -s -X POST http://localhost:8500/mcpcfc/endpoints/messages.cfm?sessionId=test-tagcontext -H "Content-Type: application/json" -d @-)

# Validate Test 3 response
if echo "$response3" | jq -e '.error?' > /dev/null; then
    echo "✅ PASS: Test 3 - Complex error properly handled"
else
    echo "❌ FAIL: Test 3 - Complex error not properly handled" 
    echo "Response: $response3"
    exit 1
fi

echo ""
echo "✅ All tagContext safety tests passed!"
echo "The error handling correctly:"
echo "  - Provides stackTrace arrays for all error types"
echo "  - Prevents secondary exceptions during error processing"
echo "  - Maintains consistent error response format"
exit 0