#!/bin/bash
# Test JSON-RPC response formatting

echo "=== Testing JSON-RPC Response Formatting ==="
echo ""

echo "1. Testing initialize response format:"
INIT_RESPONSE=$(echo '{"jsonrpc":"2.0","id":0,"method":"initialize","params":{"protocolVersion":"2024-11-05","capabilities":{},"clientInfo":{"name":"claude-ai","version":"0.1.0"}}}' | ./cf-mcp-simple-bridge.sh)
echo "$INIT_RESPONSE"
# Check if fields are in correct order
if [[ "$INIT_RESPONSE" =~ ^{\"jsonrpc\":\"2.0\",\"id\":0,\"result\": ]]; then
    echo "✅ Initialize response has correct field order"
else
    echo "❌ Initialize response has incorrect field order"
fi
echo ""

echo "2. Testing error response format:"
ERROR_RESPONSE=$(echo '{"jsonrpc":"2.0","id":1,"method":"resources/list"}' | ./cf-mcp-simple-bridge.sh)
echo "$ERROR_RESPONSE"
# Check if error fields are in correct order
if [[ "$ERROR_RESPONSE" =~ ^{\"jsonrpc\":\"2.0\",\"id\":1,\"error\":{\"code\":-32601,\"message\": ]]; then
    echo "✅ Error response has correct field order"
else
    echo "❌ Error response has incorrect field order"
fi
echo ""

echo "3. Testing tools/list response format:"
TOOLS_RESPONSE=$(echo '{"jsonrpc":"2.0","id":2,"method":"tools/list"}' | ./cf-mcp-simple-bridge.sh)
echo "$TOOLS_RESPONSE" | head -c 200
echo "..."
if [[ "$TOOLS_RESPONSE" =~ ^{\"jsonrpc\":\"2.0\",\"id\":2,\"result\": ]]; then
    echo "✅ Tools/list response has correct field order"
else
    echo "❌ Tools/list response has incorrect field order"
fi
echo ""

echo "=== All tests complete ==="
echo ""
echo "Next steps:"
echo "1. Restart Claude Desktop"
echo "2. Check if coldfusion-mcp server connects successfully"
echo "3. Try using one of the tools (e.g., hello tool)"