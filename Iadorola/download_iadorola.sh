#!/usr/bin/env bash
# Downloads Iadorola et al. 2016 human trigeminal ganglia RNA-seq (BioProject SRP113004)
# 16 samples (TG1–TG22, not contiguous), all paired-end, 125 bp, HiSeq 2500
# Uses ENA FTP mirror — no SRA toolkit required
# Run from an interactive compute node on Juno:
#   srun --account=tprice --partition=normal --cpus-per-task=8 --mem=16G --time=12:00:00 --pty bash
#   bash /groups/tprice/pipelines/containers/virome/Iadorola/download_iadorola.sh

set -euo pipefail

OUTDIR="${1:-/groups/tprice/data/iadorola_tg}"

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

    # ENA FTP path: vol1/fastq/SRR{first6}/0{last2}/{SRR}/
    PREFIX="${SRR:0:6}"
    SUBDIR="0${SRR: -2}"
    BASE="ftp://ftp.sra.ebi.ac.uk/vol1/fastq/${PREFIX}/${SUBDIR}/${SRR}"

    echo "[download] $SAMPLE ($SRR)"
    wget -q --show-progress -O "$R1" "${BASE}/${SRR}_1.fastq.gz"
    wget -q --show-progress -O "$R2" "${BASE}/${SRR}_2.fastq.gz"
    echo "[done] $SAMPLE"
done

echo ""
echo "All downloads complete: $OUTDIR"
echo "$(ls "$OUTDIR"/*_1.fastq.gz 2>/dev/null | wc -l) samples present."
