process KRAKEN2_FILTER {
    tag "${meta.id}"

    container "${params.container_dir}/python.sif"

    input:
    tuple val(meta), path(report)
    path artifact_list
    path taxon_remap

    output:
    tuple val(meta), path("${meta.id}.filtered.tsv"),          emit: filtered
    tuple val(meta), path("${meta.id}.bracken_raw.tsv"),       emit: bracken_raw
    tuple val(meta), path("${meta.id}.minreads.tsv"),          emit: minreads
    tuple val(meta), path("${meta.id}.filter_summary.tsv"),    emit: summary
    tuple val(meta), path("${meta.id}.artifacts_removed.tsv"), emit: artifacts

    script:
    def artifacts = artifact_list.name != 'NO_FILE' ? "--artifact-list ${artifact_list}" : ''
    def remap     = taxon_remap.name   != 'NO_FILE' ? "--taxon-remap ${taxon_remap}"     : ''
    """
    filter_kraken2_report.py \\
        --report       ${report} \\
        --sample-id    ${meta.id} \\
        --min-reads    ${params.min_reads_per_taxon} \\
        ${artifacts} \\
        ${remap} \\
        --output       ${meta.id}.filtered.tsv
    """
}
