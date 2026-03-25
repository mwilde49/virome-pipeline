process REPORT {

    container "${params.container_dir}/python.sif"

    publishDir "${params.outdir}/results", mode: 'copy'

    input:
    path bracken_matrix      // bracken_raw_matrix.tsv  (pre-filtering baseline)
    path minreads_matrix     // minreads_matrix.tsv      (after read-count threshold)
    path final_matrix        // viral_abundance_matrix.tsv (final: + artifact exclusion)
    path filter_summaries    // collection of per-sample filter_summary.tsv files
    path sample_metadata     // samplesheet CSV
    path comparison_plot     // db_comparison.png (optional; NO_FILE if single-DB run)

    output:
    path "virome_report/", emit: report_dir

    script:
    def summary_args = filter_summaries instanceof List
        ? filter_summaries.collect { "--filter-summary $it" }.join(' \\\n        ')
        : "--filter-summary ${filter_summaries}"
    def comparison_arg = comparison_plot.name != 'NO_FILE' ? "--comparison-plot ${comparison_plot}" : ''
    """
    virome_report.py \\
        --bracken-matrix  ${bracken_matrix} \\
        --minreads-matrix ${minreads_matrix} \\
        --matrix          ${final_matrix} \\
        ${summary_args} \\
        --metadata        ${sample_metadata} \\
        ${comparison_arg} \\
        --outdir          virome_report
    """
}
