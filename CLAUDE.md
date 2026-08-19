# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project

Nextflow DSL2 pipeline for systematic profiling of the human dorsal root ganglion (DRG) virome from paired-end bulk RNA-seq data. Runs on the Juno HPC cluster (UT Dallas, TJP group) via SLURM and Apptainer. Lives as a git submodule at `containers/virome` within `github.com/mwilde49/hpc`.

> **`docs/juno_hpc_operations_guide.md`** — general Nextflow/SLURM/Apptainer/Juno
> operations knowledge (session-resume mechanics, QOS limits, dependency-chain
> pitfalls, data-staging patterns, WSL2 git gotchas, monitoring recipes), written
> from real production batch launches on this pipeline but **not specific to
> virome** — applicable to any Nextflow pipeline on Juno (`psoma`, `bulkseq`,
> `10x`, `longreads`, `dconvatac`, a new one). Read it before debugging an
> HPC/SLURM/Nextflow issue anywhere in the `firebase2` workspace, not just here.

Current version: **2.2.0** — pipeline-native run provenance (`${outdir}/provenance/`:
`manifest.json`, `software_versions.yml`, `PROVENANCE_README.md`) for all three entry
points, working identically under `tjp-launch`/SLURM or a bare `nextflow run` with no
framework at all — see "Provenance output format" below. Config/samplesheet pairs
built for 11 real cohorts (151 samples) staged gataca → Titan
(`/titan/tprice/ingest/virome/`) ahead of a batch launch — one cohort = one config,
per established convention, tracked in `docs/cohort_registry.md`'s new "Planned"
section. New `scripts/run_virome_config.sbatch` (a `-params-file`-based sibling to
the existing `scripts/run_virome.sbatch`) for submitting each cohort as its own
unattended background SLURM job. One new output directory (`provenance/`) for
existing users; no changes to any existing output file, matrix, or report.

Previously, **2.1.0** — PathSeq verification offshoot productionized and validated
end-to-end (`pathseq_verify.nf`, GATK `PathSeqPipelineSpark`) across 4 real public
cohorts (`cmv_fibroblast`, `vzv_hsv1_tg`, `ebv_gm12878`, `iadorola_tg` batch1), with a
literature-verified performance assessment against each cohort's source publication
(`docs/pathseq_validation_results_2026-08-15.md`); dual Kraken2×PathSeq concordance
heatmap tooling (`scripts/make_concordance_heatmap*.py`, `docs/figures/`) with
per-taxon, taxonomic-lineage, multi-cohort, and per-sample variants; a cohort registry
(`docs/cohort_registry.md`) and Prometheus raw-FASTQ inventory
(`docs/prometheus_fastq_inventory_2026-08-18.md`) ahead of the next ingestion push;
ready-to-launch configs/samplesheets for `dpn_ra_kulkarni` and `osm_juliet`. No core
pipeline logic changed — no rerun needed for existing `run_host_quant`/dual-DB users.

Before that, **2.0.0** — optional host gene expression quantification arm added (dedup/filter + dual-count the GRCh38-mapped reads STAR_HOST_REMOVAL was previously discarding, via featureCounts and HTSeq), enabling host-vs-viral expression correlation (e.g. antiviral/ISG or neurodegeneration-pathway genes vs. HERV-K/HSV-1 signal). Ported from the `psoma`/`bulkseq` sibling bulk RNA-seq pipelines. Inactive by default (`params.run_host_quant = false`).

Before that, **1.5.0** — BLAST verification offshoot pipeline added (`blast_verify.nf`); PD19 HSV-1 Tier 1 detection (first ever); min_reads sensitivity analysis; PD vs. non-PD DRG comparison report; pipeline design whitepaper (`docs/pipeline_design_whitepaper.md`).

## Running the pipeline

```bash
# On Juno via the HPC framework (preferred)
tjp-launch virome

# Directly with Nextflow (SLURM) — always run from an interactive compute node, NOT the login node
# Step 1: get a compute node (login nodes have shared memory exhausted by other users)
srun --account=tprice --partition=normal --cpus-per-task=2 --mem=4G --time=4:00:00 --pty bash
# Step 2: once on the compute node:
export NXF_JVM_ARGS="-Xms512m -Xmx2g"
nextflow run main.nf -profile slurm -params-file assets/config.yaml

# Locally (no SLURM)
nextflow run main.nf -profile standard \
  --samplesheet assets/samplesheet.csv \
  --outdir results \
  --star_index /path/to/star_index \
  --kraken2_db /path/to/kraken2_viral_db \
  --container_dir /path/to/containers/virome
```

Never run Nextflow from the login node — always use `srun` to get an interactive compute node first (see commands above). Login node memory is shared and unpredictably exhausted; the JVM crashes with `Cannot allocate memory` even before starting jobs. Once on a compute node, set `NXF_JVM_ARGS="-Xms512m -Xmx2g"` — 512m max heap is insufficient when tracking 15+ concurrent jobs.

The `slurm` profile automatically sets `workDir = /scratch/juno/$USER/nf_work`. Never run with `-profile slurm` from the groups filesystem work dir — STAR BAM files and `stageInMode = 'copy'` will exhaust the groups quota fast.

## Building containers

Containers must be built before the pipeline runs. `.sif` files are gitignored.

```bash
# Build all containers locally (uses --fakeroot, no sudo needed)
bash scripts/build_containers_local.sh

# Build a single container (always run from repo root)
apptainer build --fakeroot --force containers/<tool>.sif containers/<tool>.def

# Build on Juno (SLURM job)
sbatch scripts/build_containers.sh
```

After building locally, rsync to Juno:
```bash
rsync -avP containers/*.sif maw210003@juno.hpcre.utdallas.edu:/groups/tprice/pipelines/containers/virome/
```

