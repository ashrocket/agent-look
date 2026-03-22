# I built a Claude plugin that looks at your screenshots so you don't have to drag them anywhere

There are probably a million reasons why I shouldn't have built this. If you know any, leave a comment below.

---

I use Claude a lot. Like, a lot a lot. And one of the tiny friction points that kept bugging me was screenshots. I'd take a screenshot, minimise whatever I was looking at, find the file — usually something like `Screenshot 2026-03-22 at 2.15.32 PM.png`, drag it into the Claude command line, then have to explain what I was even looking at.

Repeat for every screenshot. Every time.

So I built **agent-look** — a Claude Code plugin (and Claude Desktop MCP server) that watches your screenshots folder and lets you just say `/look` to pull up whatever you've captured recently. Claude examines them in a separate subagent (so your main context doesn't turn into a wall of image tokens), renames the generic ones based on what's actually in the image, and asks if you want to use any of them for the current task.

Default window is 3 minutes — the assumption is you just took these screenshots and want to use them right now.

---

It didn't go perfectly the first time.

The first test run, every rename failed. `mv` kept saying "No such file or directory" even though the files were sitting right there. Turns out macOS uses **U+202F** — a *narrow no-break space* — before AM/PM in screenshot filenames. It looks exactly like a regular space. It is not a regular space. Shell string matching disagrees with it violently.

The fix: the MCP server uses Node's `fs.renameSync()` with the exact byte paths returned by Spotlight, so it never touches a shell. Works perfectly. The fallback in the skill now explicitly warns never to use `mv` for this — use Python's `os.rename()` instead if the MCP is somehow unavailable.

That took me longer to figure out than the rest of it combined. I'm choosing to believe this counts as learning.

---

**Get it:** [github.com/ashrocket/agent-look](https://github.com/ashrocket/agent-look)

If something's broken, file an issue. I will probably get to it eventually.
