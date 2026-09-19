/*
 * modules/star_realign_multimap.nf
 *
 * Telescope verification offshoot -- dedicated STAR re-alignment, deliberately
 * SEPARATE from modules/star_host_removal.nf (the main pipeline's host-removal
 * step). The two cannot share a BAM:
 *
 *   - star_host_removal.nf runs `--outFilterMultimapNmax 1` (uniquely-mapped
 *     reads only) and its whole purpose is to feed Kraken2 the *unmapped*
 *     pool. HERV-K (HML-2) reads DO map to GRCh38 (they're endogenous
 *     retroviral loci already in the reference) -- they are exactly the kind
 *     of multi-locus-ambiguous read `--outFilterMultimapNmax 1` throws away
 *     as "mapped to too many loci". The main pipeline's unmapped pool
 *     (consumed by blast_verify.nf / pathseq_verify.nf) therefore contains
 *     ~none of the reads Telescope needs.
 *
 *   - Telescope instead needs the MAPPED, multi-mapper-permissive BAM, on
 *     the original (trimmed) input FASTQs, not the unmapped/host-depleted
 *     pool -- see HERVK/experimental_roadmap.md, Phase 1 Experiment 1,
 *     "How to run it".
 *
 * Params beyond the roadmap doc's literal spec (--outFilterMultimapNmax 100
 * --outSAMmultNmax 100): `--winAnchorMultimapNmax 100` is added here because
 * STAR's default anchor-seed search cap (50) silently limits how many loci a
 * read can even be considered for BEFORE outFilterMultimapNmax is evaluated --
 * raising outFilterMultimapNmax alone would not fully retain HML-2
 * multi-mappers, since ~90 near-identical full-length loci can exceed the
 * default anchor cap. This is standard STAR/TE-quantification practice (same
 * pairing used by TEtranscripts/SQuIRE-style pipelines), not something the
 * roadmap doc itself specifies -- flagging in case the PI wants to tune it.
 *
 * `--outSAMtype BAM SortedByCoordinate` (same as star_host_removal.nf):
 * CORRECTED 2026-09-18 by the synthetic-data smoke test, which is exactly
 * why that test exists before any real sample. Originally this module used
 * `BAM Unsorted`, reasoned from Telescope's CLI help text ("alignments for a
 * read pair appear sequentially"). That assumption was wrong: a real run
 * failed with `ValueError: fetch called on bamfile without index` --
 * Telescope's `telescope assign` (telescope/utils/alignment.py
 * fetch_region()) processes the BAM ONE ANNOTATED LOCUS AT A TIME via
 * pysam's indexed `AlignmentFile.fetch(region, ...)`, which requires a
 * coordinate-sorted, `.bai`-indexed BAM, not an unsorted one. See
 * modules/telescope_assign.nf for the samtools index step this requires.
 */

process STAR_REALIGN_MULTIMAP {
    tag "${meta.id}"

    container "${params.container_dir}/star.sif"

    input:
    tuple val(meta), path(r1), path(r2)
    path  star_index

    output:
    tuple val(meta), path("${meta.id}_Aligned.sortedByCoord.out.bam"),   emit: bam
    tuple val(meta), path("${meta.id}_Log.final.out"),                  emit: log

    script:
    """
    STAR \\
        --runThreadN ${task.cpus} \\
        --genomeDir ${star_index} \\
        --readFilesIn ${r1} ${r2} \\
        --readFilesCommand zcat \\
        --outSAMtype BAM SortedByCoordinate \\
        --outSAMattributes NH HI AS NM \\
        --outFilterMultimapNmax ${params.telescope_star_multimap_nmax ?: 100} \\
        --outSAMmultNmax ${params.telescope_star_sam_mult_nmax ?: 100} \\
        --winAnchorMultimapNmax ${params.telescope_star_anchor_multimap_nmax ?: 100} \\
        --outFileNamePrefix ${meta.id}_ \\
        --runMode alignReads \\
        ${params.star_extra_args}
    """
}
