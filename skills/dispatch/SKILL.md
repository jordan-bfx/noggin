---
name: dispatch
description: Dispatch engineer and scientist sub-agents for the open items in the project's tasks.md and research.md, then log results to tasks.log and research.log. Use when asked to "dispatch", when tasks.md or research.md changes, or from watch.sh.
---

# Dispatch

One pass, then stop.

## 1. Read
- `tasks.md` and `research.md` in the project root. An open item is a line `- [ ] ...`. Ignore `- [x]` (done) and `- [?]` (waiting on the user).
- `tasks.log` and `research.log`, so you don't repeat work.
- If `graphify-out/` exists, give each agent a scoped `graphify query "<question>"` result, not the whole graph.
- If `research.md` has open items, make sure `.gitignore` lists `research/data/` and `research/*/*/tmp/`; add the lines if missing. Downloads and intermediates never go in git.
- Limits from `Skill(check)` (`noggin.conf`, or its defaults). Put them in every scientist's brief, with the noggin scripts path from your session context (for `fetch.sh`).

## 2. Dispatch
Spawn sub-agents for the open items, using the Agent tool, at most 10 items per pass, in file order. Leave the rest `- [ ]` for the next pass.
- `tasks.md` item: an **engineer** for code or pipelines, a **scientist** for analysis.
- `research.md` item: a **scientist** for one round. A round tests exactly one hypothesis. The line sets the number of rounds, e.g. `- [ ] topic (hypotheses: 3)`; with no count it gets 1. Give the scientist the topic's earlier `research.log` entries, so each round builds on the last and doesn't repeat it.

A research round runs in two phases, each its own scientist (`Skill(experiment)`), both in the same pass:
1. **Plan:** the scientist writes `analysis_plan.md`, checks the limits, and stops. Nothing is downloaded or analyzed.
2. **Register:** you run `shasum -a 256 <plan>` and append a `registered` entry to `research.log` (template below) before spawning anything else for that round.
3. **Run:** a fresh scientist gets only the plan's path and its sha256, the limits and the round hash, and executes the plan.

If the plan phase ends untestable, blocked or over a limit, there is no run phase. A round whose latest entry is `registered` (a pass stopped between phases) resumes at the run phase.

Every item has a hash: the first 7 characters of `printf '%s' "<text>" | shasum -a 1`, where `<text>` is the line after `- [ ] ` without its trailing `(...)` tags. It stays the same across rounds and checkbox changes. A research round is `<hash>-<k>`, e.g. `3f9a1c2-2`. Put the hash in the brief.

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
```

`research.log`, after the run phase (or a plan phase that ended the round):
```
## <YYYY-MM-DD HH:MM> [<hash>-<k>] <topic> (round k/N)
- status: supported | not supported | untestable | blocked
- hypothesis: <as pre-registered in the plan>
- plan: research/<topic>/<hash>-<k>/analysis_plan.md sha256:<64 hex>
- method: <data, container (quay.io digest or dockerfiles/ path), every test run, including the ones that found nothing>
- result: <test, p or q value, effect size, n; null results count>
- evidence: <file paths, DOIs, or accession number>
- next: <follow-up or open question>
```

New containers a scientist reports go in `BioContainers/containers.md` (create it with this header if missing), one row each, skipping digests already listed:

```
| quay.io digest | purpose |
|---|---|
| quay.io/biocontainers/samtools@sha256:<hash> | sort and index BAMs |
```

- Research round done with rounds left: the line stays `- [ ]` and its count records progress, `(hypotheses: 3)` → `(hypotheses: 1/3)` → `(hypotheses: 2/3)`.
- Done (a task, or a topic's last round): `- [ ]` becomes `- [x]`, e.g. `- [x] topic (hypotheses: 3/3)`.
- Blocked, failed, over a `Skill(check)` limit, or an agent's question (ponytail pushback included): `- [ ]` becomes `- [?]`, and the question (or the size/time estimate) goes on an indented line under the item, and in the log entry as `- question:`. Ask it in the CLI too if a user is present.
  ```
  - [?] add fastp step to qc pipeline
    - Q: Trim adapters only, or quality-trim too?
  ```
  The user writes `  - A: <answer>` under it and sets the item back to `- [ ]` to retry. The next log entry for that item records the answer as `- answer:`. Leave the `Q:`/`A:` lines in place; the user tidies them.

Then clean up: for every item that became `- [x]` this pass (a task, or a research item's last round), run `<noggin scripts>/clean-tmp.sh <hash>` from the project root (the scripts path is in your session context). It deletes that item's `tmp/` folders: every research round's, and a kept worktree's on `noggin/<hash>`. `results/`, `command.sh`, logs and branches stay. Items still `- [ ]` or `- [?]` keep their `tmp/` for the next round or for debugging.

Report to the user, leading with anything that is `[?]`.
