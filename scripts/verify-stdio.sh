#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

BRIDGE="${BRIDGE:-"$ROOT_DIR/bridge/cf-mcp-bridge.sh"}"
MCPCFC_URL="${MCPCFC_URL:-"http://localhost:8500/mcpcfc"}"

if [[ ! -x "$BRIDGE" ]]; then
  echo "ERROR: Bridge script not found or not executable: $BRIDGE" >&2
  echo "Fix: chmod +x \"$BRIDGE\"" >&2
  exit 2
fi

if ! command -v python3 >/dev/null 2>&1; then
  echo "ERROR: python3 is required for this smoke test." >&2
  exit 2
fi

set +e
OUTPUT="$(
  MCPCFC_URL="$MCPCFC_URL" MCPCFC_DEBUG=0 "$BRIDGE" <<'EOF'
{"jsonrpc":"2.0","id":0,"method":"initialize","params":{"protocolVersion":"2025-06-18","capabilities":{},"clientInfo":{"name":"mcpcfc-stdio-smoke","version":"1.0.0"}}}
{"jsonrpc":"2.0","method":"notifications/initialized"}
{"jsonrpc":"2.0","id":1,"method":"tools/list","params":{}}
{"jsonrpc":"2.0","id":2,"method":"prompts/list","params":{}}
{"jsonrpc":"2.0","id":3,"method":"resources/list","params":{}}
{"jsonrpc":"2.0","id":4,"method":"tools/call","params":{"name":"hello","arguments":{"name":"stdio-smoke-test"}}}
EOF
)"
BRIDGE_EXIT=$?
set -e

if [[ $BRIDGE_EXIT -ne 0 ]]; then
  echo "ERROR: Bridge exited with code $BRIDGE_EXIT" >&2
  exit $BRIDGE_EXIT
fi

if [[ -z "${OUTPUT//[$'\t\r\n ']}" ]]; then
  echo "ERROR: No output received from server." >&2
  echo "MCPCFC_URL=$MCPCFC_URL" >&2
  exit 1
fi

TMP_FILE="$(mktemp "${TMPDIR:-/tmp}/mcpcfc-stdio-smoke.XXXXXX")"
cleanup() {
  rm -f "$TMP_FILE" 2>/dev/null || true
}
trap cleanup EXIT
printf '%s\n' "$OUTPUT" >"$TMP_FILE"

python3 - "$MCPCFC_URL" "$TMP_FILE" <<'PY'
import json
import sys

base_url = sys.argv[1]
output_path = sys.argv[2]

with open(output_path, "r", encoding="utf-8") as f:
    raw = f.read()
lines = [l.strip() for l in raw.splitlines() if l.strip()]

def fail(message: str) -> None:
    print(f"FAIL: {message}", file=sys.stderr)
    print(f"MCPCFC_URL={base_url}", file=sys.stderr)
    sys.exit(1)

messages = []
for idx, line in enumerate(lines, start=1):
    try:
        messages.append(json.loads(line))
    except json.JSONDecodeError as e:
        fail(f"Line {idx} is not valid JSON: {e}: {line[:200]}")

by_id = {m.get("id"): m for m in messages if "id" in m}

def require_id(msg_id: int) -> dict:
    msg = by_id.get(msg_id)
    if not isinstance(msg, dict):
        fail(f"Missing JSON-RPC response with id={msg_id}")
    if msg.get("jsonrpc") != "2.0":
        fail(f"id={msg_id} missing jsonrpc=2.0")
    if "error" in msg:
        fail(f"id={msg_id} returned error: {msg['error']}")
    if "result" not in msg:
        fail(f"id={msg_id} missing result")
    return msg

init = require_id(0)
if not isinstance(init["result"], dict):
    fail("initialize result is not an object")

tools_list = require_id(1)
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

prompts_list = require_id(2)
prompts_result = prompts_list["result"]
if not isinstance(prompts_result, dict) or "prompts" not in prompts_result:
    fail("prompts/list result must be an object containing key 'prompts' (lowercase)")
if not isinstance(prompts_result["prompts"], list):
    fail("prompts/list prompts must be an array")

resources_list = require_id(3)
resources_result = resources_list["result"]
if not isinstance(resources_result, dict) or "resources" not in resources_result:
    fail("resources/list result must be an object containing key 'resources' (lowercase)")
if not isinstance(resources_result["resources"], list):
    fail("resources/list resources must be an array")

hello = require_id(4)
hello_result = hello["result"]
if not isinstance(hello_result, dict):
    fail("tools/call result must be an object")
content = hello_result.get("content")
if not isinstance(content, list) or not content:
    fail("tools/call result missing non-empty content array")
first = content[0]
if not isinstance(first, dict) or first.get("type") != "text" or not isinstance(first.get("text"), str):
    fail("tools/call content[0] must contain {type:'text', text:'...'}")

print(f"OK: stdio MCP smoke test passed ({len(tools)} tools).")
PY
