process AGGREGATE {

    container "${params.container_dir}/python.sif"

    publishDir "${params.outdir}/results", mode: 'copy'

    input:
    val   output_name   // e.g. 'viral_abundance_matrix', 'bracken_raw_matrix', 'minreads_matrix'
    path  filtered_tsvs // collection of per-sample TSVs
    path  star_logs     // collection of per-sample STAR Log.final.out files

    output:
    path "${output_name}.tsv", emit: matrix
    path "${output_name}.csv", emit: matrix_csv

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
        --output ${output_name}
    """
}
