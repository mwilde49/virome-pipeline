#!/bin/bash
# =============================================================================
# Build all virome Apptainer containers locally and rsync to Juno
#
# Usage:
#   bash scripts/build_containers_local.sh
#
# Requires:
#   - apptainer (installed)
#   - sudo access (for apptainer build)
#   - SSH access to Juno (for rsync; uses your configured SSH key)
# =============================================================================

set -euo pipefail

REPO_DIR="$(realpath "$(dirname "$0")/..")"
SIF_DIR="${REPO_DIR}/containers"
JUNO_USER="maw210003"
JUNO_HOST="juno.hpcre.utdallas.edu"
JUNO_DEST="/groups/tprice/pipelines/containers/virome"

CONTAINERS=(fastqc trimmomatic star kraken2 python multiqc)

log() { echo "[$(date '+%H:%M:%S')] $*"; }

cd "${REPO_DIR}"

# ---------------------------------------------------------------------------
# Build
# ---------------------------------------------------------------------------
log "=== Building containers ==="

for name in "${CONTAINERS[@]}"; do
    def="${SIF_DIR}/${name}.def"
    sif="${SIF_DIR}/${name}.sif"

    if [[ -f "${sif}" ]]; then
        log "SKIP ${name}.sif (already exists — delete to rebuild)"
        continue
    fi

    log "Building ${name}.sif ..."
    apptainer build --fakeroot "${sif}" "${def}"
    log "Done: ${name}.sif ($(du -sh "${sif}" | cut -f1))"
done

log ""
log "=== All containers built ==="
du -sh "${SIF_DIR}"/*.sif

# ---------------------------------------------------------------------------
# Transfer to Juno
# ---------------------------------------------------------------------------
log ""
log "=== Syncing to Juno: ${JUNO_USER}@${JUNO_HOST}:${JUNO_DEST} ==="

ssh "${JUNO_USER}@${JUNO_HOST}" "mkdir -p ${JUNO_DEST}"

rsync -avP --no-perms \
    "${SIF_DIR}"/*.sif \
    "${JUNO_USER}@${JUNO_HOST}:${JUNO_DEST}/"

log ""
log "=== Transfer complete ==="
log "Containers are ready at ${JUNO_DEST} on Juno."
log "Next: sbatch scripts/build_kraken2_db.sh"
