---
name: experiment
description: Test one hypothesis on public omics data (genomics, epigenomics, bulk and single-cell transcriptomics, proteomics, or any other kind), or on local knowledge in `graphify-out/`, with a pre-registered plan.
---

# Experiment

Each round is two agents; your brief says which phase you are.
- **Plan phase:** Hypothesis, Method, and Analysis step 1. Report the plan's path and stop. Download no data and run no analysis. Dispatch then registers the plan's sha256, and a fresh scientist runs it.
- **Run phase:** your brief gives the plan's path and sha256. First check `shasum -a 256 <plan>` matches; if not, stop and report it. Then Analysis steps 2-3 and Results, following the plan exactly. Never edit the plan.

## Hypothesis
1. Determine what hypothesis the sub-agent is testing.
2. Determine what data is needed to test it, and whether a public repository has it, for example:
   - sequencing (genomics, epigenomics, bulk and single-cell transcriptomics): GEO, SRA/ENA, ENCODE, CELLxGENE, GDC (open access);
   - proteomics: PRIDE, MassIVE (via ProteomeXchange), UniProt;
   - references: Ensembl, UCSC, GENCODE.
   Controlled-access data (dbGaP, EGA, GDC controlled) needs the user's credentials: report it as a question. If no suitable data exists, report back to dispatch.

## Method
1. Before downloading or analyzing anything, write the plan to `research/<topic>/<hash>-<k>/analysis_plan.md` (the round hash is in your brief). It holds:
   - the hypothesis;
   - the data: accessions, file URLs and total size. If the full set is over `max_download_gb`, choose a subset here, never in the run phase (fewer samples, runs, files, cells or records; a partial read count with `fastq-dump -X N`). State the subset, its size, and what it costs in n and power;
   - tools, parameters, preprocessing and expected outputs;
   - the statistical test and the decision rule: supported if p < 0.05, or q < 0.05 (Benjamini-Hochberg FDR) when there is more than one test. No effect-size or fold-change threshold.
   Once dispatch registers its sha256, the plan is frozen. A deviation in the run phase gets its own note in the results, with the reason.
2. Pick a container, in this order:
   - Reuse one listed in `BioContainers/containers.md`.
   - Else a BioContainers image from quay.io, pinned by digest: `docker pull <image>`, then `docker inspect --format '{{index .RepoDigests 0}}' <image>` gives `quay.io/biocontainers/<tool>@sha256:<hash>`. Report it with a one-line purpose; dispatch adds it to the table.
   - Else write a Dockerfile with pinned versions to `dockerfiles/<name>.Dockerfile` (it exists nowhere else, so it must be kept).
   Name the container by its digest or Dockerfile path in the plan and in the log's `method` line.

## Analysis
1. Unless the item says `(approved)`, check the limits in your brief first, as `Skill(check)` describes: the download size of the data the plan names (its subset, if it downsamples) and the plan's run-time estimate. Over a limit even with the subset, or size unknown: report the estimate and stop.
2. Download exactly the files the plan names to `research/data/<repository>/<accession>/`, shared by every topic, with `<noggin scripts>/fetch.sh <url> <dest>`. It downloads only from known repositories and only into `research/data/`; a source it refuses is a question for the user, not a reason to find another way. Whatever the omics, it is the same command; what differs is the file:
   - genomics and epigenomics: BAM/CRAM, VCF, BED, bigWig, peak calls (ENCODE, GDC open access, GEO supplementary files);
   - bulk transcriptomics: count matrices (GEO supplementary files), or raw reads;
   - single-cell: `.h5ad`, `.rds`, or matrix/barcodes/features files (CELLxGENE, GEO, 10x);
   - proteomics: RAW or mzML spectra, identification results (mzIdentML, mzTab), protein FASTA (PRIDE, MassIVE, UniProt);
   - raw reads deposited in SRA: their ENA FASTQ URLs (`fastq_ftp` in the ENA filereport, prefixed with `https://`). Only when a run isn't on ENA, or the plan subsets reads (`fastq-dump -X N`), use the SRA Toolkit (`prefetch`, `fasterq-dump`) with output under `research/data/`; the plan says which runs and why.
   Verify every file against the checksum its repository publishes (ENA `fastq_md5`, ENCODE and GDC `md5sum`, PRIDE checksum files), when there is one. If the data is already present, verify it the same way.
3. Execute the analysis plan using the Docker image, ensuring that all steps are logged for reproducibility. In `research/<topic>/<hash>-<k>/`:
   - `results/`: only the small final outputs the hypothesis test needs (tables, figures, statistics). It is tracked.
   - `tmp/`: everything else (intermediates, large files, Nextflow `-work-dir research/<topic>/<hash>-<k>/tmp/work`). It is ignored.

## Results
1. Summarize the results of the analysis, including any statistical tests performed, effect sizes, and confidence intervals. Include visualizations if applicable.
2. Apply the plan's decision rule: `supported` or `not supported`, nothing in between. Report effect sizes, but they don't decide. Document any unexpected findings or anomalies.
3. Copy every command used, in run order and including failed attempts and fixes, to `research/<topic>/<hash>-<k>/command.sh`.
