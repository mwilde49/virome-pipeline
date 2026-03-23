process MULTIQC {

    container "${params.container_dir}/multiqc.sif"

    publishDir "${params.outdir}/multiqc", mode: 'copy'

    input:
    path qc_files  // collection: FastQC zips, Trimmomatic logs, STAR logs, Kraken2 reports

    output:
    path "multiqc_report.html", emit: report
    path "multiqc_data/",       emit: data

    script:
    def config = params.multiqc_config ? "--config ${params.multiqc_config}" : ''
    def title  = params.multiqc_title  ? "--title '${params.multiqc_title}'"  : ''
    """
    multiqc \\
        ${config} \\
        ${title} \\
        --filename multiqc_report.html \\
        --force \\
        .
    """
}
