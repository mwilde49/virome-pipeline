process BRACKEN {
    tag "${meta.id}"

    container "${params.container_dir}/bracken.sif"

    input:
    tuple val(meta), path(kraken2_report)
    val   kraken2_db

    output:
    tuple val(meta), path("${meta.id}.bracken"),        emit: bracken_output
    tuple val(meta), path("${meta.id}.bracken_report"), emit: report

    script:
    """
    bracken \\
        -d ${kraken2_db} \\
        -i ${kraken2_report} \\
        -o ${meta.id}.bracken \\
        -w ${meta.id}.bracken_report \\
        -r ${params.bracken_read_length} \\
        -l ${params.bracken_level} \\
        -t ${params.bracken_threshold}
    """
}
