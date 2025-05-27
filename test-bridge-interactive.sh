#!/bin/bash
# Interactive test for ColdFusion MCP bridge
# Simulates Claude Desktop's communication pattern

echo "=== Interactive Bridge Test ==="
echo "Starting bridge and sending multiple requests..."
echo ""

# Create a named pipe for communication
PIPE=$(mktemp -u)
mkfifo "$PIPE"

# Start the bridge in background, connecting stdin to our pipe
./cf-mcp-bridge-fixed.sh < "$PIPE" > /tmp/bridge-output.txt 2>&1 &
BRIDGE_PID=$!

# Function to send a request and wait for response
send_request() {
    local request="$1"
    local description="$2"
    
    echo "Sending: $description"
    echo "$request" > "$PIPE"
    sleep 1  # Give time for response
    
    # Show last response
    if [[ -f /tmp/bridge-output.txt ]]; then
        echo "Response:"
        tail -1 /tmp/bridge-output.txt
        echo ""
    fi
}

# Test sequence
send_request '{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":"2024-11-05","capabilities":{},"clientInfo":{"name":"test","version":"1.0.0"}}}' "Initialize"

send_request '{"jsonrpc":"2.0","id":2,"method":"tools/list"}' "List tools"

send_request '{"jsonrpc":"2.0","id":3,"method":"tools/call","params":{"name":"hello","arguments":{"name":"Bridge Test"}}}' "Call hello tool"

send_request '{"jsonrpc":"2.0","id":4,"method":"tools/call","params":{"name":"validateEmailAddress","arguments":{"email":"test@example.com"}}}' "Validate email"

# Let it run for a few more seconds to catch any async messages
echo "Waiting for any additional messages..."
sleep 3

# Cleanup
kill $BRIDGE_PID 2>/dev/null
rm -f "$PIPE"

echo ""
echo "Full bridge output:"
echo "=================="
cat /tmp/bridge-output.txt

echo ""
echo "Test complete!"