# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project

Nextflow DSL2 pipeline for systematic profiling of the human dorsal root ganglion (DRG) virome from paired-end bulk RNA-seq data. Runs on the Juno HPC cluster (UT Dallas, TJP group) via SLURM and Apptainer. Lives as a git submodule at `containers/virome` within `github.com/mwilde49/hpc`.

Current version: **1.2.1** — artifact list expanded to 24 entries; added Orthohantavirus oxbowense (3052491) and Oxbow virus (660954) confirmed as k-mer cross-mapping artifact by per-read Kraken2 analysis across all cohorts and tissue types.

## Running the pipeline

```bash
# On Juno via the HPC framework (preferred)
tjp-launch virome

# Directly with Nextflow (SLURM)
export NXF_JVM_ARGS="-Xms256m -Xmx512m"   # required on Juno login nodes
nextflow run main.nf -profile slurm -params-file assets/config.yaml

# Locally (no SLURM)
nextflow run main.nf -profile standard \
  --samplesheet assets/samplesheet.csv \
  --outdir results \
  --star_index /path/to/star_index \
  --kraken2_db /path/to/kraken2_viral_db \
  --container_dir /path/to/containers/virome
```

Always set `NXF_JVM_ARGS="-Xms256m -Xmx512m"` on Juno — the login node has limited memory and the JVM will OOM without it.

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

**Data flow** (v0.3.0, 7 steps + multi-stage aggregation):
```
raw FASTQs → FASTQC → TRIMMOMATIC → STAR_HOST_REMOVAL → KRAKEN2_CLASSIFY → BRACKEN → KRAKEN2_FILTER ─┬→ AGGREGATE(final)       ─┐
                                                                                                       ├→ AGGREGATE(minreads)    ─┼→ REPORT
                                                                                                       └→ AGGREGATE(bracken_raw) ─┘
                                                                                      └──────────────────────────────────────────→ MULTIQC
```

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

**Key architectural decisions:**

- `main.nf` only handles samplesheet parsing and channel creation. All logic is in `workflows/virome.nf`.
- Each process has its own container (`${params.container_dir}/<tool>.sif`). Never hardcoded.
- STAR is used for host removal using the pre-existing GRCh38 index. Unmapped reads feed Kraken2.
- `bin/*.py` scripts are baked into `containers/python.sif` at build time via `%files`. Rebuild the container whenever scripts change. Always run `apptainer build` from the repo root (paths in `%files` are relative to the build invocation directory).
- `stageInMode = 'copy'` is set in `conf/base.config` — required because Apptainer with `--cleanenv` cannot follow symlinks across work directories.
- `module load apptainer` is in `conf/slurm.config`'s `beforeScript` — required on Juno compute nodes.
- `NXF_JVM_ARGS` must be set before running Nextflow on the login node.
- Nextflow is installed at `/groups/tprice/pipelines/bin/nextflow` (not a module).

**Samplesheet format** (CSV, required columns):
```
sample,fastq_r1,fastq_r2
```

**Abundance matrix format** (output):
- `taxon_id`, `taxon_name`, `rank` — taxonomy columns
- `<sample>_reads` — raw Kraken2 direct read counts per sample
- `<sample>_rpm` — reads per million trimmed reads (normalized via STAR input read count)

**Artifact exclusion:**
`assets/artifact_taxa.tsv` — curated TSV of taxon IDs to exclude from all samples. 22 entries covering: ruminant orthobunyaviruses, insect baculoviruses, phages, environmental metagenome viruses (DRG k-mer cross-mapping), avian herpesviruses, and giant amoeba viruses. Enabled by default via `params.artifact_list`. Set to `null` to disable.

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
- **PathSeq validation module** — optional GATK PathSeq step for orthogonal validation of high-confidence hits; stub exists in params (`run_pathseq`)
- **Reference augmentation** — re-map Kraken2 hits back to viral reference genomes using minimap2 for depth-of-coverage validation; add human CMV strain diversity (Toledo, TB40/E) to database to fix HHV-5 cross-mapping at source
- **Cohort-level statistical module** — DESeq2-style differential abundance testing between sample groups (neuropathy vs. control, donor vs. cultured)

### Longer-term
- **Metadata integration** — accept a metadata TSV (sample type, neuropathy status, donor ID) and incorporate into report groupings and plots
- **Assembly-based discovery** — de novo viral assembly on host-depleted reads using SPAdes/MEGAHIT for detection of novel/divergent viruses below Kraken2's k-mer threshold
- **Multi-database classification** — run against both viral and complete standard Kraken2 DB to catch non-viral contaminants and improve specificity
- **Longitudinal tracking** — compare virome profiles across timepoints for the same donor
