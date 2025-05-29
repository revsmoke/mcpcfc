#!/bin/bash

# Ensure script fails fast on errors
set -euo pipefail

# Test script for CF2023 CLI Bridge

echo "Testing CF2023 MCP CLI Bridge..."
echo "================================"

# Ensure we're in the correct directory
if [[ ! -f "cli-bridge/cf-mcp-cli-bridge-v2.cfm" ]]; then
    echo "ERROR: cli-bridge/cf-mcp-cli-bridge-v2.cfm not found."
    echo "Please run this script from the mcpcfc root directory."
    exit 1
fi

 # Check if required tools are installed
echo "Checking for required tools..."

# Check for cfml (ColdFusion CLI)
if ! command -v cfml &> /dev/null; then
    echo "ERROR: cfml command not found. ColdFusion 2023 CLI is required."
    echo "Ensure ColdFusion 2023 is installed and cfml is in your PATH."
    exit 1
fi

# Test 1: Initialize
echo -e "\n1. Testing initialize..."
echo '{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":"2024-11-05","capabilities":{"roots":{"listChanged":true},"sampling":{}},"clientInfo":{"name":"test-client","version":"1.0.0"}}}' | cfml cli-bridge/cf-mcp-cli-bridge-v2.cfm 2>/tmp/cf-mcp-test.log

# Test 2: List tools
echo -e "\n2. Testing tools/list..."
echo '{"jsonrpc":"2.0","id":2,"method":"tools/list","params":{}}' | cfml cli-bridge/cf-mcp-cli-bridge-v2.cfm 2>>/tmp/cf-mcp-test.log

# Test 3: Call hello tool
echo -e "\n3. Testing hello tool..."
echo '{"jsonrpc":"2.0","id":3,"method":"tools/call","params":{"name":"hello","arguments":{"name":"CF2023"}}}' | cfml cli-bridge/cf-mcp-cli-bridge-v2.cfm 2>>/tmp/cf-mcp-test.log

# Test 4: Test notification (should not return response)
echo -e "\n4. Testing notification..."
echo '{"jsonrpc":"2.0","method":"notifications/initialized","params":{}}' | cfml cli-bridge/cf-mcp-cli-bridge-v2.cfm 2>>/tmp/cf-mcp-test.log

echo -e "\n\nTest log available at: /tmp/cf-mcp-test.log"
echo "To view: cat /tmp/cf-mcp-test.log"