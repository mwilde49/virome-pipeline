#!/usr/bin/env nextflow

/*
 * telescope_verify.nf — Entry point for the Telescope verification offshoot pipeline.
 *
 * Locus-level HML-2 (HERV-K) quantification via Telescope (Bendall et al.
 * 2019), the "gating experiment" for the HERV-K thesis project — see
 * workflows/telescope_verification.nf for the full rationale and
 * HERVK/experimental_roadmap.md Phase 1 Experiment 1 for the biology.
 *
 * Usage:
 *   nextflow run telescope_verify.nf -profile slurm -params-file assets/config_telescope_<cohort>.yaml
 *
 * Samplesheet CSV format (sample,fastq_r1,fastq_r2) — the SAME shape as
 * main.nf's samplesheet (original/trimmed FASTQs), NOT blast_verify.nf's or
 * pathseq_verify.nf's (those take the STAR-unmapped pool). See
 * workflows/telescope_verification.nf's header for why this offshoot needs
 * its own re-alignment of the original reads rather than reusing the main
 * pipeline's unmapped output.
 *
 * Required params:
 *   samplesheet          — path to samplesheet CSV
 *   outdir                — output directory
 *   star_index            — GRCh38 STAR index (same one main.nf uses)
 *   telescope_annotation  — Telescope-format HML-2/TE annotation GTF
 *
 * Optional params: see workflows/telescope_verification.nf header.
 */

nextflow.enable.dsl = 2

include { TELESCOPE_VERIFICATION } from './workflows/telescope_verification'
include { generateProvenance } from './lib/provenance'

workflow {

    // Pipeline-native provenance report -- see lib/provenance.nf. Registered
    // FIRST so it still fires (producing a FAILED-status provenance/ report)
    // even if this run fails fast on a missing required param below.
    workflow.onComplete {
        generateProvenance('telescope_verify')
    }

    if (!params.samplesheet)          error "Please provide --samplesheet <path>"
    if (!params.outdir)               error "Please provide --outdir <path>"
    if (!params.star_index)           error "Please provide --star_index <path>"
    if (!params.telescope_annotation) error "Please provide --telescope_annotation <path>"

    Channel
        .fromPath(params.samplesheet)
        .splitCsv(header: true, strip: true)
        .map { row ->
            def meta = [ id: row.sample ]
            def r1   = file(row.fastq_r1, checkIfExists: true)
            def r2   = file(row.fastq_r2, checkIfExists: true)
            [ meta, r1, r2 ]
        }
        .set { ch_samples }

    TELESCOPE_VERIFICATION(ch_samples)
}
