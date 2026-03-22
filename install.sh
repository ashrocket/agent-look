#!/usr/bin/env bash
# agent-look installer — wires up Claude Desktop only.
# Claude Code installation: /plugin marketplace add /path/to/agent-look
#                           /plugin install agent-look@agent-look-dev
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
CLAUDE_DESKTOP_CONFIG="$HOME/Library/Application Support/Claude/claude_desktop_config.json"

echo "agent-look — Claude Desktop setup"
echo "=================================="

# -- Pick screencapture folder -------------------------------------------
echo ""
echo "Opening folder picker for your screencapture folder..."
SCREENGRABS=$(osascript <<'APPLESCRIPT'
tell application "System Events"
    activate
end tell
set chosen to choose folder with prompt "Select your screencapture folder:"
return POSIX path of chosen
APPLESCRIPT
)
SCREENGRABS="${SCREENGRABS%/}"
echo "  Folder: $SCREENGRABS"

# -- Register MCP in Claude Desktop --------------------------------------
echo ""
echo "Registering MCP server in Claude Desktop..."

MCP_ENTRY=$(cat <<JSON
{
  "command": "node",
  "args": ["$SCRIPT_DIR/mcp/server.js"],
  "env": {
    "SCREENGRABS_DIR": "$SCREENGRABS"
  }
}
JSON
)

if [ -f "$CLAUDE_DESKTOP_CONFIG" ]; then
    UPDATED=$(jq --argjson entry "$MCP_ENTRY" '.mcpServers["agent-look"] = $entry' "$CLAUDE_DESKTOP_CONFIG")
    echo "$UPDATED" > "$CLAUDE_DESKTOP_CONFIG"
else
    mkdir -p "$(dirname "$CLAUDE_DESKTOP_CONFIG")"
    jq -n --argjson entry "$MCP_ENTRY" '{"mcpServers": {"agent-look": $entry}}' > "$CLAUDE_DESKTOP_CONFIG"
fi
echo "  ✓ MCP registered in Claude Desktop config"

# -- Done ----------------------------------------------------------------
echo ""
echo "Done! Restart Claude Desktop to activate."
echo ""
echo "For Claude Code, install via the plugin system:"
echo "  /plugin marketplace add $SCRIPT_DIR"
echo "  /plugin install agent-look@agent-look-dev"
echo ""
echo "Questions? Email: recall-skill@raiteri.net"
