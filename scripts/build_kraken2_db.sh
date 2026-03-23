#!/bin/bash
#SBATCH --job-name=kraken2_db
#SBATCH --partition=normal
#SBATCH --account=tprice
#SBATCH --cpus-per-task=4
#SBATCH --mem=16G
#SBATCH --time=02:00:00
#SBATCH --output=logs/kraken2_build_%j.log
#SBATCH --error=logs/kraken2_build_%j.err

# =============================================================================
# Download pre-built Kraken2 viral database (Langmead Lab / AWS)
#
# Avoids building from NCBI directly (rsync API is unreliable).
# Database is pre-built, tested, and updated regularly.
# Source: https://benlangmead.github.io/aws-indexes/k2
#
# Usage:
#   mkdir -p logs
#   sbatch scripts/build_kraken2_db.sh
#
# Output:
#   /groups/tprice/pipelines/references/kraken2_viral_db/
# =============================================================================

set -euo pipefail

module load apptainer

DB_DIR="/groups/tprice/pipelines/references/kraken2_viral_db"
DB_URL="https://genome-idx.s3.amazonaws.com/kraken/k2_viral_20240904.tar.gz"
TMP_DIR="/scratch/juno/${USER}/kraken2_db_tmp"

echo "=== Kraken2 DB Download ==="
echo "Job ID  : ${SLURM_JOB_ID}"
echo "Node    : $(hostname)"
echo "DB dir  : ${DB_DIR}"
echo "Source  : ${DB_URL}"
echo "Started : $(date)"
echo ""

mkdir -p "${DB_DIR}" "${TMP_DIR}"

TARBALL="${TMP_DIR}/k2_viral.tar.gz"

echo "[1/2] Downloading pre-built viral database (~500 MB)..."
wget --progress=dot:giga -O "${TARBALL}" "${DB_URL}"

echo "[2/2] Extracting to ${DB_DIR}..."
tar -xzf "${TARBALL}" -C "${DB_DIR}"

echo "Cleaning up temp files..."
rm -rf "${TMP_DIR}"

echo ""
echo "=== Download complete ==="
echo "Finished : $(date)"
echo "DB size  : $(du -sh ${DB_DIR} | cut -f1)"
echo "Contents :"
ls -lh "${DB_DIR}"
