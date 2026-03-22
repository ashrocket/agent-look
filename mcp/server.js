#!/usr/bin/env node
import { Server } from "@modelcontextprotocol/sdk/server/index.js";
import { StdioServerTransport } from "@modelcontextprotocol/sdk/server/stdio.js";
import {
  CallToolRequestSchema,
  ListToolsRequestSchema,
} from "@modelcontextprotocol/sdk/types.js";
import { execSync } from "child_process";
import { existsSync, renameSync, statSync } from "fs";
import { join, extname, basename, dirname } from "path";
import { homedir } from "os";

const SCREENGRABS =
  process.env.SCREENGRABS_DIR ||
  join(
    homedir(),
    "Library/Mobile Documents/com~apple~CloudDocs/Downloads/screengrabs"
  );

const TOOLS = [
  {
    name: "find_recent_screenshots",
    description:
      "List screenshots from the screengrabs folder modified within the last N minutes. Returns filename, full path, modification time, and whether the name is generic.",
    inputSchema: {
      type: "object",
      properties: {
        minutes: {
          type: "number",
          description: "How far back to look (default: 30)",
          default: 30,
        },
      },
    },
  },
  {
    name: "rename_screenshot",
    description:
      "Rename a screenshot file. Formats the new name as YYYY-MM-DD_HHMM_slug.ext derived from the file's mtime. Returns the new path.",
    inputSchema: {
      type: "object",
      properties: {
        path: {
          type: "string",
          description: "Full path to the file to rename",
        },
        slug: {
          type: "string",
          description:
            "Descriptive slug (lowercase, hyphens, max 40 chars, no extension)",
        },
      },
      required: ["path", "slug"],
    },
  },
];

function humanRelative(mtime) {
  const diffMs = Date.now() - mtime;
  const mins = Math.round(diffMs / 60000);
  if (mins < 1) return "just now";
  if (mins === 1) return "1 min ago";
  if (mins < 60) return `${mins} min ago`;
  const hrs = Math.floor(mins / 60);
  return `${hrs}h ${mins % 60}m ago`;
}

function isGenericName(filename) {
  return /^(Screenshot|Screen Shot|Simulator Screen)/i.test(filename);
}

function findRecentScreenshots(minutes = 30) {
  const cutoff = Date.now() - minutes * 60 * 1000;

  let files;
  try {
    // kMDItemIsScreenCapture bypasses TCC — works on iCloud paths where find fails
    const raw = execSync(
      `mdfind 'kMDItemIsScreenCapture = 1'`,
      { encoding: "utf8" }
    );
    files = raw
      .trim()
      .split("\n")
      .filter(Boolean)
      .filter((filepath) => dirname(filepath) === SCREENGRABS)
      .map((filepath) => {
        const name = basename(filepath);
        const stat = statSync(filepath);
        const mtime = stat.mtimeMs;
        return { name, path: filepath, mtime, modified: humanRelative(mtime), size_bytes: stat.size, generic: isGenericName(name) };
      })
      .filter((f) => f.mtime >= cutoff)
      .sort((a, b) => b.mtime - a.mtime);
  } catch {
    files = [];
  }

  return { folder: SCREENGRABS, minutes, count: files.length, files };
}

function renameScreenshot(filePath, slug) {
  if (!existsSync(filePath)) {
    return { error: `File not found: ${filePath}` };
  }

  const stat = statSync(filePath);
  const mtime = new Date(stat.mtimeMs);
  const ymd = mtime.toISOString().slice(0, 10);
  const hhmm = mtime.toTimeString().slice(0, 5).replace(":", "");
  const ext = extname(filePath);
  const dir = dirname(filePath);

  const cleanSlug = slug
    .toLowerCase()
    .replace(/[^a-z0-9-]/g, "-")
    .replace(/-+/g, "-")
    .replace(/^-|-$/g, "")
    .slice(0, 40);

  let newName = `${ymd}_${hhmm}_${cleanSlug}${ext}`;
  let newPath = join(dir, newName);

  let suffix = 2;
  while (existsSync(newPath)) {
    newName = `${ymd}_${hhmm}_${cleanSlug}-${suffix}${ext}`;
    newPath = join(dir, newName);
    suffix++;
  }

  renameSync(filePath, newPath);
  return { old_path: filePath, new_path: newPath, new_name: newName };
}

const server = new Server(
  { name: "agent-look", version: "0.1.0" },
  { capabilities: { tools: {} } }
);

server.setRequestHandler(ListToolsRequestSchema, async () => ({ tools: TOOLS }));

server.setRequestHandler(CallToolRequestSchema, async (req) => {
  const { name, arguments: args } = req.params;

  if (name === "find_recent_screenshots") {
    const result = findRecentScreenshots(args?.minutes ?? 30);
    return { content: [{ type: "text", text: JSON.stringify(result, null, 2) }] };
  }

  if (name === "rename_screenshot") {
    if (!args?.path || !args?.slug) {
      return { content: [{ type: "text", text: JSON.stringify({ error: "path and slug are required" }) }] };
    }
    const result = renameScreenshot(args.path, args.slug);
    return { content: [{ type: "text", text: JSON.stringify(result, null, 2) }] };
  }

  return { content: [{ type: "text", text: JSON.stringify({ error: `Unknown tool: ${name}` }) }] };
});

const transport = new StdioServerTransport();
await server.connect(transport);
