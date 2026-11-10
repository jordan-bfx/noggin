---
name: worktree
description: Give one sub-agent that edits tracked files its own git worktree and branch, so parallel agents never share a checkout. Used by dispatch to start and finish agents, and by the agent inside its worktree.
---

# Worktree

Parallel agents in one checkout break each other's edits and each other's `Skill(verify)` runs. One agent, one worktree, one branch.

## Start (dispatch)
- Not a git repo (`git rev-parse` fails): no worktrees. Run these agents one at a time in the project root.
- Otherwise spawn the agent with the Agent tool's `isolation: "worktree"`, and put in its brief:
  - the branch name `noggin/<hash>`, using the item's hash from dispatch;
  - the project root's absolute path. Untracked inputs (`data/`, `tests/data/` if ignored, `graphify-out/`) exist only there: read them by absolute path, never write there.

## Inside (the agent)
1. `git switch -c noggin/<hash>` before the first edit.
2. Do the work and run `Skill(verify)` here, in the worktree.
3. `git add` only the files you changed, then `git commit -m "<item verbatim>"`.
4. Report the branch, the commit hash and the worktree path.

Never push, merge, rebase or touch the project root's checkout.

## Finish (dispatch)
1. Run `Skill(verify)` yourself with the worktree as the working directory.
2. Pass: `git worktree remove <path>`, keep the branch, and log `where: noggin/<hash>`.
3. Fail: keep the worktree and the branch so the user can inspect them, and log both.

The user merges branches. Dispatch never merges or pushes.
