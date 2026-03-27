# agent-look Install & Documentation Design

**Date:** 2026-03-27
**Scope:** README creation and install wizard redesign
**Status:** Approved

## Overview

agent-look is a screenshot scanner MCP server that finds recent screenshots via Spotlight, extracts OCR text, and renames generic filenames. Currently it has minimal documentation and a basic install script. This design improves both the README and installation experience with smart defaults, multi-platform detection, and user configuration management.

## 1. README (Balanced Approach)

### Purpose
Provide new users a fast path to getting started (30 seconds) while offering depth for users who want more information. Target audience: developers using Claude Desktop, Claude Code, Gemini CLI, or Codex on macOS.

### Structure

```
# agent-look

[One sentence description from package.json]

## Quick Start (30 seconds)
- Clone or download the repo
- Run `./install.sh`
- Answer 2 prompts:
  1. Which platforms to install to (or accept all detected)
  2. Screencapture directory (or accept default)
- Restart your tool and you're done

## What It Does

- Finds recent screenshots via Spotlight
- Extracts OCR text from them
- Renames generic filenames (Screenshot 2026-03-27 at...) to descriptive ones
- Works with: Claude Desktop, Claude Code, Gemini CLI, Codex

## Supported Platforms

- **Required:** macOS 10.15+ (Spotlight indexing)
- **Compatible with:** Claude Desktop, Claude Code, Gemini CLI, Codex

## Examples

[2-3 before/after examples showing screenshot rename transformations, e.g. "Screenshot 2026-03-27 at 10.25.15 AM.png" → "react-component-button-styling-example.png"]

## Installation (Detailed)

[Explanation of what the install script does, platform-specific setup notes, manual installation alternatives for users who want to set it up without the wizard]

## Configuration

Config file location: `~/.config/agent-look/config.json`

User can edit this file to change the screencapture directory or enabled platforms without re-running install. Format:
```json
{
  "screencaptureDir": "~/Pictures/Screenshots",
  "enabledPlatforms": ["claude-desktop", "claude-code"]
}
```

## Troubleshooting

- **Spotlight not finding screenshots:** Verify screencapture folder is indexed by Spotlight (System Preferences → Siri & Spotlight)
- **Wrong directory being scanned:** Edit `~/.config/agent-look/config.json` to change `screencaptureDir`
- **MCP server not connecting:** Restart Claude Desktop or Claude Code after install
- **Permission denied when running install.sh:** Ensure script is executable: `chmod +x install.sh`

## License & Author

MIT License
Author: Ashley Raiteri (recall-skill@raiteri.net)
```

### Key Design Decisions
- Quick start is 30 seconds: clone → run install.sh → 2 prompts → done
- Examples show actual filename transformations (most compelling feature)
- Configuration section explains how to edit settings later without re-running install
- Troubleshooting focuses on the most common issues

---

## 2. Install Wizard

### Purpose
Replace the simple install.sh with an interactive wizard that detects installed tools, asks user preferences with smart defaults, and creates a persistent config file for future adjustments.

### Flow

**Step 1: Detect Installed Tools**
- Check for Claude Desktop: `~/Library/Application Support/Claude/claude_desktop_config.json`
- Check for Claude Code: `which claude` or plugin command availability
- Check for Gemini CLI: `which gemini` or config file location
- Check for Codex: `which codex` or config location
- Display results with checkmarks

**Step 2: Show Detected Tools**
```
✓ Claude Desktop found
✓ Claude Code found
✗ Gemini CLI not found
✗ Codex not found
```

**Step 3: Propose Installation Choice**
```
Install agent-look to:
[1] All detected tools (RECOMMENDED)
[2] Select specific tools
[3] Cancel
Default: [1]

Choose (press Enter for default):
```
- User can press Enter to accept [1] (all detected)
- Or type number to choose different option
- If [2], show checkboxes for each detected tool

**Step 4: Propose Screencapture Directory**
- Query macOS setting: `defaults read com.apple.screencapture location`
- If found, propose that path
- If not found, propose `~/Pictures/Screenshots`
- Display:
```
Screencapture directory: ~/Pictures/Screenshots
Accept? [Y/n]
```
- User can press Enter to accept or type custom path
- Validate path exists before proceeding

**Step 5: Create Config File**
- Create `~/.config/agent-look/` directory if needed
- Write `config.json` with:
  ```json
  {
    "screencaptureDir": "[user choice]",
    "enabledPlatforms": ["[selected platforms]"]
  }
  ```

**Step 6: Install to Selected Platforms**
- For each selected platform, register MCP server:
  - **Claude Desktop:** Add entry to `claude_desktop_config.json` with MCP command and env vars pointing to config file
  - **Claude Code:** Use plugin registration system (if available) or manual plugin installation
  - **Gemini CLI:** Register MCP server configuration
  - **Codex:** Register MCP server configuration
- Print status for each installation

**Step 7: Summary**
```
✓ Installation complete!

Installed to:
  • Claude Desktop
  • Claude Code

Config file: ~/.config/agent-look/config.json
Edit this file to change settings without re-running install.

Next steps:
  • Restart Claude Desktop or Claude Code
  • Try: /look (Claude Code) or use the agent-look MCP directly
```

### Key Design Decisions
- Defaults are proposed based on quick system searches, minimizing user input
- Config file allows users to adjust settings (directory, platforms) without re-running install
- Multi-platform support detected automatically, reducing user errors
- Config location is standard (`~/.config/agent-look/`) following XDG conventions

---

## 3. Configuration File

### Purpose
Store user preferences (screencapture directory, enabled platforms) in a persistent, editable file that the MCP server reads at startup.

### Location
`~/.config/agent-look/config.json`

### Format
```json
{
  "screencaptureDir": "~/Pictures/Screenshots",
  "enabledPlatforms": ["claude-desktop", "claude-code"]
}
```

### Fields
- **screencaptureDir** (string): Absolute or home-relative path to the directory containing screenshots
- **enabledPlatforms** (array of strings): Platforms where the MCP server is registered (e.g., `["claude-desktop", "claude-code"]`)

### Future Expansion
- Design allows adding additional directories (change `screencaptureDir` to `screencaptureDirs` array) without breaking current setup
- Design allows adding more config options (e.g., OCR language, rename patterns) in future versions

### User Editing
- Users can edit the config file directly to change settings
- MCP server should read the config on each startup (or watch for changes)
- No need to re-run install after editing config

---

## Implementation Order

1. Create README.md with all sections
2. Rewrite install.sh as interactive wizard with tool detection
3. Create MCP config file handling (read/write `~/.config/agent-look/config.json`)
4. Update MCP server to read config file at startup
5. Test install workflow on clean system (all platforms, platform combinations)
6. Commit and push

---

## Success Criteria

- ✓ README provides 30-second quick start + comprehensive info
- ✓ Install wizard detects installed tools automatically
- ✓ Install wizard uses smart defaults (macOS Spotlight setting, "all detected")
- ✓ User can press Enter through most prompts using defaults
- ✓ Config file is created and editable by users
- ✓ MCP server reads config on startup
- ✓ No breaking changes to existing install process
