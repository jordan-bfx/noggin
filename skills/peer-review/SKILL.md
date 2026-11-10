---
name: peer-review
description: Three independent reviewers check one noggin item: a task's branch, or a research topic's rounds. Run as /noggin:peer-review <hash> or <hash>-<k>.
argument-hint: <hash>[-<k>]
disable-model-invocation: true
---

# Peer review

Review `$ARGUMENTS`. Read only: reviewers never edit, commit, download, or reopen items.

## 1. Find the work
- A hash in `tasks.log`: the branch `noggin/<hash>`. Review `git diff main...noggin/<hash>` and its log entries. No branch: stop and say so.
- `<hash>-<k>` in `research.log`: that round; `<hash>` alone: every round. Per round: the log entry, `research/<topic>/<hash>-<k>/analysis_plan.md`, its outputs, and `shasum -a 256` of the plan against its `registered` entry in `research.log` (same hash, and registered before the result entry?).
- No log entry with that hash: stop and say so.

## 2. Review
Spawn three reviewers in parallel, one focus each. Each gets the item verbatim and the work, not the author's summary, and never sees the other reviews.

Task (engineers):
1. Correctness: bugs, edge cases, what breaks on real data.
2. Tests: do the tests behind `Skill(verify)` actually exercise this change, or would they pass without it?
3. Minimalism: is every line needed? Use `ponytail:ponytail-review` if it is loaded.

Research (scientists):
1. Pre-registration: the plan's sha256 matches its `registered` entry, the run followed it, and every deviation is noted with a reason.
2. Statistics: right test for the data, assumptions checked, FDR where needed, every test reported, including nulls. Hypotheses tested across rounds on the same data count as multiple tests.
3. Reproducibility: recompute the key p/q values from the stored outputs (write nothing to the repo); container digest and accessions match the method line; the verdict follows the decision rule.

Each finding: `major` or `minor`, a file:line or log line, and one sentence on why. No evidence, no finding.

## 3. Check and record
Check every major finding yourself against what it cites; drop any that don't hold. Then append to the item's log:

```
## <YYYY-MM-DD HH:MM> [<hash or hash-k>] peer review: <item>
- status: accept | minor revisions | major revisions
- reviewers: <the three focuses>
- findings: <one line each, with its evidence>
```

Report the verdict to the user, majors first.
