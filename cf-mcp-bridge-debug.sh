#!/bin/bash
# Debug version of stdio bridge for ColdFusion MCP Server
# Handles line-delimited JSON communication for Claude Desktop

SESSION_ID=$(uuidgen)
MCP_URL="http://localhost:8500/mcpcfc"
LOG_FILE="/tmp/cf-mcp-bridge-debug.log"

# Enable logging
log() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE"
}

log "Bridge started with session ID: $SESSION_ID"

# Start SSE connection in background to receive server-initiated messages
(
    log "Starting SSE connection..."
    curl -s -N -H "Accept: text/event-stream" \
        "$MCP_URL/endpoints/sse.cfm?sessionId=$SESSION_ID" 2>&1 | \
    while IFS= read -r line; do
        log "SSE line: $line"
        if [[ $line == data:* ]]; then
            data="${line#data: }"
            # Skip empty data, timestamps, and non-JSON-RPC messages
            if [[ -n "$data" && "$data" != " " && ! "$data" =~ ^\{ts[[:space:]] ]]; then
                # Only output if it contains "jsonrpc" field (valid JSON-RPC message)
                if [[ "$data" == *'"jsonrpc"'* ]]; then
                    log "SSE JSON-RPC output: $data"
                    echo "$data"
                else
                    log "SSE skipping non-JSON-RPC: $data"
                fi
            fi
        fi
    done
) &

SSE_PID=$!
log "SSE PID: $SSE_PID"

# Handle cleanup on exit
trap 'log "Shutting down..."; kill $SSE_PID 2>/dev/null' EXIT INT TERM

# Process stdin messages
while IFS= read -r line; do
    if [[ -n "$line" ]]; then
        log "Received from stdin: $line"
        
        # Send to ColdFusion server and capture response
        response=$(curl -s -X POST \
            -H "Content-Type: application/json" \
            -d "$line" \
            "$MCP_URL/endpoints/messages.cfm?sessionId=$SESSION_ID" 2>&1)
        
        log "Response from CF server: $response"
        
        # Output the response
        if [[ -n "$response" ]]; then
            echo "$response"
            log "Sent to stdout: $response"
        fi
    fi
done

log "Bridge exiting..."