process AGGREGATE {

    container "${params.container_dir}/python.sif"

    publishDir "${params.outdir}/results", mode: 'copy'

    input:
    path filtered_tsvs  // collection of all per-sample filtered TSVs

    output:
    path "viral_abundance_matrix.tsv", emit: matrix
    path "viral_abundance_matrix.csv", emit: matrix_csv

    script:
    def input_args = filtered_tsvs instanceof List
        ? filtered_tsvs.collect { "--input $it" }.join(' \\\n        ')
        : "--input ${filtered_tsvs}"
    """
    aggregate_virome.py \\
        ${input_args} \\
        --output viral_abundance_matrix
    """
}
