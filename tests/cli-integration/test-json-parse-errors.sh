#!/bin/bash

# Ensure script fails fast on errors
set -euo pipefail

# Test script to verify JSON parsing error handling in CLI bridge

echo "Testing JSON parsing error handling in CLI bridge..."

# Change to script directory
cd "$(dirname "$0")/../.."

# Check if required tools are installed
if ! command -v cfml &> /dev/null; then
    echo "ERROR: cfml command not found. ColdFusion 2023 CLI is required."
    exit 1
fi

if ! command -v jq &> /dev/null; then
    echo "ERROR: jq not found. jq is required for JSON processing."
    exit 1
fi

echo "Testing JSON parse error handling..."

# Test 1: Valid JSON (should work)
echo ""
echo "Test 1: Valid JSON input..."
VALID_JSON='{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":"2024-11-05"}}'
RESPONSE1=$(echo "$VALID_JSON" | cfml cli-bridge/cf-mcp-cli-bridge.cfm 2>/dev/null)
if echo "$RESPONSE1" | jq -e '.result' >/dev/null 2>&1; then
     echo "✓ Valid JSON processed successfully"
 else
    echo "✗ Valid JSON failed to process"
    exit 1
 fi

# Test 2: Invalid JSON - Missing closing brace (should return parse error)
echo ""
echo "Test 2: Invalid JSON - missing closing brace..."
INVALID_JSON1='{"jsonrpc":"2.0","id":1,"method":"initialize"'
RESPONSE2=$(echo "$INVALID_JSON1" | cfml cli-bridge/cf-mcp-cli-bridge.cfm 2>/dev/null)
if echo "$RESPONSE2" | jq -e '.error.code == -32700' >/dev/null 2>&1; then
    echo "✓ Parse error correctly returned with code -32700"
else
    echo "✗ Parse error not handled correctly"
    echo "Response: $RESPONSE2"
fi

# Test 3: Invalid JSON - malformed structure (should return parse error)
echo ""
echo "Test 3: Invalid JSON - malformed structure..."
INVALID_JSON2='{"jsonrpc":"2.0","id":1,"method":invalid_value}'
RESPONSE3=$(echo "$INVALID_JSON2" | cfml cli-bridge/cf-mcp-cli-bridge.cfm 2>/dev/null)
if echo "$RESPONSE3" | jq -e '.error.code == -32700' >/dev/null 2>&1; then
    echo "✓ Parse error correctly returned with code -32700"
else
    echo "✗ Parse error not handled correctly"
    echo "Response: $RESPONSE3"
fi

# Test 4: Completely invalid input (should return parse error)
echo ""
echo "Test 4: Completely invalid input..."
INVALID_JSON3='this is not json at all'
RESPONSE4=$(echo "$INVALID_JSON3" | cfml cli-bridge/cf-mcp-cli-bridge.cfm 2>/dev/null)
if echo "$RESPONSE4" | jq -e '.error.code == -32700' >/dev/null 2>&1; then
    echo "✓ Parse error correctly returned with code -32700"
else
    echo "✗ Parse error not handled correctly"
    echo "Response: $RESPONSE4"
fi

# Test 5: Check that parse errors have null ID
echo ""
echo "Test 5: Verify parse errors have null ID..."
RESPONSE5=$(echo "$INVALID_JSON1" | cfml cli-bridge/cf-mcp-cli-bridge.cfm 2>/dev/null)
if echo "$RESPONSE5" | jq -e '.id == null' >/dev/null 2>&1; then
    echo "✓ Parse error correctly has null ID"
else
    echo "✗ Parse error ID not null as expected"
    echo "Response: $RESPONSE5"
fi

echo ""
echo "JSON parse error handling tests completed!"
echo "All parse errors should return JSON-RPC error responses with:"
echo "- error.code: -32700 (Parse error)"
echo "- id: null (per JSON-RPC specification)"
echo "- Proper error message describing the parse failure"