#!/usr/bin/env bash
# Downloads Iadorola et al. 2016 human trigeminal ganglia RNA-seq (BioProject SRP113004)
# 16 samples (TG1–TG22, not contiguous), all paired-end, 125 bp, HiSeq 2500
# Run from an interactive compute node on Juno:
#   srun --account=tprice --partition=normal --cpus-per-task=8 --mem=16G --time=12:00:00 --pty bash
#   bash /groups/tprice/pipelines/containers/virome/Iadorola/download_iadorola.sh

set -euo pipefail

OUTDIR="${1:-/groups/tprice/data/iadorola_tg}"
THREADS=8

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

mkdir -p "$OUTDIR"
echo "Downloading to: $OUTDIR"

for SRR in "${!SAMPLE_MAP[@]}"; do
    SAMPLE="${SAMPLE_MAP[$SRR]}"
    R1="$OUTDIR/${SAMPLE}_1.fastq.gz"
    R2="$OUTDIR/${SAMPLE}_2.fastq.gz"

    if [[ -f "$R1" && -f "$R2" ]]; then
        echo "[skip] $SAMPLE already exists"
        continue
    fi

    echo "[download] $SAMPLE ($SRR)"
    fasterq-dump "$SRR" \
        --outdir "$OUTDIR" \
        --threads "$THREADS" \
        --split-files \
        --skip-technical \
        --progress \
        --temp "$OUTDIR"

    # fasterq-dump outputs uncompressed; pigz for parallel gzip
    pigz -p "$THREADS" "$OUTDIR/${SRR}_1.fastq" "$OUTDIR/${SRR}_2.fastq"
    mv "$OUTDIR/${SRR}_1.fastq.gz" "$R1"
    mv "$OUTDIR/${SRR}_2.fastq.gz" "$R2"
    echo "[done] $SAMPLE → $(basename $R1), $(basename $R2)"
done

echo ""
echo "All downloads complete: $OUTDIR"
echo "$(ls "$OUTDIR"/*_1.fastq.gz 2>/dev/null | wc -l) samples present."
