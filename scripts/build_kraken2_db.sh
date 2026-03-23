#!/bin/bash
#SBATCH --job-name=kraken2_build
#SBATCH --partition=normal
#SBATCH --account=tprice
#SBATCH --cpus-per-task=16
#SBATCH --mem=64G
#SBATCH --time=08:00:00
#SBATCH --output=logs/kraken2_build_%j.log
#SBATCH --error=logs/kraken2_build_%j.err

# =============================================================================
# Build Kraken2 viral database from NCBI RefSeq
#
# Run once on Juno to populate the shared references directory.
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
THREADS=${SLURM_CPUS_PER_TASK:-16}
KRAKEN2_CONTAINER="/groups/tprice/pipelines/containers/virome/kraken2.sif"

echo "=== Kraken2 DB Build ==="
echo "Job ID  : ${SLURM_JOB_ID}"
echo "Node    : $(hostname)"
echo "DB dir  : ${DB_DIR}"
echo "Threads : ${THREADS}"
echo "Started : $(date)"
echo ""

mkdir -p "${DB_DIR}"

# Run all kraken2-build steps inside the container
apptainer exec \
    --cleanenv \
    --bind "${DB_DIR}:${DB_DIR}" \
    "${KRAKEN2_CONTAINER}" \
    bash -c "
        set -euo pipefail

        echo '[1/3] Downloading NCBI taxonomy...'
        kraken2-build --download-taxonomy --db ${DB_DIR}

        echo '[2/3] Downloading viral library from NCBI RefSeq...'
        kraken2-build --download-library viral --db ${DB_DIR}

        echo '[3/3] Building database (this is the slow step)...'
        kraken2-build \
            --build \
            --db ${DB_DIR} \
            --threads ${THREADS}

        echo 'Cleaning up intermediate files...'
        kraken2-build --clean --db ${DB_DIR}

        echo 'Done.'
    "

echo ""
echo "=== Build complete ==="
echo "Finished : $(date)"
echo "DB size  : $(du -sh ${DB_DIR} | cut -f1)"
