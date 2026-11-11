---
name: experiment
description: Test one hypothesis on public omics data (genomics, epigenomics, bulk and single-cell transcriptomics, proteomics, or any other kind), or on local knowledge in `graphify-out/`, with a pre-registered plan.
---

# Experiment

Each round is up to three agents; your brief says which phase you are.
- **Plan phase:** Hypothesis, Method, and Analysis step 1. Report the plan's path and stop. Download no data and run no analysis. Dispatch then registers the plan's sha256, and a fresh scientist runs it.
- **Run phase:** your brief gives the plan's path and sha256. First check `shasum -a 256 <plan>` matches; if not, stop and report it. Then Analysis steps 2-3 and Results on the **discovery** data, following the plan exactly. Never download or open the validation data: it is held out, like a benchmark's gold standard. Never edit the plan.
- **Validate phase** (only after a `supported` run): your brief gives the plan's path and sha256 and nothing about the discovery results; don't read them. Check the hash, then run the same plan, unchanged, on the **validation** data: same preprocessing, test, decision rule and negative control. Work in `research/<topic>/<hash>-<k>/validation/` (`results/`, `command.sh`; intermediates in the round's `tmp/validation/`). Report `replicated` if the decision rule is met with the effect in the same direction as the hypothesis and the negative control stays null; otherwise `not replicated`.

## Hypothesis
1. Determine what hypothesis the sub-agent is testing.
2. Determine what data is needed to test it. Look first in `research/datasets.md`, the user's preferred sources across single-cell, bulk transcriptomics, genomics, epigenomics and proteomics; if you use anything else, the plan says why. Only sources listed there can be downloaded. Controlled-access data (dbGaP, EGA, GDC controlled) needs the user's credentials: report it as a question. If no suitable data exists, report back to dispatch.

## Method
1. Before downloading or analyzing anything, write the plan to `research/<topic>/<hash>-<k>/analysis_plan.md` (the round hash is in your brief). It holds:
   - the hypothesis;
   - the discovery data: accessions, file URLs and total size. If the full set is over `max_download_gb`, choose a subset here, never in the run phase (fewer samples, runs, files, cells or records; a partial read count with `fastq-dump -X N`). State the subset, its size, and what it costs in n and power;
   - the validation data, held out from the run: an independent dataset (another study, cohort or lab) with the same kind of measurement, its accessions, file URLs, size, and the `research/data/` paths it will download to. If the item says `(validate: <accession>)`, use that. If no independent dataset exists, write `validation: none` and why; the result can then only be `supported (unreplicated)`;
   - tools, parameters, preprocessing and expected outputs;
   - the statistical test and the decision rule: supported if p < 0.05, or q < 0.05 (Benjamini-Hochberg FDR) when there is more than one test. No effect-size or fold-change threshold. State the direction of effect the hypothesis predicts;
   - a negative control that must come out null, run through the same pipeline and test: by default the same analysis with the group labels permuted; or a comparison where no effect is expected. If it is significant, the pipeline is broken, leaking or gaming the test, and the result is not trusted.
   Once dispatch registers its sha256, the plan is frozen. A deviation in the run phase gets its own note in the results, with the reason.

   **Prediction items.** An item tagged `(metric: ...)` builds a predictive model. Its plan holds everything above, with these in place of the statistical test and decision rule:
   - the target, the features, and the model family;
   - the primary metric: the item's, or if the tag is empty (`(metric:)`), the one you choose from the table below, with one line on why it fits the target and the class balance. Secondary metrics are reported but never decide;
   - a baseline: a published method, a simple model (e.g. linear or logistic regression on a few known markers), or the class prevalence;
   - the decision rule: `supported` if the model beats the baseline on the primary metric, p < 0.05 by one paired test per phase, named in the plan. Run phase (cross-validated on the discovery data): a permutation test over the whole cross-validation procedure, since reused folds make other tests overconfident. Validate phase (the saved model scored once on the held-out data): DeLong's test for AUROC, otherwise a paired bootstrap. No metric threshold in either phase;
   - leakage rules: tune only on discovery data, split by donor, patient or study (never by sample alone), and do every feature-selection and normalization step inside the training folds;
   - the negative control: the same pipeline with permuted labels must score at chance. Significantly above chance means leakage.

   The run phase saves the final model and its preprocessing under `results/model/`. The validate phase scores that saved model once on the validation data: never retrain or re-tune it there.

   | Task | Primary metric | Choose it when |
   |---|---|---|
   | Regression | RMSE | errors should count in the target's units, large misses weigh more |
   | Regression | MAE | outliers or heavy tails; every miss weighs the same |
   | Binary classification | AUROC | ranking cases from controls, classes roughly balanced |
   | Binary classification | AUPRC | positives are rare (under ~10%) |
   | Binary, with a decision | F1 | a yes/no call is needed and positives matter most; fix the threshold on discovery data |
   | Binary, with a decision | MCC | a yes/no call on imbalanced classes, both classes matter |
   | Multiclass | Macro-F1 | every class matters equally, including small ones |
   | Multiclass | Balanced accuracy | one number for overall correctness with unequal class sizes |
   | Survival | C-index | time-to-event targets with censoring |

   R² can always be reported for regression, but never decides.
2. Pick a container, in this order:
   - Reuse one listed in `BioContainers/containers.md`.
   - Else a BioContainers image from quay.io, pinned by digest: `docker pull <image>`, then `docker inspect --format '{{index .RepoDigests 0}}' <image>` gives `quay.io/biocontainers/<tool>@sha256:<hash>`. Report it with a one-line purpose; dispatch adds it to the table.
   - Else write a Dockerfile with pinned versions to `dockerfiles/<name>.Dockerfile` (it exists nowhere else, so it must be kept).
   Name the container by its digest or Dockerfile path in the plan and in the log's `method` line.

## Analysis
1. Unless the item says `(approved)`, check the limits in your brief first, as `Skill(check)` describes: the download size of the data the plan names (its subset, if it downsamples) and the plan's run-time estimate. Over a limit even with the subset, or size unknown: report the estimate and stop.
2. Download exactly the files the plan names for your phase (discovery data in the run phase, validation data in the validate phase) to `research/data/<repository>/<accession>/`, shared by every topic, with `<noggin scripts>/fetch.sh <url> <dest>`. It downloads only from sources listed in `research/datasets.md` and only into `research/data/`; a source it refuses is a question for the user, not a reason to find another way. Whatever the omics, it is the same command; what differs is the file:
   - genomics and epigenomics: BAM/CRAM, VCF, BED, bigWig, peak calls (ENCODE, GDC open access, GEO supplementary files);
   - bulk transcriptomics: count matrices (GEO supplementary files), or raw reads;
   - single-cell: `.h5ad`, `.rds`, or matrix/barcodes/features files (CELLxGENE, GEO, 10x);
   - proteomics: RAW or mzML spectra, identification results (mzIdentML, mzTab), protein FASTA (PRIDE, MassIVE, UniProt);
   - raw reads deposited in SRA: their ENA FASTQ URLs (`fastq_ftp` from the ENA filereport via `fetch.sh --print`, prefixed with `https://`). Only when a run isn't on ENA, or the plan subsets reads (`fastq-dump -X N`), use the SRA Toolkit (`prefetch`, `fasterq-dump`) with output under `research/data/`; the plan says which runs and why.
   Verify every file against the checksum its repository publishes (ENA `fastq_md5`, ENCODE and GDC `md5sum`, PRIDE checksum files), when there is one. If the data is already present, verify it the same way.
3. Execute the analysis plan using the Docker image, ensuring that all steps are logged for reproducibility. Containers run offline, so step 2 must have downloaded everything first:
   - `docker run --network none --user "$(id -u):$(id -g)" -v "$PWD/research/data:/data:ro" -v "$PWD/research/<topic>/<hash>-<k>:/work" -w /work <image@digest> ...`: no network, data read-only, writes only to the round folder (in the validate phase, mount `.../<hash>-<k>/validation` as `/work`).
   - With Nextflow, pass `-with-docker` and `-c` a config holding `docker.runOptions = '--network none'`.
   A step that needs the network inside a container is a question for the user.

   In `research/<topic>/<hash>-<k>/`:
   - `results/`: only the small final outputs the hypothesis test needs (tables, figures, statistics). It is tracked.
   - `tmp/`: everything else (intermediates, large files, Nextflow `-work-dir research/<topic>/<hash>-<k>/tmp/work`). It is ignored.

## Results
1. Summarize the results of the analysis, including any statistical tests performed, effect sizes, and confidence intervals. Include visualizations if applicable.
2. Run the negative control. If it is significant, stop: report `blocked` with "negative control failed", not a verdict.
3. Apply the plan's decision rule: `supported` or `not supported`, nothing in between. Report effect sizes and their direction, but they don't decide. For a prediction item, report the primary metric for the model and the baseline, each with a 95% confidence interval, and the secondary metrics. Document any unexpected findings or anomalies.
4. Copy every command used, in run order and including failed attempts and fixes, to `research/<topic>/<hash>-<k>/command.sh`.
