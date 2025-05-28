#!/bin/bash
set -euo pipefail

# Test REPLTool tagContext safety improvements
echo "=== Testing REPLTool tagContext Safety ==="

cd "$(git rev-parse --show-toplevel)"

# Test 1: Execute code that causes an error (should not cause secondary exceptions)
echo "Test 1: Execute code that causes an error"
result=$(echo '{"jsonrpc":"2.0","id":1,"method":"tools/call","params":{"name":"executeCode","arguments":{"code":"undefinedVariable.nonExistentProperty","returnOutput":true,"timeout":5}}}' | curl -s -X POST 'http://localhost:8500/mcpcfc/endpoints/messages.cfm?sessionId=test-tagcontext' -H "Content-Type: application/json" -d @-)

if echo "$result" | jq -e '.result.success == false' >/dev/null; then
    echo "✅ PASS: Error properly handled"
    
    # Check that error message is present
    if echo "$result" | jq -e '.result.error | length > 0' >/dev/null; then
        echo "✅ PASS: Error message is populated"
    else
        echo "❌ FAIL: Error message is missing"
        exit 1
    fi
    
    # Check that stackTrace is an array (even if empty)
    if echo "$result" | jq -e '.result.stackTrace | type == "array"' >/dev/null; then
        echo "✅ PASS: stackTrace is safely set as array"
    else
        echo "❌ FAIL: stackTrace is not an array"
        exit 1
    fi
    
    # Verify the response is valid JSON (no secondary exceptions)
    if echo "$result" | jq . >/dev/null 2>&1; then
        echo "✅ PASS: Response is valid JSON (no secondary exceptions)"
    else
        echo "❌ FAIL: Response is malformed JSON"
        exit 1
    fi
    
else
    echo "❌ FAIL: Expected error response"
    exit 1
fi

echo ""
echo "Test 2: Test timeout with error handling"
result=$(echo '{"jsonrpc":"2.0","id":2,"method":"tools/call","params":{"name":"executeCode","arguments":{"code":"sleep(10000)","returnOutput":true,"timeout":1}}}' | curl -s -X POST 'http://localhost:8500/mcpcfc/endpoints/messages.cfm?sessionId=test-tagcontext' -H "Content-Type: application/json" -d @-)

# Should handle timeout gracefully without tagContext issues
if echo "$result" | jq -e '.result | has("executionTime")' >/dev/null; then
    echo "✅ PASS: Timeout handled gracefully with executionTime"
else
    echo "❌ FAIL: Timeout not handled properly"
    exit 1
fi

echo ""
echo "✅ All tagContext safety tests passed!"
echo "The REPLTool now:"
echo "  - Safely checks tagContext existence and structure before access"
echo "  - Uses try-catch blocks around tagContext operations to prevent secondary exceptions"
echo "  - Provides fallback values when tagContext is unavailable or malformed"
echo "  - Ensures stackTrace is always a valid array in responses"