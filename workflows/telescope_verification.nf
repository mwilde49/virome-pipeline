/*
 * workflows/telescope_verification.nf
 *
 * Telescope Verification Offshoot — locus-level HML-2 (HERV-K) quantification
 * via Telescope (Bendall et al. 2019, mlbendall/telescope), the "gating
 * experiment" for the HERV-K thesis project (HERVK/experimental_roadmap.md,
 * Phase 1 Experiment 1). Every HERV-K number produced by the main pipeline is
 * Kraken2/Bracken species-level (taxon 45617, all ~90 full-length HML-2
 * proviruses + ~1000 solo LTRs collapsed into one number) — this offshoot
 * asks which specific genomic loci are driving that signal.
 *
 * Structurally a sibling to blast_verify.nf / pathseq_verify.nf (separate
 * entry point, opt-in, post-hoc), but with one load-bearing difference: input
 * is NOT the main pipeline's STAR-unmapped/host-depleted pool. HML-2 reads
 * map to GRCh38 (they're endogenous loci already in the reference) and are
 * exactly what star_host_removal.nf's `--outFilterMultimapNmax 1` discards as
 * "too many loci" — so this offshoot re-aligns the ORIGINAL (trimmed) input
 * FASTQs itself, multi-mapper-permissive, via its own dedicated
 * STAR_REALIGN_MULTIMAP step. See modules/star_realign_multimap.nf for the
 * full reasoning and the STAR parameter citations.
 *
 * Input samplesheet format (CSV) — same shape as main.nf's samplesheet, NOT
 * pathseq_verify.nf's/blast_verify.nf's (those take the unmapped pool):
 *   sample,fastq_r1,fastq_r2
 *   TG3,/path/to/TG3_R1.fastq.gz,/path/to/TG3_R2.fastq.gz
 *
 * Required params:
 *   params.star_index            — same GRCh38 STAR index main.nf uses
 *   params.telescope_annotation  — Telescope-format GTF of TE/HML-2 loci.
 *                                   Recommended: HERV_rmsk.hg38.v2's
 *                                   transcripts.gtf from mlbendall/
 *                                   telescope_annotation_db (HERV-only,
 *                                   ~fits this project's HML-2 focus) —
 *                                   NOT retro.hg38.v1 (combines HERV + L1,
 *                                   ~28.5k loci, would dilute/slow the run
 *                                   with LINE-1 elements this project
 *                                   doesn't care about). See
 *                                   assets/config_telescope_template.yaml
 *                                   for the exact download command.
 *                                   CORRECTION to HERVK/experimental_roadmap.md:
 *                                   that doc calls this "RetroSpective v2,
 *                                   from Hammell lab GitHub" — verified
 *                                   2026-09-18 that Telescope and its
 *                                   annotation db are both mlbendall
 *                                   (Weill Cornell), not Hammell lab (that
 *                                   appears to be a mix-up with the
 *                                   different TEtranscripts tool, also CSHL);
 *                                   and there is no "v2" of the combined
 *                                   retro build, only retro.hg38.v1.
 *
 * Optional params:
 *   params.telescope_reassign_mode           — default 'exclude' (see
 *                                                modules/telescope_assign.nf)
 *   params.telescope_star_multimap_nmax      — default 100
 *   params.telescope_star_sam_mult_nmax      — default 100
 *   params.telescope_star_anchor_multimap_nmax — default 100
 */

nextflow.enable.dsl = 2

include { STAR_REALIGN_MULTIMAP } from '../modules/star_realign_multimap'
include { TELESCOPE_ASSIGN      } from '../modules/telescope_assign'
include { AGGREGATE_TELESCOPE   } from '../modules/aggregate_telescope'
include { CAPTURE_SOFTWARE_VERSIONS } from '../modules/capture_software_versions'
include { telescopeToolSpecs    } from '../lib/provenance'


workflow TELESCOPE_VERIFICATION {

    take:
    ch_samples  // [ meta(id), path(r1), path(r2) ] -- ORIGINAL trimmed FASTQs, not unmapped pool

    main:

    if (!params.star_index)           error "params.star_index is required"
    if (!params.telescope_annotation) error "params.telescope_annotation is required"

    ch_star_index = file(params.star_index, checkIfExists: true)
    ch_annotation = file(params.telescope_annotation, checkIfExists: true)

    // -------------------------------------------------------------------------
    // Step 1 — dedicated multi-mapper-permissive STAR re-alignment (NOT
    // star_host_removal.nf — see module header for why they can't be shared).
    // -------------------------------------------------------------------------
    STAR_REALIGN_MULTIMAP(ch_samples, ch_star_index)

    // -------------------------------------------------------------------------
    // Step 2 — telescope assign: EM-based locus reassignment per sample.
    // -------------------------------------------------------------------------
    TELESCOPE_ASSIGN(STAR_REALIGN_MULTIMAP.out.bam, ch_annotation)

    // -------------------------------------------------------------------------
    // Step 3 — collect all samples' telescope_report.tsv (+ STAR logs for
    // RPM) into one locus x sample matrix.
    // -------------------------------------------------------------------------
    ch_all_counts = TELESCOPE_ASSIGN.out.report
        .map { meta, tsv -> tsv }
        .collect()

    ch_all_logs = STAR_REALIGN_MULTIMAP.out.log
        .map { meta, log -> log }
        .collect()

    AGGREGATE_TELESCOPE(ch_all_counts, ch_all_logs)

    // Provenance — real, live-queried container tool versions. See
    // lib/provenance.nf (manifest.json / PROVENANCE_README.md are written
    // from telescope_verify.nf's workflow.onComplete{}).
    CAPTURE_SOFTWARE_VERSIONS(telescopeToolSpecs())

    emit:
    matrix = AGGREGATE_TELESCOPE.out.matrix
}
