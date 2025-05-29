#!/bin/bash
# Claude Desktop MCP Server Restart Script
# This script restarts Claude Desktop to reload MCP tools

echo "🔄 Restarting Claude Desktop to load new MCP tools..."

# Get the current URL/thread if Claude is running
CLAUDE_URL=$(osascript -e 'tell application "Claude" to if it is running then return URL of current tab of front window' 2>/dev/null || echo "")

# Kill Claude Desktop
osascript -e 'tell application "Claude" to quit' 2>/dev/null || true

# Wait for it to fully close
sleep 2

# Restart Claude Desktop
open -a "Claude"

# Wait for it to start
sleep 3

# If we had a URL, navigate back to it
if [ ! -z "$CLAUDE_URL" ]; then
    echo "📍 Returning to previous conversation..."
    open "$CLAUDE_URL"
fi

echo "✅ Claude Desktop restarted! New tools should be available."