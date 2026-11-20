#!/usr/bin/env bash
# noggin watcher. /noggin:init copies this into the project root; start it there yourself: ./watch.sh
# Every 30 minutes, if tasks.md or research.md has an open "- [ ]" item and no other pass holds dispatch.lock,
# it runs one headless dispatch pass. Extra args pass to claude, e.g. ./watch.sh --model sonnet
# Headless runs can't answer permission prompts: the allow= and deny= lines in noggin.conf are pre-approved
# or refused, anything else is denied (the agent marks the item [?]).
set -uo pipefail

[ -f noggin.conf ] || { echo "noggin: no noggin.conf here; run from a project root set up with /noggin:init" >&2; exit 1; }

conf() { sed -n "s/^$1=//p" noggin.conf 2>/dev/null; }
# A pass must never widen the next pass's permissions or limits: these denies hold whatever noggin.conf says.
guard=("Edit(noggin.conf)" "Write(noggin.conf)" "Edit(watch.sh)" "Write(watch.sh)"
  "Edit(research/datasets.md)" "Write(research/datasets.md)")

lock=dispatch.lock
held() {  # true while a live pass holds the lock
  [ -f "$lock" ] || return 1
  { read -r who _ < "$lock"; } 2>/dev/null || return 1
  if [ "$who" = interactive ]; then  # /noggin:dispatch in Claude Code; stale after max_run_hours
    hours=$(conf max_run_hours | tail -1)
    [ -z "$(find "$lock" -mmin +$(( ${hours:-24} * 60 )) 2>/dev/null)" ]
  else
    kill -0 "$who" 2>/dev/null  # another watcher's pass; stale once that process is gone
  fi
}
release() { { read -r who _ < "$lock"; } 2>/dev/null && [ "$who" = "$$" ] && rm -f "$lock"; return 0; }  # only our own lock
trap release EXIT
trap 'exit 130' INT TERM

while true; do
  if grep -Eqs '^[[:space:]]*- \[ \]' tasks.md research.md; then
    if held; then
      echo "noggin: another dispatch pass holds $lock, skipping $(date '+%F %T')"
    else
      rm -f "$lock"
      if (set -o noclobber; echo "$$ $(date '+%F %T')" > "$lock") 2>/dev/null; then
        allow=() deny=("${guard[@]}")
        while IFS= read -r r; do [ -n "$r" ] && allow+=("$r"); done < <(conf allow)
        while IFS= read -r r; do [ -n "$r" ] && deny+=("$r"); done < <(conf deny)
        if [ "${#allow[@]}" -eq 0 ]; then
          echo "noggin: no allow= lines in noggin.conf; re-run /noggin:init to add the defaults" >&2; exit 1
        fi
        budget=$(conf max_budget_usd | tail -1)  # set with /noggin:check
        before=$(cat tasks.md research.md 2>/dev/null | grep -Ec '^[[:space:]]*- \[\?\]')
        echo "noggin: dispatching $(date '+%F %T') (max \$${budget:-20})"
        claude -p "/noggin:dispatch watch" --permission-mode acceptEdits --max-budget-usd "${budget:-20}" \
          --allowedTools "${allow[@]}" --disallowedTools "${deny[@]}" "$@" \
          || echo "noggin: dispatch failed" >&2
        release
        # Notify only when the number of [?] items goes up; the count only, never the question text.
        q=$(cat tasks.md research.md 2>/dev/null | grep -Ec '^[[:space:]]*- \[\?\]')
        if [ "$q" -gt "$before" ]; then
          echo "noggin: $q question(s) waiting in tasks.md / research.md"
          command -v osascript >/dev/null &&
            osascript -e "display notification \"$q waiting in tasks.md / research.md\" with title \"noggin: questions\""
        fi
      fi
    fi
  fi
  sleep 1800 & wait $!  # a backgrounded sleep lets Ctrl-C or kill stop the watcher at once
done
