#!/usr/bin/env node
/**
 * Register/unregister agent-look MCP server in AI tool configs.
 * Supports: Claude Desktop, Claude Code, Gemini CLI, Codex.
 */
import { readFileSync, writeFileSync, existsSync, mkdirSync } from "fs";
import { join, dirname } from "path";
import { homedir } from "os";
import { fileURLToPath } from "url";

const ROOT = dirname(dirname(fileURLToPath(import.meta.url)));
const HOME = homedir();
const UNREGISTER = process.env.AGENT_LOOK_UNREGISTER === "1";
const STATUS_ONLY = process.env.AGENT_LOOK_STATUS === "1";
const SERVER_PATH = join(ROOT, "mcp", "server.js");
const MCP_NAME = "agent-look";

// MCP entry that gets written into each platform's config
function mcpEntry() {
  return {
    command: "node",
    args: [SERVER_PATH],
  };
}

// -- Platform configs -------------------------------------------------------

const PLATFORMS = [
  {
    name: "Claude Desktop",
    path: join(HOME, "Library/Application Support/Claude/claude_desktop_config.json"),
    key: "mcpServers",
    read(raw) { return JSON.parse(raw); },
    write(obj) { return JSON.stringify(obj, null, 2); },
  },
  {
    name: "Claude Code (user settings)",
    path: join(HOME, ".claude/settings.json"),
    key: "mcpServers",
    read(raw) { return JSON.parse(raw); },
    write(obj) { return JSON.stringify(obj, null, 2); },
  },
  {
    name: "Gemini CLI",
    path: join(HOME, ".gemini/settings.json"),
    key: "mcpServers",
    read(raw) { return JSON.parse(raw); },
    write(obj) { return JSON.stringify(obj, null, 2); },
  },
  {
    name: "Codex",
    path: join(HOME, ".codex/config.json"),
    key: "mcpServers",
    read(raw) { return JSON.parse(raw); },
    write(obj) { return JSON.stringify(obj, null, 2); },
  },
];

// -- Helpers ----------------------------------------------------------------

function readConfig(platform) {
  if (!existsSync(platform.path)) return null;
  try {
    return platform.read(readFileSync(platform.path, "utf8"));
  } catch {
    return null;
  }
}

function isRegistered(config, key) {
  return config && config[key] && config[key][MCP_NAME];
}

// -- Status -----------------------------------------------------------------

if (STATUS_ONLY) {
  console.log("agent-look MCP registration status:\n");
  for (const p of PLATFORMS) {
    const config = readConfig(p);
    if (!config) {
      console.log(`  ${p.name}: config not found`);
    } else if (isRegistered(config, p.key)) {
      console.log(`  ${p.name}: ✓ registered`);
    } else {
      console.log(`  ${p.name}: not registered`);
    }
  }
  process.exit(0);
}

// -- Register / Unregister --------------------------------------------------

const action = UNREGISTER ? "Unregistering" : "Registering";
console.log(`${action} agent-look MCP server...\n`);
console.log(`  Server: ${SERVER_PATH}\n`);

let changed = 0;

for (const p of PLATFORMS) {
  let config = readConfig(p);

  if (UNREGISTER) {
    if (!config || !isRegistered(config, p.key)) {
      console.log(`  ${p.name}: skipped (not registered)`);
      continue;
    }
    delete config[p.key][MCP_NAME];
    writeFileSync(p.path, p.write(config));
    console.log(`  ${p.name}: ✓ removed`);
    changed++;
  } else {
    // Register
    if (isRegistered(config, p.key)) {
      console.log(`  ${p.name}: already registered`);
      continue;
    }
    if (!config) {
      // Create config file if parent dir exists or is a known location
      const dir = dirname(p.path);
      if (!existsSync(dir)) mkdirSync(dir, { recursive: true });
      config = {};
    }
    if (!config[p.key]) config[p.key] = {};
    config[p.key][MCP_NAME] = mcpEntry();
    writeFileSync(p.path, p.write(config));
    console.log(`  ${p.name}: ✓ registered`);
    changed++;
  }
}

console.log(`\n${changed === 0 ? "No changes needed." : "Done!"}`);
if (!UNREGISTER && changed > 0) {
  console.log("Restart any running AI tools to pick up the new MCP server.");
}
