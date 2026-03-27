# agent-look

Screenshot scanner and renamer MCP server for macOS. Finds recent screenshots via Spotlight, extracts OCR text, and auto-renames generic filenames. Works with Claude Desktop, Claude Code, Gemini CLI, and Codex.

---

## Quick Start (30 seconds)

```
1. git clone https://github.com/ashrocket/agent-look.git
2. cd agent-look
3. ./install.sh
4. A folder picker opens — select your screenshots directory (or press Cancel for default)
5. Restart Claude Desktop
6. Done!
```

**For Claude Code:** install via the plugin system, then use `/look` or call `find_recent_screenshots` directly.

```
/plugin marketplace add /path/to/agent-look
/plugin install agent-look@agent-look-dev
```

---

## What It Does

- Finds recent screenshots in your macOS screengrabs folder using Spotlight (`mdfind`)
- Extracts OCR text from generic-named screenshots — reads text Spotlight already extracted, avoids loading images into the AI context
- Renames files from generic timestamp names to descriptive slugs
- Dispatches a lightweight subagent (Claude Haiku) to visually examine any screenshots that have no OCR text (pure graphics, charts)

### Before / After Examples

| Before | After |
|--------|-------|
| `Screenshot 2026-03-27 at 10.25.15 AM.png` | `2026-03-27_1025_react-component-button-styling.png` |
| `Screenshot 2026-03-27 at 2.14.00 PM.png` | `2026-03-27_1414_claims-nav-aba-charts.png` |
| `Screen Shot 2026-03-27 at 9.03.11 AM.png` | `2026-03-27_0903_grafana-cpu-spike.png` |

The output format is always `YYYY-MM-DD_HHMM_descriptive-slug.ext`, derived from the file's modification time.

---

## Supported Platforms

**Required:** macOS 10.15+ (Catalina or later) — uses Spotlight (`mdfind`) and macOS OCR (`mdls`). Linux and Windows are not supported.

**Compatible AI platforms:**

| Platform | How to install | How to use |
|---|---|---|
| Claude Desktop | `./install.sh` | MCP tools available automatically |
| Claude Code | `/plugin marketplace add` | `/look` command or `find_recent_screenshots` tool |
| Gemini CLI | Add MCP server to config | `find_recent_screenshots` tool |
| Codex | Add MCP server to config | `find_recent_screenshots` tool |

---

## Installation (Detailed)

### Automated — Claude Desktop

Run the installer:

```bash
chmod +x install.sh
./install.sh
```

The installer:
1. Opens a folder picker (AppleScript) — select your screenshots directory
2. Writes the MCP server entry into `~/Library/Application Support/Claude/claude_desktop_config.json`
3. Sets `SCREENGRABS_DIR` in the MCP server environment

After the installer finishes, restart Claude Desktop. The `find_recent_screenshots` and `rename_screenshot` tools will be available in all conversations.

### Manual — Claude Desktop

Edit `~/Library/Application Support/Claude/claude_desktop_config.json` and add:

```json
{
  "mcpServers": {
    "agent-look": {
      "command": "node",
      "args": ["/absolute/path/to/agent-look/mcp/server.js"],
      "env": {
        "SCREENGRABS_DIR": "/Users/yourname/Pictures/Screenshots"
      }
    }
  }
}
```

Restart Claude Desktop.

### Claude Code (Plugin System)

```bash
# Add this repo to the plugin marketplace
/plugin marketplace add /path/to/agent-look

# Install the plugin
/plugin install agent-look@agent-look-dev
```

After installing, the `/look` command and `find_recent_screenshots` MCP tool are available in Claude Code sessions.

### Other Platforms (Gemini CLI, Codex)

Add the MCP server to your platform's MCP configuration. The server is started with:

```bash
SCREENGRABS_DIR=/path/to/screenshots node /path/to/agent-look/mcp/server.js
```

Refer to your platform's documentation for where to add MCP server entries.

---

## Configuration

Config file: `~/.config/agent-look/config.json`

```json
{
  "screencaptureDir": "~/Pictures/Screenshots",
  "enabledPlatforms": ["claude-desktop", "claude-code"]
}
```

Edit this file to change your screencapture directory or enabled platforms without re-running the installer. Changes take effect on next tool restart.

**Fallback behavior:** If no config file exists, the server checks the `SCREENGRABS_DIR` environment variable, then defaults to `~/Library/Mobile Documents/com~apple~CloudDocs/Downloads/screengrabs`.

---

## MCP Tools

The server exposes two tools:

### `find_recent_screenshots`

Lists screenshots from the screengrabs folder modified within the last N minutes.

| Parameter | Type | Default | Description |
|---|---|---|---|
| `minutes` | number | 3 | How far back to look |

Returns: filename, full path, modification time, whether the name is generic, and Spotlight OCR text for generic-named files.

### `rename_screenshot`

Renames a screenshot file using a descriptive slug.

| Parameter | Type | Required | Description |
|---|---|---|---|
| `path` | string | yes | Full path to the file |
| `slug` | string | yes | Descriptive slug (lowercase, hyphens, max 40 chars, no extension) |

The server formats the output name as `YYYY-MM-DD_HHMM_slug.ext` using the file's modification time, sanitizes the slug, and handles collisions by appending `-2`, `-3`, etc.

---

## Troubleshooting

### Spotlight not finding screenshots

Check that Spotlight has indexed your screenshots folder:

```bash
mdfind -onlyin ~/Pictures/Screenshots 'kMDItemIsScreenCapture = 1'
```

If no results appear, wait a few seconds after taking a screenshot and try again. Spotlight indexing can lag by a few seconds on first use or after folder changes.

Also confirm that macOS saves screenshots to the expected location:

```bash
defaults read com.apple.screencapture location
```

### Wrong folder being scanned

Check what folder the server is using by running `/look` and seeing which folder appears in the report. To change it, update `SCREENGRABS_DIR` in your MCP config or environment (see Configuration above).

### Permission denied on install.sh

Make the script executable:

```bash
chmod +x install.sh
./install.sh
```

### MCP server not connecting after install

1. Confirm the config file was written correctly:
   ```bash
   cat ~/Library/Application\ Support/Claude/claude_desktop_config.json
   ```
2. Verify `node` is available at the path the config uses:
   ```bash
   which node
   node --version  # must be 18+
   ```
3. Restart Claude Desktop completely (quit and reopen, not just close the window).

### agent-look not recognized in Claude Code

If `/look` gives a "command not found" error:

1. Confirm the plugin was installed:
   ```
   /plugin list
   ```
2. If not listed, re-run the install commands:
   ```
   /plugin marketplace add /path/to/agent-look
   /plugin install agent-look@agent-look-dev
   ```
3. Start a new Claude Code session after installing.

---

## License & Author

MIT License

**Author:** Ashley Raiteri — [recall-skill@raiteri.net](mailto:recall-skill@raiteri.net)

**Repository:** [https://github.com/ashrocket/agent-look](https://github.com/ashrocket/agent-look)
