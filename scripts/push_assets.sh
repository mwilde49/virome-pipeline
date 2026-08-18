#!/bin/bash
# =============================================================================
# Push virome pipeline assets (samplesheets, configs) from local repo to Juno
#
# Run this after adding or editing any file under assets/ so Juno is in sync
# before launching a pipeline run.
#
# Usage:
#   bash scripts/push_assets.sh
# =============================================================================

set -euo pipefail

JUNO_USER="maw210003"
JUNO_HOST="juno.hpcre.utdallas.edu"
JUNO_PIPELINE="/groups/tprice/pipelines/containers/virome"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "${SCRIPT_DIR}")"

echo "Pushing assets → ${JUNO_USER}@${JUNO_HOST}:${JUNO_PIPELINE}/assets/"
echo ""

rsync -avP --no-perms --no-owner --no-group \
    "${REPO_ROOT}/assets/" \
    "${JUNO_USER}@${JUNO_HOST}:${JUNO_PIPELINE}/assets/"

echo ""
echo "Done. Assets are up to date on Juno."
