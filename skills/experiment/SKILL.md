---
name: experiment
description: Use NCBI or misc accessions for public datasets, or local knowledge in `graphify-out/`, to bioinformatically analyze a dataset.
---

# Experiment

## Hypothesis
1. Determine what hypothesis the sub-agent is testing.
2. Determine what data is needed to test it, and if it is available in the accessions below. If there is no data available, report back to dispatcher.

## Method
1. Before downloading or analyzing anything, write the plan to `research/<topic>/<id>-<k>/analysis_plan.md` (the round ID is in your brief). It holds:
   - the hypothesis;
   - tools, parameters, preprocessing and expected outputs;
   - the statistical test and the decision rule: supported if p < 0.05, or q < 0.05 (Benjamini-Hochberg FDR) when there is more than one test. No effect-size or fold-change threshold.
   Don't edit the plan after you see results. A deviation gets its own note in the results, with the reason.
2. Pick a container, in this order:
   - Reuse one listed in `BioContainers/containers.md`.
   - Else a BioContainers image from quay.io, pinned by digest: `docker pull <image>`, then `docker inspect --format '{{index .RepoDigests 0}}' <image>` gives `quay.io/biocontainers/<tool>@sha256:<hash>`. Report it with a one-line purpose; dispatch adds it to the table.
   - Else write a Dockerfile with pinned versions to `dockerfiles/<name>.Dockerfile` (it exists nowhere else, so it must be kept).
   Name the container by its digest or Dockerfile path in the plan and in the log's `method` line.

## Analysis
1. Unless the item says `(approved)`, check the limits in your brief first, as `Skill(check)` describes: total download size and the plan's run-time estimate. Over a limit, or size unknown: don't download; report the estimate and stop.
2. Download the datasets from NCBI or other specified accessions to `data/`. If the data is already present, verify its integrity.
3. Execute the analysis plan using the Docker image, ensuring that all steps are logged for reproducibility. Keep only the necessary outputs for the hypothesis test, and store them in a structured manner.

## Results
1. Summarize the results of the analysis, including any statistical tests performed, effect sizes, and confidence intervals. Include visualizations if applicable.
2. Apply the plan's decision rule: `supported` or `not supported`, nothing in between. Report effect sizes, but they don't decide. Document any unexpected findings or anomalies.
