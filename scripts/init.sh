#!/usr/bin/env bash
# Sets up a project for noggin. Run from the project root. Creates only what is missing, never overwrites; safe to re-run.
set -euo pipefail

say() { printf '%-8s %s\n' "$1" "$2"; }
file() {  # file <path> <content>
  if [ -e "$1" ]; then say exists "$1"; else printf '%b' "$2" > "$1"; say created "$1"; fi
}

file tasks.md     '# Tasks\n\n'
file research.md  '# Research\n\n'
file tasks.log    ''
file research.log ''
file noggin.conf  'max_download_gb=100\nmax_run_hours=24\nmax_budget_usd=20\n'  # defaults in skills/check
if [ -d research/data ]; then say exists research/data/; else mkdir -p research/data; say created research/data/; fi

[ -e .gitignore ] || { : > .gitignore; say created .gitignore; }
# Without a final newline, an appended rule would merge into the last line and break both.
[ -s .gitignore ] && [ -n "$(tail -c1 .gitignore)" ] && echo >> .gitignore
for l in 'research/data/' 'research/*/*/tmp/'; do
  if grep -qxF "$l" .gitignore; then say exists ".gitignore: $l"; else echo "$l" >> .gitignore; say added ".gitignore: $l"; fi
done
