---
name: look
description: This skill should be used when the user says "/look", "look at my screenshots", "check my screengrabs", "any new screenshots?", "look at what I captured", "rename my screenshots", or wants to review recent screenshots from their macOS screengrabs folder. Also triggers when the user mentions renaming generic screenshot filenames or wants to scan for recent screen captures.
argument-hint: "[minutes] — optional recency window, default 30"
allowed-tools: ["Read", "Bash", "Glob", "Agent"]
---

# Look — Screenshot Scanner & Renamer

Scan the user's macOS screengrabs folder for recent screenshots, present them for review before loading (to save tokens), and rename generically-named files with descriptive, date-stamped names.

## Configuration

- **Screengrabs folder:** set via `SCREENGRABS_DIR` env var (configured by installer), defaults to `~/Library/Mobile Documents/com~apple~CloudDocs/Downloads/screengrabs`
- **Default recency window:** 30 minutes
- **Accepts argument:** optional minutes override (e.g., `/look 60` for last hour)

## Workflow

### Step 1: Find Recent Screenshots

Use `mdfind` with `kMDItemIsScreenCapture` — this bypasses macOS TCC restrictions and works with iCloud Drive paths where `find` would fail with "Operation not permitted":

```bash
mdfind 'kMDItemIsScreenCapture = 1' -attr kMDItemFSContentChangeDate 2>/dev/null
```

Filter to the configured screengrabs folder and sort by most recent. To apply the recency window, filter by `kMDItemFSContentChangeDate` in the results (parse the date and compare to cutoff).

### Step 2: Present File List

If no files found, report "No screenshots in the last N minutes" and stop.

If files found, present a numbered list showing:
- Filename
- Modification time (human-readable)
- Whether the name looks generic (starts with "Screenshot" or "Screen Shot" or "Simulator Screen")

Example output:
```
Found 3 screenshots in the last 30 minutes:

1. Screenshot 2026-03-18 at 2.15.32 PM.png (2 min ago) ← generic name
2. ar-aging-drilldown.png (12 min ago)
3. Screenshot 2026-03-18 at 2.03.11 PM.png (14 min ago) ← generic name

Which would you like me to examine? (numbers, "all", or "none")
```

**CRITICAL:** Do NOT read any image files yet. Wait for the user to choose.

### Step 3: Examine Selected Screenshots

For each selected screenshot, use the **Agent tool** to dispatch a `screenshot-examiner` subagent:

```
Agent tool call:
  subagent_type: screenshot-examiner
  prompt: "Examine the screenshot at /full/path/to/image.png"
```

The subagent reads the image and returns a 1-2 sentence description + a suggested filename slug. Present the subagent's findings to the user.

**CRITICAL:** Do NOT read image files directly in the main context — always delegate to the subagent. This is the core token-efficiency design. If an image is read in the main conversation, the token savings are lost.

### Step 4: Rename Generic Files

For files with generic names (starting with "Screenshot", "Screen Shot", or "Simulator Screen"):

1. Use the description from the examiner to generate a filename
2. Format: `YYYY-MM-DD_HHMM_descriptive-slug.ext`
   - Date-time from the file's modification time
   - Slug: lowercase, hyphens, max 40 chars, no special characters
3. Show the proposed rename and ask for confirmation
4. Rename with `mv` (preserve the original extension)

Example rename:
```
Screenshot 2026-03-18 at 2.15.32 PM.png → 2026-03-18_1415_ar-aging-summary-table.png
```

### Step 5: Offer Context

After examining, ask: "Want me to use any of these screenshots for the current task?"

**CRITICAL:** Do NOT re-read image files in the main context. Use only the text descriptions returned by the screenshot-examiner subagent. The images are already described — reference those descriptions to assist the user.

## Edge Cases

- If `mdfind` returns no results, check if the screengrabs folder path is correct with `defaults read com.apple.screencapture location`
- If a rename target already exists, append a numeric suffix (`-2`, `-3`)
- If the user says "all", examine all files but still confirm renames individually
- For very large screenshots, check `kMDItemFSSize` from mdfind before dispatching the examiner. If over 10,000,000 bytes, warn the user and ask before proceeding
