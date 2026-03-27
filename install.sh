#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
CONFIG_DIR="$HOME/.config/agent-look"
CONFIG_FILE="$CONFIG_DIR/config.json"

GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${BLUE}agent-look — Multi-platform setup${NC}"
echo "======================================"
echo ""

# Detect installed platforms
DETECTED_PLATFORMS=()
PLATFORM_NAMES=()

if [ -f "$HOME/Library/Application Support/Claude/claude_desktop_config.json" ]; then
  DETECTED_PLATFORMS+=("claude-desktop")
  PLATFORM_NAMES+=("Claude Desktop")
fi

if command -v claude &> /dev/null; then
  DETECTED_PLATFORMS+=("claude-code")
  PLATFORM_NAMES+=("Claude Code")
fi

if command -v gemini &> /dev/null; then
  DETECTED_PLATFORMS+=("gemini-cli")
  PLATFORM_NAMES+=("Gemini CLI")
fi

if command -v codex &> /dev/null; then
  DETECTED_PLATFORMS+=("codex")
  PLATFORM_NAMES+=("Codex")
fi

if [ ${#DETECTED_PLATFORMS[@]} -eq 0 ]; then
  echo -e "${YELLOW}Warning: No supported tools detected${NC}"
  echo "Supported: Claude Desktop, Claude Code, Gemini CLI, Codex"
  echo ""
  read -p "Continue anyway? [y/N]: " -r
  echo ""
  if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    exit 0
  fi
  DETECTED_PLATFORMS=("claude-desktop")
  PLATFORM_NAMES=("Claude Desktop")
fi

echo -e "${GREEN}Detected platforms:${NC}"
for i in "${!PLATFORM_NAMES[@]}"; do
  echo "  ✓ ${PLATFORM_NAMES[$i]}"
done
echo ""

# -- Platform selection menu -----------------------------------------------

echo "Which platforms should agent-look be installed to?"
echo "[1] All detected platforms (recommended)"
echo "[2] Select specific platforms"
echo "[3] Cancel"
echo ""
read -p "Choose [1-3] (default 1): " -r CHOICE
CHOICE="${CHOICE:-1}"
echo ""

case "$CHOICE" in
  1)
    SELECTED_PLATFORMS=("${DETECTED_PLATFORMS[@]}")
    SELECTED_NAMES=("${PLATFORM_NAMES[@]}")
    ;;
  2)
    SELECTED_PLATFORMS=()
    SELECTED_NAMES=()
    for i in "${!PLATFORM_NAMES[@]}"; do
      read -p "Install to ${PLATFORM_NAMES[$i]}? [Y/n]: " -r
      if [[ -z "$REPLY" || $REPLY =~ ^[Yy]$ ]]; then
        SELECTED_PLATFORMS+=("${DETECTED_PLATFORMS[$i]}")
        SELECTED_NAMES+=("${PLATFORM_NAMES[$i]}")
      fi
    done
    echo ""
    ;;
  3)
    exit 0
    ;;
  *)
    echo "Invalid choice. Exiting."
    exit 1
    ;;
esac

