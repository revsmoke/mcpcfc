#!/bin/bash
set -euo pipefail

# Test script to verify error handling improvements in test scripts

echo "Testing improved error handling in test scripts..."

# Test 1: Check if scripts have proper error handling
echo "1. Checking for 'set -euo pipefail' in main test scripts..."

SCRIPTS_TO_CHECK=(
     "test-devtools.sh"
     "test-cli-bridge.sh" 
     "test-package-tools.sh"
     "test-repl-tools.sh"
     "test-server-tools.sh"
)
for script in "${SCRIPTS_TO_CHECK[@]}"; do
     if grep -q "set -euo pipefail" "/Applications/ColdFusion2023/cfusion/wwwroot/mcpcfc/tests/cli-integration/$script"; then
         echo "✓ $script has proper error handling"
     else
         echo "✗ $script missing error handling"
        exit 1
     fi
 done

# Test 2: Check for tool dependency checks
echo ""
echo "2. Checking for tool dependency checks..."
for script in "${SCRIPTS_TO_CHECK[@]}"; do
    if grep -q "command -v cfml" "/Applications/ColdFusion2023/cfusion/wwwroot/mcpcfc/tests/cli-integration/$script"; then
          echo "✓ $script checks for cfml dependency"
      else
          echo "✗ $script missing cfml check"
         exit 1
      fi

     if grep -q "command -v jq" "/Applications/ColdFusion2023/cfusion/wwwroot/mcpcfc/tests/cli-integration/$script"; then
          echo "✓ $script checks for jq dependency"
      else
          echo "✗ $script missing jq check (if needed)"
     fi
 done
        exit 1
     fi
done

echo ""
echo "3. Testing actual error handling behavior..."

# Create a temporary test script to verify error handling
cat > /tmp/test-error-handling.sh << 'EOF'
#!/bin/bash
set -euo pipefail

echo "This should work"
false  # This should cause the script to exit
echo "This should not appear"
EOF

chmod +x /tmp/test-error-handling.sh

# Run the test script and capture exit code
if /tmp/test-error-handling.sh 2>/dev/null; then
    echo "✗ Error handling test failed - script did not exit on error"
else
    echo "✓ Error handling working correctly - script exited on error"
fi

# Clean up
rm -f /tmp/test-error-handling.sh

echo ""
echo "Error handling verification complete!"