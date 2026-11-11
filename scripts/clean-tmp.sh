#!/usr/bin/env bash
# Deletes the tmp/ folders of one item once it is done ([x]). Run from the project root.
# Takes the item hash, not a path, so it can only touch:
#   research/*/<hash>-<k>/tmp            every round of a research item, and <hash>-final
#   <worktree>/tmp                       a linked worktree on branch noggin/<hash> (a task's kept worktree)
set -euo pipefail
[ $# -eq 1 ] && [[ $1 =~ ^[0-9a-f]{7}$ ]] || { echo "usage: clean-tmp.sh <7-character item hash>" >&2; exit 2; }

dirs=()
for d in research/*/"$1"-*; do [ -d "$d" ] && dirs+=("$d"); done
# Porcelain lists "worktree <path>" then "branch refs/heads/<name>"; the main checkout is never on noggin/<hash>.
while read -r wt; do dirs+=("$wt"); done < <(git worktree list --porcelain 2>/dev/null |
  awk -v b="branch refs/heads/noggin/$1" '/^worktree /{p=substr($0,10)} $0==b{print p}')

n=0
for d in ${dirs[@]+"${dirs[@]}"}; do
  [ -e "$d/tmp" ] || [ -L "$d/tmp" ] || continue
  rm -rf "$d/tmp"  # a symlinked tmp loses only the link
  echo "clean-tmp: removed $d/tmp"
  n=$((n + 1))
done
[ "$n" -gt 0 ] || echo "clean-tmp: no tmp/ folders for $1"
