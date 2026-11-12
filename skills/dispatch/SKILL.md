---
name: dispatch
description: Dispatch engineer and scientist sub-agents for the open items in the project's tasks.md and research.md, then log results to tasks.log and research.log. Use when asked to "dispatch", when tasks.md or research.md changes, or from watch.sh.
---

# Dispatch

One pass, then stop.

## 1. Read
- `tasks.md` and `research.md` in the project root. An open item is a line `- [ ] ...`. Ignore `- [x]` (done) and `- [?]` (waiting on the user).
- `tasks.log` and `research.log`, so you don't repeat work.
- Compute every open item's hash before anything else and say it in your report, with the round you are starting and where that number came from. An item's state is only what is filed under its own hash: `[<hash>-...]` entries in the logs and `research/<topic>/<hash>-*` folders. Entries, folders and counts belonging to any other hash are a different item that happens to share a topic name, so a hash with nothing filed under it starts at round 1 — whatever sits beside it in that topic folder, and whatever the item line's count says.
- If `graphify-out/` exists, give each agent a scoped `graphify query "<question>"` result, not the whole graph.
- If `research.md` has open items, make sure `.gitignore` lists `research/data/` and `research/*/*/tmp/`; add the lines if missing. Downloads and intermediates never go in git.
- Limits from `Skill(check)` (`noggin.conf`, or its defaults). Put them in every scientist's brief, with the noggin scripts path from your session context (for `fetch.sh`).

## 2. Dispatch
Spawn sub-agents for the open items, using the Agent tool, at most 10 items per pass, in file order. Leave the rest `- [ ]` for the next pass.
- `tasks.md` item: an **engineer** for code or pipelines, a **scientist** for analysis.
- `research.md` item: **scientists**, round by round. A round tests exactly one hypothesis. The line sets the number of rounds, e.g. `- [ ] topic (hypotheses: 3)`; with no count it gets 1. Run every round of the item in this pass, one after another, until the count is met: the item counts as one of the 10, however many rounds it takes. Give each round's scientist the earlier `research.log` entries under this item's own hash, so the round builds on the last and doesn't repeat it. Entries under other hashes are a different item, even where the topic name matches: never count them as this item's rounds or pass them on as its history. A prediction item tagged `(iterations: N)` runs iterations in place of rounds, as `<hash>-<k>` (`Skill(experiment)`, Iterated prediction items).

A research round runs in up to three phases, each its own scientist (`Skill(experiment)`), all in the same pass:
1. **Plan:** the scientist writes `analysis_plan.md` (with discovery data, held-out validation data and a negative control), checks the limits, and stops. Nothing is downloaded or analyzed.
2. **Register:** you run `shasum -a 256 <plan>` and append a `registered` entry to `research.log` (template below) before spawning anything else for that round. Note which of the plan's validation paths already exist in `research/data/`.
3. **Run:** a fresh scientist gets only the plan's path and its sha256, the limits and the round hash, and executes the plan on the discovery data. The validation data is held out from it.
4. **Validate:** only if the run is `supported` and the plan names validation data. A third, fresh scientist gets the plan's path and sha256, the limits and the round hash, and nothing about the discovery results. It runs the same plan on the validation data: `replicated` or `not replicated`. With `validation: none`, the round ends `supported (unreplicated)`.
   An iterated item has no validate phase per iteration. Keep going until N is reached, five iterations in a row don't beat the best outer-fold score, or a planner reports `converged`; then a fresh scientist runs the final validate phase as `<hash>-final`, on the chosen iteration's plan and saved model.

Log each round or iteration as it finishes, before starting the next, so an interrupted pass resumes where it stopped. A round or iteration that is blocked, over a limit, or asks the user stops the item there: log it, leave the item `- [?]`, and run no more rounds for it (and no final phase). The other items in the pass carry on.

