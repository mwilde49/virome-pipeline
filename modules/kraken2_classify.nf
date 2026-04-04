process KRAKEN2_CLASSIFY {
    tag "${meta.id}"

    container "${params.container_dir}/kraken2.sif"

    // Publish the per-read output file when params.save_kraken2_output is true.
    // This file is required by the BLAST verification offshoot pipeline.
    // Enable with: save_kraken2_output: true in your params file.
    publishDir "${params.outdir}/kraken2_output", mode: 'copy', enabled: params.save_kraken2_output ?: false,
        saveAs: { fn -> fn.endsWith('.kraken2.output') ? fn : null }

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
