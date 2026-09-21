#!/bin/bash
#SBATCH --job-name=nextflow_blast
#SBATCH --account=tprice
#SBATCH --qos=juno-pri
#SBATCH --partition=normal
#SBATCH --cpus-per-task=2
#SBATCH --mem=4G
#SBATCH --time=48:00:00
#SBATCH --output=/scratch/juno/%u/logs/nextflow_blast_%j.log
#SBATCH --error=/scratch/juno/%u/logs/nextflow_blast_%j.log

# ── Usage ─────────────────────────────────────────────────────────────────────
# Sibling to run_virome_config.sbatch / run_telescope_config.sbatch, for the
# BLAST verification offshoot (blast_verify.nf) instead of the main pipeline
# or the Telescope offshoot. This wrapper's own #SBATCH resources are for the
# Nextflow HEAD process only (light -- it just orchestrates); the actual
# heavy work (BLAST_VERIFY against the nt database, etc.) is submitted as
# separate SLURM sub-jobs by Nextflow's slurm executor, sized per
# conf/base.config's withName overrides.
#
# NOTE: hpcdark's `submit` verb cannot be used for this -- it dispatches
# through tjp-launch, which always runs main.nf for the "virome" pipeline
# name regardless of config content. This script is a direct
# `nextflow run blast_verify.nf` invocation instead, launched by hand.
#
#   sbatch --job-name=blast_<candidate> scripts/run_blast_config.sbatch \
#       assets/config_blast_<candidate>.yaml [extra nextflow args]
#
# Example (Molluscum contagiosum + AAV, the only sample carrying both):
#   sbatch --job-name=blast_109T3 scripts/run_blast_config.sbatch \
#       assets/config_blast_109T3.yaml
# ─────────────────────────────────────────────────────────────────────────────

set -euo pipefail

CONFIG="${1:?Usage: sbatch run_blast_config.sbatch <params-file.yaml> [extra nextflow args]}"
shift 1  # remaining args passed through to nextflow

PIPELINE_DIR="/groups/tprice/pipelines/containers/virome"
NF_BIN="/groups/tprice/pipelines/bin/nextflow"

export NXF_JVM_ARGS="-Xms256m -Xmx2g"

mkdir -p "/scratch/juno/${USER}/logs"

echo "=== BLAST verification offshoot (params-file mode) ==="
echo "Job ID:  ${SLURM_JOB_ID}"
echo "Host:    $(hostname)"
echo "Config:  ${CONFIG}"
echo "Started: $(date)"
echo ""

cd "${PIPELINE_DIR}"

"${NF_BIN}" run blast_verify.nf \
    -profile slurm \
    -params-file "${CONFIG}" \
    "$@"

echo ""
echo "Finished: $(date)"
