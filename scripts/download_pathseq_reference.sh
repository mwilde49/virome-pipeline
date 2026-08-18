#!/bin/bash
#SBATCH --job-name=pathseq_ref_download
#SBATCH --account=tprice
#SBATCH --cpus-per-task=2
#SBATCH --mem=4G
#SBATCH --output=logs/pathseq_ref_download_%j.log
#SBATCH --error=logs/pathseq_ref_download_%j.err
#
# --partition/--time not set here -- pass them at submit time from real
# `bash scripts/check_partitions.sh` output, e.g.:
#   sbatch --partition=<name> --time=<value> scripts/download_pathseq_reference.sh

# =============================================================================
# Pull the GATK PathSeq microbe reference bundle ("Path A" from
# docs/pathseq_and_test_datasets_2026-08-14.md) -- the pre-built, if stale
# (RefSeq release 81 / April 2017), microbe BWA index + taxonomy DB. Confirmed
# HSV-1 (taxid 10298) is present. Deliberately SKIPS the ~26 GB host
# k-mer/BWA bundle -- not needed, PATHSEQ_SCORE runs on already
# STAR-host-depleted input (see CLAUDE.md's "PathSeq verification offshoot"
# section for why).
#
# Verified real file sizes (live GCS bucket listing, 2026-08-14):
#   pathseq_microbe.tar.gz    94.6 GB
#   pathseq_taxonomy.tar.gz    6.7 MB
#
# Usage:
#   mkdir -p logs
#   sbatch --partition=<name> --time=<value> scripts/download_pathseq_reference.sh
#
# Output:
#   /groups/tprice/pipelines/references/pathseq/
#
# After it finishes, `ls` the extracted contents (printed at the end of this
# script's log too) and set nextflow.config's three PathSeq params --
# pathseq_microbe_bwa_image / pathseq_microbe_fasta / pathseq_taxonomy -- to
# the real extracted filenames (the exact names inside the tarball were not
# independently verified before this script was written -- confirm from the
# actual `ls -la` output below rather than guessing).
# =============================================================================

set -euo pipefail

REF_DIR="/groups/tprice/pipelines/references/pathseq"
BASE_URL="https://storage.googleapis.com/gatk-best-practices/pathseq/resources"

echo "=== PathSeq Reference Bundle Download (Path A) ==="
echo "Job ID  : ${SLURM_JOB_ID:-manual}"
echo "Node    : $(hostname)"
echo "Ref dir : ${REF_DIR}"
echo "Started : $(date)"
echo ""

mkdir -p "${REF_DIR}"
cd "${REF_DIR}"

download() {
    local NAME=$1
    if [[ -f "${NAME}" ]]; then
        echo "[skip] ${NAME} already present ($(du -h "${NAME}" | cut -f1))"
        return 0
    fi
    echo "[download] ${NAME}"
    # -C - resumes a partial download rather than restarting from 0 --
    # important for the 94.6 GB microbe bundle specifically.
    curl -fSL --retry 5 --retry-delay 15 -C - -o "${NAME}" "${BASE_URL}/${NAME}"
}

echo "[1/2] Taxonomy bundle (6.7 MB, fast)"
download "pathseq_taxonomy.tar.gz"
tar xzf pathseq_taxonomy.tar.gz

echo ""
echo "[2/2] Microbe reference bundle (94.6 GB -- this is the long part)"
download "pathseq_microbe.tar.gz"
tar xzf pathseq_microbe.tar.gz

echo ""
echo "=== Download + extraction complete ==="
echo "Finished : $(date)"
echo "Total size: $(du -sh "${REF_DIR}" | cut -f1)"
echo ""
echo "Extracted contents (map these real filenames to nextflow.config's"
echo "pathseq_microbe_bwa_image / pathseq_microbe_fasta / pathseq_taxonomy):"
ls -la "${REF_DIR}"
