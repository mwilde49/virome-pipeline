#!/usr/bin/env bash
# extract_hantavirus_reads.sh
#
# Extract reads classified as Orthohantavirus oxbowense (taxon 3052491) from
# Kraken2 output files and write them to FASTA for BLAST validation.
#
# Requires: kraken2 output files (NOT the report — the per-read output)
# These are in the Nextflow work directory under the KRAKEN2_CLASSIFY process.
#
# Usage:
#   bash scripts/extract_hantavirus_reads.sh <nf_work_dir> <outdir>
#
# Example:
#   bash scripts/extract_hantavirus_reads.sh \
#       /scratch/juno/maw210003/nf_work \
#       /work/maw210003/pipelines/virome/hantavirus_blast
#
# After extraction, run BLAST remotely (small read sets only):
#   blastn -query hantavirus_reads.fa -db nt -remote \
#          -outfmt "6 qseqid sseqid pident length evalue bitscore stitle" \
#          -max_target_seqs 5 -out hantavirus_blast_results.txt
#
# Target taxon IDs for hantavirus extraction:
#   3052491  Orthohantavirus oxbowense  (species — direct assignment)
#   1980442  Orthohantavirus            (genus — LCA rollup, include for completeness)
#   1980413  Hantaviridae               (family)
#
# Samples of interest (Saad cohort + donor1_L2 spike):
#   Saad_1, Saad_3, Saad_4, Saad_5, donor1_L2

set -euo pipefail

HANTA_TAXIDS="3052491 1980442 1980413"
SAMPLES="Saad_1 Saad_3 Saad_4 Saad_5 donor1_L2"

NF_WORK="${1:?Usage: $0 <nf_work_dir> <outdir>}"
OUTDIR="${2:?Usage: $0 <nf_work_dir> <outdir>}"

mkdir -p "${OUTDIR}"

echo "Searching for Kraken2 output files in: ${NF_WORK}"
echo "Target taxon IDs: ${HANTA_TAXIDS}"
echo ""

# Find Kraken2 output files (per-read, not report)
# They are named *.kraken2.output or similar in the KRAKEN2_CLASSIFY work dirs
# kraken2 --output writes: C/U <tab> read_id <tab> taxid <tab> length <tab> kmer_hits
mapfile -t K2_OUTPUTS < <(find "${NF_WORK}" -name "*.kraken2.output" -o -name "*classified*" 2>/dev/null | grep -v ".report" | sort)

if [ ${#K2_OUTPUTS[@]} -eq 0 ]; then
    echo "ERROR: No Kraken2 output files found in ${NF_WORK}"
    echo "The scratch work directory may have been purged."
    echo ""
    echo "Alternative: use the Bracken report files from the results directory."
    echo "See scripts/extract_hantavirus_from_results.sh for that approach."
    exit 1
fi

echo "Found ${#K2_OUTPUTS[@]} Kraken2 output file(s)"

TOTAL_READS=0
for K2_OUT in "${K2_OUTPUTS[@]}"; do
    # Extract sample name from path (Nextflow work dirs have hash subdirs)
    SAMPLE=$(basename "$(dirname "${K2_OUT}")")

    # Extract classified reads with hantavirus taxon IDs
    # kraken2 output format: C <tab> readID <tab> taxID <tab> length <tab> kmers
    HANTA_READS=$(awk -v taxids="${HANTA_TAXIDS}" '
        BEGIN { split(taxids, t, " "); for (i in t) tset[t[i]] = 1 }
        $1 == "C" && ($3 in tset) { print $2 }
    ' "${K2_OUT}")

    COUNT=$(echo "${HANTA_READS}" | grep -c . || true)
    if [ "${COUNT}" -gt 0 ]; then
        echo "  ${SAMPLE}: ${COUNT} hantavirus-classified reads"
        echo "${HANTA_READS}" >> "${OUTDIR}/hantavirus_read_ids.txt"
        TOTAL_READS=$((TOTAL_READS + COUNT))
    fi
done

echo ""
echo "Total hantavirus-classified reads found: ${TOTAL_READS}"

if [ "${TOTAL_READS}" -eq 0 ]; then
    echo "No reads found. Work directory may be purged — see note above."
    exit 0
fi

echo ""
echo "Next steps:"
echo "  1. Extract FASTQ sequences by read ID from the trimmed FASTQs"
echo "     (use seqtk subseq or grep -A3 approach)"
echo "  2. Convert to FASTA and run BLAST:"
echo "     blastn -query ${OUTDIR}/hantavirus_reads.fa -db nt -remote \\"
echo "            -outfmt '6 qseqid sseqid pident length evalue bitscore stitle' \\"
echo "            -max_target_seqs 5 -out ${OUTDIR}/blast_results.txt"
