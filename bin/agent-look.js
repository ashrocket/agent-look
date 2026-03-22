#!/usr/bin/env node
import { execSync } from "child_process";
import { fileURLToPath } from "url";
import { dirname, join } from "path";

const ROOT = dirname(dirname(fileURLToPath(import.meta.url)));
const args = process.argv.slice(2);
const cmd = args[0];

function usage() {
  console.log(`agent-look — screenshot scanner & renamer MCP server

Usage:
  agent-look serve          Start the MCP server (stdio transport)
  agent-look register       Register MCP in detected AI tool configs
  agent-look unregister     Remove MCP from AI tool configs
  agent-look status         Show registration status
  agent-look --version      Show version
  agent-look --help         Show this help

The MCP server provides two tools:
  find_recent_screenshots   List recent screenshots with OCR text
  rename_screenshot         Rename a screenshot with a descriptive slug`);
}

if (cmd === "--version" || cmd === "-v") {
  const pkg = JSON.parse(
    (await import("fs")).readFileSync(join(ROOT, "package.json"), "utf8")
  );
  console.log(pkg.version);
} else if (cmd === "serve") {
  await import(join(ROOT, "mcp", "server.js"));
} else if (cmd === "register") {
  await import(join(ROOT, "bin", "register.js"));
} else if (cmd === "unregister") {
  process.env.AGENT_LOOK_UNREGISTER = "1";
  await import(join(ROOT, "bin", "register.js"));
} else if (cmd === "status") {
  process.env.AGENT_LOOK_STATUS = "1";
  await import(join(ROOT, "bin", "register.js"));
} else if (cmd === "--help" || cmd === "-h" || !cmd) {
  usage();
} else {
  console.error(`Unknown command: ${cmd}\nRun 'agent-look --help' for usage.`);
  process.exit(1);
}
