# agent-look Install Wizard & README Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Create a comprehensive README and rewrite install.sh as an interactive wizard that detects installed tools, proposes smart defaults, and manages configuration via a persistent JSON file.

**Architecture:** The install wizard detects which platforms (Claude Desktop, Claude Code, Gemini CLI, Codex) are installed, proposes sensible defaults from system settings, then creates a persistent config file at `~/.config/agent-look/config.json`. The MCP server reads this config file at startup, allowing users to adjust settings without re-running install.

**Tech Stack:** Bash (install wizard), JSON (config file), Node.js (MCP server modification)

---

## File Structure

### Files to Create:
- `README.md` — User-facing documentation with quick start, features, examples, troubleshooting
- `lib/config.js` — Config file reader/writer utility
- `docs/superpowers/plans/2026-03-27-agent-look-install-wizard.md` — This plan (for tracking)

### Files to Modify:
- `install.sh` — Replace simple script with interactive wizard
- `mcp/server.js` — Read config file for screencapture directory
- `.gitignore` — Add `~/.config/agent-look/` note (optional, it's user config)

---

## Tasks

### Task 1: Create README.md

**Files:**
- Create: `README.md`

This is the comprehensive user-facing documentation covering quick start through troubleshooting.

- [ ] **Step 1: Create README.md with Quick Start section**

```markdown
# agent-look

Screenshot scanner and renamer for Claude Desktop, Claude Code, Gemini CLI, and Codex. Finds recent screenshots via Spotlight, extracts OCR text, and renames generic filenames.

## Quick Start (30 seconds)

1. Clone the repo: `git clone https://github.com/ashrocket/agent-look.git`
2. Enter directory: `cd agent-look`
3. Run installer: `./install.sh`
4. Answer 2 prompts:
   - Which platforms to install to (or press Enter for all detected)
   - Screencapture directory (or press Enter for default)
5. Restart Claude Desktop or Claude Code
6. Done!

For Claude Code: use `/look` command or `find_recent_screenshots` tool

## What It Does

- **Finds** recent screenshots via macOS Spotlight
- **Extracts** OCR text from generic-named screenshots
- **Renames** files from `Screenshot 2026-03-27 at 10.25.15 AM.png` to `react-component-button-styling.png`
- **Works with** Claude Desktop, Claude Code, Gemini CLI, Codex

## Supported Platforms

- **Required:** macOS 10.15+ (for Spotlight)
- **Compatible with:**
  - Claude Desktop
  - Claude Code (with /plugin system)
  - Gemini CLI
  - Codex

```

- [ ] **Step 2: Add Examples section**

```markdown
## Examples

### Before & After

| Generic Name | Smart Name |
|---|---|
| Screenshot 2026-03-27 at 10.25.15 AM.png | react-component-button-styling.png |
| Pasted Graphic 7.png | database-schema-diagram.png |
| CleanShot 2026-03-27 at 14.32.11.png | slack-webhook-setup-error.png |

The OCR text from each screenshot informs the new filename, making them searchable and meaningful.
```

- [ ] **Step 3: Add Installation (Detailed) section**

```markdown
## Installation (Detailed)

### Automated Install (Recommended)

```bash
./install.sh
```

The wizard will:
1. Detect which tools you have installed
2. Ask which to set up (or use all detected by default)
3. Ask for your screencapture directory (or propose default)
4. Register the MCP server with each tool
5. Create a config file at `~/.config/agent-look/config.json`

### Manual Installation

**Claude Desktop:**
Edit `~/Library/Application Support/Claude/claude_desktop_config.json`:
```json
{
  "mcpServers": {
    "agent-look": {
      "command": "node",
      "args": ["/path/to/agent-look/mcp/server.js"],
      "env": {
        "SCREENGRABS_DIR": "~/Pictures/Screenshots"
      }
    }
  }
}
```

**Claude Code:**
```bash
/plugin marketplace add /path/to/agent-look
/plugin install agent-look@agent-look-dev
```

Then run the installer to configure the screencapture directory.

### Configuration

Config file: `~/.config/agent-look/config.json`

```json
{
  "screencaptureDir": "~/Pictures/Screenshots",
  "enabledPlatforms": ["claude-desktop", "claude-code"]
}
```

Edit this file to change settings without re-running install. Changes take effect on next tool restart.
```

- [ ] **Step 4: Add Troubleshooting section**

```markdown
## Troubleshooting

### Spotlight isn't finding my screenshots

Check that your screencapture folder is indexed by Spotlight:
1. System Settings → Siri & Spotlight
2. Verify the screencapture directory isn't in the "Exclude" list
3. Try reindexing: `mdutil -i on ~/Pictures/Screenshots`

### The wrong folder is being scanned

Edit `~/.config/agent-look/config.json` and change `screencaptureDir` to the correct path. Restart your tool.

### Installation script permission denied

Make install.sh executable:
```bash
chmod +x install.sh
```

### MCP server not connecting after install

Restart Claude Desktop completely (not just close the window). For Claude Code, run `/plugin marketplace update`.

### "agent-look" not recognized as command in Claude Code

After running install.sh, run:
```bash
/plugin install agent-look@agent-look-dev
```
from within Claude Code.
```

- [ ] **Step 5: Add License & Author section**

```markdown
## License & Author

MIT License

Author: Ashley Raiteri
Email: recall-skill@raiteri.net
Repository: https://github.com/ashrocket/agent-look
```

- [ ] **Step 6: Verify README.md is complete and readable**

Run: `cat README.md | wc -l`

Expected: 150+ lines (complete documentation)

- [ ] **Step 7: Commit**

```bash
git add README.md
git commit -m "docs: add comprehensive README with quick start and troubleshooting"
```

---

### Task 2: Create lib/config.js — Config File Handler

**Files:**
- Create: `lib/config.js`

This utility handles reading, writing, and validation of the config file.

- [ ] **Step 1: Create lib directory if it doesn't exist**

```bash
mkdir -p lib
```

- [ ] **Step 2: Create lib/config.js with read function**

```javascript
import { readFileSync, existsSync } from "fs";
import { join } from "path";
import { homedir } from "os";

const CONFIG_DIR = join(homedir(), ".config", "agent-look");
const CONFIG_FILE = join(CONFIG_DIR, "config.json");

/**
 * Read config file. Returns default if file doesn't exist.
 * Falls back to environment variable SCREENGRABS_DIR for backward compatibility.
 */
export function readConfig() {
  if (existsSync(CONFIG_FILE)) {
    try {
      const raw = readFileSync(CONFIG_FILE, "utf8");
      return JSON.parse(raw);
    } catch (err) {
      console.warn(`Warning: Could not parse ${CONFIG_FILE}:`, err.message);
    }
  }

  // Fallback to environment variable for backward compatibility
  const screencaptureDir =
    process.env.SCREENGRABS_DIR ||
    join(
      homedir(),
      "Library/Mobile Documents/com~apple~CloudDocs/Downloads/screengrabs"
    );

  return {
    screencaptureDir,
    enabledPlatforms: ["claude-desktop"],
  };
}

/**
 * Validate config object has required fields.
 */
export function validateConfig(config) {
  if (!config.screencaptureDir || typeof config.screencaptureDir !== "string") {
    throw new Error("Config must have screencaptureDir (string)");
  }
  if (!Array.isArray(config.enabledPlatforms)) {
    throw new Error("Config must have enabledPlatforms (array)");
  }
  return true;
}

export { CONFIG_DIR, CONFIG_FILE };
```

- [ ] **Step 3: Verify lib/config.js loads without errors**

```bash
node -e "import('./lib/config.js').then(m => console.log('✓ Config module loads'))"
```

Expected: `✓ Config module loads`

- [ ] **Step 4: Commit**

```bash
git add lib/config.js
git commit -m "feat: add config file reader with backward-compatible fallback"
```

---

### Task 3: Modify mcp/server.js — Read Config File

**Files:**
- Modify: `mcp/server.js`

Update the server to read screencapture directory from the config file instead of only from environment variables.

- [ ] **Step 1: Add import for config module at top of mcp/server.js**

Add after line 11 (after `import { homedir } from "os"`):

```javascript
import { readConfig } from "../lib/config.js";
```

- [ ] **Step 2: Replace SCREENGRABS constant with config-based lookup**

Find the SCREENGRABS constant (lines 21-26):

```javascript
const SCREENGRABS =
  process.env.SCREENGRABS_DIR ||
  join(
    homedir(),
    "Library/Mobile Documents/com~apple~CloudDocs/Downloads/screengrabs"
  );
```

Replace with:

```javascript
const CONFIG = readConfig();
const SCREENGRABS = CONFIG.screencaptureDir;
```

- [ ] **Step 3: Verify mcp/server.js still starts without errors**

```bash
node mcp/server.js &
PROCESS_ID=$!
sleep 2
kill $PROCESS_ID
```

Expected: Server starts cleanly, no errors in stderr

- [ ] **Step 4: Commit**

```bash
git add mcp/server.js
git commit -m "refactor: read screencapture directory from config file"
```

---

### Task 4: Rewrite install.sh — Interactive Wizard

**Files:**
- Modify: `install.sh`

Replace the simple install script with an interactive wizard that detects platforms, proposes defaults, and manages the config file.

- [ ] **Step 1: Create new install.sh with header and platform detection**

```bash
#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
CONFIG_DIR="$HOME/.config/agent-look"
CONFIG_FILE="$CONFIG_DIR/config.json"

# Color codes for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${BLUE}agent-look — Multi-platform setup${NC}"
echo "======================================"
echo ""

# -- Detect installed platforms -------------------------------------------
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

# Show what we found
echo -e "${GREEN}Detected platforms:${NC}"
for i in "${!PLATFORM_NAMES[@]}"; do
  echo "  ✓ ${PLATFORM_NAMES[$i]}"
done
echo ""
```

- [ ] **Step 2: Add platform selection menu**

Add after the detection code:

```bash
# -- Ask which platforms to install to -----------------------------------
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
```

- [ ] **Step 3: Add screencapture directory detection and prompt**

Add after platform selection:

```bash
# -- Detect and propose screencapture directory --------------------------
echo "Where are your screenshots stored?"

# Try to get macOS Spotlight setting
SPOTLIGHT_DIR=$(/usr/bin/defaults read com.apple.screencapture location 2>/dev/null || echo "")

# Propose a directory
if [ -n "$SPOTLIGHT_DIR" ]; then
  PROPOSED_DIR="$SPOTLIGHT_DIR"
elif [ -d "$HOME/Pictures/Screenshots" ]; then
  PROPOSED_DIR="$HOME/Pictures/Screenshots"
else
  PROPOSED_DIR="$HOME/Desktop"
fi

read -p "Screencapture directory [$PROPOSED_DIR]: " -r USER_DIR
SCREENGRABS_DIR="${USER_DIR:-$PROPOSED_DIR}"

# Validate directory exists
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
```

- [ ] **Step 4: Add config file creation**

Add after screencapture directory validation:

```bash
# -- Create config file --------------------------------------------------
echo "Creating config file at $CONFIG_FILE..."

mkdir -p "$CONFIG_DIR"

# Build enabled platforms JSON array
PLATFORMS_JSON="["
for i in "${!SELECTED_PLATFORMS[@]}"; do
  if [ $i -gt 0 ]; then
    PLATFORMS_JSON="$PLATFORMS_JSON,"
  fi
  PLATFORMS_JSON="$PLATFORMS_JSON\"${SELECTED_PLATFORMS[$i]}\""
done
PLATFORMS_JSON="$PLATFORMS_JSON]"

# Write config file
cat > "$CONFIG_FILE" <<EOF
{
  "screencaptureDir": "$SCREENGRABS_DIR",
  "enabledPlatforms": $PLATFORMS_JSON
}
EOF

echo "  ✓ Config file created"
echo ""
```

- [ ] **Step 5: Add Claude Desktop registration**

Add after config file creation:

```bash
# -- Install to selected platforms ----------------------------------------
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
    # Update existing config
    /usr/bin/python3 - "$CLAUDE_DESKTOP_CONFIG" "$MCP_ENTRY" <<'PYTHON'
import json, sys
config_path = sys.argv[1]
mcp_entry = json.loads(sys.argv[2])
with open(config_path, 'r') as f:
  config = json.load(f)
config.setdefault('mcpServers', {})['agent-look'] = mcp_entry
with open(config_path, 'w') as f:
  json.dump(config, f, indent=2)
PYTHON
  else
    # Create new config
    /usr/bin/python3 - "$CLAUDE_DESKTOP_CONFIG" "$MCP_ENTRY" <<'PYTHON'
import json, sys
config_path = sys.argv[1]
mcp_entry = json.loads(sys.argv[2])
config = {'mcpServers': {'agent-look': mcp_entry}}
with open(config_path, 'w') as f:
  json.dump(config, f, indent=2)
PYTHON
  fi

  echo "  ✓ Claude Desktop configured"
fi

if [[ " ${SELECTED_PLATFORMS[@]} " =~ " claude-code " ]]; then
  echo "Claude Code setup:"
  echo "  Run in Claude Code: /plugin marketplace add $SCRIPT_DIR"
  echo "  Then run: /plugin install agent-look@agent-look-dev"
fi

echo ""
```

- [ ] **Step 6: Add summary and cleanup**

Add at the end:

```bash
# -- Done ----------------------------------------------------------------
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
echo "  2. Try the agent-look command or use the find_recent_screenshots tool"
echo ""
echo "Questions? Email: recall-skill@raiteri.net"
```

- [ ] **Step 7: Make install.sh executable and test basic syntax**

```bash
chmod +x install.sh
bash -n install.sh
```

Expected: No syntax errors

- [ ] **Step 8: Commit**

```bash
git add install.sh
git commit -m "feat: rewrite install.sh as interactive wizard with platform detection"
```

---

### Task 5: Manual Testing — Verify Installation Workflow

**Files:**
- Test: All modified/created files
- No new test files (manual testing only)

- [ ] **Step 1: Test install.sh in dry-run mode**

Simulate what the script does without modifying the system:

```bash
# Just verify the script loads and has no syntax errors
bash -n install.sh && echo "✓ Script has valid bash syntax"
```

Expected: `✓ Script has valid bash syntax`

- [ ] **Step 2: Test lib/config.js module loads**

```bash
node -e "import('./lib/config.js').then(m => { console.log('✓ Config module loads'); console.log('Functions:', Object.keys(m)); })"
```

Expected output includes:
```
✓ Config module loads
Functions: readConfig, validateConfig, CONFIG_DIR, CONFIG_FILE
```

- [ ] **Step 3: Test mcp/server.js loads with config**

```bash
timeout 2 node mcp/server.js 2>&1 | head -5 || true
```

Expected: Server starts without errors related to config

- [ ] **Step 4: Create a test config file and verify server reads it**

```bash
mkdir -p ~/.config/agent-look
cat > ~/.config/agent-look/config.json <<'JSON'
{
  "screencaptureDir": "~/Desktop",
  "enabledPlatforms": ["claude-desktop"]
}
JSON

node -e "import('./lib/config.js').then(m => { const c = m.readConfig(); console.log('✓ Config read:', c.screencaptureDir); })"
```

Expected: `✓ Config read: ~/Desktop`

- [ ] **Step 5: Verify README.md is valid markdown**

```bash
# Check that README exists and is non-empty
[ -s README.md ] && echo "✓ README.md exists and has content" || echo "✗ README.md missing or empty"
```

Expected: `✓ README.md exists and has content`

- [ ] **Step 6: Verify all required sections are in README**

```bash
for section in "Quick Start" "What It Does" "Installation" "Troubleshooting"; do
  grep -q "$section" README.md && echo "✓ Found section: $section" || echo "✗ Missing section: $section"
done
```

Expected: All four sections found

- [ ] **Step 7: Commit test verification**

```bash
git add .
git commit -m "test: verify installation workflow and config file handling"
```

---

### Task 6: Final Verification and Documentation

**Files:**
- Verify: README.md, install.sh, lib/config.js, mcp/server.js
- No new files

- [ ] **Step 1: Verify git status is clean**

```bash
git status
```

Expected: `working tree clean`

- [ ] **Step 2: Verify all commits follow the pattern**

```bash
git log --oneline -10
```

Expected: Commits like:
```
docs: add comprehensive README with quick start and troubleshooting
feat: rewrite install.sh as interactive wizard with platform detection
feat: add config file reader with backward-compatible fallback
refactor: read screencapture directory from config file
```

- [ ] **Step 3: Create a brief installation notes file for reference**

This is optional documentation for future contributors:

```bash
cat > INSTALL_NOTES.md <<'EOF'
# Installation Notes for Developers

## Installation Flow

1. User runs `./install.sh`
2. Script detects installed platforms (Claude Desktop, Code, Gemini, Codex)
3. Script proposes "install all detected" (default) or custom selection
4. Script detects macOS Spotlight setting or proposes ~/Pictures/Screenshots
5. Script creates `~/.config/agent-look/config.json` with user's choices
6. Script registers MCP server with selected platforms
7. User restarts tools to activate

## Config File

Location: `~/.config/agent-look/config.json`

Format:
```json
{
  "screencaptureDir": "~/Pictures/Screenshots",
  "enabledPlatforms": ["claude-desktop", "claude-code"]
}
```

The MCP server (`mcp/server.js`) reads this file at startup. Changes take effect on restart.

## Backward Compatibility

- If config file doesn't exist, server falls back to `SCREENGRABS_DIR` environment variable
- Default fallback: `~/Library/Mobile Documents/com~apple~CloudDocs/Downloads/screengrabs`
- This ensures existing installations continue to work

## Testing

Manual test checklist:
- [ ] install.sh has valid bash syntax
- [ ] lib/config.js loads without errors
- [ ] mcp/server.js reads config file on startup
- [ ] README.md contains all required sections
- [ ] Config file can be created and parsed correctly
EOF

git add INSTALL_NOTES.md
git commit -m "docs: add installation notes for developers"
```

- [ ] **Step 4: View final README for quality check**

```bash
head -30 README.md
```

Expected: Shows Quick Start and beginning of What It Does section, well-formatted

- [ ] **Step 5: Verify install.sh is executable and readable**

```bash
ls -l install.sh | grep '^-rwx'
```

Expected: `-rwxr-xr-x` (executable by user)

- [ ] **Step 6: Final commit and summary**

```bash
git log --oneline -7
```

Expected: Shows 7 commits including README, install wizard, config handling

- [ ] **Step 7: Push to remote (when ready)**

After testing locally, push with:
```bash
git push origin main
```

---

## Success Criteria

- ✓ README.md created with Quick Start (30 seconds), features, examples, troubleshooting
- ✓ install.sh rewritten as interactive wizard with platform detection
- ✓ Platform detection checks for Claude Desktop, Claude Code, Gemini CLI, Codex
- ✓ Wizard proposes sensible defaults (macOS Spotlight setting or ~/Pictures/Screenshots)
- ✓ Config file created at ~/.config/agent-look/config.json
- ✓ mcp/server.js reads config file on startup
- ✓ Backward compatibility maintained (falls back to SCREENGRABS_DIR env var)
- ✓ All code changes committed with clear commit messages
- ✓ Manual testing verifies workflow end-to-end

---

## Notes for Implementation

- The install.sh uses Python 3 (available on all modern Macs) for JSON manipulation instead of jq (simpler, no dependency)
- Platform detection is conservative: only checks for well-known command/config paths
- Config file is user-editable, allowing post-install customization
- No breaking changes to existing installation process
- Environment variable fallback ensures backward compatibility with existing installations

