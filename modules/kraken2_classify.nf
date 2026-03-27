process KRAKEN2_CLASSIFY {
    tag "${meta.id}"

    container "${params.container_dir}/kraken2.sif"

    input:
    tuple val(meta), path(r1), path(r2)
    path  kraken2_db

    output:
    tuple val(meta), path("${meta.id}.kraken2.output"),  emit: output
    tuple val(meta), path("${meta.id}.kraken2.report"),  emit: report

    script:
    """
    kraken2 \\
        --db ${kraken2_db} \\
        --threads ${task.cpus} \\
        --paired \\
        --gzip-compressed \\
        --confidence ${params.kraken2_confidence} \\
        --output ${meta.id}.kraken2.output \\
        --report ${meta.id}.kraken2.report \\
        ${params.kraken2_extra_args} \\
        ${r1} ${r2}
    """
}
