#!/bin/bash
#SBATCH --job-name=finish_blast_nt_db
#SBATCH --partition=normal
#SBATCH --account=tprice
#SBATCH --cpus-per-task=8
#SBATCH --mem=32G
#SBATCH --time=24:00:00
#SBATCH --output=logs/finish_blast_nt_build_%j.log
#SBATCH --error=logs/finish_blast_nt_build_%j.err

# =============================================================================
# Finish setting up the NCBI BLAST nt database after build_blast_nt_db.sh.
#
# Real gotcha found 2026-09-25: `update_blastdb.pl --decompress` only
# decompresses files it downloads IN THAT INVOCATION. After several
# interrupted/timed-out download attempts across multiple sessions, all 365
# nt.NNN.tar.gz volumes were already present on disk, so a fresh
# `update_blastdb.pl` run saw "nothing new to fetch" and exited COMPLETED
# without ever decompressing the pre-existing archives or building the
# nt.nal alias file that ties all volumes into one queryable "nt" database.
# Confirmed via real blastn runs against this "COMPLETED" database: every
# BLAST_VERIFY task failed with "No alias or index file found for
# nucleotide database [blast_nt/nt]" (106T3L/109T3, 2026-09-25).
#
# This script does explicitly what update_blastdb.pl silently skipped:
# extract every remaining .tar.gz volume, then build nt.nal via
# blastdb_aliastool if a VALID one doesn't already exist.
#
# Usage:
#   sbatch scripts/finish_blast_nt_db.sh
#
# Safe to re-run: per-volume extraction is skipped if that volume's .nin
# already exists (not a blind re-extract of everything every time), and the
# alias step checks non-emptiness (-s), not just existence (-f) -- caught
# 2026-09-25 after a real run found a STALE, 0-byte nt.nal (dated
# 2026-09-16, long before this session, from some earlier abandoned setup
# attempt) that fooled a plain `-f` check into skipping the real build
# entirely. That run also died partway (likely OOM at the old 16GB request,
# from page-cache pressure decompressing ~1.6TB) -- bumped to 32GB.
# =============================================================================

set -uo pipefail  # NOT -e: a single volume's tar failure shouldn't kill the whole batch

module load apptainer

DB_DIR="/groups/tprice/pipelines/references/blast_nt"
CONTAINER="/groups/tprice/pipelines/containers/virome/blast.sif"

echo "=== Finish BLAST nt Database Setup (decompress + alias) ==="
echo "Job ID    : ${SLURM_JOB_ID}"
echo "Node      : $(hostname)"
echo "DB dir    : ${DB_DIR}"
echo "Started   : $(date)"
echo ""

cd "${DB_DIR}"

echo "[1/2] Extracting any .tar.gz volumes not already decompressed (${SLURM_CPUS_PER_TASK}-way parallel)..."
TODO=0
for f in *.tar.gz; do
    base="${f%.tar.gz}"
    if [ ! -f "${base}.nin" ]; then
        echo "${f}"
        TODO=$((TODO + 1))
    fi
done > /tmp/blast_nt_todo_${SLURM_JOB_ID}.txt
echo "${TODO} volumes still need extraction (already-decompressed ones skipped)"
xargs -a "/tmp/blast_nt_todo_${SLURM_JOB_ID}.txt" -P "${SLURM_CPUS_PER_TASK}" -n1 tar -xzf
EXTRACT_STATUS=$?
rm -f "/tmp/blast_nt_todo_${SLURM_JOB_ID}.txt"
echo "Extraction pass exit status: ${EXTRACT_STATUS} (nonzero means at least one volume failed -- check for corrupt downloads)"

echo ""
echo "[2/2] Checking for a VALID (non-empty) nt.nal alias file..."
if [ ! -s nt.nal ]; then
    if [ -f nt.nal ]; then
        echo "nt.nal exists but is EMPTY/stale (likely a leftover from an earlier abandoned attempt) -- rebuilding"
        rm -f nt.nal
    else
        echo "nt.nal not found -- building via blastdb_aliastool"
    fi
    VOLUMES=$(ls nt.*.nin 2>/dev/null | sed -E 's/\.nin$//' | sort | tr '\n' ' ')
    VOL_COUNT=$(echo "${VOLUMES}" | wc -w)
    echo "Found ${VOL_COUNT} volume index sets to alias together"
    apptainer exec "${CONTAINER}" blastdb_aliastool -dblist "${VOLUMES}" -dbtype nucl -out nt -title "nt"
else
    echo "nt.nal already present and non-empty -- leaving as-is"
fi

echo ""
echo "=== Done ==="
echo "Finished : $(date)"
echo "DB size  : $(du -sh ${DB_DIR} | cut -f1)"
if [ -s nt.nal ]; then
    echo "nt.nal confirmed present and non-empty -- database should be queryable now"
else
    echo "WARNING: nt.nal still missing/empty after this run -- something else is wrong, do not assume BLAST is ready"
fi
