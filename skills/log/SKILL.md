---
name: log
description: Show every tasks.log and research.log entry as one table, oldest first, with its hash, like `nextflow log`. With a hash, show that item's full entries. Use for "/noggin:log", or when asked what noggin has done.
disable-model-invocation: true
allowed-tools: Bash(awk *) Bash(ls *)
---

# Log

!`awk 'function out() { if (id) printf "%-16s  %-11s  %-8s  %-15s  %s\n", ts, id, kind, st, item; id = "" } FNR == 1 { out(); kind = FILENAME; sub(/\.log$/, "", kind) } /^## / { out(); ts = $2 " " $3; id = $4; gsub(/[][]/, "", id); item = $0; sub(/^## [^]]*\] /, "", item); st = "-" } /^- status:/ { st = $0; sub(/^- status: */, "", st) } END { out() }' $(ls tasks.log research.log 2>/dev/null) </dev/null | sort`

- No arguments: print the lines above, verbatim, in a code block under the header `TIMESTAMP  HASH  LOG  STATUS  ITEM` (aligned to the columns). If there are none, say there are no logs yet.
- `/noggin:log <hash>`, e.g. `3f9a1c2` or `3f9a1c2-2`: print every full entry in `tasks.log` and `research.log` whose header hash starts with it, oldest first.

Read only. Never edit the logs.
