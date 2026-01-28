#!/bin/bash
# Simple stdio bridge for ColdFusion MCP Server (macOS compatible)
# Handles line-delimited JSON communication for Claude Desktop

SESSION_ID=$(uuidgen)
MCP_URL="http://localhost:8500/mcpcfc"

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