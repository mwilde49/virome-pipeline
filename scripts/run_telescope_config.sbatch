#!/bin/bash
#SBATCH --job-name=nextflow_telescope
#SBATCH --account=tprice
#SBATCH --qos=juno-pri
#SBATCH --partition=normal
#SBATCH --cpus-per-task=2
#SBATCH --mem=4G
#SBATCH --time=48:00:00
#SBATCH --output=/scratch/juno/%u/logs/nextflow_telescope_%j.log
#SBATCH --error=/scratch/juno/%u/logs/nextflow_telescope_%j.log

# ── Usage ─────────────────────────────────────────────────────────────────────
# Sibling to run_virome_config.sbatch, for the Telescope offshoot
# (telescope_verify.nf) instead of the main pipeline. This wrapper's own
# #SBATCH resources are for the Nextflow HEAD process only (light — it just
# orchestrates); the actual heavy work (STAR_REALIGN_MULTIMAP,
# TELESCOPE_ASSIGN) is submitted as separate SLURM sub-jobs by Nextflow's
# slurm executor, sized per conf/base.config's withName overrides.
#
# NOTE: hpcdark's `submit` verb cannot be used for this -- it dispatches
# through tjp-launch, which always runs main.nf for the "virome" pipeline
# name regardless of config content. This script is a direct
# `nextflow run telescope_verify.nf` invocation instead, launched by hand.
#
#   sbatch --job-name=telescope_<cohort> scripts/run_telescope_config.sbatch \
#       assets/config_telescope_<cohort>.yaml [extra nextflow args]
#
# Example (Phase 2 pilot -- one real sample, Iadorola TG12):
#   sbatch --job-name=telescope_tg12_pilot scripts/run_telescope_config.sbatch \
#       assets/config_telescope_iadorola_tg12_pilot.yaml
# ─────────────────────────────────────────────────────────────────────────────

set -euo pipefail

CONFIG="${1:?Usage: sbatch run_telescope_config.sbatch <params-file.yaml> [extra nextflow args]}"
shift 1  # remaining args passed through to nextflow

PIPELINE_DIR="/groups/tprice/pipelines/containers/virome"
NF_BIN="/groups/tprice/pipelines/bin/nextflow"

export NXF_JVM_ARGS="-Xms256m -Xmx2g"

mkdir -p "/scratch/juno/${USER}/logs"

echo "=== Telescope offshoot (params-file mode) ==="
echo "Job ID:  ${SLURM_JOB_ID}"
echo "Host:    $(hostname)"
echo "Config:  ${CONFIG}"
echo "Started: $(date)"
echo ""

cd "${PIPELINE_DIR}"

"${NF_BIN}" run telescope_verify.nf \
    -profile slurm \
    -params-file "${CONFIG}" \
    "$@"

echo ""
echo "Finished: $(date)"
