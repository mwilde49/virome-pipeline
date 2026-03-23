#!/bin/bash
#SBATCH --job-name=virome_containers
#SBATCH --partition=normal
#SBATCH --account=tprice
#SBATCH --cpus-per-task=4
#SBATCH --mem=16G
#SBATCH --time=02:00:00
#SBATCH --output=logs/build_containers_%j.log
#SBATCH --error=logs/build_containers_%j.err

# =============================================================================
# Build all Apptainer containers for the virome pipeline
#
# Requires fakeroot (ask your sysadmin to enable it for your user if not set).
# Run once, or re-run when a container definition changes.
#
# Usage:
#   mkdir -p logs
#   sbatch scripts/build_containers.sh
#
# Optional — build a single container only:
#   sbatch scripts/build_containers.sh fastqc
#
# Output:
#   /groups/tprice/pipelines/containers/virome/<tool>.sif
# =============================================================================

set -euo pipefail

CONTAINER_DIR="/groups/tprice/pipelines/containers/virome"
DEF_DIR="$(realpath "$(dirname "$0")/../containers")"

# If a specific container name is passed as argument, build only that one
TARGET="${1:-all}"

mkdir -p "${CONTAINER_DIR}"
mkdir -p logs

CONTAINERS=(fastqc trimmomatic star kraken2 python multiqc)

build_container() {
    local name="$1"
    local def="${DEF_DIR}/${name}.def"
    local sif="${CONTAINER_DIR}/${name}.sif"

    if [[ ! -f "${def}" ]]; then
        echo "ERROR: Definition file not found: ${def}"
        return 1
    fi

    echo ""
    echo "--- Building ${name} ---"
    echo "  def : ${def}"
    echo "  sif : ${sif}"
    echo "  time: $(date)"

    apptainer build --fakeroot "${sif}" "${def}"

    echo "  done: $(date) | size: $(du -sh "${sif}" | cut -f1)"
}

echo "=== Virome Container Build ==="
echo "Job ID       : ${SLURM_JOB_ID:-local}"
echo "Node         : $(hostname)"
echo "Container dir: ${CONTAINER_DIR}"
echo "Started      : $(date)"

if [[ "${TARGET}" == "all" ]]; then
    for name in "${CONTAINERS[@]}"; do
        build_container "${name}"
    done
else
    build_container "${TARGET}"
fi

echo ""
echo "=== All builds complete ==="
echo "Finished : $(date)"
echo "Contents :"
ls -lh "${CONTAINER_DIR}"
