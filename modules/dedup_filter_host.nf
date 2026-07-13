process DEDUP_FILTER_HOST {
    tag "${meta.id}"

    container "${params.container_dir}/host_quant.sif"

    input:
    tuple val(meta), path(bam)
    path  blacklist_bed
    path  exclude_bed

    output:
    tuple val(meta), path("${meta.id}.filt.bam"), path("${meta.id}.filt.bam.bai"), emit: bam

    script:
    """
    sambamba markdup -r -t ${task.cpus} ${bam} ${meta.id}.dedup.bam
    samtools index ${meta.id}.dedup.bam

    bedtools intersect -v -abam ${meta.id}.dedup.bam -b ${exclude_bed} ${blacklist_bed} > ${meta.id}.filt.bam

    samtools index ${meta.id}.filt.bam
    """
}
