# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project

Nextflow DSL2 pipeline for systematic profiling of the human dorsal root ganglion (DRG) virome from paired-end bulk RNA-seq data. Runs on the Juno HPC cluster (UT Dallas, TJP group) via SLURM and Apptainer. Lives as a git submodule at `containers/virome` within `github.com/mwilde49/hpc`.

## Running the pipeline

```bash
# On Juno via the HPC framework (preferred)
tjp-launch virome

# Directly with Nextflow (SLURM)
nextflow run main.nf -profile slurm -params-file assets/config.yaml

# Locally (no SLURM)
nextflow run main.nf -profile standard \
  --samplesheet assets/samplesheet.csv \
  --outdir results \
  --star_index /path/to/star_index \
  --kraken2_db /path/to/kraken2_viral_db \
  --container_dir /path/to/containers/virome
```

## Building containers

Containers must be built before the pipeline runs. `.sif` files are gitignored.

```bash
# Build all containers locally (uses --fakeroot, no sudo needed)
bash scripts/build_containers_local.sh

# Build a single container
apptainer build --fakeroot containers/fastqc.sif containers/fastqc.def

# Build on Juno (SLURM job, uses --fakeroot)
sbatch scripts/build_containers.sh
# Or single container: sbatch scripts/build_containers.sh fastqc
```

After building locally, rsync to Juno:
```bash
rsync -avP containers/*.sif maw210003@juno.utdallas.edu:/groups/tprice/pipelines/containers/virome/
```

## Kraken2 viral database

Pre-built from Langmead Lab (AWS). Run once on Juno:
```bash
mkdir -p logs && sbatch scripts/build_kraken2_db.sh
```
Outputs to `/groups/tprice/pipelines/references/kraken2_viral_db/` (~1.1 GB).

## Architecture

**Data flow** (7 steps):
```
raw FASTQs → FASTQC → TRIMMOMATIC → STAR_HOST_REMOVAL → KRAKEN2_CLASSIFY → KRAKEN2_FILTER → AGGREGATE → REPORT
                                                                                           └──────────────→ MULTIQC
```

**Key architectural decisions:**
- `main.nf` only handles samplesheet parsing and channel creation. All logic is in `workflows/virome.nf`.
- Each process has its own container (per-step `.sif`). Container path is `${params.container_dir}/<tool>.sif` — never hardcoded.
- STAR is used for host removal (not a dedicated host-removal tool), leveraging the pre-existing GRCh38 index at `/groups/tprice/pipelines/references/star_index`. Unmapped reads from STAR are the input to Kraken2.
- `bin/` Python scripts (`filter_kraken2_report.py`, `aggregate_virome.py`, `virome_report.py`) are baked into `containers/python.sif` at build time via the `%files` section in `containers/python.def`. They must be rebuilt into the container whenever changed.
- The `python.def` `%files` paths are relative to the **repo root**, not the `containers/` directory. Always run `apptainer build` from the repo root.

**Samplesheet format** (CSV, required columns):
```
sample,fastq_r1,fastq_r2
```

**Profiles:**
- `slurm` — production use on Juno
- `standard` — local execution
- `test` — uses `conf/test.config` (not yet written; needed for Stage 2 testing)

## Cluster paths (Juno)

| Resource | Path |
|---|---|
| Shared pipeline root | `/groups/tprice/pipelines` |
| Virome submodule | `/groups/tprice/pipelines/containers/virome` |
| Container `.sif` files | `/groups/tprice/pipelines/containers/virome/*.sif` |
| STAR index (GRCh38) | `/groups/tprice/pipelines/references/star_index` |
| Kraken2 viral DB | `/groups/tprice/pipelines/references/kraken2_viral_db` |
| User workspace | `/work/$USER/pipelines/virome/` |

## Adding or modifying a module

1. Edit or create `modules/<name>.nf` — container directive must use `${params.container_dir}/<tool>.sif`
2. If adding a new tool, create `containers/<tool>.def` using a biocontainers or staphb Docker base image
3. Register the new process in `workflows/virome.nf`
4. Rebuild the container: `apptainer build --fakeroot containers/<tool>.sif containers/<tool>.def`
5. If modifying `bin/*.py` scripts, rebuild `python.sif` from repo root

## Testing plan (in progress)

- **Stage 1**: Container + syntax smoke test (no data)
- **Stage 2**: Single sample, synthetic data (~10k reads with planted viral sequences)
- **Stage 3**: Single real DRG sample
- **Stage 4**: Small cohort (3-5 samples, mixed type)

`conf/test.config` and synthetic test data generation script are not yet written.