When only `bin/*.py` scripts change, only `python.sif` needs to be rebuilt and rsynced.

When `bin/extract_kraken2_reads.py` or `bin/analyze_blast_results.py` change, rebuild `blast.sif` instead.

## BLAST verification offshoot

Confirms identity and infers viral life cycle phase for Tier 1 candidates. Entry point: `blast_verify.nf`.

```bash
# Prerequisites: locate or publish the per-sample kraken2.output and STAR-unmapped FASTQs
# For the PD19 HSV-1 case, find in the Juno work directory:
find /scratch/juno/maw210003/nf_work -name "PD19.kraken2.output" 2>/dev/null
find /scratch/juno/maw210003/nf_work -name "PD19_unmapped_R1.fastq.gz" 2>/dev/null

# Then copy to the paths expected by the samplesheet, or update the samplesheet paths.

# Launch on Juno (from an interactive compute node):
export NXF_JVM_ARGS="-Xms512m -Xmx2g"
nextflow run blast_verify.nf -profile slurm -params-file assets/config_blast_pd19.yaml
```

**For future runs:** add `save_kraken2_output: true` and `save_unmapped_reads: true` to your main pipeline params file — these will publish the needed intermediate files to outdir automatically.

**Default behavior:** processes all Tier 1 taxa from `params.consensus_matrix`. Override with `params.target_taxa = "3050292,10298"`.

**Required on Juno (one-time setup):**
- BLAST nt database: `update_blastdb.pl --decompress nt` → `/groups/tprice/pipelines/references/blast_nt/`
- HSV-1 reference: `efetch -db nucleotide -id NC_001806.2 -format fasta > 3050292.fa` → `/groups/tprice/pipelines/references/viral_refs/3050292.fa`
- Build container: `apptainer build --fakeroot --force containers/blast.sif containers/blast.def`

## PathSeq verification offshoot (optional)

A third-opinion validator for publication-critical Tier 1 candidates (PD19-class
novel findings) — a post-hoc offshoot, structurally a sibling to `blast_verify.nf`,
**not** a routine per-cohort arm and **not** a fourth tier feeding the Tier1/2/3
consensus. Entry point: `pathseq_verify.nf`. Background/feasibility writeup:
`docs/pathseq_and_test_datasets_2026-08-14.md` (Part 1).

Unlike the BLAST offshoot, PathSeq does not do per-taxon read extraction: it
classifies a sample's entire STAR-unmapped read pool in one `PathSeqPipelineSpark`
run, producing a taxonomy-wide abundance table (all taxa, not just candidates).
Filtering to taxa of interest happens afterward in `AGGREGATE_PATHSEQ` by looking
`target_taxa`/`consensus_matrix` taxon IDs up in that table.

PathSeq's own host-subtraction step is skipped entirely — the input is already
host-depleted by `STAR_HOST_REMOVAL` upstream, so no host k-mer file or host BWA
image is configured; GATK's `PSFilterArgumentCollection` marks those inputs
optional and PathSeq is explicitly designed to accept pre-host-depleted input.

```bash
# Samplesheet CSV format (simpler than blast_verify.nf's — no kraken2_output
# column, since PathSeq classifies the whole unmapped pool, not per-taxon extracts):
#   sample,fastq_r1,fastq_r2

# Prerequisite: STAR-unmapped FASTQs must exist at the samplesheet paths — same
# requirement as the BLAST offshoot (save_unmapped_reads: true, or locate in the
# Nextflow work directory).

# Launch on Juno (from an interactive compute node):
export NXF_JVM_ARGS="-Xms512m -Xmx2g"
nextflow run pathseq_verify.nf -profile slurm -params-file assets/config_pathseq_<cohort>.yaml
```

Template params file: `assets/config_pathseq_template.yaml`.

**PathSeq always scores every taxon** in a sample's STAR-unmapped read pool — unlike
`blast_verify.nf`'s `target_taxa`, neither `params.target_taxa` nor
`params.consensus_matrix` gates what gets classified. Optionally set one of them to
restrict which taxa `AGGREGATE_PATHSEQ` highlights in `pathseq_concordance.tsv`
(`target_taxa` explicit IDs win over `consensus_matrix`-derived Tier 1 taxa, same
param `blast_verify.nf` reads); if both are left unset, the concordance table falls
back to reporting every taxon PathSeq itself detected — no error either way.
Optionally set `params.blast_lifecycle_dir` (null by default) to fold BLAST offshoot
lifecycle calls into a three-way concordance table.

**Required on Juno (one-time setup):**
- Pull the Broad's public PathSeq reference bundle into
  `/groups/tprice/pipelines/references/pathseq/`: the microbe bundle (BWA image +
  companion FASTA/dict, **94.6 GB**) and the taxonomy bundle (**6.7 MB**). Skip the
  ~26 GB host bundle entirely — it is never used (see above). This is RefSeq
  release 81 (April 2017): confirmed HSV-1 (taxid 10298) is present, but anything
  characterized since 2017 will be absent. Rebuilding fresh is 150–300+ GB and
  reported to take ~14 days to index with `BwaMemIndexImageCreator` — only worth it
  for a specific post-2017 target organism.
- Confirm a `.dict` sequence dictionary exists alongside the microbe FASTA
  (standard GATK/samtools naming: strip `.fasta`/`.fa`/`.fna`, append `.dict`) —
  `PathSeqPipelineSpark`'s `--microbe-dict` consumes this, not the raw FASTA. See
  `assets/config_pathseq_template.yaml` for the exact filename check and the
  `gatk CreateSequenceDictionary`/`samtools dict` fallback if it's missing.
