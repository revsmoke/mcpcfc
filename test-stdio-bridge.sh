#!/bin/bash
# Test harness for stdio bridge testing
# Simulates Claude Desktop's communication pattern

echo "=== Testing ColdFusion MCP Server Stdio Bridge ==="
echo ""

# Test 1: Direct server test
echo "1. Testing direct server connection..."
DIRECT_RESPONSE=$(curl -s -X POST -H "Content-Type: application/json" \
    -d '{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":"2024-11-05","capabilities":{},"clientInfo":{"name":"test","version":"1.0.0"}}}' \
    "http://localhost:8500/mcpcfc/endpoints/messages.cfm?sessionId=test-direct")

if [[ -n "$DIRECT_RESPONSE" ]]; then
    echo "✅ Direct server test passed"
    echo "Response: $DIRECT_RESPONSE"
else
    echo "❌ Direct server test failed - no response"
fi
echo ""

# Test 2: Bridge test with timeout
echo "2. Testing bridge with initialize request..."
# Using background process with sleep instead of timeout
{
    echo '{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":"2024-11-05","capabilities":{},"clientInfo":{"name":"test","version":"1.0.0"}}}' | \
    ./cf-mcp-bridge.sh 2>&1
} &
BRIDGE_PID=$!
sleep 5
if kill -0 $BRIDGE_PID 2>/dev/null; then
    kill $BRIDGE_PID 2>/dev/null
    BRIDGE_RESPONSE="Process timed out"
else
    wait $BRIDGE_PID
    BRIDGE_RESPONSE=$(cat)

if [[ -n "$BRIDGE_RESPONSE" ]]; then
    echo "✅ Bridge test passed"
    echo "Response: $BRIDGE_RESPONSE"
else
    echo "❌ Bridge test failed - no response or timeout"
fi
echo ""

# Test 3: Debug bridge with log monitoring
echo "3. Testing debug bridge..."
LOG_FILE="/tmp/cf-mcp-bridge-debug.log"
rm -f "$LOG_FILE"

echo '{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":"2024-11-05","capabilities":{},"clientInfo":{"name":"test","version":"1.0.0"}}}' | \
    timeout 5 ./cf-mcp-bridge-debug.sh > /tmp/bridge-output.txt 2>&1 &

sleep 3
echo "Debug log contents:"
if [[ -f "$LOG_FILE" ]]; then
    cat "$LOG_FILE"
else
    echo "No log file created"
fi

echo ""
echo "Bridge output:"
if [[ -f "/tmp/bridge-output.txt" ]]; then
    cat "/tmp/bridge-output.txt"
else
    echo "No output file created"
fi

# Test 4: SSE connection test
echo ""
echo "4. Testing SSE connection..."
timeout 3 curl -s -N -H "Accept: text/event-stream" \
    "http://localhost:8500/mcpcfc/endpoints/sse.cfm?sessionId=test-sse" | \
    head -n 10

echo ""
echo "=== Test Complete ==="