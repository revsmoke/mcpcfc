#!/bin/bash
#
# MCPCFC Bridge v2.0
# ColdFusion 2025 MCP Server Bridge for stdio transport
#
# This script translates Claude Desktop's stdio protocol to HTTP requests
# to the MCPCFC server endpoint.
#
# Usage:
#   Configure in Claude Desktop's MCP settings:
#   {
#     "mcpcfc": {
#       "command": "/path/to/cf-mcp-bridge.sh",
#       "env": {
#         "MCPCFC_URL": "https://mcpcfc.local"
#       }
#     }
#   }
#

set -e

# Configuration
SESSION_ID="${SESSION_ID:-$(uuidgen 2>/dev/null || cat /proc/sys/kernel/random/uuid 2>/dev/null || echo "session-$$-$(date +%s)")}"
MCP_URL="${MCPCFC_URL:-https://mcpcfc.local}"
MCP_ENDPOINT="${MCP_URL}/endpoints/mcp.cfm"
DEBUG="${MCPCFC_DEBUG:-0}"
TIMEOUT="${MCPCFC_TIMEOUT:-60}"

# Log function (only if DEBUG=1)
log_debug() {
    if [ "$DEBUG" = "1" ]; then
        echo "[$(date +'%Y-%m-%d %H:%M:%S')] [DEBUG] $1" >&2
    fi
}

log_error() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] [ERROR] $1" >&2
}

# Startup message
log_debug "MCPCFC Bridge v2.0 starting"
log_debug "Session ID: $SESSION_ID"
log_debug "Target URL: $MCP_ENDPOINT"

# Main loop - read JSON-RPC requests from stdin, send to server, output responses
while IFS= read -r line; do
    # Skip empty lines
    if [ -z "$line" ]; then
        continue
    fi

    log_debug "Request: $line"

    # Send request to MCPCFC server
    response=$(curl -s -S -X POST \
        -H "Content-Type: application/json" \
        -H "Accept: application/json" \
        -H "X-Session-ID: $SESSION_ID" \
        --max-time "$TIMEOUT" \
        -d "$line" \
        "${MCP_ENDPOINT}?sessionId=${SESSION_ID}" 2>&1)

    curl_exit_code=$?

    if [ $curl_exit_code -ne 0 ]; then
        log_error "curl failed with exit code $curl_exit_code: $response"

        # Check if the request had an ID (not a notification)
        if echo "$line" | grep -q '"id"'; then
            # Extract the ID from the request for the error response
            request_id=$(echo "$line" | grep -o '"id"[[:space:]]*:[[:space:]]*[^,}]*' | sed 's/"id"[[:space:]]*:[[:space:]]*//')
            echo "{\"jsonrpc\":\"2.0\",\"error\":{\"code\":-32603,\"message\":\"Connection error\"},\"id\":${request_id:-null}}"
        fi
        continue
    fi

    # Check if response is valid JSON
    if [ -n "$response" ] && echo "$response" | grep -q '^{'; then
        log_debug "Response: $response"
        echo "$response"
    elif [ -n "$response" ]; then
        log_error "Invalid response from server: $response"

        # Try to extract ID for error response
        if echo "$line" | grep -q '"id"'; then
            request_id=$(echo "$line" | grep -o '"id"[[:space:]]*:[[:space:]]*[^,}]*' | sed 's/"id"[[:space:]]*:[[:space:]]*//')
            echo "{\"jsonrpc\":\"2.0\",\"error\":{\"code\":-32603,\"message\":\"Invalid server response\"},\"id\":${request_id:-null}}"
        fi
    fi
    # Empty response is OK for notifications (status 204)

done

log_debug "MCPCFC Bridge exiting"