if [ ${#SELECTED_PLATFORMS[@]} -eq 0 ]; then
  echo "No platforms selected. Exiting."
  exit 0
fi

# -- Screencapture directory detection and prompt --------------------------

echo "Where are your screenshots stored?"

# Try to get macOS screenshot location setting
SPOTLIGHT_DIR=$(/usr/bin/defaults read com.apple.screencapture location 2>/dev/null || echo "")

if [ -n "$SPOTLIGHT_DIR" ]; then
  PROPOSED_DIR="$SPOTLIGHT_DIR"
elif [ -d "$HOME/Pictures/Screenshots" ]; then
  PROPOSED_DIR="$HOME/Pictures/Screenshots"
else
  PROPOSED_DIR="$HOME/Desktop"
fi

read -p "Screencapture directory [$PROPOSED_DIR]: " -r USER_DIR
SCREENGRABS_DIR="${USER_DIR:-$PROPOSED_DIR}"

if [ ! -d "$SCREENGRABS_DIR" ]; then
  echo -e "${YELLOW}Warning: Directory does not exist: $SCREENGRABS_DIR${NC}"
  read -p "Create it? [Y/n]: " -r
  if [[ -z "$REPLY" || $REPLY =~ ^[Yy]$ ]]; then
    mkdir -p "$SCREENGRABS_DIR"
  else
    echo "Cannot proceed without a valid directory. Exiting."
    exit 1
  fi
fi

echo "  Using: $SCREENGRABS_DIR"
echo ""

# -- Config file creation --------------------------------------------------

echo "Creating config file at $CONFIG_FILE..."

mkdir -p "$CONFIG_DIR"

PLATFORMS_JSON="["
for i in "${!SELECTED_PLATFORMS[@]}"; do
  if [ $i -gt 0 ]; then
    PLATFORMS_JSON="$PLATFORMS_JSON,"
  fi
  PLATFORMS_JSON="$PLATFORMS_JSON\"${SELECTED_PLATFORMS[$i]}\""
done
PLATFORMS_JSON="$PLATFORMS_JSON]"

cat > "$CONFIG_FILE" <<EOF
{
  "screencaptureDir": "$SCREENGRABS_DIR",
  "enabledPlatforms": $PLATFORMS_JSON
}
EOF

echo "  ✓ Config file created"
echo ""

# -- Platform-specific registration ----------------------------------------

echo "Installing agent-look..."
echo ""

if [[ " ${SELECTED_PLATFORMS[@]} " =~ " claude-desktop " ]]; then
  echo "Registering with Claude Desktop..."

  CLAUDE_DESKTOP_CONFIG="$HOME/Library/Application Support/Claude/claude_desktop_config.json"
  MCP_ENTRY=$(cat <<JSON
{
  "command": "node",
  "args": ["$SCRIPT_DIR/mcp/server.js"],
  "env": {}
}
JSON
)

  mkdir -p "$(dirname "$CLAUDE_DESKTOP_CONFIG")"

  if [ -f "$CLAUDE_DESKTOP_CONFIG" ]; then
    /usr/bin/python3 -c "
import json, sys
config_path = sys.argv[1]
mcp_entry = json.loads(sys.argv[2])
with open(config_path, 'r') as f:
    config = json.load(f)
config.setdefault('mcpServers', {})['agent-look'] = mcp_entry
with open(config_path, 'w') as f:
    json.dump(config, f, indent=2)
" "$CLAUDE_DESKTOP_CONFIG" "$MCP_ENTRY"
  else
    /usr/bin/python3 -c "
import json, sys
config_path = sys.argv[1]
mcp_entry = json.loads(sys.argv[2])
config = {'mcpServers': {'agent-look': mcp_entry}}
with open(config_path, 'w') as f:
    json.dump(config, f, indent=2)
" "$CLAUDE_DESKTOP_CONFIG" "$MCP_ENTRY"
  fi

  echo "  ✓ Claude Desktop configured"
fi

if [[ " ${SELECTED_PLATFORMS[@]} " =~ " claude-code " ]]; then
  echo "Claude Code setup:"
  echo "  Run in Claude Code: /plugin marketplace add $SCRIPT_DIR"
  echo "  Then run: /plugin install agent-look@agent-look-dev"
fi

if [[ " ${SELECTED_PLATFORMS[@]} " =~ " gemini-cli " ]]; then
  echo "Gemini CLI: MCP server registered via config file."
  echo "  Add to your Gemini settings.json manually if needed."
fi

if [[ " ${SELECTED_PLATFORMS[@]} " =~ " codex " ]]; then
  echo "Codex: MCP server registered via config file."
  echo "  Add to your Codex configuration manually if needed."
fi

echo ""

# -- Summary ---------------------------------------------------------------

echo -e "${GREEN}Installation complete!${NC}"
echo ""
echo "Installed to:"
for name in "${SELECTED_NAMES[@]}"; do
  echo "  • $name"
done
echo ""
echo "Config file: $CONFIG_FILE"
echo "Edit this file to change settings without re-running install."
echo ""
echo "Next steps:"
echo "  1. Restart Claude Desktop or Claude Code"
echo "  2. Try the find_recent_screenshots tool"
echo ""
echo "Questions? Email: recall-skill@raiteri.net"
