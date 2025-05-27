#!/bin/bash

# MCPCFC Cleanup Script - Remove obsolete files after successful Claude Desktop integration
# Created: $(date)
# Purpose: Clean up old debugging files, test scripts, and obsolete bridge versions

echo "==================================="
echo "MCPCFC Cleanup Script"
echo "==================================="
echo ""
echo "This script will remove obsolete files that are no longer needed"
echo "after successfully implementing Claude Desktop integration."
echo ""

# Safety check - confirm we're in the right directory
if [ ! -f "Application.cfc" ] || [ ! -d "components" ]; then
    echo "ERROR: This script must be run from the MCPCFC root directory!"
    echo "Current directory: $(pwd)"
    exit 1
fi

echo "Current directory: $(pwd)"
echo ""
read -p "Are you sure you want to remove obsolete files? (y/N): " -n 1 -r
echo ""

if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Cleanup cancelled."
    exit 0
fi

echo ""
echo "Starting cleanup..."
echo ""

# Counter for removed files
removed_count=0

# Function to safely remove a file
remove_file() {
    local file="$1"
    if [ -f "$file" ]; then
        echo "  ✓ Removing: $file"
        rm -f "$file"
        ((removed_count++))
    else
        echo "  - Already gone: $file"
    fi
}

echo "1. Removing obsolete bridge scripts..."
remove_file "cf-mcp-bridge-debug.sh"
remove_file "cf-mcp-bridge-v2.sh"
remove_file "cf-mcp-bridge-simple.sh"
remove_file "cf-mcp-stdio-bridge.sh"
remove_file "cf-mcp-bridge.sh"  # Keeping cf-mcp-clean-bridge.sh as the working version

echo ""
echo "2. Removing debug/test endpoints..."
remove_file "endpoints/debug-messages.cfm"
remove_file "endpoints/messages-debug.cfm"

echo ""
echo "3. Removing standalone test files..."
remove_file "test-debug.cfm"
remove_file "test-jsonrpc.cfm"
remove_file "test-messages.cfm"
remove_file "simple-test.cfm"

echo ""
echo "4. Removing old PDF files from temp directory..."
remove_file "temp/test.pdf"
remove_file "temp/test2.pdf"
remove_file "temp/merged.pdf"

echo ""
echo "==================================="
echo "Cleanup Complete!"
echo "==================================="
echo "Removed $removed_count obsolete files."
echo ""
echo "Files kept:"
echo "  ✓ cf-mcp-clean-bridge.sh (working bridge script)"
echo "  ✓ client-examples/test-client.cfm (browser test client)"
echo "  ✓ database-setup.cfm (database setup utility)"
echo "  ✓ restart-app.cfm (application restart utility)"
echo "  ✓ view-pdf.cfm (PDF viewer utility)"
echo "  ✓ Recent test PDFs in temp/ (examples of working tools)"
echo ""
echo "Your MCPCFC installation is now clean and ready for production!"
echo ""

# Optional: Create a cleanup log
log_file="cleanup-log-$(date +%Y%m%d-%H%M%S).txt"
echo "Creating cleanup log: $log_file"
{
    echo "MCPCFC Cleanup Log"
    echo "Date: $(date)"
    echo "Removed $removed_count files"
    echo ""
    echo "Files removed:"
    echo "- cf-mcp-bridge-debug.sh"
    echo "- cf-mcp-bridge-v2.sh"
    echo "- cf-mcp-bridge-simple.sh"
    echo "- cf-mcp-stdio-bridge.sh"
    echo "- cf-mcp-bridge.sh"
    echo "- endpoints/debug-messages.cfm"
    echo "- endpoints/messages-debug.cfm"
    echo "- test-debug.cfm"
    echo "- test-jsonrpc.cfm"
    echo "- test-messages.cfm"
    echo "- simple-test.cfm"
    echo "- temp/test.pdf"
    echo "- temp/test2.pdf"
    echo "- temp/merged.pdf"
} > "$log_file"

echo "Cleanup log saved to: $log_file"
echo ""
echo "Done! 🎉"