If the plan phase ends untestable, blocked or over a limit, there is no run phase, but the item's next round still runs. A round resumes at the first phase without a log entry: after `registered`, at the run; after a `supported` run with validation data, at validation.

Every item has a hash: the first 7 characters of `printf '%s' "<text>" | shasum -a 1`, where `<text>` is the line after `- [ ] ` with its trailing `(...)` tags removed and then any leading or trailing whitespace trimmed, so the same item always hashes the same way. It stays the same across rounds and checkbox changes, and changed text means a different item, never a line to correct. A research round is `<hash>-<k>`, e.g. `3f9a1c2-2`. Put the hash in the brief.

Each brief states the item verbatim, its inputs, what done looks like, and what it must not touch. If the item has `Q:`/`A:` lines under it, include them: they are the user's answers from an earlier pass.

Engineer briefs also say: if ponytail is loaded, work at its ultra level. Before building, push back on any part of the item the need doesn't justify, and report the pushback as a question.

Agents run in parallel:
- Every engineer, who can edit tracked files, gets its own worktree and branch via `Skill(worktree)`.
- Scientists download data for bioinformatic analysis to `research/data/` and follow analysis plans published in `research/<topic>/<hash>-<k>/analysis_plan.md`. Scientists write only inside their own `research/<topic>/<hash>-<k>/`.

IMPORTANT: If a scientist reports no testable data, the round still counts: log it with `status: untestable`, advance the count, and the next pass runs the next round.

## 3. Verify
A sub-agent saying it is done is a claim, not proof. Before accepting a result:
- If engineer was dispatched: `Skill(verify)` must pass in its worktree. Then finish the worktree as `Skill(worktree)` says.
- If scientist was dispatched: the reported numbers must trace to a file or a DOI you can open, and `shasum -a 256` of the plan must still match its `registered` entry. A mismatch makes the round blocked, with the question "plan changed after registration".
- Iterated items: at iteration 1's registration, record the sha256 of its fixed inputs (`discovery_ids.tsv`, `folds.tsv`, `permuted_labels.tsv`, and `heldout_ids.tsv` if any). Every later plan must name the same files; check their hashes at every registration, run and the final validate phase. A mismatch blocks the item with "fixed inputs changed".
- After a run: the negative control must be reported and null, or the round is blocked with "negative control failed". Validation paths that didn't exist at registration but exist now mean the run touched held-out data: the round is blocked with "validation data opened during the run", and no validate phase follows.
- Both must provide records following the template below.

## 4. Record
Append one entry per item, then update the item's checkbox in place:

`tasks.log`
```
## <YYYY-MM-DD HH:MM> [<hash>] <item>
- status: done | blocked
- proof: <check run and its result>
- where: <files or branch>
```

