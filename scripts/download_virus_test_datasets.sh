#!/bin/bash
#SBATCH --job-name=virus_test_dl
#SBATCH --account=tprice
#SBATCH --array=0-14
#SBATCH --cpus-per-task=4
#SBATCH --mem=8G
#SBATCH --output=logs/virus_dl_%A_%a.log
#SBATCH --error=logs/virus_dl_%A_%a.err
#
# --partition and --time are DELIBERATELY NOT set here -- pass them on the
# sbatch command line, chosen from real `bash scripts/check_partitions.sh`
# output, e.g.:
#   sbatch --partition=<name> --time=<MaxTime for that partition> download_virus_test_datasets.sh
# Guessing a --time here previously left a job stuck PD/PartitionTimeLimit
# forever. If you omit --time entirely, SLURM uses the partition's
# DefaultTime, which is guaranteed valid but may be short -- that's fine,
# see the resume note below.

# =============================================================================
# Download the 14 virus-positive bulk RNA-seq test datasets (see
# docs/pathseq_and_test_datasets_2026-08-14.md) to /titan/tprice/ingest/virus.
#
# One independent SLURM array task per dataset -- each is its own job, can be
# individually cancelled (scancel <jobid>_<index>) without touching the
# others, and re-running is safe/resumable: fully-downloaded files are
# skipped entirely, and a file killed mid-transfer (e.g. by hitting a SLURM
# wall-clock limit) resumes from its last byte via curl -C - rather than
# restarting from 0. So a short --time + several resubmissions is a
# perfectly fine strategy, not just a fallback.
#
# Uses the ENA portal API to resolve FTP URLs dynamically (same pattern as
# Iadorola/download_iadorola.sh) rather than hardcoding URLs -- run-level
# metadata (fastq_ftp, fastq_bytes) is fetched fresh at run time.
#
# Verified total: ~867 GB across all 14 datasets (see virus_test_datasets.conf).
#
# Usage (run in this exact order):
#   bash scripts/check_partitions.sh                        # 1. see real partition limits
#   mkdir -p logs
#   bash scripts/virus_test_datasets_manifest.sh             # 2. sanity-check sizes
#   sbatch --partition=<name> --time=<value> \
#       scripts/download_virus_test_datasets.sh               # 3. launch all 14 as one array job
#   squeue -u $USER                                           # 4. watch progress
#   tail -f logs/virus_dl_<jobid>_<index>.log                 #    follow one dataset
#
#   # Or run a single dataset manually (no SLURM), e.g. index 5 = cmv_fibroblast:
#   bash scripts/download_virus_test_datasets.sh 5
# =============================================================================

set -euo pipefail

# Under sbatch, this script runs from a per-job spool copy
# (/var/spool/slurmd/job<id>/slurm_script), NOT from its real location -- so
# BASH_SOURCE-based path resolution finds nothing next to it. SLURM_SUBMIT_DIR
# (the directory `sbatch` was invoked from) is the reliable one when present;
# fall back to BASH_SOURCE for direct/manual invocation (no sbatch).
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

# EBI's FTP servers appear to throttle/reject a burst of simultaneous fresh
# connections from one IP (observed 2026-08-14: with the old MAX_PARALLEL=8,
# ~8-9 of the first downloads in a task failed instantly while 1 succeeded
# and progressed normally -- classic connection-flood rejection, not a
# per-file problem). With --array=...%4, up to 4 tasks run at once, so total
# concurrent connections = 4 x MAX_PARALLEL. Keep MAX_PARALLEL low enough
# that the total stays close to the ~4 concurrent connections previously
# proven to work fine against the same EBI FTP servers (see
# Iadorola/download_iadorola.sh's MAX_PARALLEL=4, used for a single task with
# no array multiplier).
MAX_PARALLEL=2

IDX="${SLURM_ARRAY_TASK_ID:-${1:-}}"
if [[ -z "$IDX" ]]; then
    echo "Usage: sbatch --array=0-$(( ${#DATASETS[@]} - 1 )) $0   (or manually: $0 <index>)" >&2
    exit 1
fi

IFS='|' read -r KEY ACCESSION RUN_FILTER NOTE <<< "${DATASETS[$IDX]}"
OUTDIR="${OUTBASE}/${KEY}"
mkdir -p "$OUTDIR"

log() { printf "[%s] [%s] %s\n" "$(date +%H:%M:%S)" "$KEY" "$*"; }
log "=== ${KEY} (${ACCESSION}) ==="
log "$NOTE"

# Stagger this task's startup so concurrently-running array tasks do not all
# open their first batch of connections in the same instant (the likely
# trigger for the connection-flood rejections observed above).
STARTUP_JITTER=$(( RANDOM % 25 ))
log "Startup jitter: sleeping ${STARTUP_JITTER}s before first connection"
sleep "$STARTUP_JITTER"

MANIFEST="${OUTDIR}/manifest.tsv"
curl -sS -m 120 "https://www.ebi.ac.uk/ena/portal/api/filereport?accession=${ACCESSION}&result=read_run&fields=run_accession,fastq_ftp,fastq_bytes,sample_title,library_layout&format=tsv" \
    > "$MANIFEST"

