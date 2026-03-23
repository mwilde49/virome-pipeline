process REPORT {

    container "${params.container_dir}/python.sif"

    publishDir "${params.outdir}/results", mode: 'copy'

    input:
    path bracken_matrix   // bracken_raw_matrix.tsv  (pre-filtering baseline)
    path minreads_matrix  // minreads_matrix.tsv      (after read-count threshold)
    path final_matrix     // viral_abundance_matrix.tsv (final: + artifact exclusion)
    path filter_summaries // collection of per-sample filter_summary.tsv files
    path sample_metadata  // samplesheet CSV

    output:
    path "virome_report/", emit: report_dir

    script:
    def summary_args = filter_summaries instanceof List
        ? filter_summaries.collect { "--filter-summary $it" }.join(' \\\n        ')
        : "--filter-summary ${filter_summaries}"
    """
    virome_report.py \\
        --bracken-matrix  ${bracken_matrix} \\
        --minreads-matrix ${minreads_matrix} \\
        --matrix          ${final_matrix} \\
        ${summary_args} \\
        --metadata        ${sample_metadata} \\
        --outdir          virome_report
    """
}
