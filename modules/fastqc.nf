process FASTQC {
    tag "${meta.id}"
    label 'process_low'

    container "${projectDir}/containers/fastqc.sif"

    input:
    tuple val(meta), path(r1), path(r2)

    output:
    tuple val(meta), path("*.html"), emit: html
    tuple val(meta), path("*.zip"),  emit: zip

    script:
    def prefix = meta.id
    """
    fastqc \\
        --threads ${task.cpus} \\
        --outdir . \\
        ${r1} ${r2}
    """
}
