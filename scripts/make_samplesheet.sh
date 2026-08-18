#!/usr/bin/env bash
# =============================================================================
# Generate a main-pipeline samplesheet (sample,fastq_r1,fastq_r2) for one of
# the downloaded virus_test_datasets, directly from its own manifest.tsv --
# avoids hand-typing run accessions, which is exactly how the CMV taxon-ID
# mixup almost happened (see research/cmv_taxonomy_investigation.md).
#
# Usage:
#   bash scripts/make_samplesheet.sh <dataset_key> > assets/samplesheets/samplesheet_<dataset_key>_juno.csv
#
# e.g.:
#   bash scripts/make_samplesheet.sh vzv_hsv1_tg > assets/samplesheets/samplesheet_vzv_hsv1_tg_juno.csv
#
# Skips (with a warning to stderr) any run whose FASTQ file(s) aren't actually
# present on disk yet, so a partially-downloaded dataset still produces a
# usable sheet for whatever has finished.
# =============================================================================

set -euo pipefail

KEY="${1:?Usage: $0 <dataset_key>}"

# Resolve the real script directory: prefer BASH_SOURCE (correct for direct
# `bash script.sh` invocation, including inside an interactive `srun --pty
# bash` session where SLURM_SUBMIT_DIR is STALE -- set once when that srun
# session started, not updated as you cd around inside it). Fall back to
# SLURM_SUBMIT_DIR only if BASH_SOURCE's directory doesn't actually have the
# conf file -- that's the sbatch case, where the script runs from a per-job
# spool copy (/var/spool/slurmd/job<id>/slurm_script) that has no sibling
# files at all. Checking for the file's actual presence, rather than
# guessing which env var to trust, handles both cases correctly.
_BASH_SOURCE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [[ -f "${_BASH_SOURCE_DIR}/virus_test_datasets.conf" ]]; then
    SCRIPT_DIR="$_BASH_SOURCE_DIR"
elif [[ -n "${SLURM_SUBMIT_DIR:-}" && -f "${SLURM_SUBMIT_DIR}/virus_test_datasets.conf" ]]; then
    SCRIPT_DIR="$SLURM_SUBMIT_DIR"
else
    SCRIPT_DIR="$_BASH_SOURCE_DIR"
fi
source "${SCRIPT_DIR}/virus_test_datasets.conf"

DATASET_DIR="${OUTBASE}/${KEY}"
MANIFEST="${DATASET_DIR}/manifest.tsv"

if [[ ! -f "$MANIFEST" ]]; then
    echo "ERROR: no manifest at $MANIFEST -- has this dataset been downloaded yet?" >&2
    exit 1
fi

RUN_FILTER="ALL"
FOUND_KEY=0
for ENTRY in "${DATASETS[@]}"; do
    IFS='|' read -r K ACC FILTER NOTE <<< "$ENTRY"
    if [[ "$K" == "$KEY" ]]; then
        RUN_FILTER="$FILTER"
        FOUND_KEY=1
    fi
done
if [[ "$FOUND_KEY" -eq 0 ]]; then
    echo "ERROR: '$KEY' not found in virus_test_datasets.conf's DATASETS array" >&2
    exit 1
fi

echo "sample,fastq_r1,fastq_r2"
while IFS=$'\t' read -r RUN FTP BYTES TITLE LAYOUT; do
    RUN="${RUN%$'\r'}"
    [[ "$RUN" == "run_accession" || -z "$RUN" ]] && continue
    if [[ "$RUN_FILTER" != "ALL" ]]; then
        [[ " $RUN_FILTER " == *" $RUN "* ]] || continue
    fi

    R1="${DATASET_DIR}/${RUN}_1.fastq.gz"
    R2="${DATASET_DIR}/${RUN}_2.fastq.gz"
    R_SINGLE="${DATASET_DIR}/${RUN}.fastq.gz"

    if [[ -f "$R1" && -f "$R2" ]]; then
        echo "${RUN},${R1},${R2}"
    elif [[ -f "$R_SINGLE" ]]; then
        echo "WARNING: $RUN is single-end (${R_SINGLE}) -- this pipeline's samplesheet format is paired-end only, skipping. Title was: ${TITLE}" >&2
    else
        echo "WARNING: no FASTQ(s) found for $RUN yet (expected ${R1}), skipping" >&2
    fi
done < "$MANIFEST"
