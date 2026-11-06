#!/usr/bin/env bash
# Run from a project root: re-runs noggin dispatch whenever tasks.md or research.md changes and has open "- [ ]" items.
# Extra args pass to claude, e.g. ./watch.sh --permission-mode acceptEdits
set -uo pipefail
sum() { cat tasks.md research.md 2>/dev/null | cksum; }
last=""
while true; do
  now=$(sum)
  if [ "$now" != "$last" ]; then
    last=$now
    # dispatch's own checkbox edits change the sum but leave no "[ ]", so they don't retrigger
    if grep -Eqs '^[[:space:]]*- \[ \]' tasks.md research.md; then
      echo "noggin: dispatching $(date '+%F %T')"
      claude -p "/noggin:dispatch" "$@" || echo "noggin: dispatch failed" >&2
    fi
  fi
  sleep "${NOGGIN_POLL:-5}"
done
