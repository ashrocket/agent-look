# I built an MCP server that looks at your screenshots so you don't have to drag them anywhere

There are probably a million reasons why I shouldn't have built this. If you know any, leave a comment below.

---

I use Claude a lot. Like, a lot a lot. And one of the tiny friction points that kept bugging me was screenshots. I'd take a screenshot, minimise whatever I was looking at, find the file — usually something like `Screenshot 2026-03-22 at 2.15.32 PM.png`, drag it into the Claude command line, then have to explain what I was even looking at.

Repeat for every screenshot. Every time.

So I built **agent-look** — an MCP server that watches your screenshots folder and lets you just say `/look` to pull up whatever you've captured recently. It auto-renames the generic ones based on what's in the image and asks if you want to use any of them for the current task. No prompts, no file picking — it just does it.

Default window is 3 minutes — the assumption is you just took these screenshots and want to use them right now.

---

The fun part: it barely uses any tokens.

The first version dispatched a vision subagent for every screenshot — about 13,000 tokens each. Five screenshots and you'd burned 65k tokens just to categorise some PNGs.

Turns out macOS already OCRs your screen captures via Spotlight. The text is sitting right there in `kMDItemTextContent`. So now the MCP server pulls the OCR text from Spotlight metadata and returns it alongside the file list. Claude reads the text (cheap text tokens), generates a slug, renames the file. Vision subagent only fires when OCR is empty — pure graphics, charts with no text, that sort of thing. And even then, it resizes to an 800px thumbnail first via `sips` to cut the vision token cost by ~10x.

Most screenshots have text on them. The examiner rarely fires.

---

It didn't go perfectly the first time.

The first test run, every rename failed. `mv` kept saying "No such file or directory" even though the files were sitting right there. Turns out macOS uses **U+202F** — a *narrow no-break space* — before AM/PM in screenshot filenames. It looks exactly like a regular space. It is not a regular space. Shell string matching disagrees with it violently.

The fix: the MCP server uses Node's `fs.renameSync()` with the exact byte paths returned by Spotlight, so it never touches a shell. Works perfectly.

That took me longer to figure out than the rest of it combined. I'm choosing to believe this counts as learning.

---

It works with everything now. `brew install` and one register command:

```
brew tap ashrocket/agent-look
brew install agent-look
agent-look register
```

That last command detects Claude Code, Claude Desktop, Gemini CLI, and Codex and wires up the MCP server in each one. `agent-look unregister` to remove it. You can also install it as a Claude Code plugin for the `/look` skill and examiner agent, or just `git clone` and run `install.sh` if you prefer.

---

**Get it:** [github.com/ashrocket/agent-look](https://github.com/ashrocket/agent-look)

If something's broken, file an issue. I will probably get to it eventually.

---

**One more thing.** If you want the AI to take *its own* screenshots instead of looking at yours, check out Jesse Vincent's [superpowers-chrome](https://github.com/obra/superpowers-chrome). It gives Claude direct browser control via Chrome DevTools Protocol — you can say "look at my local dev server and find the mistake" and it navigates there, takes a screenshot, inspects the DOM, and tells you what's wrong. No manual screenshotting needed. agent-look and superpowers-chrome solve different sides of the same problem: agent-look is for when *you* capture something and want Claude to see it; superpowers-chrome is for when you want Claude to go look at something itself.
