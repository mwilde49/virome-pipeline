/*
 * modules/blast_verify.nf
 *
 * Run BLASTn on extracted reads against the local nt database.
 * Output is tabular format 6 with standard 12 columns.
 *
 * Parameters (all configurable in params):
 *   params.blast_db           — path to local BLAST nt database (required)
 *   params.blast_evalue       — E-value threshold (default: 1e-5)
 *   params.blast_max_targets  — max target sequences per query (default: 10)
 *   params.blast_word_size    — word size (default: 28 for blastn; lower = more sensitive)
 *   params.blast_perc_identity — minimum % identity filter (default: 80)
 *   params.blast_extra_args   — any additional blastn arguments (default: '')
 *
 * Design notes:
 *   - Input reads are interleaved R1+R2 (concatenated) for BLAST.
 *     Paired reads share prefixes; both are BLASTed independently.
 *   - outfmt 6 is used downstream by analyze_blast_results.py.
 *   - For small read sets (e.g. 46 HSV-1 reads from PD19), BLAST is fast.
 *     For larger sets, consider subsampling via params.blast_max_reads.
 *   - Remote mode (-remote) queries NCBI over the network; only suitable if
 *     no local nt database is available and the cluster has internet access.
 */

process BLAST_VERIFY {
    tag "${meta.id}:${meta.taxon_id}"

    container "${params.container_dir}/blast.sif"

    input:
    tuple val(meta), path(r1), path(r2)
    path  blast_db_dir

    output:
    tuple val(meta), path("${meta.id}.${meta.taxon_id}.blast_results.tsv"), emit: results

    script:
    def db_path   = "${blast_db_dir}/${params.blast_db_name ?: 'nt'}"
    def evalue    = params.blast_evalue       ?: '1e-5'
    def max_tgt   = params.blast_max_targets  ?: 10
    def word_size = params.blast_word_size    ?: 28
    def perc_id   = params.blast_perc_identity ?: 80
    def max_reads = params.blast_max_reads    ?: 0   // 0 = no limit
    def extra     = params.blast_extra_args   ?: ''
    """
    # Convert gzipped FASTQ to FASTA for BLAST input (R1 + R2 together)
    seqtk seq -a ${r1} > query_R1.fa
    seqtk seq -a ${r2} > query_R2.fa
    cat query_R1.fa query_R2.fa > query_all.fa

    # Optional: subsample if blast_max_reads is set
    if [[ "${max_reads}" -gt 0 ]]; then
        seqtk sample -s 42 query_all.fa ${max_reads} > query_subset.fa
        QUERY_FA=query_subset.fa
    else
        QUERY_FA=query_all.fa
    fi

    READ_COUNT=\$(grep -c '>' "\${QUERY_FA}" || echo 0)
    echo "BLASTing \${READ_COUNT} reads for ${meta.id} taxon ${meta.taxon_id}" >&2

    if [[ "\${READ_COUNT}" -eq 0 ]]; then
        echo "WARNING: no reads to BLAST for ${meta.id}:${meta.taxon_id}" >&2
        echo -e "# No reads extracted for taxon ${meta.taxon_id}" \\
            > ${meta.id}.${meta.taxon_id}.blast_results.tsv
    else
        blastn \\
            -query "\${QUERY_FA}" \\
            -db ${db_path} \\
            -out ${meta.id}.${meta.taxon_id}.blast_results.tsv \\
            -outfmt "6 qseqid sseqid pident length mismatch gapopen qstart qend sstart send evalue bitscore" \\
            -evalue ${evalue} \\
            -max_target_seqs ${max_tgt} \\
            -word_size ${word_size} \\
            -perc_identity ${perc_id} \\
            -num_threads ${task.cpus} \\
            ${extra}
    fi
    """
}
