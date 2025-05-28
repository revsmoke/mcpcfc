#!/bin/bash

# MCPCFC Phase 5 Cleanup Script
# This script removes obsolete files identified after Phase 5 implementation
# Date: $(date)

echo "MCPCFC Phase 5 Cleanup Script"
echo "============================="
echo ""
echo "This script will remove obsolete files identified after Phase 5 completion."
echo ""

# Get the script directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$SCRIPT_DIR"

# Create log file
LOG_FILE="cleanup-phase5-log-$(date +%Y%m%d-%H%M%S).txt"
echo "MCPCFC Phase 5 Cleanup Log" > "$LOG_FILE"
echo "Date: $(date)" >> "$LOG_FILE"
echo "" >> "$LOG_FILE"

# Counter for removed files
REMOVED_COUNT=0

# Function to safely remove a file
remove_file() {
    local file="$1"
    if [ -f "$file" ]; then
        echo "✓ Removing: $file"
        rm -f "$file"
        echo "- Removed: $file" >> "$LOG_FILE"
        ((REMOVED_COUNT++))
    else
        echo "⚠ Skipping (not found): $file"
        echo "- Not found: $file" >> "$LOG_FILE"
    fi
}

# Confirm with user
echo "The following files will be removed:"
echo ""
echo "Duplicate/Old test scripts:"
echo "  - tests/cli-integration/test-json-parse-errors.sh"
echo "  - tests/cli-integration/test-original-bridge-json-parsing.sh"
echo "  - tests/cli-integration/test-tagcontext-safety.sh"
echo ""
echo "Old cleanup artifacts:"
echo "  - cleanup-log-20250527-165842.txt"
echo "  - cleanup-obsolete-tests.sh"
echo ""
echo "Redundant bridge scripts:"
echo "  - cf-mcp-bridge-fixed.sh"
echo "  - cf-mcp-simple-bridge.sh"
echo ""

read -p "Do you want to proceed? (y/N) " -n 1 -r
echo ""
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Cleanup cancelled."
    exit 0
fi

echo ""
echo "Starting cleanup..."
echo "" >> "$LOG_FILE"

# Remove duplicate/old test scripts
echo ""
echo "Removing duplicate/old test scripts..."
echo "Duplicate/Old test scripts:" >> "$LOG_FILE"
remove_file "tests/cli-integration/test-json-parse-errors.sh"
remove_file "tests/cli-integration/test-original-bridge-json-parsing.sh"
remove_file "tests/cli-integration/test-tagcontext-safety.sh"

# Remove old cleanup artifacts
echo ""
echo "Removing old cleanup artifacts..."
echo "" >> "$LOG_FILE"
echo "Old cleanup artifacts:" >> "$LOG_FILE"
remove_file "cleanup-log-20250527-165842.txt"
remove_file "cleanup-obsolete-tests.sh"

# Remove redundant bridge scripts
echo ""
echo "Removing redundant bridge scripts..."
echo "" >> "$LOG_FILE"
echo "Redundant bridge scripts:" >> "$LOG_FILE"
remove_file "cf-mcp-bridge-fixed.sh"
remove_file "cf-mcp-simple-bridge.sh"

echo ""
echo "==============================="
echo "Cleanup Summary:"
echo "==============================="
echo "Removed $REMOVED_COUNT files" | tee -a "$LOG_FILE"
echo ""
echo "Log saved to: $LOG_FILE"
echo ""

# Show files that might need manual review
echo "Files to consider removing manually (project-dependent):"
echo ""
echo "Setup/Utility files:"
echo "  - database-setup.cfm (if database is already configured)"
echo "  - restart-app.cfm (if not needed for development)"
echo "  - view-pdf.cfm (if PDF testing is complete)"
echo ""
echo "Playwright files (if not using Playwright):"
echo "  - playwright-test.js"
echo "  - playwright.config.js"
echo ""
echo "Historical documentation (if no longer needed):"
echo "  - ANNOUNCEMENT.md"
echo "  - PHASE1-COMPLETE.md"
echo "  - PHASE3-COMPLETE.md"
echo ""
echo "Important: The following bridge scripts were KEPT:"
echo "  ✓ cf-mcp-clean-bridge.sh (recommended bridge)"
echo "  ✓ cf-mcp-cf2023-cli.sh (native CF2023 CLI bridge)"
echo "  ✓ cli-bridge/cf-mcp-cli-bridge-v2.cfm (enhanced CLI bridge)"
echo ""
echo "Cleanup complete!"