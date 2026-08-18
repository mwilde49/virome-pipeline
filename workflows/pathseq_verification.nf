/*
 * workflows/pathseq_verification.nf
 *
 * PathSeq Verification Offshoot — GATK4 PathSeqPipelineSpark run on STAR-unmapped
 * reads, providing a third-opinion, taxonomy-wide validation of the main
 * pipeline's Kraken2/Bracken calls (and, transitively, the BLAST offshoot's
 * identity/lifecycle calls). Unlike blast_verification.nf, PathSeq classifies
 * the ENTIRE unmapped read pool for a sample in ONE run, producing an all-taxa
 * (viral, bacterial, everything) abundance table — there is no upfront
 * per-taxon read extraction and no per-taxon channel expansion. Filtering down
 * to specific candidate taxa happens afterward in AGGREGATE_PATHSEQ by looking
 * those taxon IDs up in the PathSeq scores table.
 *
 * Intended use: a Tier-1-only, post-hoc offshoot for publication-critical novel
 * calls (PD19-class findings) run after the BLAST offshoot, not routine
 * per-cohort infrastructure. See docs/pathseq_and_test_datasets_2026-08-14.md
 * ("Part 1 — GATK PathSeq") for the full rationale, compute-cost citations, and
 * reference-bundle provenance.
 *
 * Input is already host-depleted: PathSeq's own host-subtraction step
 * (PathSeqFilterSpark) is intentionally skipped entirely — no host k-mer file
 * or host BWA image is ever passed to PathSeqPipelineSpark — because
 * STAR_HOST_REMOVAL upstream has already removed GRCh38-mapped reads. See
 * modules/pathseq_score.nf for the GATK source citations confirming
 * host-filter arguments are optional and that omitting them is the documented
 * way to feed already-host-depleted input.
 *
 * Input samplesheet format (CSV) — simpler than blast_verification.nf's, no
 * kraken2_output column (PathSeq does not do per-taxon read extraction):
 *   sample,fastq_r1,fastq_r2
 *   PD19,/path/to/PD19_unmapped_R1.fastq.gz,/path/to/PD19_unmapped_R2.fastq.gz
 *
 * Required params:
 *   params.pathseq_microbe_bwa_image — GATK PathSeq microbe BWA-MEM index image
 *   params.pathseq_microbe_fasta     — matching microbe reference FASTA; its .dict
 *                                       sibling (same path, .fasta/.fa/.fna suffix
 *                                       swapped for .dict) is resolved and staged
 *                                       alongside it below and is REQUIRED to exist
 *                                       — checkIfExists: true fails fast at parse
 *                                       time if the naming convention doesn't match
 *                                       the downloaded Broad PathSeq bundle
 *   params.pathseq_taxonomy          — PathSeq taxonomy file (PSTaxonomyDatabase)
 *
 * Optional params:
 *   params.consensus_matrix    — Tier 1 consensus_matrix.tsv from a prior dual-DB
 *                                 main-pipeline run (same param blast_verification.nf's
 *                                 get_target_taxa() reads); used here for concordance
 *                                 annotation only — it does NOT restrict what PathSeq
 *                                 classifies (PathSeq always scores all taxa).
 *   params.blast_lifecycle_dir — directory of {sample}.{taxon_id}.lifecycle_inference.tsv
 *                                 files from a prior blast_verify.nf run, enabling a
 *                                 three-way (Kraken2 / BLAST / PathSeq) concordance table.
 *                                 Default null (skipped).
 */

nextflow.enable.dsl = 2

include { FASTQ_TO_UBAM     } from '../modules/fastq_to_ubam'
include { PATHSEQ_SCORE     } from '../modules/pathseq_score'
include { AGGREGATE_PATHSEQ } from '../modules/aggregate_pathseq'


