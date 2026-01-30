#!/bin/bash
#
# MCPCFC Bridge v2.1
# ColdFusion 2025 MCP Server Bridge for stdio transport
#
# This script translates Claude Desktop's stdio protocol to HTTP requests
# to the MCPCFC server endpoint.
#
# Usage:
#   Configure in Claude Desktop's MCP settings
#   (~/Library/Application Support/Claude/claude_desktop_config.json):
#
#   {
#     "mcpServers": {
#       "coldfusion-mcp": {
#         "command": "/path/to/mcpcfc/bridge/cf-mcp-bridge.sh",
#         "env": {
#           "MCPCFC_URL": "https://mcpcfc.local"
#         }
#       }
#     }
#   }
#
# Environment variables:
#   MCPCFC_URL        - Base URL of ColdFusion server (default: https://mcpcfc.local)
#   MCPCFC_DEBUG      - Enable debug logging to stderr: 0 or 1 (default: 0)
#   MCPCFC_TIMEOUT    - Request timeout in seconds (default: 60)
#   MCPCFC_INSECURE   - Skip SSL verification: 0 or 1 (default: 0)
#

# Do NOT use set -e — curl failures must be handled by the error-handling
# code below, not by killing the entire bridge process.

# Configuration
SESSION_ID="${SESSION_ID:-$(uuidgen 2>/dev/null || cat /proc/sys/kernel/random/uuid 2>/dev/null || echo "session-$$-$(date +%s)")}"
MCP_URL="${MCPCFC_URL:-https://mcpcfc.local}"
MCP_ENDPOINT="${MCP_URL}/endpoints/mcp.cfm"
DEBUG="${MCPCFC_DEBUG:-0}"
TIMEOUT="${MCPCFC_TIMEOUT:-60}"
INSECURE="${MCPCFC_INSECURE:-0}"

# Build curl flags
CURL_EXTRA_FLAGS=""
if [ "$INSECURE" = "1" ]; then
    CURL_EXTRA_FLAGS="$CURL_EXTRA_FLAGS --insecure"
fi

# macOS .local domains use mDNS (Bonjour) which adds a 5-second timeout
# before falling back to regular DNS. Pre-resolve to 127.0.0.1 to avoid this.
MCP_HOST=$(echo "$MCP_URL" | sed -E 's|https?://([^:/]+).*|\1|')
if echo "$MCP_HOST" | grep -q '\.local$'; then
    MCP_PORT=$(echo "$MCP_URL" | grep -oE ':[0-9]+' | tr -d ':')
    MCP_PORT="${MCP_PORT:-443}"
    CURL_EXTRA_FLAGS="$CURL_EXTRA_FLAGS --resolve ${MCP_HOST}:${MCP_PORT}:127.0.0.1"
fi

# Log to stderr only (stdout is reserved for JSON-RPC protocol data)
log_debug() {
    if [ "$DEBUG" = "1" ]; then
        echo "[$(date +'%Y-%m-%d %H:%M:%S')] [MCPCFC-DEBUG] $1" >&2
    fi
}

log_error() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] [MCPCFC-ERROR] $1" >&2
}

# Extract JSON-RPC request ID (returns empty string for notifications)
extract_request_id() {
    echo "$1" | grep -o '"id"[[:space:]]*:[[:space:]]*[^,}]*' | head -1 | sed 's/"id"[[:space:]]*:[[:space:]]*//'
}

# Emit a JSON-RPC error response to stdout
emit_error() {
    local id="$1"
    local code="$2"
    local message="$3"
    if [ -n "$id" ]; then
        printf '{"jsonrpc":"2.0","error":{"code":%s,"message":"%s"},"id":%s}\n' "$code" "$message" "$id"
    fi
}

# Startup
log_debug "MCPCFC Bridge v2.1 starting"
log_debug "Session ID: $SESSION_ID"
log_debug "Target URL: $MCP_ENDPOINT"

# Main loop — read JSON-RPC requests from stdin, POST to server, output responses
while IFS= read -r line; do
    # Skip empty lines
    if [ -z "$line" ]; then
        continue
    fi

    log_debug ">>> $line"

    # Send request to MCPCFC server
    # - Capture only stdout (HTTP response body) into $response
    # - Send curl's stderr to /dev/null (errors detected via exit code)
    # - No set -e, so curl failure won't kill the script
    response=$(curl -s \
        $CURL_EXTRA_FLAGS \
        --connect-timeout 10 \
        --max-time "$TIMEOUT" \
        -X POST \
        -H "Content-Type: application/json" \
        -H "Accept: application/json" \
        -H "X-Session-ID: $SESSION_ID" \
        -d "$line" \
        "${MCP_ENDPOINT}?sessionId=${SESSION_ID}" </dev/null 2>/dev/null)

    curl_exit_code=$?

    # Handle curl failure
    if [ $curl_exit_code -ne 0 ]; then
        log_error "curl failed (exit $curl_exit_code) for endpoint $MCP_ENDPOINT"

        request_id=$(extract_request_id "$line")
        emit_error "$request_id" "-32603" "Connection error"
        continue
    fi

    # Empty response is OK for notifications (HTTP 204)
    if [ -z "$response" ]; then
        log_debug "<<< (empty — notification acknowledged)"
        continue
    fi

    # Validate response looks like JSON before forwarding
    if printf '%s' "$response" | grep -q '^[[:space:]]*{'; then
        log_debug "<<< $response"
        printf '%s\n' "$response"
    else
        log_error "Non-JSON response from server: $response"

        request_id=$(extract_request_id "$line")
        emit_error "$request_id" "-32603" "Invalid server response"
    fi

done

log_debug "MCPCFC Bridge exiting"
