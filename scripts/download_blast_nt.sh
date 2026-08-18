#!/bin/bash
#SBATCH --job-name=blast_nt_download
#SBATCH --partition=normal
#SBATCH --account=tprice
#SBATCH --cpus-per-task=4
#SBATCH --mem=16G
#SBATCH --time=24:00:00
#SBATCH --output=logs/blast_nt_download_%j.log
#SBATCH --error=logs/blast_nt_download_%j.err

# =============================================================================
# Download and decompress the NCBI BLAST nt database
#
# Uses update_blastdb.pl from inside blast.sif (BLAST+ container).
# Full nt database: ~100 volumes, ~250 GB compressed, ~500 GB decompressed.
# Requires 24h time limit — previous attempts with shorter limits timed out.
#
# Usage:
#   mkdir -p logs
#   sbatch scripts/download_blast_nt.sh
#
# Output:
#   /groups/tprice/pipelines/references/blast_nt/
#
# Verify completion:
#   ls /groups/tprice/pipelines/references/blast_nt/*.nsi
# =============================================================================

set -euo pipefail

module load apptainer

BLAST_SIF="/groups/tprice/pipelines/containers/virome/blast.sif"
DB_DIR="/groups/tprice/pipelines/references/blast_nt"

echo "=== BLAST nt Database Download ==="
echo "Job ID  : ${SLURM_JOB_ID}"
echo "Node    : $(hostname)"
echo "DB dir  : ${DB_DIR}"
echo "Started : $(date)"
echo ""

mkdir -p "${DB_DIR}"

echo "[1/1] Downloading and decompressing nt database (~250 GB compressed)..."
echo "      This will take many hours. Monitor with:"
echo "      ls ${DB_DIR} | wc -l"
echo ""

apptainer exec --bind /groups,/scratch "${BLAST_SIF}" bash -c "
    mkdir -p '${DB_DIR}' && \
    cd '${DB_DIR}' && \
    update_blastdb.pl --decompress --num_threads 4 nt
"

echo ""
echo "=== Download complete ==="
echo "Finished : $(date)"
echo "DB size  : $(du -sh ${DB_DIR} | cut -f1)"
echo "Volumes  : $(ls ${DB_DIR}/*.nsi 2>/dev/null | wc -l) index files"
echo "Contents :"
ls -lh "${DB_DIR}"/*.nsi 2>/dev/null | head -10
