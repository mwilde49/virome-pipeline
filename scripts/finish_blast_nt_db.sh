#!/bin/bash
#SBATCH --job-name=finish_blast_nt_db
#SBATCH --partition=normal
#SBATCH --account=tprice
#SBATCH --cpus-per-task=8
#SBATCH --mem=16G
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
# blastdb_aliastool if it wasn't bundled in one of the archives.
#
# Usage:
#   sbatch scripts/finish_blast_nt_db.sh
#
# Safe to re-run: tar -xzf on an already-extracted volume is a harmless
# no-op overwrite, and the nt.nal check only builds the alias if missing.
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

REMAINING=$(find . -maxdepth 1 -name '*.tar.gz' | wc -l)
echo "[1/2] Extracting ${REMAINING} remaining .tar.gz volumes (${SLURM_CPUS_PER_TASK}-way parallel)..."
find . -maxdepth 1 -name '*.tar.gz' -print0 | xargs -0 -P "${SLURM_CPUS_PER_TASK}" -n1 tar -xzf
EXTRACT_STATUS=$?
echo "Extraction pass exit status: ${EXTRACT_STATUS} (nonzero means at least one volume failed -- check for corrupt downloads)"

echo ""
echo "[2/2] Checking for nt.nal alias file..."
if [ ! -f nt.nal ]; then
    echo "nt.nal not found after extraction -- building manually via blastdb_aliastool"
    VOLUMES=$(ls nt.*.nin 2>/dev/null | sed -E 's/\.nin$//' | sort | tr '\n' ' ')
    VOL_COUNT=$(echo "${VOLUMES}" | wc -w)
    echo "Found ${VOL_COUNT} volume index sets to alias together"
    apptainer exec "${CONTAINER}" blastdb_aliastool -dblist "${VOLUMES}" -dbtype nucl -out nt -title "nt"
else
    echo "nt.nal already present (was bundled in a volume archive)"
fi

echo ""
echo "=== Done ==="
echo "Finished : $(date)"
echo "DB size  : $(du -sh ${DB_DIR} | cut -f1)"
if [ -f nt.nal ]; then
    echo "nt.nal confirmed present -- database should be queryable now"
else
    echo "WARNING: nt.nal still missing after this run -- something else is wrong, do not assume BLAST is ready"
fi
