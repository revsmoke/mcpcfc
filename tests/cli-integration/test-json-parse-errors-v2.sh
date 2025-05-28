#!/bin/bash
set -euo pipefail

# Test JSON parsing error handling in cf-mcp-cli-bridge-v2.cfm
echo "=== Testing JSON Parsing Error Handling in v2 Bridge ==="

cd /Applications/ColdFusion2023/cfusion/wwwroot/mcpcfc

# Test 1: Invalid JSON syntax
echo "Test 1: Invalid JSON syntax"
result=$(echo '{"invalid": json}' | timeout 5s cfml cli-bridge/cf-mcp-cli-bridge-v2.cfm 2>/dev/null | head -1 || true)
if [[ "$result" == *'"code":-32700'* ]] && [[ "$result" == *'"message":"Parse error:'* ]]; then
    echo "✅ PASS: Invalid JSON returns parse error (-32700)"
else
    echo "❌ FAIL: Expected parse error, got: $result"
    exit 1
fi

# Test 2: Empty object (valid JSON, should not error)
echo "Test 2: Valid JSON (empty object)"
result=$(echo '{}' | timeout 5s cfml cli-bridge/cf-mcp-cli-bridge-v2.cfm 2>/dev/null | head -1 || true)
if [[ "$result" == *'"code":-32700'* ]]; then
    echo "❌ FAIL: Valid JSON should not return parse error"
    exit 1
else
    echo "✅ PASS: Valid JSON processed without parse error"
fi

# Test 3: Malformed JSON with missing quotes
echo "Test 3: Malformed JSON (missing quotes)"
result=$(echo '{method: initialize}' | timeout 5s cfml cli-bridge/cf-mcp-cli-bridge-v2.cfm 2>/dev/null | head -1 || true)
if [[ "$result" == *'"code":-32700'* ]] && [[ "$result" == *'"id":null'* ]]; then
    echo "✅ PASS: Malformed JSON returns parse error with null ID"
else
    echo "❌ FAIL: Expected parse error with null ID, got: $result"
    exit 1
fi

# Test 4: Valid JSON-RPC but unknown method (should not be parse error)
echo "Test 4: Valid JSON-RPC with unknown method"
result=$(echo '{"jsonrpc":"2.0","id":1,"method":"unknownMethod"}' | timeout 5s cfml cli-bridge/cf-mcp-cli-bridge-v2.cfm 2>/dev/null | head -1 || true)
if [[ "$result" == *'"code":-32700'* ]]; then
    echo "❌ FAIL: Valid JSON-RPC should not return parse error"
    exit 1
else
    echo "✅ PASS: Valid JSON-RPC processed (method error, not parse error)"
fi

echo ""
echo "✅ All JSON parsing error handling tests passed for v2 bridge!"
echo "The bridge correctly:"
echo "  - Returns -32700 for JSON parse errors"
echo "  - Uses null ID for parse errors per JSON-RPC spec"
echo "  - Processes valid JSON without parse errors"
echo "  - Distinguishes between parse errors and method errors"