---
name: init
description: Set up a project for noggin: tasks.md, research.md, their logs, research/data/, noggin.conf and the .gitignore lines. Use for "/noggin:init", or when asked to set up noggin in a project.
disable-model-invocation: true
allowed-tools: Bash(*)
---

# Init

From the project root, run this once. It only creates what is missing and never overwrites an existing file, so it is safe to re-run.

```bash
[ -e tasks.md ]    || printf '# Tasks\n\n' > tasks.md
[ -e research.md ] || printf '# Research\n\n' > research.md
touch tasks.log research.log
mkdir -p research/data
[ -e noggin.conf ] || printf 'max_download_gb=100\nmax_run_hours=24\nmax_budget_usd=20\n' > noggin.conf
touch .gitignore
for l in 'research/data/' 'research/*/*/tmp/'; do grep -qxF "$l" .gitignore || echo "$l" >> .gitignore; done
```

Then report which files were created and which already existed, and tell the user to add `- [ ] ...` lines to `tasks.md` or `research.md`, then run `/noggin:dispatch` or `watch.sh`.
