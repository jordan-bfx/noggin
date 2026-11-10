#!/usr/bin/env bash
# Run from a project root: re-runs noggin dispatch whenever tasks.md or research.md changes and has open "- [ ]" items.
# Extra args pass to claude, e.g. ./watch.sh --model sonnet
# Headless runs can't answer permission prompts: commands below are pre-approved, anything else is denied
# (the agent marks the item [?]). Allow more in the project's .claude/settings.json.
set -uo pipefail

allow=(Edit Write
  "Bash(nf-test *)" "Bash(nextflow *)" "Bash(graphify *)"
  "Bash(docker pull *)" "Bash(docker run *)"
  "Bash(printf *)" "Bash(shasum *)" "Bash(md5 *)" "Bash(md5sum *)" "Bash(*/scripts/clean-tmp.sh *)"
  "Bash(*/scripts/fetch.sh *)"  # any omics download: prefixes in research/datasets.md only, into research/data/ only
  "Bash(prefetch *)" "Bash(fasterq-dump *)" "Bash(fastq-dump *)" "Bash(datasets *)"
  "Bash(git status *)" "Bash(git diff *)" "Bash(git log *)" "Bash(git rev-parse *)" "Bash(git branch *)"
  "Bash(git switch *)" "Bash(git add *)" "Bash(git commit *)" "Bash(git worktree *)")
deny=("Bash(git push *)" "Bash(git merge *)" "Bash(git rebase *)" "Bash(git reset *)"
  "Bash(rm -rf *)" "Bash(nf-test * --update-snapshot*)"
  # Agents never change what they may download or how much.
  "Edit(research/datasets.md)" "Write(research/datasets.md)" "Edit(noggin.conf)" "Write(noggin.conf)")

max=${NOGGIN_MAX_RUNS:-20}  # dispatches per day; stops a runaway loop from spending all day
sum() { cat tasks.md research.md 2>/dev/null | cksum; }
last="" day="" runs=0 lastq=0
while true; do
  now=$(sum)
  if [ "$now" != "$last" ]; then
    last=$now
    # Re-dispatches while edits leave open items: multi-round research advances, and items over the 10-agent cap get their turn.
    if grep -Eqs '^[[:space:]]*- \[ \]' tasks.md research.md; then
      [ "$(date +%F)" != "$day" ] && day=$(date +%F) runs=0
      if [ "$runs" -ge "$max" ]; then
        echo "noggin: $max dispatches today, stopping. Check tasks.log/research.log, then restart (NOGGIN_MAX_RUNS to change)." >&2
        exit 1
      fi
      runs=$((runs + 1))
      budget=$(sed -n 's/^max_budget_usd=//p' noggin.conf 2>/dev/null | tail -1)  # set with /noggin:check
      echo "noggin: dispatching $(date '+%F %T') ($runs/$max today, max \$${budget:-20})"
      claude -p "/noggin:dispatch" --permission-mode acceptEdits --max-budget-usd "${budget:-20}" \
        --allowedTools "${allow[@]}" --disallowedTools "${deny[@]}" "$@" \
        || echo "noggin: dispatch failed" >&2
      # Notify only when the number of [?] items goes up; the count only, never the question text.
      q=$(cat tasks.md research.md 2>/dev/null | grep -Ec '^[[:space:]]*- \[\?\]')
      if [ "$q" -gt "$lastq" ]; then
        echo "noggin: $q question(s) waiting in tasks.md / research.md"
        command -v osascript >/dev/null &&
          osascript -e "display notification \"$q waiting in tasks.md / research.md\" with title \"noggin: questions\""
      fi
      lastq=$q
    fi
  fi
  sleep "${NOGGIN_POLL:-5}"
done