- Build container: `apptainer build --fakeroot --force containers/pathseq.sif containers/pathseq.def`
  then `rsync -avP containers/pathseq.sif maw210003@juno.hpcre.utdallas.edu:/groups/tprice/pipelines/containers/virome/`
  (see also the "⚠ Deployment notes" section below).
- Set `params.pathseq_microbe_bwa_image`, `params.pathseq_microbe_fasta`,
  `params.pathseq_taxonomy` to the pulled bundle paths (these three params already
  exist as a stub in `nextflow.config` under `--- PathSeq (optional validation) ---`).

**Compute cost (the main reason this stays a narrow offshoot, not routine
infrastructure):** `PATHSEQ_SCORE` is by far the heaviest process in this
repo — Broad's own WDL resource table lists 140 GB/8cpu for the align step alone,
and a real-world Biostars report (biostars.org/p/9603549) of `PathSeqPipelineSpark`
run on this pipeline's exact data shape (short-read bulk-RNA STAR-unmapped reads)
needed 200 GB heap and was still slow. `conf/base.config` allocates 200 GB/32cpu/48h
accordingly.

## Host gene expression quantification (optional)

Dedup/filter + dual-count (featureCounts via Rsubread, and HTSeq independently) the
GRCh38-mapped reads that `STAR_HOST_REMOVAL` produces as a side effect but the main
pipeline otherwise discards (only the *unmapped* reads feed the viral branch). Enables
correlating host gene expression against the viral abundance matrices on the same
sample set and the same RPM denominator (STAR total input reads). Ported from the
`psoma` (HISAT2) and `bulkseq` (STAR) sibling bulk RNA-seq pipeline repos, which
validated this exact dedup → filter → dual-count design on real data
(`psoma/U19joe_counts/`).

**Inactive by default** (`params.run_host_quant = false`) — no change to existing
outputs or runtime unless explicitly enabled.

```yaml
# assets/config.yaml additions to enable
run_host_quant: true
gtf:            /groups/tprice/pipelines/references/gencode.v48.primary_assembly.annotation.gtf
blacklist_bed:  /groups/tprice/pipelines/references/blacklist.bed
exclude_bed:    /groups/tprice/pipelines/references/filter.bed
```

**Required on Juno (one-time setup) — source files live locally in the `psoma` sibling repo:**
```bash
# From the psoma repo checkout, rsync the reference files virome needs:
rsync -avP psoma/HISAT2_pipeline_files/HISAT2_pipeline_files/gencode.v48.primary_assembly.annotation.gtf \
    maw210003@juno.hpcre.utdallas.edu:/groups/tprice/pipelines/references/
rsync -avP psoma/HISAT2_pipeline_files/HISAT2_pipeline_files/blacklist.bed \
    psoma/HISAT2_pipeline_files/HISAT2_pipeline_files/filter.bed \
    maw210003@juno.hpcre.utdallas.edu:/groups/tprice/pipelines/references/

# Build the new container (bundles sambamba, bedtools, samtools, R+Rsubread, HTSeq):
apptainer build --fakeroot --force containers/host_quant.sif containers/host_quant.def
rsync -avP containers/host_quant.sif maw210003@juno.hpcre.utdallas.edu:/groups/tprice/pipelines/containers/virome/
```

`assets/gene_id_name_biotype.tsv` (gene_id/gene_name/gene_biotype lookup, ~79k GENCODE
v48 entries) is committed to the repo — no separate transfer needed. Set
`params.gene_info = null` to disable gene-name annotation of the output matrix.

**Pipeline steps added** (`DEDUP_FILTER_HOST` → collect all samples → `FEATURECOUNTS` +
`HTSEQ_COUNT` → `AGGREGATE_HOST_COUNTS`): sambamba dedup (`markdup -r`) → bedtools
blacklist/exclude-region filtering → featureCounts and HTSeq run independently on the
full sample set → merged into `host_gene_expression_matrix.tsv` with a per-sample
featureCounts/HTSeq concordance QC file (`host_gene_expression_matrix_qc_summary.tsv`,
log1p Pearson + Spearman across all genes — flags samples where the two counters
disagree before you trust the numbers).

## Kraken2 viral database

Pre-built from Langmead Lab (AWS). Run once on Juno:
```bash
mkdir -p logs && sbatch scripts/build_kraken2_db.sh
```
Outputs to `/groups/tprice/pipelines/references/kraken2_viral_db/` (~1.1 GB).

## Pulling results locally

```bash
bash scripts/pull_results.sh <juno_outdir> <local_outdir>
# e.g.:
bash scripts/pull_results.sh /scratch/juno/maw210003/virome_test results/muscle_cohort
```

## Architecture

**Data flow** (v2.1.0, 7 steps + multi-stage aggregation + optional dual-DB branch + optional host-quant branch + BLAST offshoot + PathSeq offshoot):
```
raw FASTQs → FASTQC → TRIMMOMATIC → STAR_HOST_REMOVAL ─┬→ (unmapped) → KRAKEN2_CLASSIFY (DB1) → BRACKEN → KRAKEN2_FILTER ─┬→ AGGREGATE(final)       ─┐
                                                        │                                     └→ KRAKEN2_CLASSIFY (DB2) → BRACKEN → KRAKEN2_FILTER ─┼→ AGGREGATE(pluspf)      ─┼→ COMPARE_DATABASES → plot
                                                        │                                                                                            ├→ AGGREGATE(minreads)    ─┼→ REPORT
                                                        │                                                                                            └→ AGGREGATE(bracken_raw) ─┘
                                                        │                                                                        └──────────────────────────────────────────→ MULTIQC
                                                        └→ (mapped, host BAM) → DEDUP_FILTER_HOST → collect ─┬→ FEATURECOUNTS ─┬→ AGGREGATE_HOST_COUNTS → host_gene_expression_matrix.tsv
                                                                                                              └→ HTSEQ_COUNT  ─┘

BLAST offshoot (blast_verify.nf — post-hoc, on Tier 1 candidates):
  [kraken2.output + unmapped FASTQs] → EXTRACT_KRAKEN2_READS → BLAST_VERIFY → BLAST_ANALYZE → lifecycle_report.html

PathSeq offshoot (pathseq_verify.nf — post-hoc, all-taxa validation):
  [STAR-unmapped FASTQs] → FASTQ_TO_UBAM → PATHSEQ_SCORE → AGGREGATE_PATHSEQ → pathseq_abundance_matrix.tsv / pathseq_concordance.tsv
```
DB2 branch is inactive by default (`params.kraken2_db2 = null`). One-line activation: set `kraken2_db2` in your params file.

