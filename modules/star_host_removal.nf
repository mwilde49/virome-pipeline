process STAR_HOST_REMOVAL {
    tag "${meta.id}"

    container "${projectDir}/containers/star.sif"

    input:
    tuple val(meta), path(r1), path(r2)
    path  star_index

    output:
    tuple val(meta), path("${meta.id}_unmapped_R1.fastq.gz"), path("${meta.id}_unmapped_R2.fastq.gz"), emit: reads
    tuple val(meta), path("${meta.id}_Log.final.out"),                                                  emit: log

    script:
    """
    STAR \\
        --runThreadN ${task.cpus} \\
        --genomeDir ${star_index} \\
        --readFilesIn ${r1} ${r2} \\
        --readFilesCommand zcat \\
        --outSAMtype BAM SortedByCoordinate \\
        --outSAMattributes NH HI AS NM \\
        --outFilterMultimapNmax 1 \\
        --outFileNamePrefix ${meta.id}_ \\
        --outReadsUnmapped Fastx \\
        --runMode alignReads \\
        ${params.star_extra_args}

    # Compress and rename unmapped reads to standard naming
    gzip -c ${meta.id}_Unmapped.out.mate1 > ${meta.id}_unmapped_R1.fastq.gz
    gzip -c ${meta.id}_Unmapped.out.mate2 > ${meta.id}_unmapped_R2.fastq.gz
    """
}
