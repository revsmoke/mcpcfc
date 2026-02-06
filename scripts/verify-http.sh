#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# If MCPCFC_ENDPOINT_URL is not set, derive it from MCPCFC_URL (base URL).
MCPCFC_ENDPOINT_URL="${MCPCFC_ENDPOINT_URL:-""}"
MCPCFC_URL="${MCPCFC_URL:-"http://localhost:8500/mcpcfc"}"
MCPCFC_TIMEOUT="${MCPCFC_TIMEOUT:-60}"
MCPCFC_INSECURE="${MCPCFC_INSECURE:-0}"

if [[ -z "$MCPCFC_ENDPOINT_URL" ]]; then
  MCPCFC_ENDPOINT_URL="${MCPCFC_URL%/}/endpoints/mcp.cfm"
fi

if ! command -v curl >/dev/null 2>&1; then
  echo "ERROR: curl is required for this smoke test." >&2
  exit 2
fi

if ! command -v python3 >/dev/null 2>&1; then
  echo "ERROR: python3 is required for this smoke test." >&2
  exit 2
fi

TMP_DIR="$(mktemp -d "${TMPDIR:-/tmp}/mcpcfc-http-smoke.XXXXXX")"
cleanup() {
  rm -rf "$TMP_DIR" 2>/dev/null || true
}
trap cleanup EXIT

CURL_FLAGS=(
  -sS
  --connect-timeout 10
  --max-time "$MCPCFC_TIMEOUT"
)

if [[ "$MCPCFC_INSECURE" == "1" ]]; then
  CURL_FLAGS+=(--insecure)
fi

request_json() {
  local name="$1"
  local payload="$2"
  shift 2

  local hdr_file="$TMP_DIR/${name}.headers"
  local body_file="$TMP_DIR/${name}.body"

  curl "${CURL_FLAGS[@]}" \
    -D "$hdr_file" \
    -o "$body_file" \
    -X POST \
    -H "Content-Type: application/json" \
    -H "Accept: application/json" \
    "$@" \
    -d "$payload" \
    "$MCPCFC_ENDPOINT_URL" >/dev/null

  echo "$hdr_file|$body_file"
}

get_status_code() {
  local hdr_file="$1"
  awk 'NR==1 {print $2}' "$hdr_file"
}

get_header_value() {
  local hdr_file="$1"
  local header_name="$2"
  awk -v name="$header_name" 'BEGIN{IGNORECASE=1} $1 ~ ("^"name":$") {print $2}' "$hdr_file" | tail -1 | tr -d '\r'
}

INIT_PAYLOAD='{"jsonrpc":"2.0","id":0,"method":"initialize","params":{"protocolVersion":"2025-06-18","capabilities":{},"clientInfo":{"name":"mcpcfc-http-smoke","version":"1.0.0"}}}'
INIT_FILES="$(request_json "initialize" "$INIT_PAYLOAD")"
INIT_HDR="${INIT_FILES%%|*}"
INIT_BODY="${INIT_FILES##*|}"

INIT_STATUS="$(get_status_code "$INIT_HDR")"
if [[ "$INIT_STATUS" != "200" ]]; then
  echo "ERROR: initialize returned HTTP $INIT_STATUS" >&2
  echo "Endpoint: $MCPCFC_ENDPOINT_URL" >&2
  sed -n '1,60p' "$INIT_HDR" >&2 || true
  sed -n '1,60p' "$INIT_BODY" >&2 || true
  exit 1
fi

SESSION_ID="$(get_header_value "$INIT_HDR" "MCP-Session-Id")"
if [[ -z "$SESSION_ID" ]]; then
  echo "ERROR: initialize response missing MCP-Session-Id header" >&2
  echo "Endpoint: $MCPCFC_ENDPOINT_URL" >&2
  sed -n '1,80p' "$INIT_HDR" >&2 || true
  exit 1
fi

NOTIFY_PAYLOAD='{"jsonrpc":"2.0","method":"notifications/initialized"}'
NOTIFY_FILES="$(request_json "notify_initialized" "$NOTIFY_PAYLOAD" -H "MCP-Session-Id: $SESSION_ID" -H "MCP-Protocol-Version: 2025-06-18")"
NOTIFY_HDR="${NOTIFY_FILES%%|*}"
NOTIFY_BODY="${NOTIFY_FILES##*|}"

NOTIFY_STATUS="$(get_status_code "$NOTIFY_HDR")"
if [[ "$NOTIFY_STATUS" != "202" ]]; then
  echo "ERROR: notifications/initialized expected HTTP 202, got $NOTIFY_STATUS" >&2
  echo "Endpoint: $MCPCFC_ENDPOINT_URL" >&2
  sed -n '1,60p' "$NOTIFY_HDR" >&2 || true
  sed -n '1,60p' "$NOTIFY_BODY" >&2 || true
  exit 1
fi

TOOLS_PAYLOAD='{"jsonrpc":"2.0","id":1,"method":"tools/list","params":{}}'
TOOLS_FILES="$(request_json "tools_list" "$TOOLS_PAYLOAD" -H "MCP-Session-Id: $SESSION_ID" -H "MCP-Protocol-Version: 2025-06-18")"
TOOLS_HDR="${TOOLS_FILES%%|*}"
TOOLS_BODY="${TOOLS_FILES##*|}"

