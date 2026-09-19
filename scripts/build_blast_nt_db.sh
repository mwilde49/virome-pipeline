#!/bin/bash
#SBATCH --job-name=blast_nt_db
#SBATCH --partition=normal
#SBATCH --account=tprice
#SBATCH --cpus-per-task=4
#SBATCH --mem=16G
#SBATCH --time=24:00:00
#SBATCH --output=logs/blast_nt_build_%j.log
#SBATCH --error=logs/blast_nt_build_%j.err

# =============================================================================
# Download the full NCBI BLAST nt database, required by blast_verify.nf.
#
# One-time setup, documented in CLAUDE.md's "BLAST verification offshoot"
# section but never actually run — /groups/tprice/pipelines/references/blast_nt/
# is confirmed empty on Juno (checked 2026-09-18), which is why every BLAST
# offshoot run to date (including the PD19 config) has never been able to
# complete.
#
# nt is large (~300+ GB as of 2026) and downloads as many volume files over
# NCBI's rsync mirror — this can take many hours depending on bandwidth and
# NCBI-side throttling. 24h walltime here is a starting guess, not a
# guarantee; if the job times out before finishing, `update_blastdb.pl` is
# resumable — just re-submit and it will pick up remaining/partial volumes
# rather than restarting from scratch. Check actual QOS wall-time limits
# (see virome/docs/juno_hpc_operations_guide.md) before assuming 24h is
# actually available in one submission.
#
# Runs via containers/blast.sif, which bundles the NCBI BLAST+ toolkit
# (update_blastdb.pl is part of blast+, alongside blastn/makeblastdb used
# elsewhere in the BLAST offshoot).
#
# Usage:
#   mkdir -p logs
#   sbatch scripts/build_blast_nt_db.sh
#
# Output:
#   /groups/tprice/pipelines/references/blast_nt/
# =============================================================================

set -euo pipefail

module load apptainer

DB_DIR="/groups/tprice/pipelines/references/blast_nt"
CONTAINER="/groups/tprice/pipelines/containers/virome/blast.sif"

echo "=== BLAST nt Database Download ==="
echo "Job ID    : ${SLURM_JOB_ID}"
echo "Node      : $(hostname)"
echo "DB dir    : ${DB_DIR}"
echo "Container : ${CONTAINER}"
echo "Started   : $(date)"
echo ""

mkdir -p "${DB_DIR}"
cd "${DB_DIR}"

echo "[1/1] Downloading + decompressing nt (this will take a while)..."
apptainer exec "${CONTAINER}" update_blastdb.pl --decompress --num_threads "${SLURM_CPUS_PER_TASK}" nt

echo ""
echo "=== Download complete ==="
echo "Finished : $(date)"
echo "DB size  : $(du -sh ${DB_DIR} | cut -f1)"
echo "Contents :"
ls -lh "${DB_DIR}" | head -20
