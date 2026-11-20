---
name: init
description: Set up a project for noggin: tasks.md, research.md, their logs, research/data/, noggin.conf (limits and watch.sh's permission rules), watch.sh and the .gitignore lines. Use for "/noggin:init", or when asked to set up noggin in a project.
disable-model-invocation: true
allowed-tools: Bash(*/scripts/init.sh)
---

# Init

From the project root, run `<noggin scripts>/init.sh` (the scripts path is in your session context). It creates only what is missing and never overwrites an existing file, so it is safe to re-run. It prints one line per file: `created`, `added` or `exists`.

Then show the user that output, and tell the user to add `- [ ] ...` lines to `tasks.md` or `research.md`, then run `/noggin:dispatch` for one pass, or start `./watch.sh` from the project root themselves to dispatch every 30 minutes while items are open. Never start `watch.sh` yourself.
