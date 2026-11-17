#!/usr/bin/env bash
# Deletes every file noggin keeps for an item. Run from the project root.
#   cleanup.sh [-n] <hash>-<k>   one round: research/*/<hash>-<k>/ (k is a number or "final")
#   cleanup.sh [-n] <hash>       every round of it, and a linked worktree on noggin/<hash>
#   cleanup.sh [-n]              the same for every hash found
# -n lists what would go and deletes nothing. Logs, branches and research/data/ stay.
set -euo pipefail
dry=0; [ "${1-}" = -n ] && { dry=1; shift; }
[ $# -le 1 ] && [[ ${1-} =~ ^(([0-9a-f]{7})(-([0-9]+|final))?)?$ ]] ||
  { echo "usage: cleanup.sh [-n] [<7-character hash>[-<k>]]" >&2; exit 2; }
hash=${BASH_REMATCH[2]}; round=${BASH_REMATCH[4]}
hre=$hash; [ -n "$hre" ] || hre="[0-9a-f]{7}"

targets=()
for d in research/*/*/; do
  d=${d%/}
  [[ ${d##*/} =~ ^$hre-(${round:-[0-9]+|final})$ ]] && targets+=("$d")
done

worktrees=()
if [ -z "$round" ]; then
  # Porcelain lists "worktree <path>" then "branch refs/heads/<name>"; entry 1 is the main checkout, never touched.
  while IFS=$'\t' read -r b p; do
    [[ $b =~ ^$hre$ ]] && worktrees+=("$p")
  done < <(git worktree list --porcelain 2>/dev/null |
    awk '/^worktree /{n++; p=substr($0,10)} n>1 && /^branch refs\/heads\/noggin\//{print substr($0,26) "\t" p}')
fi

if [ ${#targets[@]} -eq 0 ] && [ ${#worktrees[@]} -eq 0 ]; then
  echo "cleanup: nothing for ${1:-any hash}"; exit 0
fi
for d in ${targets[@]+"${targets[@]}"}; do
  [ "$dry" = 1 ] && echo "would remove $d/" || { rm -rf "$d"; echo "cleanup: removed $d/"; }
done
for w in ${worktrees[@]+"${worktrees[@]}"}; do
  [ "$dry" = 1 ] && echo "would remove worktree $w" || { git worktree remove --force "$w"; echo "cleanup: removed worktree $w"; }
done
