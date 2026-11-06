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

## 2. Dispatch
Spawn one sub-agent per open item, using the Agent tool:
- `tasks.md` item: an **engineer** for code or pipelines, a **scientist** for analysis.
- `research.md` item: a **scientist** for one round. A round tests exactly one hypothesis. The line sets the number of rounds, e.g. `- [ ] topic (hypotheses: 3)`; with no count it gets 1. Give the scientist the topic's earlier `research.log` entries, so each round builds on the last and doesn't repeat it.

Each brief states the item verbatim, its inputs, what done looks like, and what it must not touch. Agents that only read can run in parallel. Run agents that write to the same files one at a time.

## 3. Verify
A sub-agent saying it is done is a claim, not proof. Before accepting a result:
- Code: `Skill(verify)` must pass.
- Research: the reported numbers must trace to a file or a DOI you can open.

## 4. Record
Append one entry per item, then update the item's checkbox in place:

`tasks.log`
```
## <YYYY-MM-DD HH:MM> <item>
- status: done | blocked
- proof: <check run and its result>
- where: <files or branch>
```

`research.log`
```
## <YYYY-MM-DD HH:MM> <topic> (round k/N)
- hypothesis: <written before looking at results>
- method: <data, tests, every test run, including the ones that found nothing>
- result: <effect size, n, uncertainty; null results count>
- evidence: <file paths, DOIs>
- next: <follow-up or open question>
```

- Research round done with rounds left: the line stays `- [ ]` and its count records progress, `(hypotheses: 3)` → `(hypotheses: 1/3)` → `(hypotheses: 2/3)`.
- Done (a task, or a topic's last round): `- [ ]` becomes `- [x]`, e.g. `- [x] topic (hypotheses: 3/3)`.
- Blocked or failed: `- [ ]` becomes `- [?]`, with the question in the log entry. Ask it in the CLI too if a user is present. The user sets it back to `- [ ]` to retry.

Report to the user, leading with anything that is `[?]`.
