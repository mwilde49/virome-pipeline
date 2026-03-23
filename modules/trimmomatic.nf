process TRIMMOMATIC {
    tag "${meta.id}"

    container "${params.container_dir}/trimmomatic.sif"

    input:
    tuple val(meta), path(r1), path(r2)
    path  adapters

    output:
    tuple val(meta), path("${meta.id}_R1_trimmed.fastq.gz"), path("${meta.id}_R2_trimmed.fastq.gz"), emit: reads
    tuple val(meta), path("${meta.id}_trimmomatic.log"),                                              emit: log

    script:
    def headcrop = params.trim_headcrop > 0 ? "HEADCROP:${params.trim_headcrop}" : ''
    """
    trimmomatic PE \\
        -threads ${task.cpus} \\
        -phred33 \\
        ${r1} ${r2} \\
        ${meta.id}_R1_trimmed.fastq.gz ${meta.id}_R1_unpaired.fastq.gz \\
        ${meta.id}_R2_trimmed.fastq.gz ${meta.id}_R2_unpaired.fastq.gz \\
        ILLUMINACLIP:${adapters}:2:30:10:8:true \\
        ${headcrop} \\
        LEADING:${params.trim_leading} \\
        TRAILING:${params.trim_trailing} \\
        SLIDINGWINDOW:${params.trim_slidingwindow} \\
        MINLEN:${params.trim_minlen} \\
        2> ${meta.id}_trimmomatic.log
    """
}
