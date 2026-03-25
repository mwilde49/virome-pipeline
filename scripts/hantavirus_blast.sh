#!/usr/bin/env bash
#SBATCH --job-name=hanta_blast
#SBATCH --output=logs/hanta_blast_%j.log
#SBATCH --time=04:00:00
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=8
#SBATCH --mem=32G
#SBATCH --partition=normal

# hantavirus_blast.sh
#
# Standalone Kraken2 + read extraction + remote BLAST for hantavirus validation.
# Runs Kraken2 directly on raw FASTQs for the 5 hantavirus-signal samples,
# captures per-read output, extracts reads classified as Orthohantavirus
# oxbowense (3052491) or related hantavirus taxa, converts to FASTA, and
# BLASTs against NCBI nt.
#
# Skips STAR host removal — acceptable here because we only care about reads
# that Kraken2 classifies as hantavirus; human reads will not classify as
# hantavirus regardless of host removal.
#
# Results written to OUTDIR — pull locally for interpretation.

set -euo pipefail

module load apptainer

KRAKEN2_SIF="/groups/tprice/pipelines/containers/virome/kraken2.sif"
KRAKEN2_DB="/groups/tprice/pipelines/references/kraken2_viral_db"
OUTDIR="/work/maw210003/pipelines/virome/hantavirus_blast"
THREADS=8

# Hantavirus taxon IDs to extract
# 3052491 = Orthohantavirus oxbowense (species, direct hit)
# 1980442 = Orthohantavirus (genus, LCA rollup)
# 1980413 = Hantaviridae (family, broad net)
HANTA_TAXIDS="3052491 1980442 1980413"

mkdir -p "${OUTDIR}" logs

declare -A SAMPLES=(
    ["Saad_1"]="/scratch/juno/maw210003/fastq/drg2/Saad-1_S19_L001"
    ["Saad_3"]="/scratch/juno/maw210003/fastq/drg2/Saad-3_S21_L001"
    ["Saad_4"]="/scratch/juno/maw210003/fastq/drg2/Saad-4_S22_L001"
    ["Saad_5"]="/scratch/juno/maw210003/fastq/drg2/Saad-5_S23_L001"
    ["donor1_L2"]="/scratch/juno/maw210003/fastq/drg/donor1-L2_S10_L002"
)

ALL_HANTA_FA="${OUTDIR}/all_hantavirus_reads.fa"
> "${ALL_HANTA_FA}"

echo "=== Hantavirus read extraction and BLAST ==="
echo "Start: $(date)"
echo ""

for SAMPLE in "${!SAMPLES[@]}"; do
    BASE="${SAMPLES[$SAMPLE]}"
    R1="${BASE}_R1_001.fastq.gz"
    R2="${BASE}_R2_001.fastq.gz"
    K2_OUT="${OUTDIR}/${SAMPLE}.kraken2.output"
    K2_RPT="${OUTDIR}/${SAMPLE}.kraken2.report"

    if [ ! -f "${R1}" ]; then
        echo "WARN: ${R1} not found — skipping ${SAMPLE}"
        continue
    fi

    echo "--- ${SAMPLE} ---"
    echo "Running Kraken2..."

    apptainer exec --cleanenv "${KRAKEN2_SIF}" \
        kraken2 \
            --db "${KRAKEN2_DB}" \
            --threads "${THREADS}" \
            --paired \
            --gzip-compressed \
            --confidence 0.1 \
            --output "${K2_OUT}" \
            --report "${K2_RPT}" \
            "${R1}" "${R2}"

    # Extract hantavirus read IDs from per-read output
    # Format: C/U <tab> readID <tab> taxID <tab> length <tab> kmer_hits
    HANTA_IDS=$(awk -v taxids="${HANTA_TAXIDS}" '
        BEGIN { split(taxids, t, " "); for (i in t) tset[t[i]] = 1 }
        $1 == "C" && ($3 in tset) { print $2 }
    ' "${K2_OUT}")

    COUNT=$(echo "${HANTA_IDS}" | grep -c . || true)
    echo "  Hantavirus-classified reads: ${COUNT}"

    if [ "${COUNT}" -gt 0 ]; then
        # Extract sequences from R1 FASTQ using read IDs
        # seqtk subseq is available in kraken2.sif or use awk fallback
        echo "${HANTA_IDS}" > "${OUTDIR}/${SAMPLE}_hanta_ids.txt"

            # Extract sequences by read ID using awk (no seqtk dependency)
        zcat "${R1}" | awk '
            NR==FNR { ids[$1]=1; next }
            /^@/ { id=substr($1,2); f=(id in ids) }
            f && /^@/ { print ">" substr($0,2); next }
            f && !/^+/ && !/^@/ { print }
        ' "${OUTDIR}/${SAMPLE}_hanta_ids.txt" - >> "${ALL_HANTA_FA}" || true

        echo "  Reads appended to ${ALL_HANTA_FA}"
    fi

    echo ""
done

TOTAL=$(grep -c "^>" "${ALL_HANTA_FA}" || true)
echo "=== Total hantavirus reads extracted: ${TOTAL} ==="
echo ""

if [ "${TOTAL}" -eq 0 ]; then
    echo "No reads extracted. Check FASTQ paths above."
    exit 0
fi

if [ "${TOTAL}" -gt 500 ]; then
    echo "Read count (${TOTAL}) exceeds remote BLAST limit."
    echo "Subsetting to 100 reads for remote BLAST..."
    head -200 "${ALL_HANTA_FA}" > "${OUTDIR}/hantavirus_blast_input.fa"
else
    cp "${ALL_HANTA_FA}" "${OUTDIR}/hantavirus_blast_input.fa"
fi

echo "Kraken2 + extraction complete: $(date)"
echo ""
echo "Next: run BLAST on the extracted reads."
echo "Check if blastn is available:"
echo "  which blastn || module avail 2>&1 | grep -i blast"
echo ""
echo "Then run:"
echo "  blastn \\"
echo "    -query  ${OUTDIR}/hantavirus_blast_input.fa \\"
echo "    -db     nt -remote \\"
echo "    -outfmt '6 qseqid sseqid pident length evalue bitscore stitle' \\"
echo "    -max_target_seqs 5 -max_hsps 1 \\"
echo "    -out    ${OUTDIR}/blast_results.txt"
echo ""
echo "Or load BLAST module first if needed:"
echo "  module load blast && blastn ..."