N_ROWS=$(( $(wc -l < "$MANIFEST") - 1 ))
if [[ "$N_ROWS" -le 0 ]]; then
    log "ERROR: ENA API returned no runs for ${ACCESSION} -- aborting. Check the accession or retry (API is occasionally flaky/rate-limited)."
    exit 1
fi
log "Manifest resolved: ${N_ROWS} runs -> ${OUTDIR}/manifest.tsv"

download_file() {
    local URL=$1 OUT=$2 LABEL=$3
    if [[ -s "$OUT" ]]; then
        log "${LABEL}: already exists (${OUT}), skipping"
        return 0
    fi

    local TOTAL
    TOTAL=$(curl -sI -m 30 "$URL" 2>/dev/null | grep -i '^content-length' | tail -1 | awk '{print $2}' | tr -d '\r\n') || true

    # -C - resumes from the existing .part file's size instead of restarting
    # at byte 0 -- important both because these are large files and this job
    # can get killed mid-transfer by a SLURM wall-clock limit, AND because a
    # rejected-connection failure (see MAX_PARALLEL comment above) should not
    # throw away whatever partial bytes a prior attempt did get.
    #
    # curl's own --retry only retries within one invocation and gives up
    # quickly; a connection-flood rejection needs a real cooldown, so wrap it
    # in an outer retry loop with exponential backoff instead of failing
    # after curl's first exhausted retry budget.
    local ATTEMPT=1 MAX_ATTEMPTS=6 DELAY=20
    while (( ATTEMPT <= MAX_ATTEMPTS )); do
        if [[ -f "${OUT}.part" ]]; then
            log "${LABEL}: attempt ${ATTEMPT}/${MAX_ATTEMPTS}, resuming from $(du -h "${OUT}.part" | cut -f1) already on disk"
        fi

        curl -fsSL --retry 3 --retry-delay 10 -C - -o "${OUT}.part" "$URL" &
        local DL_PID=$! LAST_PCT=-1 LAST_LOG=0

        while kill -0 "$DL_PID" 2>/dev/null; do
            if [[ -f "${OUT}.part" ]]; then
                local CURRENT NOW
                CURRENT=$(stat -c%s "${OUT}.part" 2>/dev/null || echo 0)
                NOW=$(date +%s)
                if [[ -n "${TOTAL:-}" && "$TOTAL" -gt 0 ]]; then
                    local PCT=$(( CURRENT * 100 / TOTAL ))
                    if [[ $PCT -ne $LAST_PCT ]]; then
                        log "${LABEL}: ${PCT}%"
                        LAST_PCT=$PCT
                    fi
                elif (( NOW - LAST_LOG >= 30 )); then
                    log "${LABEL}: $(( CURRENT / 1024 / 1024 )) MB"
                    LAST_LOG=$NOW
                fi
            fi
            sleep 3
        done

        if wait "$DL_PID"; then
            mv "${OUT}.part" "$OUT"
            log "${LABEL}: done ($(du -h "$OUT" | cut -f1))"
            return 0
        fi

        log "${LABEL}: attempt ${ATTEMPT}/${MAX_ATTEMPTS} failed -- retrying in ${DELAY}s (leaving partial file in place to resume from)"
        sleep "$DELAY"
        DELAY=$(( DELAY * 2 ))
        ATTEMPT=$(( ATTEMPT + 1 ))
    done

    log "ERROR ${LABEL}: download failed after ${MAX_ATTEMPTS} attempts -- leaving ${OUT}.part in place; re-running this script will resume it"
    return 1
}

download_run() {
    local RUN=$1 FTP=$2
    IFS=';' read -ra URLS <<< "$FTP"
    if [[ ${#URLS[@]} -ge 2 ]]; then
        download_file "ftp://${URLS[0]}" "${OUTDIR}/${RUN}_1.fastq.gz" "${RUN} R1"
        download_file "ftp://${URLS[1]}" "${OUTDIR}/${RUN}_2.fastq.gz" "${RUN} R2"
    else
        download_file "ftp://${URLS[0]}" "${OUTDIR}/${RUN}.fastq.gz" "${RUN}"
    fi
}

PIDS=()
while IFS=$'\t' read -r RUN FTP BYTES TITLE LAYOUT; do
    RUN="${RUN%$'\r'}"
    [[ "$RUN" == "run_accession" || -z "$RUN" ]] && continue
    if [[ "$RUN_FILTER" != "ALL" ]]; then
        [[ " $RUN_FILTER " == *" $RUN "* ]] || continue
    fi

    while (( $(jobs -r -p | wc -l) >= MAX_PARALLEL )); do sleep 2; done
    download_run "$RUN" "$FTP" &
    PIDS+=($!)
done < "$MANIFEST"

FAIL=0
for PID in "${PIDS[@]}"; do
    wait "$PID" || FAIL=1
done

log "=== ${KEY} complete (exit ${FAIL}) — $(du -sh "$OUTDIR" 2>/dev/null | cut -f1) in ${OUTDIR} ==="
exit $FAIL
