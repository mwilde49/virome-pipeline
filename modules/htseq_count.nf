process HTSEQ_COUNT {

    container "${params.container_dir}/host_quant.sif"

    publishDir "${params.outdir}/host_quant", mode: 'copy'

    input:
    path bams  // collection of per-sample dedup/filtered BAMs (all samples, one job)
    path gtf

    output:
    path "htseq_raw.tsv", emit: matrix

    script:
    def bam_list = bams instanceof List ? bams : [bams]
    def header   = (['gene_id'] + bam_list.collect { it.name.replace('.filt.bam', '') }).join('\t')
    def bam_args = bam_list.join(' ')
    """
    echo -e "${header}" > htseq_raw.tsv
    htseq-count \\
        -f bam \\
        -s ${params.htseq_strand} \\
        -r ${params.htseq_paired_order} \\
        ${bam_args} \\
        ${gtf} \\
        >> htseq_raw.tsv
    """
}
