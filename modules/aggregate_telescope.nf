/*
 * modules/aggregate_telescope.nf
 *
 * Merges all samples' Telescope *-telescope_report.tsv into one locus x
 * sample matrix via bin/aggregate_telescope.py. STAR realignment logs are
 * optional (RPM columns are added only for samples with a matching log --
 * see script docstring); the click multiple=True gotcha (CLAUDE.md "Known
 * issues") means each repeated flag must be passed individually, not
 * space-joined.
 */

process AGGREGATE_TELESCOPE {

    container "${params.container_dir}/telescope.sif"

    publishDir "${params.outdir}/telescope_verification", mode: 'copy'

    input:
    path te_counts_files  // collection of per-sample <sample>-telescope_report.tsv
    path star_logs        // collection of per-sample <sample>_Log.final.out (may be empty)

    output:
    path "telescope_locus_matrix.tsv", emit: matrix

    script:
    def counts_args = te_counts_files instanceof List
        ? te_counts_files.collect { "--counts $it" }.join(' \\\n        ')
        : "--counts ${te_counts_files}"
    def log_args = (star_logs instanceof List ? star_logs : [star_logs])
        .findAll { it.name != 'NO_FILE' }
        .collect { "--star-log $it" }.join(' \\\n        ')
    """
    aggregate_telescope.py \\
        ${counts_args} \\
        ${log_args} \\
        --output telescope_locus_matrix.tsv
    """
}