TOOLS_STATUS="$(get_status_code "$TOOLS_HDR")"
if [[ "$TOOLS_STATUS" != "200" ]]; then
  echo "ERROR: tools/list returned HTTP $TOOLS_STATUS" >&2
  echo "Endpoint: $MCPCFC_ENDPOINT_URL" >&2
  sed -n '1,60p' "$TOOLS_HDR" >&2 || true
  sed -n '1,60p' "$TOOLS_BODY" >&2 || true
  exit 1
fi

HELLO_PAYLOAD='{"jsonrpc":"2.0","id":2,"method":"tools/call","params":{"name":"hello","arguments":{"name":"http-smoke-test"}}}'
HELLO_FILES="$(request_json "hello" "$HELLO_PAYLOAD" -H "MCP-Session-Id: $SESSION_ID" -H "MCP-Protocol-Version: 2025-06-18")"
HELLO_HDR="${HELLO_FILES%%|*}"
HELLO_BODY="${HELLO_FILES##*|}"

HELLO_STATUS="$(get_status_code "$HELLO_HDR")"
if [[ "$HELLO_STATUS" != "200" ]]; then
  echo "ERROR: tools/call(hello) returned HTTP $HELLO_STATUS" >&2
  echo "Endpoint: $MCPCFC_ENDPOINT_URL" >&2
  sed -n '1,60p' "$HELLO_HDR" >&2 || true
  sed -n '1,60p' "$HELLO_BODY" >&2 || true
  exit 1
fi

python3 - "$MCPCFC_ENDPOINT_URL" "$INIT_BODY" "$TOOLS_BODY" "$HELLO_BODY" <<'PY'
import json
import sys

endpoint = sys.argv[1]
init_path = sys.argv[2]
tools_path = sys.argv[3]
hello_path = sys.argv[4]

def read_json(path: str) -> dict:
    with open(path, "r", encoding="utf-8") as f:
        raw = f.read().strip()
    if not raw:
        raise ValueError(f"Empty JSON body: {path}")
    return json.loads(raw)

def fail(msg: str) -> None:
    print(f"FAIL: {msg}", file=sys.stderr)
    print(f"MCPCFC_ENDPOINT_URL={endpoint}", file=sys.stderr)
    sys.exit(1)

init = read_json(init_path)
if init.get("jsonrpc") != "2.0" or init.get("id") != 0 or "result" not in init:
    fail("initialize response is not valid JSON-RPC 2.0 with id=0 + result")

tools_list = read_json(tools_path)
if tools_list.get("jsonrpc") != "2.0" or tools_list.get("id") != 1 or "result" not in tools_list:
    fail("tools/list response is not valid JSON-RPC 2.0 with id=1 + result")

tools_result = tools_list["result"]
if not isinstance(tools_result, dict) or "tools" not in tools_result:
    fail("tools/list result must be an object containing key 'tools' (lowercase)")
tools = tools_result["tools"]
if not isinstance(tools, list) or not tools:
    fail("tools/list returned no tools")

upper_key_markers = {"TOOLS", "PROMPTS", "RESOURCES", "CONTENTS", "TYPE", "PROPERTIES", "REQUIRED"}

def walk(obj):
    if isinstance(obj, dict):
        for k, v in obj.items():
            yield k
            yield from walk(v)
    elif isinstance(obj, list):
        for item in obj:
            yield from walk(item)

all_keys = set(k for k in walk(tools_list))
bad = sorted(all_keys.intersection(upper_key_markers))
if bad:
    fail(f"tools/list JSON contains uppercased keys that break MCP clients: {', '.join(bad)}")

for tool in tools:
    if not isinstance(tool, dict) or not isinstance(tool.get("name"), str) or not tool["name"]:
        fail("tool missing required string field: name")
    schema = tool.get("inputSchema")
    if not isinstance(schema, dict):
        fail(f"tool {tool.get('name')} missing inputSchema object")
    if schema.get("type") != "object":
        fail(f"tool {tool.get('name')} inputSchema.type must be 'object'")
    props = schema.get("properties")
    if not isinstance(props, dict):
        fail(f"tool {tool.get('name')} inputSchema.properties must be an object")

hello = read_json(hello_path)
if hello.get("jsonrpc") != "2.0" or hello.get("id") != 2 or "result" not in hello:
    fail("tools/call response is not valid JSON-RPC 2.0 with id=2 + result")

hello_result = hello["result"]
if not isinstance(hello_result, dict):
    fail("tools/call result must be an object")
content = hello_result.get("content")
if not isinstance(content, list) or not content:
    fail("tools/call result missing non-empty content array")
first = content[0]
if not isinstance(first, dict) or first.get("type") != "text" or not isinstance(first.get("text"), str):
    fail("tools/call content[0] must contain {type:'text', text:'...'}")

print(f"OK: HTTP MCP smoke test passed ({len(tools)} tools).")
PY

