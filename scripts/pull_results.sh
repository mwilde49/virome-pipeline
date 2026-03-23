#!/bin/bash
# =============================================================================
# Pull virome pipeline results from Juno to local machine
#
# Usage:
#   bash scripts/pull_results.sh <juno_outdir> <local_outdir>
#
# Examples:
#   bash scripts/pull_results.sh /scratch/juno/maw210003/virome_test results/single_sample
#   bash scripts/pull_results.sh /scratch/juno/maw210003/virome_test_cohort results/muscle_cohort
# =============================================================================

set -euo pipefail

JUNO_USER="maw210003"
JUNO_HOST="juno.utdallas.edu"
JUNO_OUTDIR="${1:?Usage: pull_results.sh <juno_outdir> <local_outdir>}"
LOCAL_OUTDIR="${2:?Usage: pull_results.sh <juno_outdir> <local_outdir>}"

mkdir -p "${LOCAL_OUTDIR}"

echo "Pulling from ${JUNO_USER}@${JUNO_HOST}:${JUNO_OUTDIR}"
echo "        into ${LOCAL_OUTDIR}"
echo ""

rsync -avP --no-perms --no-owner --no-group \
    "${JUNO_USER}@${JUNO_HOST}:${JUNO_OUTDIR}/" \
    "${LOCAL_OUTDIR}/"

echo ""
echo "Done. Opening reports..."

# Open HTML reports in browser
for html in \
    "${LOCAL_OUTDIR}/results/virome_report/summary.html" \
    "${LOCAL_OUTDIR}/multiqc/multiqc_report.html"; do
    if [[ -f "${html}" ]]; then
        explorer.exe "$(wslpath -w "${html}")" 2>/dev/null || echo "  Open manually: ${html}"
    fi
done

echo ""
echo "Results:"
echo "  Abundance matrix : ${LOCAL_OUTDIR}/results/viral_abundance_matrix.tsv"
echo "  Virome report    : ${LOCAL_OUTDIR}/results/virome_report/summary.html"
echo "  MultiQC          : ${LOCAL_OUTDIR}/multiqc/multiqc_report.html"
