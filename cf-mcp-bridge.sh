#!/bin/bash
# Simple stdio bridge for ColdFusion MCP Server
# Handles line-delimited JSON communication for Claude Desktop

SESSION_ID=$(uuidgen)
MCP_URL="http://localhost:8500/mcpcfc"

# Start SSE connection in background to receive server-initiated messages
curl -s -N -H "Accept: text/event-stream" \
    "$MCP_URL/endpoints/sse.cfm?sessionId=$SESSION_ID" 2>/dev/null | \
while IFS= read -r line; do
    if [[ $line == data:* ]]; then
        data="${line#data: }"
        # Skip empty data, timestamps, and non-JSON-RPC messages
        if [[ -n "$data" && "$data" != " " && ! "$data" =~ ^\{ts[[:space:]] ]]; then
            # Only output if it contains "jsonrpc" field (valid JSON-RPC message)
            if [[ "$data" == *'"jsonrpc"'* ]]; then
                echo "$data"
            fi
        fi
    fi
done &

SSE_PID=$!

# Handle cleanup on exit
trap 'kill $SSE_PID 2>/dev/null' EXIT INT TERM

# Process stdin messages
while IFS= read -r line; do
    if [[ -n "$line" ]]; then
        # Send to ColdFusion server and output response
        response=$(curl -s -X POST \
            -H "Content-Type: application/json" \
            -d "$line" \
            "$MCP_URL/endpoints/messages.cfm?sessionId=$SESSION_ID" 2>/dev/null)
        
        # Output response with newline if not empty
        if [[ -n "$response" ]]; then
            echo "$response"
        fi
    fi
done