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
limits='max_download_gb=100\nmax_run_hours=24\nmax_budget_usd=20\n'  # defaults in skills/check
# What watch.sh's headless dispatch may run without asking (allow=) and must never run (deny=), one rule per line.
rules='
# watch.sh: tools a headless dispatch pass may use without asking. Anything not listed is denied.
allow=Edit
allow=Write
allow=Bash(nf-test *)
allow=Bash(nextflow *)
allow=Bash(graphify *)
allow=Bash(docker pull *)
# containers run offline: all downloads go through fetch.sh
allow=Bash(docker run --network none *)
allow=Bash(printf *)
allow=Bash(shasum *)
allow=Bash(md5 *)
allow=Bash(md5sum *)
allow=Bash(*/scripts/clean-tmp.sh *)
# any omics download: prefixes in research/datasets.md only, into research/data/ only
allow=Bash(*/scripts/fetch.sh *)
allow=Bash(prefetch *)
allow=Bash(fasterq-dump *)
allow=Bash(fastq-dump *)
allow=Bash(datasets *)
allow=Bash(git status *)
allow=Bash(git diff *)
allow=Bash(git log *)
allow=Bash(git rev-parse *)
allow=Bash(git branch *)
allow=Bash(git switch *)
allow=Bash(git add *)
allow=Bash(git commit *)
allow=Bash(git worktree *)
# watch.sh: never allowed. Edits to noggin.conf, watch.sh and research/datasets.md are always denied.
deny=Bash(git push *)
deny=Bash(git merge *)
deny=Bash(git rebase *)
deny=Bash(git reset *)
deny=Bash(rm -rf *)
deny=Bash(nf-test * --update-snapshot*)
# a second network flag would override --network none; each pattern needs text the allowed form never has
deny=Bash(docker run --network none *--net*)
deny=Bash(docker run *--network=*)
deny=Bash(docker run *--net=*)
'
file noggin.conf "$limits$rules"
# A noggin.conf from before watch.sh read its rules from here: add the defaults once.
if grep -Eq '^(allow|deny)=' noggin.conf; then say exists "noggin.conf: allow/deny rules"; else
  [ -n "$(tail -c1 noggin.conf)" ] && echo >> noggin.conf
  printf '%s' "$rules" >> noggin.conf; say added "noggin.conf: allow/deny rules"
fi
# The watcher; you start it yourself from the project root: ./watch.sh
if [ -e watch.sh ]; then say exists watch.sh; else cp "$(dirname "$0")/../templates/watch.sh" watch.sh; chmod +x watch.sh; say created watch.sh; fi
if [ -d research/data ]; then say exists research/data/; else mkdir -p research/data; say created research/data/; fi
# The plugin's curated sources; fetch.sh downloads only from the prefixes listed here. Edit it to add or remove sources.
if [ -e research/datasets.md ]; then say exists research/datasets.md; else cp "$(dirname "$0")/../templates/datasets.md" research/datasets.md; say created research/datasets.md; fi

[ -e .gitignore ] || { : > .gitignore; say created .gitignore; }
# Without a final newline, an appended rule would merge into the last line and break both.
[ -s .gitignore ] && [ -n "$(tail -c1 .gitignore)" ] && echo >> .gitignore
for l in 'research/data/' 'research/*/*/tmp/' 'dispatch.lock'; do
  if grep -qxF "$l" .gitignore; then say exists ".gitignore: $l"; else echo "$l" >> .gitignore; say added ".gitignore: $l"; fi
done

# Last, so everything above exists even if this step stops init: the deny= rules for every Claude session in the
# project, /noggin:dispatch by hand included, merged into .claude/settings.json without touching anything else in it.
# Written to .claude/settings.json.tmp and renamed over the original, so a crash never leaves it half-written.
deny=$(printf '%s' "$rules" | sed -n 's/^deny=//p')
fail() { say error ".claude/settings.json: $1, then re-run /noggin:init" >&2; exit 1; }
python3 -c '' 2>/dev/null || fail "needs python3 (on macOS: xcode-select --install, the same tools git needs)"
out=$(python3 - "$deny" 2>&1 <<'PY'
import json, os, sys
path, rules = '.claude/settings.json', sys.argv[1].splitlines()
existed = os.path.exists(path)
try:
    s = json.load(open(path, encoding='utf-8')) if existed else {}
except ValueError as e:
    sys.exit('error not valid JSON (%s), so Claude Code ignores it too; fix it' % e)
p = s.setdefault('permissions', {}) if isinstance(s, dict) else None
d = p.setdefault('deny', []) if isinstance(p, dict) else None
if not isinstance(d, list):
    sys.exit('error permissions.deny must be a list inside a permissions object; fix it')
new = [r for r in rules if r not in d]
if not new:
    print('exists deny rules'); sys.exit()
d.extend(new)
os.makedirs('.claude', exist_ok=True)
with open(path + '.tmp', 'w', encoding='utf-8') as f:
    json.dump(s, f, indent=2, ensure_ascii=False); f.write('\n')
os.replace(path + '.tmp', path)
print(('added' if existed else 'created'), '%d deny rules' % len(new))
PY
) || true
case "$out" in
  exists*|added*|created*) say "${out%% *}" ".claude/settings.json: ${out#* }" ;;
  error*) fail "${out#error }" ;;
  *) fail "python3 failed ($(printf '%s' "$out" | tail -1))" ;;
esac
