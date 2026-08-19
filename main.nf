#!/usr/bin/env nextflow

nextflow.enable.dsl = 2

include { VIROME } from './workflows/virome'
include { generateProvenance } from './lib/provenance'

//
// Entry point — parses samplesheet and launches the VIROME workflow
//

workflow {

    // Pipeline-native provenance report -- see lib/provenance.nf. Registered
    // FIRST, before any param validation/error below, so it still fires (and
    // still produces a provenance/ dir with a FAILED-status report) even when
    // this run fails fast on a missing required param -- workflow.onComplete
    // only fires for handlers that actually got registered before the run
    // ended, and `error "..."` below throws immediately. Runs on both success
    // and failure. Produces ${params.outdir}/provenance/{manifest.json,
    // software_versions.yml (from VIROME's CAPTURE_SOFTWARE_VERSIONS process),
    // PROVENANCE_README.md} identically whether launched via tjp-launch/SLURM or
    // a bare `nextflow run main.nf -profile standard` with no framework at all.
    workflow.onComplete {
        generateProvenance('main')
    }

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
