#!/bin/bash

# MCPCFC Test Files Cleanup Script
# This script removes obsolete test files and temporary files
# Date: $(date)

echo "MCPCFC Test Files Cleanup Script"
echo "================================="
echo ""

# Get the script directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$SCRIPT_DIR"

# Create log file
LOG_FILE="cleanup-log-$(date +%Y%m%d-%H%M%S).txt"
echo "MCPCFC Cleanup Log" > "$LOG_FILE"
echo "Date: $(date)" >> "$LOG_FILE"
echo "" >> "$LOG_FILE"

# Counter for removed files
REMOVED_COUNT=0

# Function to safely remove a file
remove_file() {
    local file="$1"
    if [ -f "$file" ]; then
        echo "Removing: $file"
        rm -f "$file"
        echo "- $file" >> "$LOG_FILE"
        ((REMOVED_COUNT++))
    else
        echo "Skipping (not found): $file"
    fi
}

echo "Removing obsolete test scripts..."
echo ""

# Remove test scripts
remove_file "test-bridge-interactive.sh"
remove_file "test-complete-sequence.sh"
remove_file "test-jsonrpc-format.sh"
remove_file "test-stdio-bridge.sh"
remove_file "test-stdio-simple.sh"

echo ""
echo "Removing cleanup files..."
echo ""

# Remove old cleanup files
remove_file "cleanup-obsolete-files.sh"
remove_file "cleanup-log-20250527-103023.txt"

echo ""
echo "Removing temporary PDF files..."
echo ""

# Remove temp PDFs
remove_file "temp/merged-cf-mcp.pdf"
remove_file "temp/test-cf-mcp-2.pdf"
remove_file "temp/test-cf-mcp.pdf"

echo ""
echo "Optional files to consider removing manually:"
echo "- database-setup.cfm (if database is already configured)"
echo "- restart-app.cfm (if not needed for development)"
echo "- view-pdf.cfm (if PDF testing is complete)"
echo "- playwright-test.js (if not using Playwright tests)"

echo ""
echo "Removed $REMOVED_COUNT files" | tee -a "$LOG_FILE"
echo ""
echo "Cleanup complete! Log saved to: $LOG_FILE"
echo ""
echo "Note: The following bridge scripts were KEPT as they are still in use:"
echo "- cf-mcp-clean-bridge.sh (recommended bridge)"
echo "- cf-mcp-simple-bridge.sh (alternative bridge)"
echo "- cf-mcp-bridge-fixed.sh (backup bridge)"