import { readFileSync, existsSync } from "fs";
import { join } from "path";
import { homedir } from "os";

const CONFIG_DIR = join(homedir(), ".config", "agent-look");
const CONFIG_FILE = join(CONFIG_DIR, "config.json");

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
