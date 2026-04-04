process STAR_HOST_REMOVAL {
    tag "${meta.id}"

    container "${params.container_dir}/star.sif"

    // Publish the host-removed (unmapped) FASTQ files when params.save_unmapped_reads is true.
    // These files are required by the BLAST verification offshoot pipeline.
    // Enable with: save_unmapped_reads: true in your params file.
    publishDir "${params.outdir}/star_unmapped", mode: 'copy', enabled: params.save_unmapped_reads ?: false,
        saveAs: { fn -> fn.endsWith('_unmapped_R1.fastq.gz') || fn.endsWith('_unmapped_R2.fastq.gz') ? fn : null }

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
