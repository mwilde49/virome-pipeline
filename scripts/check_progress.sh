#!/usr/bin/env bash
# =============================================================================
# One-shot consolidated status check across everything currently in flight:
#   - virus test dataset downloads (/titan/tprice/ingest/virus)
#   - PathSeq reference bundle download
#   - cmv_fibroblast main pipeline run (STAR_HOST_REMOVAL / unmapped FASTQs)
#   - overall SLURM queue
#
# Re-run this anytime for a fresh snapshot -- nothing here is destructive.
#
# Usage:
#   bash scripts/check_progress.sh
# =============================================================================

set -uo pipefail

section() { echo ""; echo "=== $* ==="; }

section "SLURM queue"
squeue -u "$USER"

section "Virus test dataset downloads (/titan/tprice/ingest/virus)"
du -sh /titan/tprice/ingest/virus/*/ 2>/dev/null
echo "--- csf_fan_chinacdc (last known incomplete dataset) tail ---"
tail -5 /groups/tprice/pipelines/containers/virome/scripts/logs/virus_dl_*_13.log 2>/dev/null

section "PathSeq reference bundle download"
MICROBE_TGZ="/groups/tprice/pipelines/references/pathseq/pathseq_microbe.tar.gz"
if [[ -f "$MICROBE_TGZ" ]]; then
    SIZE_BYTES=$(stat -c%s "$MICROBE_TGZ" 2>/dev/null || echo 0)
    SIZE_GB=$(awk -v b="$SIZE_BYTES" 'BEGIN{printf "%.1f", b/1e9}')
    PCT=$(awk -v b="$SIZE_BYTES" 'BEGIN{printf "%.1f", (b/1e9)/94.6*100}')
    echo "pathseq_microbe.tar.gz: ${SIZE_GB} GB / ~94.6 GB (~${PCT}%)"
else
    echo "pathseq_microbe.tar.gz: not started or not found"
fi
ls -la /groups/tprice/pipelines/references/pathseq/ 2>&1

section "cmv_fibroblast main pipeline"
echo "-- unmapped FASTQs (needed before pathseq_verify.nf can launch) --"
ls -la /scratch/juno/maw210003/virome_cmv_fibroblast/star_unmapped/ 2>&1
echo "-- execution trace tail (if present) --"
tail -8 /scratch/juno/maw210003/virome_cmv_fibroblast/pipeline_info/execution_trace.tsv 2>&1

echo ""
echo "=== Done -- $(date) ==="
