#!/usr/bin/env nextflow

/*
 * pathseq_verify.nf — Entry point for the PathSeq verification offshoot pipeline.
 *
 * Third-opinion, taxonomy-wide validation of the main pipeline's Kraken2/Bracken
 * calls using GATK4 PathSeqPipelineSpark, run on the same STAR-unmapped
 * (host-depleted) FASTQs blast_verify.nf consumes. Structurally a sibling to
 * blast_verify.nf, but classifies the ENTIRE unmapped read pool per sample in
 * one PathSeq run (all taxa — viral, bacterial, everything) rather than
 * extracting reads for specific target taxa upfront; filtering to candidate
 * taxa happens afterward in the aggregation step. Intended as a
 * publication-critical third-opinion validator for novel calls (PD19-class
 * findings), sequenced after the BLAST offshoot — not routine per-cohort
 * infrastructure. See docs/pathseq_and_test_datasets_2026-08-14.md
 * ("Part 1 — GATK PathSeq") for the full rationale and compute-cost citations.
 *
 * Usage:
 *   nextflow run pathseq_verify.nf -profile slurm -params-file assets/config_pathseq_XXX.yaml
 *
 * Samplesheet CSV format (sample,fastq_r1,fastq_r2) — simpler than
 * blast_verify.nf's samplesheet, no kraken2_output column:
 *   The fastq_r1/r2 columns should point to the STAR-unmapped (host-removed)
 *   FASTQ files from STAR_HOST_REMOVAL — the same files blast_verify.nf consumes.
 *
 *   If the main pipeline was run without publishDir on these intermediate files,
 *   locate them in the Nextflow work directory:
 *     find /scratch/juno/$USER/nf_work -name "PD19_unmapped_R1.fastq.gz" 2>/dev/null
 *
 *   Alternatively, re-run the main pipeline with params.save_unmapped_reads=true
 *   to publish these files to outdir.
 *
 * Required params:
 *   samplesheet                — path to samplesheet CSV
 *   outdir                     — output directory
 *   pathseq_microbe_bwa_image  — GATK PathSeq microbe BWA-MEM index image (.img)
 *   pathseq_microbe_fasta      — matching microbe reference FASTA; a .dict sibling
 *                                 (same path, .fasta/.fa/.fna -> .dict) MUST exist
 *                                 alongside it — resolved and required by
 *                                 workflows/pathseq_verification.nf
 *   pathseq_taxonomy           — PathSeq taxonomy file (PSTaxonomyDatabase, .db)
 *
 * Optional params:
 *   consensus_matrix     — path to consensus_matrix.tsv from a prior dual-DB main
 *                           pipeline run, for Kraken2/PathSeq concordance annotation
 *   target_taxa          — comma-separated taxon IDs (e.g. "3050292,10298"), an
 *                           alternative to consensus_matrix — same precedence as
 *                           blast_verify.nf's get_target_taxa() (explicit target_taxa
 *                           wins if both are set)
 *   blast_lifecycle_dir  — path to a directory of {sample}.{taxon_id}.lifecycle_inference.tsv
 *                           files from a prior blast_verify.nf run, for three-way
 *                           (Kraken2/BLAST/PathSeq) concordance
 */

nextflow.enable.dsl = 2

include { PATHSEQ_VERIFICATION } from './workflows/pathseq_verification'

workflow {

    if (!params.samplesheet)               error "Please provide --samplesheet <path>"
    if (!params.outdir)                    error "Please provide --outdir <path>"
    if (!params.pathseq_microbe_bwa_image) error "Please provide --pathseq_microbe_bwa_image <path>"
    if (!params.pathseq_microbe_fasta)     error "Please provide --pathseq_microbe_fasta <path>"
    if (!params.pathseq_taxonomy)          error "Please provide --pathseq_taxonomy <path>"

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

    PATHSEQ_VERIFICATION(ch_samples)
}
