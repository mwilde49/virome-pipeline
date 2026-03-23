process KRAKEN2_FILTER {
    tag "${meta.id}"

    container "${params.container_dir}/python.sif"

    input:
    tuple val(meta), path(report)
    path artifact_list

    output:
    tuple val(meta), path("${meta.id}.filtered.tsv"), emit: filtered

    script:
    def artifacts = artifact_list.name != 'NO_FILE' ? "--artifact-list ${artifact_list}" : ''
    """
    filter_kraken2_report.py \\
        --report ${report} \\
        --min-reads ${params.min_reads_per_taxon} \\
        ${artifacts} \\
        --output ${meta.id}.filtered.tsv
    """
}
