# I built a Claude plugin that looks at your screenshots so you don't have to drag them anywhere

There are probably a million reasons why I shouldn't have built this. If you know any, leave a comment below.

---

I use Claude a lot. Like, a lot a lot. And one of the tiny friction points that kept bugging me was screenshots. I'd take a screenshot, minimise whatever I was looking at, find the file — usually something like `Screenshot 2026-03-18 at 2.15.32 PM.png`, drag it into the Claude command line, then have to explain what I was even looking at.

Repeat for every screenshot. Every time.

So I built **agent-look** — a Claude Code plugin (and Claude Desktop MCP server) that watches your screenshots folder and lets you just say `/look` to pull up whatever you've captured recently. Claude shows you a list, you pick which ones matter, and it reads them in a separate subagent so your main context doesn't turn into a wall of image tokens.

It also renames generic screenshot filenames using the actual image content. So `Screenshot 2026-03-22 at 2.15.32 PM.png` becomes something like `2026-03-22_1415_login-error-state.png`. A small thing. Surprisingly satisfying.

It uses `mdfind` under the hood with `kMDItemIsScreenCapture` — which is the only reliable way to find screenshots in iCloud Drive paths without running into macOS TCC permission errors. That took me longer to figure out than the rest of it combined.

**Get it:** [github.com/ashrocket/agent-look](https://github.com/ashrocket/agent-look)

File an issue if you want it improved. I will probably get to it eventually.
