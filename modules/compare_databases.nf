process COMPARE_DATABASES {

    container "${params.container_dir}/python.sif"

    publishDir "${params.outdir}/results/db_comparison", mode: 'copy'

    input:
    path viral_only_matrix   // viral_abundance_matrix.tsv (viral-only DB final)
    path pluspf_matrix       // pluspf_abundance_matrix.tsv (PlusPF DB final)

    output:
    path "db_comparison.tsv",              emit: comparison
    path "consensus_matrix.tsv",           emit: consensus
    path "false_positive_candidates.tsv",  emit: false_positives
    path "db_comparison_summary.tsv",      emit: summary
    path "db_comparison.png",              emit: plot

    script:
    """
    compare_db_results.py \\
        --viral-only-matrix ${viral_only_matrix} \\
        --pluspf-matrix     ${pluspf_matrix} \\
        --outdir            .
    """
}
