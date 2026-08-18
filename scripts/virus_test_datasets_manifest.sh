#!/usr/bin/env bash
# =============================================================================
# Quick size/run-count check for scripts/virus_test_datasets.conf.
#
# Lightweight (just ENA API metadata queries, no downloading) — safe to run
# directly on the Juno login node. Run this FIRST, before submitting the real
# download job, to confirm the numbers and available space on /titan.
#
# Usage:
#   bash scripts/virus_test_datasets_manifest.sh
# =============================================================================

set -euo pipefail
# Same SLURM spool-dir gotcha as download_virus_test_datasets.sh -- see the
# comment there. This script is meant to be run directly (not via sbatch), so
# BASH_SOURCE resolution normally works fine, but fall back safely either way.
# See scripts/make_samplesheet.sh for why this checks file existence rather
# than blindly preferring SLURM_SUBMIT_DIR -- that var is stale inside an
# interactive `srun --pty bash` session, not just absent outside SLURM.
_BASH_SOURCE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [[ -f "${_BASH_SOURCE_DIR}/virus_test_datasets.conf" ]]; then
    SCRIPT_DIR="$_BASH_SOURCE_DIR"
elif [[ -n "${SLURM_SUBMIT_DIR:-}" && -f "${SLURM_SUBMIT_DIR}/virus_test_datasets.conf" ]]; then
    SCRIPT_DIR="$SLURM_SUBMIT_DIR"
else
    SCRIPT_DIR="$_BASH_SOURCE_DIR"
fi
source "${SCRIPT_DIR}/virus_test_datasets.conf"

GRAND_BYTES=0
printf "%-26s %-14s %6s %10s  %s\n" "KEY" "ACCESSION" "RUNS" "SIZE(GB)" "NOTE"
printf -- '-%.0s' $(seq 1 110); echo

for ENTRY in "${DATASETS[@]}"; do
    IFS='|' read -r KEY ACCESSION RUN_FILTER NOTE <<< "$ENTRY"

    TSV=$(curl -sS -m 60 "https://www.ebi.ac.uk/ena/portal/api/filereport?accession=${ACCESSION}&result=read_run&fields=run_accession,fastq_bytes&format=tsv" 2>/dev/null || true)

    N=0
    BYTES=0
    while IFS=$'\t' read -r RUN FB; do
        RUN="${RUN%$'\r'}"
        [[ "$RUN" == "run_accession" || -z "$RUN" ]] && continue
        if [[ "$RUN_FILTER" != "ALL" ]]; then
            [[ " $RUN_FILTER " == *" $RUN "* ]] || continue
        fi
        N=$(( N + 1 ))
        IFS=';' read -ra PARTS <<< "$FB"
        for P in "${PARTS[@]}"; do
            P="${P%$'\r'}"
            [[ -n "$P" ]] && BYTES=$(( BYTES + P ))
        done
    done <<< "$TSV"

    if [[ "$N" -eq 0 ]]; then
        echo "  [WARN] ${KEY} (${ACCESSION}): 0 runs resolved — ENA API may be rate-limiting; re-run this script, or check the accession manually." >&2
    fi

    GRAND_BYTES=$(( GRAND_BYTES + BYTES ))
    GB=$(awk -v b="$BYTES" 'BEGIN{printf "%.2f", b/1e9}')
    printf "%-26s %-14s %6s %10s  %s\n" "$KEY" "$ACCESSION" "$N" "$GB" "$NOTE"
    sleep 1   # be polite to the ENA API across 14 sequential queries
done

echo ""
GRAND_GB=$(awk -v b="$GRAND_BYTES" 'BEGIN{printf "%.2f", b/1e9}')
GRAND_TB=$(awk -v b="$GRAND_BYTES" 'BEGIN{printf "%.3f", b/1e12}')
echo "GRAND TOTAL: ${GRAND_GB} GB  (~${GRAND_TB} TB)"
echo "Target directory: ${OUTBASE}"
echo ""
echo "Check available space there with:  df -h \$(dirname ${OUTBASE})"
