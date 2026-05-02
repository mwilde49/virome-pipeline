#!/usr/bin/env bash
# Downloads Iadorola et al. 2016 human trigeminal ganglia RNA-seq (BioProject SRP113004)
# 16 samples (TG1–TG22, not contiguous), all paired-end, 125 bp, HiSeq 2500
# Uses ENA API to resolve correct FTP URLs — no SRA toolkit required
# Parallel downloads with progress tracking per file
# Usage:
#   nohup bash download_iadorola.sh [outdir] > /scratch/juno/maw210003/iadorola_download.log 2>&1 &
#   tail -f /scratch/juno/maw210003/iadorola_download.log

set -euo pipefail

OUTDIR="${1:-/scratch/juno/maw210003/iadorola_tg}"
MAX_PARALLEL=4

declare -A SAMPLE_MAP=(
    [SRR5850220]=TG8
    [SRR5850221]=TG10
    [SRR5850222]=TG9
    [SRR5850223]=TG1
    [SRR5850224]=TG2
    [SRR5850225]=TG3
    [SRR5850226]=TG4
    [SRR5850227]=TG11
    [SRR5850228]=TG12
    [SRR5850229]=TG13
    [SRR5850230]=TG14
    [SRR5850231]=TG6
    [SRR5850232]=TG16
    [SRR5850233]=TG7
    [SRR5850234]=TG22
    [SRR5850235]=TG5
)

log() { printf "[%s] %s\n" "$(date +%H:%M:%S)" "$*"; }

# Returns two ftp:// URLs (R1 and R2) for a given SRR accession via ENA API
get_ena_urls() {
    local SRR=$1
    curl -s "https://www.ebi.ac.uk/ena/portal/api/filereport?accession=${SRR}&result=read_run&fields=fastq_ftp&format=tsv" \
        | tail -1 | cut -f2 | tr ';' '\n' | sed 's|^|ftp://|'
}

download_file() {
    local URL=$1 OUT=$2 LABEL=$3
    local TOTAL=""
    TOTAL=$(curl -sI "$URL" 2>/dev/null | grep -i 'content-length' | tail -1 | awk '{print $2}' | tr -d '\r\n') || true

    curl -fsSL -o "$OUT" "$URL" &
    local DL_PID=$! LAST_PCT=-1 LAST_LOG=0

    while kill -0 "$DL_PID" 2>/dev/null; do
        if [[ -f "$OUT" ]]; then
            local CURRENT NOW
            CURRENT=$(stat -c%s "$OUT" 2>/dev/null || echo 0)
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
        sleep 2
    done

    if ! wait "$DL_PID"; then
        log "ERROR ${LABEL}: download failed"
        rm -f "$OUT"
        return 1
    fi
    log "${LABEL}: done"
}

download_sample() {
    local SRR=$1 SAMPLE=$2

    log "$SAMPLE: resolving URLs via ENA API"
    local URLS
    mapfile -t URLS < <(get_ena_urls "$SRR")

    if [[ ${#URLS[@]} -lt 2 ]]; then
        log "ERROR $SAMPLE: could not resolve ENA URLs (got ${#URLS[@]})"
        return 1
    fi

    download_file "${URLS[0]}" "$OUTDIR/${SAMPLE}_1.fastq.gz" "$SAMPLE R1"
    download_file "${URLS[1]}" "$OUTDIR/${SAMPLE}_2.fastq.gz" "$SAMPLE R2"
    log "$SAMPLE: complete"
}

mkdir -p "$OUTDIR"
log "Downloading to: $OUTDIR (up to $MAX_PARALLEL parallel)"

PIDS=()
for SRR in "${!SAMPLE_MAP[@]}"; do
    SAMPLE="${SAMPLE_MAP[$SRR]}"

    if [[ -f "$OUTDIR/${SAMPLE}_1.fastq.gz" && -f "$OUTDIR/${SAMPLE}_2.fastq.gz" ]]; then
        log "skip: $SAMPLE already complete"
        continue
    fi

    # Throttle to MAX_PARALLEL
    while true; do
        LIVE=()
        for PID in "${PIDS[@]+"${PIDS[@]}"}"; do
            kill -0 "$PID" 2>/dev/null && LIVE+=("$PID")
        done
        PIDS=("${LIVE[@]+"${LIVE[@]}"}")
        [[ ${#PIDS[@]} -lt $MAX_PARALLEL ]] && break
        sleep 2
    done

    log "start: $SAMPLE ($SRR)"
    download_sample "$SRR" "$SAMPLE" &
    PIDS+=($!)
done

# Wait for remaining jobs
FAILED=0
for PID in "${PIDS[@]+"${PIDS[@]}"}"; do
    wait "$PID" || FAILED=$(( FAILED + 1 ))
done

PRESENT=$(ls "$OUTDIR"/*_1.fastq.gz 2>/dev/null | wc -l)
log "Done: ${PRESENT}/16 samples present"
[[ $FAILED -gt 0 ]] && log "WARNING: ${FAILED} sample(s) failed" || log "All downloads succeeded"
