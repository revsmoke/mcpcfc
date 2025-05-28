#!/bin/bash

# Ensure script fails fast on errors
set -euo pipefail

# Test script for REPL tools in CF2023 CLI Bridge

echo "Testing CF2023 REPL Tools..."
echo "============================"

# Change to script directory
cd "$(dirname "$0")/../.."

# Check if required tools are installed
echo "Checking for required tools..."

# Check for cfml (ColdFusion CLI)
if ! command -v cfml &> /dev/null; then
    echo "ERROR: cfml command not found. ColdFusion 2023 CLI is required."
    echo "Ensure ColdFusion 2023 is installed and cfml is in your PATH."
    exit 1
fi

# Check for jq (JSON processor)
if ! command -v jq &> /dev/null; then
    echo "ERROR: jq not found. jq is required for JSON processing."
    echo "Install with: brew install jq (macOS) or apt-get install jq (Linux)"
    exit 1
fi

# Test 1: Initialize
echo -e "\n1. Testing initialize..."
INIT_RESPONSE=$(echo '{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":"2024-11-05"}}' | cfml cli-bridge/cf-mcp-cli-bridge-v2.cfm 2>/tmp/cf-mcp-repl-test.log)
echo "$INIT_RESPONSE" | jq '.'

# Test 2: List tools (should include REPL tools)
echo -e "\n2. Testing tools/list (checking for REPL tools)..."
TOOLS_RESPONSE=$(echo '{"jsonrpc":"2.0","id":2,"method":"tools/list","params":{}}' | cfml cli-bridge/cf-mcp-cli-bridge-v2.cfm 2>>/tmp/cf-mcp-repl-test.log)
echo "$TOOLS_RESPONSE" | jq '.result.tools[] | select(.name | startswith("execute") or startswith("evaluate") or startswith("test") or startswith("inspect"))'

# Test 3: Execute simple code
echo -e "\n3. Testing executeCode tool..."
CODE_RESPONSE=$(echo '{"jsonrpc":"2.0","id":3,"method":"tools/call","params":{"name":"executeCode","arguments":{"code":"writeOutput(\"Hello from REPL!\"); return 42;"}}}' | cfml cli-bridge/cf-mcp-cli-bridge-v2.cfm 2>>/tmp/cf-mcp-repl-test.log)
echo "$CODE_RESPONSE" | jq '.'

# Test 4: Evaluate expression
echo -e "\n4. Testing evaluateExpression tool..."
EVAL_RESPONSE=$(echo '{"jsonrpc":"2.0","id":4,"method":"tools/call","params":{"name":"evaluateExpression","arguments":{"expression":"now()"}}}' | cfml cli-bridge/cf-mcp-cli-bridge-v2.cfm 2>>/tmp/cf-mcp-repl-test.log)
echo "$EVAL_RESPONSE" | jq '.'

# Test 5: Test snippet with assertions
echo -e "\n5. Testing testSnippet tool..."
TEST_RESPONSE=$(echo '{"jsonrpc":"2.0","id":5,"method":"tools/call","params":{"name":"testSnippet","arguments":{"code":"x = 5 + 5;","assertions":[{"expression":"x == 10","message":"x should equal 10"}],"measurePerformance":true}}}' | cfml cli-bridge/cf-mcp-cli-bridge-v2.cfm 2>>/tmp/cf-mcp-repl-test.log)
echo "$TEST_RESPONSE" | jq '.'

# Test 6: Inspect variable
echo -e "\n6. Testing inspectVariable tool..."
INSPECT_RESPONSE=$(echo '{"jsonrpc":"2.0","id":6,"method":"tools/call","params":{"name":"inspectVariable","arguments":{"setupCode":"myStruct = {name: \"Test\", items: [1,2,3], nested: {foo: \"bar\"}};","variableName":"myStruct"}}}' | cfml cli-bridge/cf-mcp-cli-bridge-v2.cfm 2>>/tmp/cf-mcp-repl-test.log)
echo "$INSPECT_RESPONSE" | jq '.'

echo -e "\n\nTest log available at: /tmp/cf-mcp-repl-test.log"
echo "To view errors: tail -f /tmp/cf-mcp-repl-test.log"