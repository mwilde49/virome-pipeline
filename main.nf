#!/usr/bin/env nextflow

nextflow.enable.dsl = 2

include { VIROME } from './workflows/virome'

//
// Entry point — parses samplesheet and launches the VIROME workflow
//

workflow {

    // Validate required params
    if (!params.samplesheet) error "Please provide --samplesheet <path/to/samplesheet.csv>"
    if (!params.outdir)      error "Please provide --outdir <path/to/output>"

    // Parse samplesheet CSV: sample,fastq_r1,fastq_r2
    Channel
        .fromPath(params.samplesheet)
        .splitCsv(header: true, strip: true)
        .map { row ->
            def meta = [id: row.sample]
            def r1   = file(row.fastq_r1, checkIfExists: true)
            def r2   = file(row.fastq_r2, checkIfExists: true)
            [ meta, r1, r2 ]
        }
        .set { ch_reads }

    VIROME(ch_reads)
}
