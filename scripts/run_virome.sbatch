#!/bin/bash
#SBATCH --job-name=nextflow_virome
#SBATCH --account=tprice
#SBATCH --partition=normal
#SBATCH --cpus-per-task=2
#SBATCH --mem=4G
#SBATCH --time=48:00:00
#SBATCH --output=/scratch/juno/%u/logs/nextflow_virome_%j.log
#SBATCH --error=/scratch/juno/%u/logs/nextflow_virome_%j.log

# ── Usage ─────────────────────────────────────────────────────────────────────
# sbatch scripts/run_virome.sbatch <outdir> <samplesheet> [extra nextflow args]
#
# Examples:
#   sbatch scripts/run_virome.sbatch /scratch/juno/maw210003/virome_muscle \
#       samplesheets/muscle_test_cohort.csv
#   sbatch scripts/run_virome.sbatch /scratch/juno/maw210003/virome_drg \
#       samplesheets/drg_donor1.csv -resume
# ─────────────────────────────────────────────────────────────────────────────

set -euo pipefail

OUTDIR="${1:?Usage: sbatch run_virome.sbatch <outdir> <samplesheet> [extra nextflow args]}"
SAMPLESHEET="${2:?Usage: sbatch run_virome.sbatch <outdir> <samplesheet> [extra nextflow args]}"
shift 2  # remaining args passed through to nextflow

PIPELINE_DIR="/groups/tprice/pipelines/containers/virome"
NF_BIN="/groups/tprice/pipelines/bin/nextflow"

export NXF_JVM_ARGS="-Xms256m -Xmx2g"

mkdir -p "/scratch/juno/${USER}/logs"

echo "=== Virome pipeline ==="
echo "Job ID:      ${SLURM_JOB_ID}"
echo "Host:        $(hostname)"
echo "Outdir:      ${OUTDIR}"
echo "Samplesheet: ${SAMPLESHEET}"
echo "Started:     $(date)"
echo ""

cd "${PIPELINE_DIR}"

"${NF_BIN}" run main.nf \
    -profile slurm \
    --samplesheet "${SAMPLESHEET}" \
    --outdir      "${OUTDIR}" \
    --star_index  /groups/tprice/pipelines/references/star_index \
    --kraken2_db  /groups/tprice/pipelines/references/kraken2_viral_db \
    --container_dir "${PIPELINE_DIR}" \
    --artifact_list "${PIPELINE_DIR}/assets/artifact_taxa.tsv" \
    "$@"

echo ""
echo "Finished: $(date)"
