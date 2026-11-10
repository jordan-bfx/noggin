#!/usr/bin/env bash
# SessionStart: noggin's house rules, plus the project's graphify summary (the full graph stays queryable, not loaded).
cat "$CLAUDE_PLUGIN_ROOT/CLAUDE.md"
printf '\nnoggin scripts: %s/scripts\n' "$CLAUDE_PLUGIN_ROOT"
report="${CLAUDE_PROJECT_DIR:-.}/graphify-out/GRAPH_REPORT.md"
if [ -f "$report" ]; then
  printf '\n## Knowledge graph (graphify-out/GRAPH_REPORT.md)\n'
  head -c 20000 "$report"  # shortcut: caps context at ~5k tokens, raise if reports get cut off
  printf '\n\nFor details beyond this summary, run `graphify query "<question>"` (also `graphify path`, `graphify explain`). EXTRACTED edges are stated in sources; INFERRED edges are graphify guesses, so treat them as hypotheses.\n'
else
  printf '\nNo knowledge graph in this project. Build one with `/graphify .` (install: `uv tool install "graphifyy[pdf]" && graphify install`).\n'
fi
