#!/bin/bash
# ColdFusion MCP Server stdio bridge v2
# Handles line-delimited JSON communication for Claude Desktop

set -euo pipefail

SESSION_ID=$(uuidgen)
MCP_URL="http://localhost:8500/mcpcfc"

# Start SSE connection in background
{
    curl -s -N \
        -H "Accept: text/event-stream" \
        -H "Cache-Control: no-cache" \
        "$MCP_URL/endpoints/sse.cfm?sessionId=$SESSION_ID" | \
    while IFS= read -r line; do
        if [[ $line == data:* ]]; then
            data="${line#data: }"
            # Only output valid JSON-RPC messages
            if [[ -n "$data" && "$data" != " " && "$data" == *'"jsonrpc"'* ]]; then
                printf '%s\n' "$data"
            fi
        fi
    done
} &

SSE_PID=$!

# Cleanup on exit
cleanup() {
    kill $SSE_PID 2>/dev/null || true
    exit
}
trap cleanup EXIT INT TERM

# Process stdin messages
while IFS= read -r line; do
    if [[ -n "$line" ]]; then
        # Send to ColdFusion server
        response=$(curl -s -X POST \
            -H "Content-Type: application/json" \
            -H "Accept: application/json" \
            -d "$line" \
            "$MCP_URL/endpoints/messages.cfm?sessionId=$SESSION_ID")
        
        # Output response immediately
        if [[ -n "$response" ]]; then
            printf '%s\n' "$response"
        fi
    fi
done