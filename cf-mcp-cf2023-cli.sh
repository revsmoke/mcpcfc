#!/bin/bash

# CF2023 MCP CLI Bridge Launcher
# This script launches the native CFML stdio bridge

# Get the directory where this script is located
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Check if cfml command is available
if ! command -v cfml &> /dev/null; then
    echo "Error: cfml command not found. Please ensure ColdFusion 2023 CLI is installed." >&2
    echo "Visit: https://helpx.adobe.com/coldfusion/using/command-line-interface.html" >&2
    exit 1
fi

# Launch the CF CLI bridge
exec cfml "$BRIDGE"