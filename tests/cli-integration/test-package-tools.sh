#!/bin/bash

# Ensure script fails fast on errors
set -euo pipefail

# Test script for Package Manager tools in CF2023 CLI Bridge

echo "Testing CF2023 Package Manager Tools..."
echo "======================================="

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
    echo "WARNING: CommandBox not found. Package manager tools require CommandBox."
    echo "Install from: https://www.ortussolutions.com/products/commandbox"
    echo "Package tools will run in simulation mode."
    export COMMANDBOX_AVAILABLE=false
else
    echo "CommandBox found - package tools will be fully functional"
    export COMMANDBOX_AVAILABLE=true
fi

# Test 1: Initialize
echo -e "\n1. Testing initialize..."
INIT_RESPONSE=$(echo '{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":"2024-11-05"}}' | cfml cli-bridge/cf-mcp-cli-bridge-v2.cfm 2>/tmp/cf-mcp-package-test.log)
echo "$INIT_RESPONSE" | jq '.result.protocolVersion'

# Test 2: Search for packages
echo -e "\n2. Testing packageSearch tool..."
SEARCH_RESPONSE=$(echo '{"jsonrpc":"2.0","id":2,"method":"tools/call","params":{"name":"packageSearch","arguments":{"query":"testbox","limit":3}}}' | cfml cli-bridge/cf-mcp-cli-bridge-v2.cfm 2>>/tmp/cf-mcp-package-test.log)
echo "$SEARCH_RESPONSE" | jq '.result'

# Test 3: List installed packages
echo -e "\n3. Testing packageList tool..."
LIST_RESPONSE=$(echo '{"jsonrpc":"2.0","id":3,"method":"tools/call","params":{"name":"packageList","arguments":{"format":"json"}}}' | cfml cli-bridge/cf-mcp-cli-bridge-v2.cfm 2>>/tmp/cf-mcp-package-test.log)
echo "$LIST_RESPONSE" | jq '.result'


# Test 5: Module manager - list modules
echo -e "\n5. Testing moduleManager tool (list)..."
MODULE_RESPONSE=$(echo '{"jsonrpc":"2.0","id":5,"method":"tools/call","params":{"name":"moduleManager","arguments":{"action":"list"}}}' | cfml cli-bridge/cf-mcp-cli-bridge-v2.cfm 2>>/tmp/cf-mcp-package-test.log)
echo "$MODULE_RESPONSE" | jq '.result'

# Test 4: Install a package (dry run - don't actually install)
 echo -e "\n4. Testing packageInstaller tool (simulated)..."
SIMULATE_RESPONSE=$(echo '{"jsonrpc":"2.0","id":4,"method":"tools/list","params":{}}' | cfml cli-bridge/cf-mcp-cli-bridge-v2.cfm 2>>/tmp/cf-mcp-package-test.log)
if echo "$SIMULATE_RESPONSE" | jq -e '.result.tools[] | select(.name=="packageInstaller")' > /dev/null; then
    echo "✓ packageInstaller tool is available"
    echo "Would run: packageInstaller with packageName='testbox@5.0.0'"
    echo "(Skipping actual installation to avoid modifying system)"
else
    echo "✗ packageInstaller tool not available"
fi

echo -e "\n\nTest log available at: /tmp/cf-mcp-package-test.log"
echo "To view errors: tail -f /tmp/cf-mcp-package-test.log"
echo ""
echo "NOTE: Some tests are simulated to avoid system modifications."
echo "      In production, these tools would actually install/update packages."