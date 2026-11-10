# Datasets

Preferred data sources for this project. Scientists check this list first and say in the plan why when they use anything else.
`fetch.sh` downloads only from the URL prefixes in the **download** column (in backticks, ending in `/`), so adding a row is what allows a source. Agents never edit this file; only the user does.

Data you place in `research/data/` by hand (lab data, collaborator files) gets a row too, with its path and where it came from.

Checked 2026-11-10: every prefix below served a real file or API response, except those marked *unverified* (unreachable that day).

## Single-cell
| dataset | institute | download | format | notes |
|---|---|---|---|---|
| Arc Virtual Cell Atlas (scBaseCount, Tahoe-100M) | Arc Institute | `https://storage.googleapis.com/arc-institute-virtual-cell-atlas/` `https://storage.googleapis.com/storage/v1/b/arc-institute-virtual-cell-atlas/` | h5ad, parquet | folders `scbasecount/<release>/`, `tahoe100M/`; ~41 TB total, pick samples or plates; record the release |
| CELLxGENE | Chan Zuckerberg Initiative | `https://datasets.cellxgene.cziscience.com/` `https://api.cellxgene.cziscience.com/curation/v1/` `https://cellxgene-census-public-us-west-2.s3.us-west-2.amazonaws.com/` | h5ad per dataset; Census (TileDB-SOMA) | find datasets via the curation API, then download each h5ad. Census is queried over the network, which offline containers can't do |
| Human Cell Atlas | HCA consortium | `https://service.azul.data.humancellatlas.org/` | h5ad, loom, fastq | `index/files` to search; `repository/files/<uuid>` redirects to storage |
| 10x Genomics public datasets | 10x Genomics | `https://cf.10xgenomics.com/samples/` | h5, mtx, fastq | reference datasets for each 10x assay |
| Allen Brain Cell Atlas | Allen Institute | `https://allen-brain-cell-atlas.s3.us-west-2.amazonaws.com/` | h5ad, parquet | `releases/<date>/manifest.json` lists every file |

## Bulk transcriptomics
| dataset | institute | download | format | notes |
|---|---|---|---|---|
| recount3 | Johns Hopkins | `https://recount-opendata.s3.amazonaws.com/recount3/` | gene/exon/junction counts | uniformly processed SRA, GTEx, TCGA |
| ARCHS4 | Mount Sinai (Ma'ayan lab) | `https://s3.dev.maayanlab.cloud/archs4/` | HDF5 | whole gene matrix is ~64 GB: needs `(approved)` or a higher limit |
| GTEx | Broad / NIH | `https://storage.googleapis.com/adult-gtex/` `https://storage.googleapis.com/storage/v1/b/adult-gtex/` | expression, eQTL tables | |
| Expression Atlas, ArrayExpress | EMBL-EBI | `https://ftp.ebi.ac.uk/pub/databases/` | tsv, sdrf | same prefix covers GENCODE |

## Genomics and epigenomics
| dataset | institute | download | format | notes |
|---|---|---|---|---|
| ENCODE (incl. Roadmap) | NHGRI | `https://www.encodeproject.org/` | BAM, bigWig, BED, peaks | `files/<ENCFF>/@@download/...` redirects to storage; `md5sum` in file metadata |
| ChIP-Atlas | Kyushu Univ. / DBCLS | `https://chip-atlas.dbcls.jp/data/` | BED, bigWig | reprocessed public ChIP-, ATAC-, bisulfite-seq |
| gnomAD | Broad | `https://storage.googleapis.com/gcp-public-data--gnomad/` | VCF, Hail tables | population variant frequencies |
| 1000 Genomes (IGSR) | EMBL-EBI | `https://ftp.1000genomes.ebi.ac.uk/vol1/ftp/` | VCF, CRAM | |
| GDC (TCGA and others), open access | NCI | `https://api.gdc.cancer.gov/` | BAM, MAF, counts | `data/<uuid>` downloads; controlled-access files need the user |

## Proteomics
| dataset | institute | download | format | notes |
|---|---|---|---|---|
| PRIDE | EMBL-EBI | `https://ftp.pride.ebi.ac.uk/` `https://www.ebi.ac.uk/pride/ws/archive/` | RAW, mzML, mzIdentML, mzTab | |
| Human Protein Atlas | KTH / SciLifeLab | `https://www.proteinatlas.org/download/` | tsv, json, xml | |
| ProteomicsDB | TU Munich | `https://www.proteomicsdb.org/proteomicsdb/logic/api/` | API (json) | |
| UniProt | UniProt Consortium | `https://rest.uniprot.org/` `https://ftp.uniprot.org/pub/databases/uniprot/` | FASTA, tsv | |

## Repositories, perturbation and references
| dataset | institute | download | format | notes |
|---|---|---|---|---|
| NCBI (GEO, SRA metadata, RefSeq, dbSNP, ClinVar) | NIH | `https://ftp.ncbi.nlm.nih.gov/` `https://www.ncbi.nlm.nih.gov/geo/download/` `https://eutils.ncbi.nlm.nih.gov/entrez/eutils/` | any | |
| ENA (SRA reads as FASTQ) | EMBL-EBI | `https://ftp.sra.ebi.ac.uk/` `https://www.ebi.ac.uk/ena/portal/api/` | fastq.gz | filereport gives `fastq_ftp`, `fastq_bytes`, `fastq_md5` |
| LINCS / Connectivity Map | Broad | (via GEO) | gctx | L1000: GSE92742, GSE70138 |
| Ensembl | EMBL-EBI | `https://ftp.ensembl.org/pub/` | FASTA, GTF | |
| UCSC Genome Browser | UC Santa Cruz | `https://hgdownload.soe.ucsc.edu/` | FASTA, bigBed, chain | |

## Local data
| dataset | path | omics / format | source |
|---|---|---|---|
