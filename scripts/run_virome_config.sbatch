#!/bin/bash
#SBATCH --job-name=nextflow_virome
#SBATCH --account=tprice
#SBATCH --qos=juno-pri
#SBATCH --partition=normal
#SBATCH --cpus-per-task=2
#SBATCH --mem=4G
#SBATCH --time=48:00:00
#SBATCH --output=/scratch/juno/%u/logs/nextflow_virome_%j.log
#SBATCH --error=/scratch/juno/%u/logs/nextflow_virome_%j.log

# ── Usage ─────────────────────────────────────────────────────────────────────
# Sibling to run_virome.sbatch, for the -params-file YAML config pattern
# (assets/config_*.yaml) instead of run_virome.sbatch's positional
# <outdir> <samplesheet> pair -- keeps every param a config specifies
# (kraken2_db2, taxon_remap, min_reads, trim_*, kraken2_confidence,
# bracken_read_len/level, run_host_quant, etc.) instead of hardcoding a
# subset as flags. The Nextflow head process runs AS the SLURM job itself,
# so this survives disconnection same as everything else this batch used
# tmux for -- submit and walk away, check squeue/logs later.
#
#   sbatch --job-name=virome_<cohort> scripts/run_virome_config.sbatch \
#       assets/config_<cohort>_titan.yaml [extra nextflow args]
#
# Example (one real cohort from the 2026-08-18 gataca->Titan batch):
#   sbatch --job-name=virome_watchmaker scripts/run_virome_config.sbatch \
#       assets/config_watchmaker_titan.yaml
#
# --job-name on the sbatch command line overrides the #SBATCH default above,
# so squeue -u $USER shows which cohort each job is, without editing this
# file per cohort.
# ─────────────────────────────────────────────────────────────────────────────

set -euo pipefail

CONFIG="${1:?Usage: sbatch run_virome_config.sbatch <params-file.yaml> [extra nextflow args]}"
shift 1  # remaining args passed through to nextflow

PIPELINE_DIR="/groups/tprice/pipelines/containers/virome"
NF_BIN="/groups/tprice/pipelines/bin/nextflow"

export NXF_JVM_ARGS="-Xms256m -Xmx2g"

mkdir -p "/scratch/juno/${USER}/logs"

echo "=== Virome pipeline (params-file mode) ==="
echo "Job ID:  ${SLURM_JOB_ID}"
echo "Host:    $(hostname)"
echo "Config:  ${CONFIG}"
echo "Started: $(date)"
echo ""

cd "${PIPELINE_DIR}"

"${NF_BIN}" run main.nf \
    -profile slurm \
    -params-file "${CONFIG}" \
    "$@"

echo ""
echo "Finished: $(date)"
