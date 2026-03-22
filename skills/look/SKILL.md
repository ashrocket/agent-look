---
name: look
description: This skill should be used when the user says "/look", "look at my screenshots", "check my screengrabs", "any new screenshots?", "look at what I captured", "rename my screenshots", or wants to review recent screenshots from their macOS screengrabs folder. Also triggers when the user mentions renaming generic screenshot filenames or wants to scan for recent screen captures.
argument-hint: "[minutes] — optional recency window, default 3"
allowed-tools: ["Read", "Bash", "Glob", "Agent"]
---

# Look — Automatic Screenshot Scanner & Renamer

Scan the user's macOS screengrabs folder for recent screenshots, automatically examine any with generic names, and rename them with descriptive date-stamped names. No user interaction required — runs end-to-end automatically.

## Configuration

- **Screengrabs folder:** set via `SCREENGRABS_DIR` env var (configured by installer), defaults to `~/Library/Mobile Documents/com~apple~CloudDocs/Downloads/screengrabs`
- **Default recency window:** 3 minutes (captures screenshots the user just took)
- **Accepts argument:** optional minutes override (e.g., `/look 30` for last half hour)

## Workflow

### Step 1: Find Recent Screenshots

Use the MCP tool `find_recent_screenshots` with the minutes argument (default 3).

If the MCP tool is unavailable, fall back to this Python snippet — it handles the time filter and returns the same shape of data without spawning a shell that could mangle paths:

```python
import os, subprocess, time
minutes = 3  # or from argument
screengrabs = os.environ.get("SCREENGRABS_DIR", os.path.expanduser(
    "~/Library/Mobile Documents/com~apple~CloudDocs/Downloads/screengrabs"))
cutoff = time.time() - minutes * 60
raw = subprocess.run(
    ["mdfind", "-onlyin", screengrabs, "kMDItemIsScreenCapture = 1"],
    capture_output=True, text=True).stdout.strip()
files = []
for p in raw.split("\n"):
    if not p: continue
    try:
        st = os.stat(p)
        if st.st_mtime >= cutoff:
            files.append({"path": p, "name": os.path.basename(p),
                          "mtime": st.st_mtime, "size": st.st_size})
    except: pass
files.sort(key=lambda f: f["mtime"], reverse=True)
```

### Step 2: Filter to Generic Names Only

Separate the results into two lists:
- **Generic** — filename starts with "Screenshot", "Screen Shot", or "Simulator Screen" (case-insensitive). These need examining and renaming.
- **Already named** — everything else. These are already descriptive and need no action.

If no screenshots at all, report "No screenshots in the last N minutes" and stop.

If screenshots exist but none are generic, briefly list them (name + relative time) and note they're already renamed. Stop.

### Step 3: Check Count & Confirm if Needed

If there are **more than 4 generic-named screenshots**, pause and ask the user before proceeding:

```
Found 7 screenshots with generic names in the last 3 minutes. Want me to examine and rename all of them?
```

Wait for confirmation before continuing. If 4 or fewer, proceed automatically — no prompt needed.

### Step 4: Generate Slugs — OCR First, Examiner Fallback

The MCP tool returns an `ocr_text` field for generic-named files when Spotlight has OCR data. This is text macOS already extracted — reading it costs only text tokens, not vision tokens.

**For files WITH `ocr_text`:** Generate a descriptive slug directly from the OCR text. Look at the visible text to determine what app, page, or content the screenshot shows. No subagent needed — just pick a slug and proceed to rename.

**For files WITHOUT `ocr_text`** (pure graphics, charts with no text, or Spotlight hasn't indexed yet): Dispatch a **screenshot-examiner** subagent as a fallback:

```
Agent tool call:
  subagent_type: screenshot-examiner
  prompt: "Examine the screenshot at /full/path/to/image.png"
```

Launch all examiner agents concurrently. Do NOT read image files in the main context — always delegate to the subagent.

### Step 5: Rename Automatically

Rename each file immediately — do NOT ask for confirmation:

1. Use the MCP tool `rename_screenshot` with the file path and the slug (from OCR or examiner). The MCP server handles date-stamping (`YYYY-MM-DD_HHMM_slug.ext`), slug sanitization, and collision avoidance.
2. If the MCP tool is unavailable, use Python — **never `mv`**. macOS screenshot filenames contain U+202F (narrow no-break space) before AM/PM, which breaks all shell string matching. Use `python3 -c "import os; os.rename('src', 'dst')"` with the exact byte paths returned by `mdfind`.

### Step 6: Report Results

Present a compact summary:

```
Processed 3 screenshots (last 3 min):

  Screenshot 2026-03-18 at 2.15.32 PM.png → 2026-03-18_1415_ar-aging-summary-table.png
    AR aging report showing summary by payer with outstanding balances (from OCR)

  Screenshot 2026-03-18 at 2.03.11 PM.png → 2026-03-18_1403_claims-filter-panel.png
    Claims dashboard filter panel with date range selectors (from examiner)

  ar-aging-drilldown.png — already named, skipped

Want me to use any of these for the current task?
```

Note which slugs came from OCR vs examiner so the user knows what was cheap vs expensive.

**CRITICAL:** Do NOT read image files in the main context. Use OCR text or examiner descriptions only.

## Edge Cases

- If `mdfind` returns no results, check if the screengrabs folder path is correct with `defaults read com.apple.screencapture location`
- If a rename target already exists, the MCP server appends a numeric suffix (`-2`, `-3`) automatically
- For very large screenshots (over 10 MB), warn the user before dispatching the examiner
