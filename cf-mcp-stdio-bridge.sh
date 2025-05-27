#!/bin/bash
# Minimal bridge for ColdFusion MCP Server to work with Claude Desktop
# This is necessary because Claude Desktop requires stdio communication
# while ColdFusion MCP Server uses HTTP/SSE

SESSION_ID=$(uuidgen)
MCP_URL="http://localhost:8500/mcpcfc"
LOG_FILE="/tmp/cf-mcp-bridge-$$.log"

# Enable logging for debugging
log() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE"
}

log "Bridge started with session ID: $SESSION_ID, PID: $$"

# Function to handle messages
handle_message() {
    local message="$1"
    log "Received from stdin: $message"
    
    # Send to ColdFusion MCP server
    response=$(curl -s -X POST \
        -H "Content-Type: application/json" \
        -d "$message" \
        "$MCP_URL/endpoints/messages.cfm?sessionId=$SESSION_ID" 2>&1)
    
    log "Response from CF server: $response"
    
    # Output response only if it's valid JSON
    if [[ -n "$response" ]]; then
        echo "$response"
        flush_output
    fi
}

# Function to ensure output is flushed
flush_output() {
    # Force output to be written immediately
    true
}

# Connect to SSE endpoint in background
(
    log "Connecting to SSE endpoint..."
    curl -s -N -H "Accept: text/event-stream" \
        "$MCP_URL/endpoints/sse.cfm?sessionId=$SESSION_ID" 2>&1 | \
    while IFS= read -r line; do
        if [[ $line == data:* ]]; then
            # Extract data after "data: "
            data="${line#data: }"
            # Skip empty data and heartbeats
            if [[ -n "$data" && "$data" != " " ]]; then
                # Skip heartbeats (timestamps)
                if [[ ! "$data" =~ ^\{ts[[:space:]] ]]; then
                    log "SSE data: $data"
                    echo "$data"
                    flush_output
                fi
            fi
        fi
    done
) &

SSE_PID=$!
log "SSE connection PID: $SSE_PID"

# Trap signals to cleanup properly
trap 'log "Signal received, cleaning up..."; kill $SSE_PID 2>/dev/null; exit' INT TERM

# Handle stdin - read line by line
while IFS= read -r line; do
    if [[ -n "$line" ]]; then
        handle_message "$line"
    fi
done

# Cleanup
log "Bridge shutting down..."
kill $SSE_PID 2>/dev/null