#!/usr/bin/env bash
@@
set -euo pipefail

for cmd in cfml jq; do
  if ! command -v "$cmd" &>/dev/null; then
    echo "ERROR: Required command '$cmd' is missing." >&2
    exit 1
  fi
done
# Test script for Development Workflow tools in CF2023 CLI Bridge

echo "Testing CF2023 Development Workflow Tools..."
echo "==========================================="

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

# Check for CommandBox (optional but recommended)
if ! command -v box &> /dev/null; then
    echo "WARNING: CommandBox not found. Dev workflow tools require CommandBox."
    echo "Install from: https://www.ortussolutions.com/products/commandbox"
    echo "Dev tools will run in simulation mode."
fi

# Test 1: Initialize
echo -e "\n1. Testing initialize..."
INIT_RESPONSE=$(echo '{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":"2024-11-05"}}' | cfml cli-bridge/cf-mcp-cli-bridge-v2.cfm 2>/tmp/cf-mcp-devtools-test.log)
echo "$INIT_RESPONSE" | jq '.result.protocolVersion'

# Test 2: Code formatter (with code string)
echo -e "\n2. Testing codeFormatter tool (code string)..."
FORMAT_RESPONSE=$(echo '{"jsonrpc":"2.0","id":2,"method":"tools/call","params":{"name":"codeFormatter","arguments":{"code":"component{function test(){var x=1;return x;}}", "settings":{"indentSize":4,"insertSpaces":true}}}}' | cfml cli-bridge/cf-mcp-cli-bridge-v2.cfm 2>>/tmp/cf-mcp-devtools-test.log)
echo "$FORMAT_RESPONSE" | jq '.result | {success, changes}'

# Test 3: Code linter (simulated)
echo -e "\n3. Testing codeLinter tool (simulated)..."
echo "Would run: codeLinter on sample code"
echo '{"jsonrpc":"2.0","id":3,"method":"tools/call","params":{"name":"codeLinter","arguments":{"code":"component{function test(){var x=1;}}","rules":"default"}}}'
echo "(Skipping actual linting - requires cflint installation)"

# Test 4: Test runner (check if tests exist)
echo -e "\n4. Testing testRunner tool..."
if [ -d "./tests" ]; then
    TEST_RESPONSE=$(echo '{"jsonrpc":"2.0","id":4,"method":"tools/call","params":{"name":"testRunner","arguments":{"directory":"./tests","reporter":"json"}}}' | cfml cli-bridge/cf-mcp-cli-bridge-v2.cfm 2>>/tmp/cf-mcp-devtools-test.log)
    echo "$TEST_RESPONSE" | jq '.result | {success, totalSpecs, totalPass, totalFail}'
else
    echo "No tests directory found - skipping test runner"
fi

# Test 5: Generate docs (simulated)
echo -e "\n5. Testing generateDocs tool (simulated)..."
echo "Would run: generateDocs for ./components directory"
echo '{"jsonrpc":"2.0","id":5,"method":"tools/call","params":{"name":"generateDocs","arguments":{"sourcePath":"./components","outputPath":"./docs","format":"html"}}}'
echo "(Skipping actual generation - requires docbox installation)"

# Test 6: Watch files (config only)
echo -e "\n6. Testing watchFiles tool (configuration)..."
WATCH_RESPONSE=$(echo '{"jsonrpc":"2.0","id":6,"method":"tools/call","params":{"name":"watchFiles","arguments":{"paths":["./"],"extensions":["cfc","cfm"],"action":"test"}}}' | cfml cli-bridge/cf-mcp-cli-bridge-v2.cfm 2>>/tmp/cf-mcp-devtools-test.log)
echo "$WATCH_RESPONSE" | jq '.result'

echo -e "\n\nTest log available at: /tmp/cf-mcp-devtools-test.log"
echo "To view errors: tail -f /tmp/cf-mcp-devtools-test.log"
echo ""
echo "NOTE: Some tests are simulated as they require additional tool installations:"
echo "      - cfformat (install via: box install cfformat)"
echo "      - cflint (install via: box install cflint)"
echo "      - testbox (install via: box install testbox)"
echo "      - docbox (install via: box install docbox)"