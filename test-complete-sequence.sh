#!/bin/bash
# Complete test sequence for Claude Desktop compatibility

echo "=== Complete MCP Protocol Test ==="
echo ""

# Test all required MCP methods
{
    echo '{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":"2024-11-05","capabilities":{},"clientInfo":{"name":"claude-desktop","version":"1.0.0"}}}'
    echo '{"jsonrpc":"2.0","id":2,"method":"tools/list"}'
    echo '{"jsonrpc":"2.0","id":3,"method":"tools/call","params":{"name":"hello","arguments":{"name":"Claude"}}}'
    echo '{"jsonrpc":"2.0","id":4,"method":"tools/call","params":{"name":"validateEmailAddress","arguments":{"email":"claude@anthropic.com"}}}'
} | ./cf-mcp-bridge-simple.sh

echo ""
echo "Test complete!"