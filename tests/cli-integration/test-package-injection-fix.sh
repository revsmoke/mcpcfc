#!/bin/bash
set -euo pipefail

# Test script to verify command injection fix in PackageManagerTool

echo "Testing PackageManagerTool command injection fix..."

# Test that malicious input is properly escaped
TEST_PAYLOAD='test-package"; echo "INJECTED" > /tmp/injection-test.txt; echo "'

# Try to inject command via package name
 echo "Testing package install with injection attempt..."
curl --connect-timeout 10 --max-time 30 -X POST \
  http://localhost:8500/mcpcfc/endpoints/messages.cfm?sessionId=test-injection \
  -H "Content-Type: application/json" \
  -d "{\"jsonrpc\":\"2.0\",\"id\":1,\"method\":\"packageInstaller\",\"params\":{\"packageName\":\"$TEST_PAYLOAD\"}}" \
  > /dev/null 2>&1

# Check if injection was successful (file should NOT exist)
if [ -f "/tmp/injection-test.txt" ]; then
    echo "FAIL: Command injection vulnerability still exists!"
    rm -f /tmp/injection-test.txt
    exit 1
else
    echo "PASS: Command injection was properly prevented"
fi

# Test with version parameter
echo "Testing package install with version injection attempt..."
curl --connect-timeout 10 --max-time 30 -X POST \
  http://localhost:8500/mcpcfc/endpoints/messages.cfm?sessionId=test-injection \
  -H "Content-Type: application/json" \
  -d "{\"jsonrpc\":\"2.0\",\"id\":2,\"method\":\"packageInstaller\",\"params\":{\"packageName\":\"valid-package\",\"version\":\"1.0.0$TEST_PAYLOAD\"}}" \
  > /dev/null 2>&1

# Check again
if [ -f "/tmp/injection-test.txt" ]; then
    echo "FAIL: Command injection via version parameter!"
    rm -f /tmp/injection-test.txt
    exit 1
else
    echo "PASS: Version parameter injection was prevented"
fi

echo "All command injection tests passed!"