Host-quant branch is inactive by default (`params.run_host_quant = false`). See "Host gene expression quantification (optional)" above.

The provenance/ output is always on (no toggle) for all three entry points — see "Provenance output format" below.

BLAST and PathSeq offshoots are both separate entry-point scripts (`blast_verify.nf`,
`pathseq_verify.nf`), not arms of `main.nf` — see their respective sections above.

**KRAKEN2_FILTER emits 5 channels per sample:**
- `filtered` → `{id}.filtered.tsv` — final output (min_reads + artifact exclusion)
- `bracken_raw` → `{id}.bracken_raw.tsv` — all viral species, no threshold
- `minreads` → `{id}.minreads.tsv` — after min_reads, before artifact exclusion
- `summary` → `{id}.filter_summary.tsv` — per-stage taxa/read counts
- `artifacts` → `{id}.artifacts_removed.tsv` — taxa removed by artifact exclusion

**Three abundance matrices are produced** (all in `results/`):
- `viral_abundance_matrix.tsv` — final filtered (the primary output)
- `minreads_matrix.tsv` — after min_reads threshold only
- `bracken_raw_matrix.tsv` — all viral species from Bracken (baseline)

**Report (`virome_report/summary.html`) includes:**
- Diversity table (richness, Shannon, total reads)
- Filtering funnel chart (taxa count per stage per sample)
- Read attrition chart (reads retained per stage per sample)
- Top-N abundance heatmap and prevalence bar (final matrix)
- Dual-DB comparison plot (Tier 1/2/3 breakdown per sample; only present when `kraken2_db2` is set)

**Dual-database comparison outputs** (in `results/db_comparison/`, only when `kraken2_db2` is set):
- `db_comparison.tsv` — full per-taxon tier classification
- `consensus_matrix.tsv` — Tier 1 taxa only (detected in both DBs; use for biology)
- `false_positive_candidates.tsv` — Tier 2 taxa (viral-only DB only; inspect before interpreting)
- `db_comparison_summary.tsv` — per-sample tier counts
- `db_comparison.png` — stacked bar chart embedded in HTML report

Three tiers: **Tier 1** = shared (both DBs agree, high confidence); **Tier 2** = viral-only only (FP candidates); **Tier 3** = PlusPF only (warrants investigation).

**Key architectural decisions:**

- `main.nf` only handles samplesheet parsing and channel creation. All logic is in `workflows/virome.nf`.
- Each process has its own container (`${params.container_dir}/<tool>.sif`). Never hardcoded.
- STAR is used for host removal using the pre-existing GRCh38 index. Unmapped reads feed Kraken2.
- `bin/*.py` scripts are baked into `containers/python.sif` at build time via `%files`. Rebuild the container whenever scripts change. Always run `apptainer build` from the repo root (paths in `%files` are relative to the build invocation directory).
- `stageInMode = 'copy'` is set in `conf/base.config` — required because Apptainer with `--cleanenv` cannot follow symlinks across work directories.
- `module load apptainer` is in `conf/slurm.config`'s `beforeScript` — required on Juno compute nodes.
- Never run Nextflow from the login node — always use `srun` first to get an interactive compute node with guaranteed memory.
- Nextflow is installed at `/groups/tprice/pipelines/bin/nextflow` (not a module).
- `lib/` is a new top-level convention (first used for `lib/provenance.nf`) alongside `modules/`/`workflows/`: plain DSL2 `include`-able Groovy helper functions (no `process`/`workflow` blocks), for logic shared across more than one entry point. Functions there read the implicit `params`/`workflow`/`projectDir`/`log` bindings directly rather than receiving them as arguments — matching `workflows/blast_verification.nf`'s pre-existing `get_target_taxa()` pattern. This isn't just style: passing `workflow`/`params` as explicit positional args into a function called from inside a `workflow.onComplete {}` closure was tried first and failed at runtime (`params` resolved to `null` inside the callee, specifically on the early param-validation-failure path) — implicit access does not have this problem.

**Samplesheet format** (CSV, required columns):
```
sample,fastq_r1,fastq_r2
```

**Abundance matrix format** (output):
- `taxon_id`, `taxon_name`, `rank` — taxonomy columns
- `<sample>_reads` — raw Kraken2 direct read counts per sample
- `<sample>_rpm` — reads per million trimmed reads (normalized via STAR input read count)

**Host gene expression matrix format** (`host_gene_expression_matrix.tsv`, only when `run_host_quant` is enabled):
- `gene_id`, `gene_name`, `gene_biotype` — annotation columns (from `assets/gene_id_name_biotype.tsv`; omitted if `params.gene_info = null`)
- `<sample>_fc_reads` / `<sample>_fc_rpm` — featureCounts (Rsubread) raw + RPM
- `<sample>_htseq_reads` / `<sample>_htseq_rpm` — HTSeq raw + RPM
- RPM uses the same STAR total-input-reads denominator as the viral matrices, so host gene RPM and viral taxon RPM are directly comparable/correlatable per sample.
- Companion file `host_gene_expression_matrix_qc_summary.tsv`: per-sample featureCounts/HTSeq concordance (log1p Pearson r, Spearman r) — check this before trusting a sample's counts.

