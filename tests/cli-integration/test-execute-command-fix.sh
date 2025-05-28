#!/bin/bash

# Test script to verify executeCommand fix handles multi-word commands properly

echo "Testing executeCommand fix for multi-word commands..."

# Test a command that would fail with the old implementation
echo "Testing multi-word command execution..."
echo '{
    "jsonrpc": "2.0",
    "id": 1,
    "method": "packageList",
    "params": {
        "showDependencies": true,
        "format": "json"
    }
}' | curl -s -X POST http://localhost:8500/mcpcfc/endpoints/messages.cfm?sessionId=test-execute-fix -H "Content-Type: application/json" -d @- | jq .

# The old implementation would pass "box list" as the name attribute to cfexecute
# which would fail because cfexecute expects just the executable name

echo ""
echo "If the response contains a success:true and a packages array, the fix is working correctly."