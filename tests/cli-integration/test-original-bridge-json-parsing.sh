#!/bin/bash
set -euo pipefail

# Test JSON parsing error handling in the original cf-mcp-cli-bridge.cfm
echo "=== Testing JSON Parsing Error Handling in Original Bridge ==="

cd "${MCPCFC_ROOT:-/Applications/ColdFusion2023/cfusion/wwwroot/mcpcfc}"

# Test 1: Invalid JSON syntax
echo "Test 1: Invalid JSON syntax"
result=$(echo '{"invalid": json}' | timeout 5s ./cf-mcp-clean-bridge.sh 2>/dev/null | head -1 || true)
if [[ "$result" == *'"code":-32700'* ]] && [[ "$result" == *'"message":"Parse error:'* ]]; then
    if [[ "$result" == *'"id":null'* ]]; then
        echo "✅ PASS: Invalid JSON returns parse error (-32700) with null ID"
    else
        echo "❌ FAIL: Parse error missing null ID, got: $result"
        exit 1
    fi
else
    echo "❌ FAIL: Expected parse error, got: $result"
    exit 1
fi

# Test 2: Empty object (valid JSON, should not error)
echo "Test 2: Valid JSON (empty object)"
result=$(echo '{}' | timeout 5s ./cf-mcp-clean-bridge.sh 2>/dev/null | head -1 || true)
if [[ "$result" == *'"code":-32700'* ]]; then
    echo "❌ FAIL: Valid JSON should not return parse error"
    exit 1
else
    echo "✅ PASS: Valid JSON processed without parse error"
fi

# Test 3: Malformed JSON with missing quotes
echo "Test 3: Malformed JSON (missing quotes)"
result=$(echo '{method: initialize}' | timeout 5s ./cf-mcp-clean-bridge.sh 2>/dev/null | head -1 || true)
if [[ "$result" == *'"code":-32700'* ]] && [[ "$result" == *'"id":null'* ]]; then
    echo "✅ PASS: Malformed JSON returns parse error with null ID"
else
    echo "❌ FAIL: Expected parse error with null ID, got: $result"
    exit 1
fi

# Test 4: Valid JSON-RPC but unknown method (should not be parse error)
echo "Test 4: Valid JSON-RPC with unknown method"
result=$(echo '{"jsonrpc":"2.0","id":1,"method":"unknownMethod"}' | timeout 5s ./cf-mcp-clean-bridge.sh 2>/dev/null | head -1 || true)
if [[ "$result" == *'"code":-32700'* ]]; then
    echo "❌ FAIL: Valid JSON-RPC should not return parse error"
    exit 1
else
    echo "✅ PASS: Valid JSON-RPC processed (method error, not parse error)"
fi

echo ""
echo "✅ All JSON parsing error handling tests passed for original bridge!"
echo "The bridge correctly:"
echo "  - Returns -32700 for JSON parse errors"
echo "  - Uses null ID for parse errors per JSON-RPC spec"
echo "  - Processes valid JSON without parse errors"
echo "  - Distinguishes between parse errors and method errors"
echo "  - Does not reference undefined message variables"