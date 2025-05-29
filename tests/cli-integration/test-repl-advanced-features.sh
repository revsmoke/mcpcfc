#!/bin/bash
set -euo pipefail

# Advanced test script for REPLTool timeout and isolation features

echo "Testing REPLTool advanced timeout and isolation features..."

# Test 1: Variable isolation - set a variable in one execution
echo "Test 1: Setting a variable in isolated context..."
RESPONSE1=$(echo '{
    "jsonrpc": "2.0",
    "id": 1,
    "method": "executeCode",
    "params": {
        "code": "variables.testVar = \"This should be isolated\"; writeOutput(\"Set testVar = \" & variables.testVar);",
        "returnOutput": true,
        "timeout": 5
    }
}' | curl -s -X POST http://localhost:8500/mcpcfc/endpoints/messages.cfm?sessionId=$SESSION_ID -H "Content-Type: application/json" -d @-)

echo "$RESPONSE1" | jq .

# Test 2: Try to access the variable from Test 1 (should fail due to isolation)
echo ""
# Generate unique session ID for this test run
SESSION_ID="test-repl-advanced-$(date +%s)-$$"

# Generate unique session ID for this test run
SESSION_ID="test-repl-advanced-$(date +%s)-$$"

 # Test 1: Variable isolation - set a variable in one execution
 echo "Test 1: Setting a variable in isolated context..."
 RESPONSE1=$(echo '{
     "jsonrpc": "2.0",
     "id": 1,
     "method": "executeCode",
     "params": {
         "code": "variables.testVar = \"This should be isolated\"; writeOutput(\"Set testVar = \" & variables.testVar);",
         "returnOutput": true,
         "timeout": 5
     }
}' | curl -s -X POST http://localhost:8500/mcpcfc/endpoints/messages.cfm?sessionId=$SESSION_ID -H "Content-Type: application/json" -d @-)
 # Test 2: Try to access the variable from Test 1 (should fail due to isolation)
 echo ""
 echo "Test 2: Trying to access variable from previous context (should fail)..."
 RESPONSE2=$(echo '{
     "jsonrpc": "2.0",
     "id": 2,
     "method": "executeCode",
     "params": {
         "code": "try { writeOutput(\"testVar = \" & variables.testVar); } catch(any e) { writeOutput(\"testVar not found - isolation working\"); }",
         "returnOutput": true,
         "timeout": 5
     }
 }' | curl -s -X POST http://localhost:8500/mcpcfc/endpoints/messages.cfm?sessionId=$SESSION_ID -H "Content-Type: application/json" -d @-)
 
 echo "$RESPONSE2" | jq .

echo "$RESPONSE1" | jq .

# Test 3: Timeout test with a simple loop (should timeout)
 echo ""
 echo "Test 3: Testing timeout with infinite loop (should timeout after 3 seconds)..."

# Use a more deterministic approach for timeout testing
 RESPONSE3=$(echo '{
     "jsonrpc": "2.0",
     "id": 3,
     "method": "executeCode",
     "params": {
        "code": "var startTime = getTickCount(); while(getTickCount() - startTime < 5000) { /* busy wait for 5 seconds */ } writeOutput(\"This should not appear due to timeout\");",
         "returnOutput": true,
         "timeout": 3
     }
 }' | curl -s -X POST http://localhost:8500/mcpcfc/endpoints/messages.cfm?sessionId=test-repl-advanced -H "Content-Type: application/json" -d @-)

echo "$RESPONSE3" | jq .

# Test 4: Valid code that runs within timeout
echo ""
echo "Test 4: Valid code that completes within timeout..."
RESPONSE4=$(echo '{
    "jsonrpc": "2.0",
    "id": 4,
    "method": "executeCode",
    "params": {
        "code": "for (var i = 1; i <= 5; i++) { writeOutput(\"Count: \" & i & \"<br>\"); } writeOutput(\"Completed successfully\");",
        "returnOutput": true,
        "timeout": 10
    }
}' | curl -s -X POST http://localhost:8500/mcpcfc/endpoints/messages.cfm?sessionId=test-repl-advanced -H "Content-Type: application/json" -d @-)

echo "$RESPONSE4" | jq .

echo ""
echo "Expected results:"
echo "- Test 1: Should succeed and show the variable was set"
echo "- Test 2: Should show 'testVar not found - isolation working'"
echo "- Test 3: Should show timedOut:true and timeout error message"
echo "- Test 4: Should succeed and show the counting output"