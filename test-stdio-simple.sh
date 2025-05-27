#!/bin/bash
# Simple test for stdio bridge

echo "=== Simple Stdio Bridge Test ==="
echo ""

# Test 1: Direct server test
echo "1. Testing direct server..."
curl -s -X POST -H "Content-Type: application/json" \
    -d '{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":"2024-11-05","capabilities":{},"clientInfo":{"name":"test","version":"1.0.0"}}}' \
    "http://localhost:8500/mcpcfc/endpoints/messages.cfm?sessionId=test-123"
echo ""
echo ""

# Test 2: Bridge test
echo "2. Testing bridge (will run for 5 seconds)..."
echo '{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":"2024-11-05","capabilities":{},"clientInfo":{"name":"test","version":"1.0.0"}}}' | \
    ./cf-mcp-bridge.sh &

BRIDGE_PID=$!
sleep 5
kill $BRIDGE_PID 2>/dev/null
echo ""

# Test 3: Debug bridge
echo "3. Running debug bridge..."
echo '{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":"2024-11-05","capabilities":{},"clientInfo":{"name":"test","version":"1.0.0"}}}' | \
    ./cf-mcp-bridge-debug.sh &

DEBUG_PID=$!
sleep 5
kill $DEBUG_PID 2>/dev/null

echo ""
echo "4. Debug log contents:"
if [[ -f "/tmp/cf-mcp-bridge-debug.log" ]]; then
    tail -20 /tmp/cf-mcp-bridge-debug.log
else
    echo "No debug log found"
fi