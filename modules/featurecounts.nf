process FEATURECOUNTS {

    container "${params.container_dir}/host_quant.sif"

    publishDir "${params.outdir}/host_quant", mode: 'copy'

    input:
    path bams  // collection of per-sample dedup/filtered BAMs (all samples, one job)
    path gtf

    output:
    path "featurecounts_raw.csv",          emit: matrix
    path "featurecounts_raw.summary.csv",  emit: summary

    script:
    """
    featurecounts_host.R . ${gtf} true ${task.cpus} featurecounts_raw.csv
    """
}
