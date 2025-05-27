#!/bin/bash
# Clean stdio bridge for ColdFusion MCP Server
# Ensures no extra output is sent to Claude Desktop

# Exit on any error
set -e

# Generate unique session ID
SESSION_ID=$(uuidgen)
MCP_URL="http://localhost:8500/mcpcfc"

# Log to stderr for debugging (not stdout)
log_debug() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $1" >&2
}

log_debug "Bridge started with session ID: $SESSION_ID"

# Process stdin messages
while IFS= read -r line; do
    if [[ -n "$line" ]]; then
        log_debug "Received: $line"
        
        # Send to ColdFusion server and capture response
        # Use -s for silent mode, -S to show errors
        response=$(curl -s -S -X POST \
            -H "Content-Type: application/json" \
            -H "Accept: application/json" \
            -d "$line" \
            "$MCP_URL/endpoints/messages.cfm?sessionId=$SESSION_ID" 2>&1)
        
        # Check if curl succeeded
        if [ $? -eq 0 ]; then
            # Only output if response is not empty and looks like JSON
            if [[ -n "$response" && "$response" == *"{"* ]]; then
                echo "$response"
                log_debug "Sent response: $response"
            else
                log_debug "Empty or invalid response from server"
            fi
        else
            log_debug "Curl error: $response"
            # Send error response
            echo '{"jsonrpc":"2.0","error":{"code":-32603,"message":"Internal server error"}}'
        fi
    fi
done

log_debug "Bridge exiting"