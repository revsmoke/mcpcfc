#!/bin/bash

# Test script for Server Management tools in CF2023 CLI Bridge

echo "Testing CF2023 Server Management Tools..."
echo "========================================"

# Change to script directory
cd "$(dirname "$0")/../.."

# Test 1: Initialize
echo -e "\n1. Testing initialize..."
INIT_RESPONSE=$(echo '{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":"2024-11-05"}}' | cfml cli-bridge/cf-mcp-cli-bridge-v2.cfm 2>/tmp/cf-mcp-server-test.log)
echo "$INIT_RESPONSE" | jq '.result.protocolVersion'

# Test 2: Get server status
echo -e "\n2. Testing serverStatus tool..."
STATUS_RESPONSE=$(echo '{"jsonrpc":"2.0","id":2,"method":"tools/call","params":{"name":"serverStatus","arguments":{"includeSystemInfo":true,"includeMemory":true}}}' | cfml cli-bridge/cf-mcp-cli-bridge-v2.cfm 2>>/tmp/cf-mcp-server-test.log)
echo "$STATUS_RESPONSE" | jq '.result'

# Test 3: Config manager - list categories
echo -e "\n3. Testing configManager tool (list)..."
CONFIG_LIST=$(echo '{"jsonrpc":"2.0","id":3,"method":"tools/call","params":{"name":"configManager","arguments":{"action":"list"}}}' | cfml cli-bridge/cf-mcp-cli-bridge-v2.cfm 2>>/tmp/cf-mcp-server-test.log)
echo "$CONFIG_LIST" | jq '.result.data'

# Test 4: Config manager - get runtime settings
echo -e "\n4. Testing configManager tool (get runtime)..."
CONFIG_GET=$(echo '{"jsonrpc":"2.0","id":4,"method":"tools/call","params":{"name":"configManager","arguments":{"action":"get","category":"runtime"}}}' | cfml cli-bridge/cf-mcp-cli-bridge-v2.cfm 2>>/tmp/cf-mcp-server-test.log)
echo "$CONFIG_GET" | jq '.result.data'

# Test 5: Clear cache
echo -e "\n5. Testing clearCache tool..."
CACHE_RESPONSE=$(echo '{"jsonrpc":"2.0","id":5,"method":"tools/call","params":{"name":"clearCache","arguments":{"cacheType":"template"}}}' | cfml cli-bridge/cf-mcp-cli-bridge-v2.cfm 2>>/tmp/cf-mcp-server-test.log)
echo "$CACHE_RESPONSE" | jq '.result'

# Test 6: Log streamer (this might fail if log file doesn't exist)
echo -e "\n6. Testing logStreamer tool..."
LOG_RESPONSE=$(echo '{"jsonrpc":"2.0","id":6,"method":"tools/call","params":{"name":"logStreamer","arguments":{"logFile":"application.log","lines":10,"fromTail":true}}}' | cfml cli-bridge/cf-mcp-cli-bridge-v2.cfm 2>>/tmp/cf-mcp-server-test.log)
echo "$LOG_RESPONSE" | jq '.result | {success, logFile, totalLines, entries: (.entries | length)}'

echo -e "\n\nTest log available at: /tmp/cf-mcp-server-test.log"
echo "To view errors: tail -f /tmp/cf-mcp-server-test.log"