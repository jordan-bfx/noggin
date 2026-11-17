---
name: cleanup
description: Delete every file noggin keeps for one item hash, or one round of it with <hash>-<k>. With no hash, do it for every hash in the project. Run as /noggin:cleanup [<hash>[-<k>]].
argument-hint: "[<hash>[-<k>]]"
disable-model-invocation: true
allowed-tools: Bash(*/scripts/cleanup.sh*)
---

# Cleanup

Clean `$ARGUMENTS` with `<noggin scripts>/cleanup.sh` from the project root (the scripts path is in your session context):
- `<hash>-<k>`, e.g. `3f9a1c2-2` or `3f9a1c2-final`: that round's folder, `research/<topic>/<hash>-<k>/`.
- `<hash>`: every `research/<topic>/<hash>-*/` folder, and the linked worktree on `noggin/<hash>` if one is kept.
- Nothing: the same for every hash found in `research/*/` and in `noggin/*` worktrees.

1. Run `<noggin scripts>/cleanup.sh -n $ARGUMENTS` and show its list. It deletes nothing.
2. Ask the user to confirm. Deleted results and uncommitted worktree changes can't be recovered.
3. On yes, run `<noggin scripts>/cleanup.sh $ARGUMENTS` and report what it removed.

It never touches `tasks.log`, `research.log`, `tasks.md`, `research.md`, `noggin/<hash>` branches or `research/data/`. Log entries for a deleted round stay, so dispatch still counts that round as done.
