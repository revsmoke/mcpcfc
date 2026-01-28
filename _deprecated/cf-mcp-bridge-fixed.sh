#!/bin/bash
# Fixed stdio bridge for ColdFusion MCP Server
# Handles line-delimited JSON communication for Claude Desktop

SESSION_ID=$(uuidgen)
MCP_URL="http://localhost:8500/mcpcfc"

# Start SSE connection in background to receive server-initiated messages
# But filter out duplicates by tracking message IDs
declare -A seen_ids
(
    curl -s -N -H "Accept: text/event-stream" \
        "$MCP_URL/endpoints/sse.cfm?sessionId=$SESSION_ID" 2>/dev/null | \
    while IFS= read -r line; do
        if [[ $line == data:* ]]; then
            data="${line#data: }"
            # Skip empty data, timestamps, and non-JSON-RPC messages
            if [[ -n "$data" && "$data" != " " && ! "$data" =~ ^\{ts[[:space:]] ]]; then
                # Only output if it contains "jsonrpc" field and has an id we haven't seen
                if [[ "$data" == *'"jsonrpc"'* && "$data" == *'"id":'* ]]; then
                    # Extract ID from JSON (simple regex approach)
                    if [[ "$data" =~ \"id\":([0-9]+) ]]; then
                        msg_id="${BASH_REMATCH[1]}"
                        if [[ -z "${seen_ids[$msg_id]}" ]]; then
                            seen_ids[$msg_id]=1
                            echo "$data"
                        fi
                    fi
                elif [[ "$data" == *'"jsonrpc"'* ]]; then
                    # Messages without ID (notifications) always output
                    echo "$data"
                fi
            fi
        fi
    done
) &

SSE_PID=$!

# Handle cleanup on exit
trap 'kill $SSE_PID 2>/dev/null' EXIT INT TERM

# Process stdin messages
while IFS= read -r line; do
    if [[ -n "$line" ]]; then
        # Extract ID from request to mark as seen
        if [[ "$line" =~ \"id\":([0-9]+) ]]; then
            req_id="${BASH_REMATCH[1]}"
            seen_ids[$req_id]=1
        fi
        
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