**Provenance output format** (`${outdir}/provenance/`, always on, all three entry points — `main.nf`, `blast_verify.nf`, `pathseq_verify.nf`):
Pipeline-native run provenance, produced identically whether launched via the
`mwilde49/hpc` framework's `tjp-launch`/SLURM or a bare `nextflow run main.nf
-profile standard` on a machine with no framework at all (e.g. a non-framework
box like "gataca"). No dependency on the framework's own
`bin/lib/provenance.sh`/`PROVENANCE_README.md`/`CONSOLE_LOG.txt` system (that
one lives under `/work/$USER/pipelines/virome/runs/<timestamp>/`, only for
`tjp-launch`-driven runs — see the `hpc` repo's own CLAUDE.md). Implementation:
`lib/provenance.nf` (shared helpers, included by all three entry-point scripts
and by `workflows/virome.nf` / `workflows/blast_verification.nf` /
`workflows/pathseq_verification.nf`) + `modules/capture_software_versions.nf`
(the `CAPTURE_SOFTWARE_VERSIONS` process).
- `manifest.json` — machine-readable: git commit (`workflow.commitId`, falling back to `git rev-parse HEAD` for a plain local checkout — the normal case for this repo), Nextflow version/run name/session ID/command line/profile(s)/workDir, the fully resolved `params` map, samplesheet path + SHA-256 checksum, start/complete timestamps, duration, exit status, and success/failure boolean.
- `software_versions.yml` — real tool version strings queried live from this run's own containers at execution time (`apptainer exec <container> <tool> --version`-style invocations run by `CAPTURE_SOFTWARE_VERSIONS`, not hardcoded). Scoped per entry point: `main.nf` probes `fastqc.sif`/`trimmomatic.sif`/`star.sif`/`kraken2.sif`/`bracken.sif`/`python.sif`/`multiqc.sif`, plus `host_quant.sif`'s six tools (sambamba/bedtools/samtools/R/Rsubread/HTSeq) when `params.run_host_quant` is true; `blast_verify.nf` probes `blast.sif`'s four tools (blastn/seqtk/minimap2/samtools); `pathseq_verify.nf` probes `pathseq.sif` (gatk/PathSeq).
- `PROVENANCE_README.md` — human-readable Markdown assembled in a `workflow.onComplete{}` block (registered as the *first* statement in each entry point's `workflow {}` body, before any param-validation `error` call, so it still fires and produces a FAILED-status report even on a fast-fail run): run status/timing/exit code, key resolved params, the software-versions table, the exact invocation, the samplesheet path+checksum, and a signpost table of every other artifact directory expected under `${outdir}` for that entry point/active arms.
- **Known, unavoidable limitation**: `provenance/` cannot include a full raw console-log transcript equivalent to the framework's `CONSOLE_LOG.txt` — Nextflow has no supported way to capture its own invoking shell's stdout/stderr from within itself (see `lib/provenance.nf`'s header comment). `PROVENANCE_README.md` itself documents this and recommends `nextflow run main.nf ... 2>&1 | tee ${outdir}/provenance/console_log.txt` as a manual workaround for gataca-side users who need one.

**Artifact exclusion:**
`assets/artifact_taxa.tsv` — curated TSV of taxon IDs to exclude from all samples. 24 entries covering: ruminant orthobunyaviruses, insect baculoviruses, phages, environmental metagenome viruses (DRG k-mer cross-mapping), avian herpesviruses, giant amoeba viruses, and hantaviruses (Orthohantavirus oxbowense 3052491 + Oxbow virus 660954 — confirmed k-mer cross-mapping artifact present in all tissue types). Enabled by default via `params.artifact_list`. Set to `null` to disable.

**Taxon display name remapping:**
`assets/taxon_remap.tsv` — curated TSV mapping taxon_id → display_name for taxa whose Kraken2/NCBI label is misleading in human tissue context (e.g. cross-species k-mer assignments). Applied after artifact exclusion to all three output stages; taxon_id is preserved for traceability. Current entry: 3050337 (*Cytomegalovirus papiinebeta3*) → `Human CMV (HHV-5) [proxy]`. Enabled by default via `params.taxon_remap`. Set to `null` to disable.

**ICTV taxonomy reclassification caveat**: ICTV updates periodically assign new taxon IDs to previously named species, causing taxa to escape exclusion filtering. Confirmed example: Ralstonia phage p12J (247080) reclassified as Porrectionivirus p12J (2956327). When adding entries, verify whether the taxon ID has been superseded; list both old and new IDs if applicable. Audit the list after database updates.

**DRG-specific cross-mapping**: Environmental metagenome-derived viruses (Gihfavirus, Kinglevirus) produce DRG-exclusive signals due to tissue-specific transcripts (neuronal ion channels, neuropeptides, lncRNAs) generating k-mer matches. Any novel "DRG-specific virus" finding requires read-level BLAST validation before biological interpretation.

**Profiles:**
- `slurm` — production use on Juno
- `standard` — local execution
- `test` — uses `conf/test.config` (not yet written)

## Cluster paths (Juno)

| Resource | Path |
|---|---|
| Shared pipeline root | `/groups/tprice/pipelines` |
| Nextflow binary | `/groups/tprice/pipelines/bin/nextflow` |
| Virome submodule | `/groups/tprice/pipelines/containers/virome` |
| Container `.sif` files | `/groups/tprice/pipelines/containers/virome/*.sif` |
| STAR index (GRCh38) | `/groups/tprice/pipelines/references/star_index` |
| Kraken2 viral DB | `/groups/tprice/pipelines/references/kraken2_viral_db` |
| User workspace | `/work/$USER/pipelines/virome/` |

## Known issues / gotchas

- **`ps` not found**: Nextflow's process monitor uses `ps` inside the container. Add `procps` to any custom container based on slim/minimal base images (`python:3.11-slim` requires it; biocontainers images already include it).
- **MultiQC output naming**: With `--filename multiqc_report.html`, the data dir is `multiqc_report_data/`, not `multiqc_data/`.
- **Click `multiple=True`**: CLI options that accept multiple values need `--flag val1 --flag val2`, not `--flag val1 val2`. Use `.collect { "--flag $it" }.join(...)` in Nextflow module scripts.
- **Network drive rsync from WSL**: Use `-r` without `-a`, add `--no-links --no-perms --no-owner --no-group`. If still failing, use Windows PowerShell `scp` directly.
- **Apptainer now works in WSL2 (2026-07 update)**: contrary to older assumptions (see the parent workspace `CLAUDE.md`'s WSL2 Notes for the historical claim and why it's now superseded), apptainer 1.4.5 on a 6.6.87.2-microsoft-standard-WSL2 kernel runs real pipeline containers correctly — verified 2026-07-15 by building a STAR genome index and running splice-aware alignment (`containers/star.sif`), and by running `sambamba`/`bedtools`/`samtools`/Rsubread `featureCounts`/`htseq-count` (`containers/host_quant.sif`) via `apptainer exec`, all producing correct output. A full local `nextflow run main.nf -profile standard` DSL2 orchestration run was also exercised successfully. This means small-scale local smoke-testing of this pipeline (toy chromosome reference, subsampled FASTQs) is now genuinely possible in WSL2 without Juno — useful for validating new modules before a real Juno run. Still worth spot-checking any new container/tool combination rather than assuming full parity with Juno's Apptainer build. Production-scale runs (real ~30GB STAR index, real ~1.8GB GTF, full cohorts) still belong on Juno — this is about local *smoke-testing*, not replacing Juno for real runs. See `docs/tooling_progress_plan.md` for a worked example (v2.0.0 host-quant arm).
- **Nextflow's eager profile-config validation (>= ~25.x)**: `nextflow.config`'s `profiles {}` block has every `includeConfig` path validated at parse time for *all* profiles, not just the one selected via `-profile`. If `conf/test.config` (referenced by the `test` profile) is ever missing again, even `-profile standard` or `-profile slurm` will fail to parse with `Invalid include source`. A minimal stub `conf/test.config` now exists specifically to prevent this — don't delete it without replacing it with a real file.
- **Bracken hard-fails when a Kraken2 report doesn't carry enough classified reads to build an estimate**: a sample whose STAR-unmapped read pool is tiny and/or mostly non-viral can produce a Kraken2 report Bracken refuses to process ("Error: no reads found. Please check your Kraken report", exit 1), which by Nextflow's default `errorStrategy` aborts the *entire* cohort run, not just that one sample. Two real cases so far, both Thoracic DRG cohort, 2026-08-19: `104T8R` (92 total STAR input reads, report is nothing but the `unclassified` summary line — a genuine library failure, same class as `Saad_2`) and `116TR5` (a real rank-`S` row is present — `Orthobunyavirus simbuense`, 2 direct reads; `BeAn 58058 virus`, 1 direct read — just too few reads to clear bracken's own internal threshold). The second case is why the fix in `modules/bracken.nf` is a try/catch on bracken's actual exit, not a pre-check: an earlier version guarded on "does any row exist at `params.bracken_level`," which caught `104T8R` but missed `116TR5` (a row existed, just without enough reads) — reverse-engineering bracken's exact internal requirement in `awk` turned out to be exactly the kind of thing that's easy to get subtly wrong. Current fix: run `bracken` for real every time; if it exits nonzero, check whether stderr contains `"no reads found"` — if so, treat it as a legitimate zero/near-zero-detection result and pass the original report through untouched as `.bracken_report` (downstream `filter_kraken2_report.py` already handles zero viral-rank rows cleanly — empty DataFrame, 0 taxa, no crash) plus an empty-but-correctly-headered `.bracken` file; any *other* bracken failure still propagates and aborts normally. No container rebuild needed (pure shell logic in the process script). No `errorStrategy`/resilience change made beyond this specific failure message — one bad sample can still abort a whole cohort for any unrelated process failure. Separately, `106T3R` (same cohort) has its own genuine anomaly worth noting: 74.52% of its 62.8M reads are "too many loci" (multi-mapping rejected by `--outFilterMultimapNmax 1`), driving a low 24.68% unique-mapping rate — unrelated to the Bracken issue, and not obviously a problem (its ~47M-read unmapped pool classified normally), but unusual enough to flag.

## Adding or modifying a module

1. Edit or create `modules/<name>.nf` — container directive must use `${params.container_dir}/<tool>.sif`
2. If adding a new tool, create `containers/<tool>.def` using a biocontainers or staphb Docker base image; add `procps` if using a slim Python/Ubuntu base
3. Register the new process in `workflows/virome.nf`
4. Rebuild: `apptainer build --fakeroot --force containers/<tool>.sif containers/<tool>.def`
5. If modifying `bin/*.py` scripts, rebuild `python.sif` from repo root

## Planned features / roadmap

### Near-term
- **`assets/taxon_remap.tsv` + relabeling step** — ✓ implemented in v1.2.0
- **`conf/test.config`** — minimal test profile with synthetic data for CI/smoke testing
- **Host removal QC metric** — emit percent unmapped reads per sample to MultiQC for cross-cohort monitoring
- **MultiQC custom content** — inject filter_summary TSV into MultiQC for per-sample filtering stats in the QC report

### Medium-term
- **Kraken2 confidence tuning** — expose per-run confidence threshold; DRG samples may benefit from higher stringency
- **PathSeq validation module** — ✓ implemented as the `pathseq_verify.nf` offshoot (not a `run_pathseq`-gated arm of the main pipeline as originally sketched here — see "PathSeq verification offshoot (optional)" above)
- **PathSeq modular input scope (planned, not started)** — `pathseq_verify.nf`'s MVP (2026-08-15) deliberately runs PathSeq on the whole STAR-unmapped read pool per sample, taxonomy-wide, mirroring exactly what Kraken2 itself consumes — no scope-selection machinery. Discussed but deferred: a `params.pathseq_scope` (or a list-valued `params.pathseq_scopes` that fans out multiple scopes in one run, for sensitivity-vs-scope comparison) selecting among:
  - `unmapped` (current MVP, no change)
  - `kraken2` — reuse `modules/extract_kraken2_reads.nf` as-is (already built for `blast_verify.nf`) to scope `PATHSEQ_SCORE` to only the reads Kraken2 already classified for a given taxon — near-zero new infrastructure, much cheaper per-run (fewer reads to align/score), same publication-defensibility value as a corroboration check
  - `blast` / `minimap2` — narrower still: a new small `seqtk subseq` filter step taking only the read IDs that passed `blast_analyze.nf`'s pident/evalue thresholds (or the not-yet-built minimap2 arm's confirmed hits) out of the Kraken2-extracted FASTQ
  - `raw` — explicitly NOT planned yet. Would need PathSeq's own host-filter stage re-enabled (currently deliberately skipped), the ~26GB host k-mer/BWA bundle we currently skip entirely, and a redundant second host-removal pass alongside STAR's. Scientifically interesting (could catch viral reads STAR's aligner sequesters as host — integrated/endogenized sequences, human-similar regions) but the most expensive and most new-infrastructure mode; revisit only after the cheap modes (`kraken2`/`blast`) prove the tool's worth having at all.
  - **Caveat that applies to every narrower scope**: PathSeq's ~94.6GB microbe BWA index loads into memory regardless of input read count — narrowing scope buys wall-clock time and less redundant compute, not a smaller `PATHSEQ_SCORE` memory floor.
- **Telescope locus-level HERV-K quantification offshoot (planned, not started, 2026-08-18)** —
  intent: a `telescope_verify.nf` offshoot, structurally a sibling to `blast_verify.nf`/
  `pathseq_verify.nf` (separate entry point, opt-in, post-hoc — not a routine per-cohort arm).
  Agreed two-leg workflow: **Leg 1** stays exactly as today — Kraken2/PathSeq taxon-level HERV-K
  detection (taxon `45617`) on every sample, no change to `main.nf`/`workflows/virome.nf`. **Leg 2**
  runs Telescope (Bendall et al., Hammell lab) selectively, only on samples/cohorts where the
  aggregate signal itself warrants locus-level resolution (e.g. HSV-1-positive donors, or cohorts
  with an anomalous aggregate HERV-K reading), to produce a locus × sample count matrix instead of
  one taxon-wide number. **Known blocker**: `modules/star_host_removal.nf` runs
  `--outFilterMultimapNmax 1` (uniquely-mapped reads only) — the exact anti-pattern that discards
  the multi-mapping reads Telescope needs (HML-2 loci share 85–95% sequence identity across ~90
  full-length copies in GRCh38; most HML-2-derived reads are genuine multi-mappers). Leg 2 needs its
  own STAR re-alignment (`--outFilterMultimapNmax 100 --outSAMmultNmax 100`), not a reuse of Leg 1's
  host-removal BAM. Full technical spec and the broader thesis-project rationale:
  `HERVK/experimental_roadmap.md` Phase 1 Experiment 1 (the project's own "gating experiment") and
  `HERVK/background/hervk_biology.md` §7.
- **Reference augmentation** — re-map Kraken2 hits back to viral reference genomes using minimap2 for depth-of-coverage validation; add human CMV strain diversity (Toledo, TB40/E) to database to fix HHV-5 cross-mapping at source
- **Cohort-level statistical module** — DESeq2-style differential abundance testing between sample groups (neuropathy vs. control, donor vs. cultured)
- **minimap2 alignment arm** (`params.run_minimap2`) — optional third classification arm running minimap2 (`-ax sr --secondary=no -q 10`) on STAR-unmapped reads against a vertebrate viral RefSeq panel (.mmi index), producing `minimap2_matrix.tsv` (RPKM-normalized) alongside the existing Kraken2 matrices. Recovers reads missed by k-mer ambiguity in the LAT region and similar AT-rich/complex viral loci. Validated against Iadorola TG cohort (LaPaglia 2017): binary detection equivalent to Kraken2, but quantification of HSV-1 burden expected to approach MAGIC pipeline's 80.3% viral read fraction. Full implementation plan in Claude memory (`project_minimap2_alignment_arm.md`). Juno reference setup: download NCBI vertebrate-infecting viral RefSeq → combined FASTA → `minimap2 -d` index at `/groups/tprice/pipelines/references/viral_refs_panel/`. New container: `minimap2.sif`. New module: `modules/minimap2_viral_align.nf`. New script: `bin/aggregate_minimap2.py`. ~4–6 days effort.

### Longer-term
- **Metadata integration** — accept a metadata TSV (sample type, neuropathy status, donor ID) and incorporate into report groupings and plots
- **Assembly-based discovery** — de novo viral assembly on host-depleted reads using SPAdes/MEGAHIT for detection of novel/divergent viruses below Kraken2's k-mer threshold
- **Multi-database classification** — ✓ implemented in v1.3.0 (dual-DB parallel branch with three-tier output)
- **Longitudinal tracking** — compare virome profiles across timepoints for the same donor

## ⚠ Deployment notes

**v1.3.0 (still applies):** `python.sif` must be rebuilt before running any dual-DB pipeline job (`--kraken2_db2`). v1.3.0 added `bin/compare_db_results.py` which is baked into the container at build time.

**v1.5.0:** `blast.sif` must be built before running `blast_verify.nf`. This is a new container.

**PathSeq offshoot (new):** `pathseq.sif` must be built before running `pathseq_verify.nf`. This is a new container (broadinstitute/gatk base image; bundles `bin/aggregate_pathseq.py`). Not required unless you're running the PathSeq offshoot — no change to existing outputs or runtime otherwise.
```bash
apptainer build --fakeroot --force containers/pathseq.sif containers/pathseq.def
rsync -avP containers/pathseq.sif maw210003@juno.hpcre.utdallas.edu:/groups/tprice/pipelines/containers/virome/
```

**v2.0.0 (new):** `host_quant.sif` is a new container (already built and smoke-tested locally: sambamba 0.6.6, bedtools 2.31.1, samtools 1.24, R 4.5.3 + Rsubread 2.24.0, htseq 2.1.2). `python.sif` was rebuilt to bake in `bin/aggregate_host_counts.py`. Neither is required unless `params.run_host_quant = true`. See "Host gene expression quantification (optional)" above for the Juno reference file setup (GTF, blacklist/exclude BED) and rsync commands — those still need to be run against Juno and haven't been done yet.

**2026-07-15 update:** the host-quant arm was smoke-tested for the first time ever (locally, WSL2, toy chr21 reference, full `nextflow run` orchestration — see `docs/tooling_progress_plan.md`) and two real bugs were found — both now fixed in the working tree, and both container images already rebuilt locally with the fixes baked in (just `rsync` them to Juno, no need to rebuild again unless your local `.sif` predates 2026-07-15):
- `bin/featurecounts_host.R` was missing a `#!/usr/bin/env Rscript` shebang, so `FEATURECOUNTS` (which invokes it as a bare command, not via explicit `Rscript`) would have failed on its first real run on Juno. Fixed; `host_quant.sif` already rebuilt locally with the fix.
- `assets/NO_FILE` (the sentinel placeholder for optional `path` inputs — `artifact_list`/`taxon_remap`/`gene_info`/`comparison_plot`/`host_expression_matrix`) never actually existed in the repo, which breaks `REPORT` (and would break the artifact/remap/gene-info disable paths) the moment `kraken2_db2` is unset. Every cohort config to date happens to always set `kraken2_db2`, which is why this was never hit in production. Fixed: a real 0-byte file now exists at `assets/NO_FILE`, git-tracked — no container rebuild needed for this one, just make sure the file is present in whatever checkout/deploy you're running from.

```bash
# Rebuild python.sif (for dual-DB main pipeline)
apptainer build --fakeroot --force containers/python.sif containers/python.def
rsync -avP containers/python.sif maw210003@juno.hpcre.utdallas.edu:/groups/tprice/pipelines/containers/virome/

# Build blast.sif (new — for BLAST verification offshoot)
apptainer build --fakeroot --force containers/blast.sif containers/blast.def
rsync -avP containers/blast.sif maw210003@juno.hpcre.utdallas.edu:/groups/tprice/pipelines/containers/virome/
```

**Optional intermediate file publishing (new params, both default false):**
- `save_kraken2_output: true` — publishes `{id}.kraken2.output` to `{outdir}/kraken2_output/`; required for BLAST offshoot without work-dir hunting
- `save_unmapped_reads: true` — publishes STAR-unmapped FASTQs to `{outdir}/star_unmapped/`; required for BLAST offshoot; WARNING: ~2 GB per sample, adds significant outdir size

## Framework Integration (Hyperion Compute v6.0.0)

Pinned to v1.4.0 in the parent HPC framework (mwilde49/hpc). Repo is ahead of that pin (now v1.5.0); update the submodule pointer when next deploying to Juno.

### Samplesheet in the HPC framework (v6.0.0)

The parent framework's samplesheet template (`templates/virome/samplesheet.csv`) has extended columns:
`sample,fastq_r1,fastq_r2,project_id,sample_id,library_id,run_id`

The `project_id`, `sample_id`, `library_id`, and `run_id` columns are Titan metadata fields.
They are read by `tjp-batch` and stored in PLR-xxxx records — they are NOT passed to Nextflow.
The `sample,fastq_r1,fastq_r2` portion IS the Nextflow native input and goes directly to `--input`.

### Batch mode

`tjp-batch virome samplesheet.csv` is per-sheet — one SLURM job for all rows.
The full samplesheet CSV is passed as `--input` to Nextflow. Nextflow handles per-sample parallelism.

### Titan metadata fields in config

The user config YAML may contain:
- `titan_project_id`, `titan_sample_id`, `titan_library_id`, `titan_run_id`

These are framework-level only. Do NOT consume them inside main.nf or nextflow.config.

### Direct Nextflow invocation (still supported)

Users can run this pipeline directly without the HPC framework:
```bash
nextflow run main.nf -profile slurm --input samplesheet.csv --outdir /scratch/...
```
The `project_id`/`sample_id` columns in the samplesheet are silently ignored by Nextflow's
`.splitCsv().map { row -> [row.sample, file(row.fastq_r1), file(row.fastq_r2)] }` pattern.
