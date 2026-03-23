process KRAKEN2_FILTER {
    tag "${meta.id}"

    container "${params.container_dir}/python.sif"

    input:
    tuple val(meta), path(report)

    output:
    tuple val(meta), path("${meta.id}.filtered.tsv"), emit: filtered

    script:
    """
    filter_kraken2_report.py \\
        --report ${report} \\
        --min-reads ${params.min_reads_per_taxon} \\
        --output ${meta.id}.filtered.tsv
    """
}