`research.log`, after the plan phase (doesn't advance the count):
```
## <YYYY-MM-DD HH:MM> [<hash>-<k>] <topic> (round k/N)
- status: registered
- plan: research/<topic>/<hash>-<k>/analysis_plan.md sha256:<64 hex>
- fixed: <iterated items, iteration 1 only: each fixed input's path sha256:<64 hex>>
```

`research.log`, after the run phase (or a plan phase that ended the round):
```
## <YYYY-MM-DD HH:MM> [<hash>-<k>] <topic> (round k/N)
- status: supported | supported (unreplicated) | not supported | untestable | blocked
- hypothesis: <as pre-registered in the plan, with its predicted direction>
- plan: research/<topic>/<hash>-<k>/analysis_plan.md sha256:<64 hex>
- method: <discovery data, container (quay.io digest or dockerfiles/ path), every test run, including the ones that found nothing>
- result: <test, p or q value, effect size and direction, n; null results count>
- negative control: <what it was, its p or q value>
- validation: <held-out accessions, or none and why>
- metric: <prediction items only: primary metric, model vs baseline with 95% CIs, and why this metric if the scientist chose it; for iterations, the outer-fold score>
- changed: <iterated items: what this iteration changed from the last>
- evidence: <file paths, DOIs, or accession number>
- next: <follow-up or open question>
```

`research.log`, after the validate phase:
```
## <YYYY-MM-DD HH:MM> [<hash>-<k>] <topic> (round k/N, validation)
- status: replicated | not replicated | blocked
- plan: research/<topic>/<hash>-<k>/analysis_plan.md sha256:<64 hex>
- data: <validation accessions>
- result: <test, p or q value, effect size and direction, n; for prediction items, the saved model's primary metric vs the baseline>
- negative control: <its p or q value>
- evidence: research/<topic>/<hash>-<k>/validation/results/...
```

`research.log`, after an iterated item's final validate phase:
```
## <YYYY-MM-DD HH:MM> [<hash>-final] <topic> (iterations k/N, final)
- status: replicated | not replicated | blocked
- chosen: <hash>-<j>, outer-fold <metric> <score>
- stopped: N reached | no improvement in five iterations | converged
- result: <the saved model's primary metric vs the baseline on the held-out data, with the test and p value>
- negative control: <its score and p value>
- evidence: research/<topic>/<hash>-final/results/...
```
An iteration's own status doesn't decide the item; the final entry does.

New containers a scientist reports go in `BioContainers/containers.md` (create it with this header if missing), one row each, skipping digests already listed:

```
| quay.io digest | purpose |
|---|---|
| quay.io/biocontainers/samtools@sha256:<hash> | sort and index BAMs |
```

- A round is done when its last phase is logged (a validated round after its validation entry). Research round done with rounds left: the line stays `- [ ]` and its count records progress, updated after each round so an interrupted pass resumes at the right one, `(hypotheses: 3)` → `(hypotheses: 1/3)` → `(hypotheses: 2/3)`; iterations count the same way, and an item that stops early goes straight to its final phase.
- Done (a task, or a topic's last round): `- [ ]` becomes `- [x]`, e.g. `- [x] topic (hypotheses: 3/3)`.
- Blocked, failed, over a `Skill(check)` limit, or an agent's question (ponytail pushback included): `- [ ]` becomes `- [?]`, and the question (or the size/time estimate) goes on an indented line under the item, and in the log entry as `- question:`. Ask it in the CLI too if a user is present.
  ```
  - [?] add fastp step to qc pipeline
    - Q: Trim adapters only, or quality-trim too?
  ```
  The user writes `  - A: <answer>` under it and sets the item back to `- [ ]` to retry. The next log entry for that item records the answer as `- answer:`. Leave the `Q:`/`A:` lines in place; the user tidies them.
- Never change an item's text, in `tasks.md` or `research.md` alike. On an item line you may change the checkbox, and the count on a research item, nothing else: the text is the user's input and its hash is the item's identity. A line whose hash has nothing filed under it is a new item — a task not started, a research item at round 1 — even when a logged item shares its topic, its folder, its branch, or all but a word of its wording. Text that no longer matches a hash you have entries for means the user re-scoped the item: run it as new and say so in your report. A count that disagrees with the log is overwritten from the log; it is never a signal that the line needs repair.
- Never rewrite a log entry. `tasks.log` and `research.log` are append-only: never edit, reword, re-date, re-hash, correct or delete an existing entry, your own from an earlier pass included, and never rewrite one to match an item line. A result that turns out wrong, a phase that has to be redone, a hash that was mis-set: all are superseded by a new entry that says so, never by changing the old one.

Then clean up: for every item that became `- [x]` this pass (a task, or a research item's last round), run `<noggin scripts>/clean-tmp.sh <hash>` from the project root (the scripts path is in your session context). It deletes that item's `tmp/` folders: every research round's, and a kept worktree's on `noggin/<hash>`. `results/`, `command.sh`, logs and branches stay. Items still `- [ ]` or `- [?]` keep their `tmp/` for the next round or for debugging.

Report to the user, leading with anything that is `[?]`.
