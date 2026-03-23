process AGGREGATE {

    container "${params.container_dir}/python.sif"

    publishDir "${params.outdir}/results", mode: 'copy'

    input:
    path filtered_tsvs  // collection of all per-sample filtered TSVs

    output:
    path "viral_abundance_matrix.tsv", emit: matrix
    path "viral_abundance_matrix.csv", emit: matrix_csv

    script:
    """
    aggregate_virome.py \\
        --input ${filtered_tsvs} \\
        --output viral_abundance_matrix
    """
}
