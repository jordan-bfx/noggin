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
- `<hash>-<k>` in `research.log`: that round; `<hash>` alone: every round (for an iterated item, every iteration and `<hash>-final`). Per round: the log entries, `research/<topic>/<hash>-<k>/analysis_plan.md`, `analysis_plan.registered.md`, `deviations.md`, its outputs (and `validation/` if it was validated), and `shasum -a 256` of the plan against its `registered` entry in `research.log` (same hash, and registered before the result entries?).
- No log entry with that hash: stop and say so.

## 2. Review
Spawn three reviewers in parallel, one focus each. Each gets the item verbatim and the work, not the author's summary, and never sees the other reviews.

Task (engineers):
1. Correctness: bugs, edge cases, what breaks on real data.
2. Tests: do the tests behind `Skill(verify)` actually exercise this change, or would they pass without it?
3. Minimalism: is every line needed? Use `ponytail:ponytail-review` if it is loaded.

Research (scientists):
1. Pre-registration: the plan's sha256 matches its `registered` entry; the validation data and negative control were named in it, before any results; the run and validation followed it. Every departure from the plan has an entry in `deviations.md` with a reason, and none changes the hypothesis, data, test, decision rule or negative control; a departure seen in the outputs but missing from `deviations.md` is a finding. Read the diff of each `plan-edit-reverted` entry: if it is operative, the round fails pre-registration.
2. Statistics: right test for the data, assumptions checked, FDR where needed, every test reported, including nulls. Hypotheses tested across rounds on the same data count as multiple tests. The negative control is a real null (could it have caught a leak?), and the validation data is truly independent of the discovery data (no shared samples, donors or study). For prediction items: the primary metric fits the target and class balance, the baseline is a fair one, nothing was tuned on held-out data, and preprocessing stayed inside the training folds. For iterated items: the fixed inputs' sha256s match iteration 1's `registered` entry in every iteration, and only the final held-out test decided.
3. Reproducibility: recompute the key p/q values from the stored outputs, discovery and validation (write nothing to the repo); container digest and accessions match the method line; each verdict follows the decision rule, and `replicated` has the same direction of effect.

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
