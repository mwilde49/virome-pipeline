process REPORT {

    container "${params.container_dir}/python.sif"

    publishDir "${params.outdir}/results", mode: 'copy'

    input:
    path abundance_matrix
    path sample_metadata   // optional: samplesheet re-used as metadata table

    output:
    path "virome_report/", emit: report_dir

    script:
    """
    virome_report.py \\
        --matrix ${abundance_matrix} \\
        --metadata ${sample_metadata} \\
        --outdir virome_report
    """
}
