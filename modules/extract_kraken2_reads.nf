/*
 * modules/extract_kraken2_reads.nf
 *
 * Given a Kraken2 per-read output file and one or more target taxon IDs,
 * extract the corresponding read pairs from the host-removed FASTQ files
 * using seqtk.
 *
 * Inputs:
 *   meta            — sample metadata map (id, taxon_id, taxon_name)
 *   kraken2_output  — {id}.kraken2.output  (per-read Kraken2 assignments)
 *   r1, r2          — host-removed (STAR-unmapped) FASTQ.gz files
 *
 * Outputs:
 *   reads           — [ meta, extracted_R1.fastq.gz, extracted_R2.fastq.gz ]
 *   stats           — extraction statistics TSV
 */

process EXTRACT_KRAKEN2_READS {
    tag "${meta.id}:${meta.taxon_id}"

    container "${params.container_dir}/blast.sif"

    input:
    tuple val(meta), path(kraken2_output), path(r1), path(r2)

    output:
    tuple val(meta), path("${meta.id}.${meta.taxon_id}_R1.fastq.gz"),
                     path("${meta.id}.${meta.taxon_id}_R2.fastq.gz"), emit: reads
    tuple val(meta), path("${meta.id}.${meta.taxon_id}.extraction_stats.tsv"),  emit: stats

    script:
    def include_genus = params.blast_include_genus ? '--include-genus' : ''
    """
    # Step 1: extract read IDs for the target taxon
    extract_kraken2_reads.py \\
        --kraken2-output ${kraken2_output} \\
        --taxon-ids "${meta.taxon_id}" \\
        --sample-id "${meta.id}" \\
        ${include_genus} \\
        --outdir .

    # Step 2: use seqtk to extract those reads from the FASTQ pair
    ID_FILE="${meta.id}.combined.read_ids.txt"

    if [[ ! -s "\${ID_FILE}" ]]; then
        echo "WARNING: no reads extracted for taxon ${meta.taxon_id} in ${meta.id}" >&2
        # Write empty files so pipeline doesn't fail
        touch empty_ids.txt
        seqtk subseq ${r1} empty_ids.txt | gzip > ${meta.id}.${meta.taxon_id}_R1.fastq.gz
        seqtk subseq ${r2} empty_ids.txt | gzip > ${meta.id}.${meta.taxon_id}_R2.fastq.gz
        # Write empty stats
        echo -e "sample_id\\ttaxon_id\\treads_extracted\\ttotal_reads\\ttotal_classified\\tpct_of_classified" \\
            > ${meta.id}.${meta.taxon_id}.extraction_stats.tsv
        echo -e "${meta.id}\\t${meta.taxon_id}\\t0\\t0\\t0\\t0.0" \\
            >> ${meta.id}.${meta.taxon_id}.extraction_stats.tsv
    else
        seqtk subseq ${r1} "\${ID_FILE}" | gzip > ${meta.id}.${meta.taxon_id}_R1.fastq.gz
        seqtk subseq ${r2} "\${ID_FILE}" | gzip > ${meta.id}.${meta.taxon_id}_R2.fastq.gz
        cp ${meta.id}.extraction_stats.tsv ${meta.id}.${meta.taxon_id}.extraction_stats.tsv
    fi
    """
}
