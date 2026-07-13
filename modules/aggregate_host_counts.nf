process AGGREGATE_HOST_COUNTS {

    container "${params.container_dir}/python.sif"

    publishDir "${params.outdir}/results", mode: 'copy'

    input:
    path featurecounts_csv
    path htseq_tsv
    path star_logs  // collection of per-sample STAR Log.final.out files
    path gene_info

    output:
    path "host_gene_expression_matrix.tsv", emit: matrix
    path "host_gene_expression_matrix.csv", emit: matrix_csv
    path "host_gene_expression_matrix_qc_summary.tsv", emit: qc_summary

    script:
    def star_log_args = star_logs instanceof List
        ? star_logs.collect { "--star-log $it" }.join(' \\\n        ')
        : "--star-log ${star_logs}"
    def gene_info_arg = gene_info.name != 'NO_FILE' ? "--gene-info ${gene_info}" : ''
    """
    aggregate_host_counts.py \\
        --featurecounts ${featurecounts_csv} \\
        --htseq ${htseq_tsv} \\
        ${star_log_args} \\
        ${gene_info_arg} \\
        --output host_gene_expression_matrix
    """
}
