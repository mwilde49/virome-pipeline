process AGGREGATE {

    container "${params.container_dir}/python.sif"

    publishDir "${params.outdir}/results", mode: 'copy'

    input:
    path filtered_tsvs  // collection of all per-sample filtered TSVs
    path star_logs      // collection of all per-sample STAR Log.final.out files

    output:
    path "viral_abundance_matrix.tsv", emit: matrix
    path "viral_abundance_matrix.csv", emit: matrix_csv

    script:
    def input_args    = filtered_tsvs instanceof List
        ? filtered_tsvs.collect { "--input $it" }.join(' \\\n        ')
        : "--input ${filtered_tsvs}"
    def star_log_args = star_logs instanceof List
        ? star_logs.collect { "--star-log $it" }.join(' \\\n        ')
        : "--star-log ${star_logs}"
    """
    aggregate_virome.py \\
        ${input_args} \\
        ${star_log_args} \\
        --output viral_abundance_matrix
    """
}