workflow PATHSEQ_VERIFICATION {

    take:
    ch_samples  // [ meta(id), path(r1), path(r2) ]

    main:

    if (!params.pathseq_microbe_bwa_image) error "params.pathseq_microbe_bwa_image is required"
    if (!params.pathseq_microbe_fasta)     error "params.pathseq_microbe_fasta is required"
    if (!params.pathseq_taxonomy)          error "params.pathseq_taxonomy is required"

    ch_microbe_bwa_image = file(params.pathseq_microbe_bwa_image, checkIfExists: true)
    ch_taxonomy          = file(params.pathseq_taxonomy,          checkIfExists: true)

    // PATHSEQ_SCORE's --microbe-dict argument is a required, distinct GATK input
    // (PSBwaArgumentCollection.java: MICROBE_REF_DICT_LONG_NAME "microbe-dict",
    // no `optional = true`) — it is NOT derived from the .fasta by Nextflow just
    // because the .dict happens to sit next to it on the reference filesystem.
    // Nextflow only stages files that are explicitly part of a channel's value,
    // so both the .fasta and its .dict sibling must be resolved and passed
    // together as a real two-element List<Path> here for modules/pathseq_score.nf's
    // `microbe_fasta instanceof List` / `.find { it.name.endsWith('.dict') }`
    // logic to ever actually find a staged .dict file (that logic was written to
    // accept a list — it just never received one before this fix).
    def microbe_fasta_path = file(params.pathseq_microbe_fasta, checkIfExists: true)
    def microbe_dict_path  = file(
        params.pathseq_microbe_fasta.replaceFirst(/\.(fasta|fa|fna)$/, '.dict'),
        checkIfExists: true
    )
    ch_microbe_fasta = [ microbe_fasta_path, microbe_dict_path ]

    // Optional inputs use the assets/NO_FILE sentinel pattern established by
    // workflows/virome.nf (ch_artifact_list, ch_taxon_remap, ch_gene_info) and
    // workflows/blast_verification.nf (ch_viral_refs) for optional path inputs.
    ch_consensus_matrix = params.consensus_matrix
        ? file(params.consensus_matrix, checkIfExists: true)
        : file("$projectDir/assets/NO_FILE")

    ch_blast_lifecycle_dir = params.blast_lifecycle_dir
        ? file(params.blast_lifecycle_dir, checkIfExists: true)
        : file("$projectDir/assets/NO_FILE")

    // -------------------------------------------------------------------------
    // Step 1 — FASTQ -> unaligned BAM (Picard FastqToSam via gatk).
    // PathSeqPipelineSpark requires BAM input, not FASTQ; no existing repo
    // precedent for this conversion. See modules/fastq_to_ubam.nf for the
    // verified FastqToSam flag citations (RG/SM tag requirements).
    // -------------------------------------------------------------------------
    FASTQ_TO_UBAM(ch_samples)

    // -------------------------------------------------------------------------
    // Step 2 — PathSeqPipelineSpark, local[*] mode, host-filter args omitted
    // (input is already STAR-host-depleted — see module header for citations).
    // -------------------------------------------------------------------------
    PATHSEQ_SCORE(
        FASTQ_TO_UBAM.out.ubam,
        ch_microbe_bwa_image,
        ch_microbe_fasta,
        ch_taxonomy
    )

    // -------------------------------------------------------------------------
    // Step 3 — collect all samples' scores tables into a single aggregation
    // job: a taxonomy-wide abundance matrix plus a Kraken2/BLAST/PathSeq
    // concordance table (consensus_matrix and blast_lifecycle_dir are both
    // optional; the aggregation script treats the NO_FILE sentinel as "skip").
    // -------------------------------------------------------------------------
    ch_all_scores = PATHSEQ_SCORE.out.scores
        .map { meta, tsv -> tsv }
        .collect()

    AGGREGATE_PATHSEQ(
        ch_all_scores,
        ch_consensus_matrix,
        ch_blast_lifecycle_dir
    )

    emit:
    matrix      = AGGREGATE_PATHSEQ.out.matrix
    concordance = AGGREGATE_PATHSEQ.out.concordance
}
