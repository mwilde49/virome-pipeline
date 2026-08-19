#!/bin/bash
#SBATCH --job-name=nextflow_pathseq
#SBATCH --account=tprice
#SBATCH --qos=juno-pri
#SBATCH --partition=normal
#SBATCH --cpus-per-task=2
#SBATCH --mem=4G
#SBATCH --time=48:00:00
#SBATCH --output=/scratch/juno/%u/logs/nextflow_pathseq_%j.log
#SBATCH --error=/scratch/juno/%u/logs/nextflow_pathseq_%j.log

# ── Usage ─────────────────────────────────────────────────────────────────────
# Sibling to scripts/run_virome_config.sbatch, for pathseq_verify.nf instead of
# main.nf. This job itself stays lightweight (4G/2cpu -- it's just the Nextflow
# head process); the actual heavy PATHSEQ_SCORE resource allocation (200 GB /
# 32 cpu / up to 48h per sample, conf/base.config) is applied automatically by
# the slurm executor when it submits that specific process's own child job.
#
#   sbatch --job-name=pathseq_<cohort> [--dependency=afterany:<main_job_id>] \
#       scripts/run_pathseq_config.sbatch assets/config_pathseq_<cohort>.yaml [extra nextflow args]
#
# Example (chain a cohort's PathSeq run behind its own main-pipeline job):
#   sbatch --job-name=pathseq_thoracic_drg --dependency=afterany:337XXX \
#       scripts/run_pathseq_config.sbatch assets/config_pathseq_thoracic_drg.yaml
#
# PREREQUISITE: the main pipeline run for this cohort must have completed with
# save_unmapped_reads: true in effect (see assets/config_<cohort>_titan.yaml)
# so ${outdir}/star_unmapped/ is actually populated -- pathseq_verify.nf's
# samplesheet-parsing checkIfExists will fail immediately otherwise, same
# failure mode as the original Titan-not-on-compute-nodes issue.
# ─────────────────────────────────────────────────────────────────────────────

set -euo pipefail

CONFIG="${1:?Usage: sbatch run_pathseq_config.sbatch <params-file.yaml> [extra nextflow args]}"
shift 1  # remaining args passed through to nextflow

PIPELINE_DIR="/groups/tprice/pipelines/containers/virome"
NF_BIN="/groups/tprice/pipelines/bin/nextflow"

export NXF_JVM_ARGS="-Xms512m -Xmx2g"

mkdir -p "/scratch/juno/${USER}/logs"

echo "=== PathSeq verification offshoot (params-file mode) ==="
echo "Job ID:  ${SLURM_JOB_ID}"
echo "Host:    $(hostname)"
echo "Config:  ${CONFIG}"
echo "Started: $(date)"
echo ""

cd "${PIPELINE_DIR}"

"${NF_BIN}" run pathseq_verify.nf \
    -profile slurm \
    -params-file "${CONFIG}" \
    "$@"

echo ""
echo "Finished: $(date)"
