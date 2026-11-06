---
name: verify
description: Verify a Nextflow project deterministically with nf-test snapshots, setting up nf-test from tests/data/ if missing. Use after any code change, or when asked to "verify" or "test".
---

# Verify

## If there is no `nf-test.config` yet
1. `nf-test init`
2. Generate a test per entry point, for example `nf-test generate pipeline main.nf`, or `nf-test generate process <file>` per module.
3. Point every test's inputs at files in `tests/data/`, and assert `snapshot(<outputs>).match()`.
4. Run `nf-test test` to write the first `.nf.test.snap` files.
5. Stop and ask the user to review the new snapshots before committing them. The first snapshot is assumed correct, so a human must accept it.

If `tests/data/` is missing or empty, stop and ask for test data. Don't invent any.

## Otherwise
1. Run `nf-test test`.
2. Pass: report the command and the summary line.
3. Fail: report which snapshot differs and why. Never run `--update-snapshot` unless the user confirms the change in output is intended.

Not a Nextflow project? Say so and run the project's own test command instead.
