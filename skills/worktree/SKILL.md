---
name: worktree
description: Give one sub-agent that edits tracked files its own git worktree and branch, so parallel agents never share a checkout. Used by dispatch to start and finish agents, and by the agent inside its worktree.
---

# Worktree

Parallel agents in one checkout break each other's edits and each other's `Skill(verify)` runs. One agent, one worktree, one branch.

## Start (dispatch)
- Not a git repo (`git rev-parse` fails): no worktrees. Run these agents one at a time in the project root.
- Otherwise make sure `$(git rev-parse --git-common-dir)/info/exclude` lists `/tmp/` (shared by every worktree, never committed), so scratch files don't block `git worktree remove`.
- A retry continues where the last attempt stopped. Look for a worktree on the branch: `git worktree list --porcelain`, the `worktree` line before `branch refs/heads/noggin/<hash>`.
  - Found (kept from a failed attempt): spawn the agent without `isolation`, and put the worktree's absolute path in its brief. It works only there, uncommitted changes included. Git refuses to check the branch out anywhere else while that worktree exists.
  - Not found: spawn the agent with the Agent tool's `isolation: "worktree"`.
- Every brief has:
  - the branch name `noggin/<hash>`, using the item's hash from dispatch;
  - on a retry, the item's earlier log entries and its `Q:`/`A:` lines;
  - the project root's absolute path. Untracked inputs (`research/data/`, `tests/data/` if ignored, `graphify-out/`) exist only there: read them by absolute path, never write there.

## Inside (the agent)
1. Before the first edit, get on the branch:
   - Your brief names a kept worktree: start every Bash command with `cd <worktree path> &&`, and edit files only by their absolute path under it. You are already on `noggin/<hash>`; build on what is there.
   - The branch exists (`git rev-parse --verify --quiet noggin/<hash>` prints a hash): `git switch noggin/<hash>`, and build on its last commit.
   - Otherwise: `git switch -c noggin/<hash>`.
2. Do the work and run `Skill(verify)` here, in the worktree. Scratch files go in `tmp/` in the worktree, nowhere else.
3. `git add` only the files you changed, then `git commit -m "<item verbatim>"`.
4. Report the branch, the commit hash and the worktree path.

Never push, merge, rebase or touch the project root's checkout.

## Finish (dispatch)
1. Run `Skill(verify)` yourself with the worktree as the working directory.
2. Pass: `git worktree remove <path>`, keep the branch, and log `where: noggin/<hash>`.
3. Fail, or `remove` refuses because of untracked files: keep the worktree and the branch so the user can inspect them, and log both. Never `--force`.

The user merges branches. Dispatch never merges or pushes.
