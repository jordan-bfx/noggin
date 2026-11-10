---
name: check
description: Show or set noggin's run limits (download size, run time, spend per dispatch pass) in the project's noggin.conf. Use for "/noggin:check", or when asked to change noggin's limits.
disable-model-invocation: true
---

# Check

Limits live in `noggin.conf` in the project root, one `key=value` per line:

```
max_download_gb=100
max_run_hours=24
max_budget_usd=20
```

Those are the defaults when the file or a key is missing.

## Usage
- `/noggin:check` with no arguments: print the current limits and whether each comes from `noggin.conf` or a default.
- `/noggin:check <key> <value>`, e.g. `/noggin:check max_download_gb 50`: set that key, keeping the other lines. Only the three keys above, plus `fetch_hosts`; refuse anything else. A limit must be a positive number.

## How each limit is enforced
- `max_budget_usd`: `watch.sh` passes it to `claude -p --max-budget-usd`, so a dispatch pass stops when it has spent that much. A pass stopped this way leaves its items open, and the next pass retries them. Interactive `/noggin:dispatch` runs have no spend cap.
- `max_download_gb`: in the plan phase, the scientist adds up the size of every file the plan would fetch, for any kind of omics data:
  - SRA/ENA runs: `https://www.ebi.ac.uk/ena/portal/api/filereport?accession=<run>&result=read_run&fields=fastq_ftp,fastq_bytes,fastq_md5,read_count` (download URLs, sizes and checksums in one call);
  - any other file (GEO, ENCODE, CELLxGENE, PRIDE, MassIVE, ...): `<noggin scripts>/fetch.sh --size <url>`, or the size the repository's metadata lists.
  If the total is over the limit, the plan may choose a subset (see `Skill(experiment)`). Still over, or a size is unknown: it doesn't download and reports the estimate. Dispatch marks the item `[?]`.
- `max_run_hours`: the analysis plan estimates run time. If the estimate is over the limit, same as above.

## Download hosts
`fetch.sh` downloads only from known public repositories (GEO/SRA/ENA, ENCODE, CELLxGENE, 10x, GDC open access, PRIDE, MassIVE, UniProt, Ensembl, UCSC). To allow more in one project, set `fetch_hosts` to comma-separated host names, e.g. `/noggin:check fetch_hosts www.proteomicsdb.org,zenodo.org`. Only add hosts you trust: agents can download anything they serve.

To approve a single item over the limit, add `(approved)` to its line, e.g. `- [ ] topic (hypotheses: 2) (approved)`, and set it back to `- [ ]`.
