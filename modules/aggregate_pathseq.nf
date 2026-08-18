/*
 * modules/aggregate_pathseq.nf
 *
 * Collapse all samples' taxonomy-wide PathSeq scores.txt tables (see
 * modules/pathseq_score.nf) into a single pathseq_abundance_matrix.tsv, and
 * cross-check PathSeq's calls against the main pipeline's dual-DB Tier 1
 * consensus_matrix.tsv and, if available, the BLAST offshoot's per-(sample,
 * taxon) lifecycle_inference.tsv calls, producing a three-way
 * (Kraken2/Bracken consensus vs. PathSeq vs. BLAST) pathseq_concordance.tsv.
 *
 * consensus_matrix and blast_lifecycle_dir are optional `path` inputs using
 * the assets/NO_FILE sentinel pattern established by workflows/virome.nf
 * (ch_artifact_list, ch_taxon_remap, ch_gene_info) and
 * workflows/blast_verification.nf (ch_viral_refs) — the calling workflow
 * (workflows/pathseq_verification.nf) passes file("$projectDir/assets/NO_FILE")
 * when params.consensus_matrix / params.blast_lifecycle_dir are unset, and this
 * module checks `.name != 'NO_FILE'` before adding the corresponding CLI flag,
 * exactly like modules/aggregate_host_counts.nf's `gene_info_arg`.
 *
 * params.target_taxa (explicit comma-separated taxon IDs) is read directly
 * here rather than declared as a formal channel input — same precedent as
 * modules/blast_analyze.nf (params.blast_pident_threshold, etc.) and
 * modules/blast_verify.nf. It is the exact same param
 * workflows/blast_verification.nf's get_target_taxa() consumes (see
 * nextflow.config's "PathSeq verification offshoot" params comment) and takes
 * precedence over --consensus-matrix in bin/aggregate_pathseq.py's
 * resolve_target_taxa(), mirroring get_target_taxa()'s own precedence.
 */
process AGGREGATE_PATHSEQ {

    container "${params.container_dir}/pathseq.sif"

    publishDir "${params.outdir}/pathseq_verification", mode: 'copy'

    input:
    path scores_files                                                  // collected list, all samples' <id>.pathseq_scores.tsv
    path(consensus_matrix, stageAs: 'consensus_matrix_or_NO_FILE')      // optional -- assets/NO_FILE sentinel if params.consensus_matrix is unset
    path(blast_lifecycle_dir, stageAs: 'blast_lifecycle_dir_or_NO_FILE') // optional -- assets/NO_FILE sentinel if params.blast_lifecycle_dir is unset
    // Explicit, DISTINCT stageAs names are required here, not just the bare
    // NO_FILE-sentinel pattern used elsewhere in this repo (report.nf's
    // comparison_plot, aggregate_host_counts.nf's gene_info) -- those only
    // ever have ONE such optional input per process. This process has TWO,
    // and when both are unset they both resolve to the literal same source
    // file (assets/NO_FILE), which Nextflow refuses to stage twice under the
    // same default filename ("input file name collision"). Confirmed via a
    // real failed run 2026-08-15 -- see feedback_pipeline.md memory.

    output:
    path 'pathseq_abundance_matrix.tsv', emit: matrix
    path 'pathseq_concordance.tsv',      emit: concordance

    script:
    // Click `multiple=True` needs one repeated --scores flag per file, not a
    // single flag with space-separated paths -- see CLAUDE.md "Known issues /
    // gotchas" and the identical pattern in modules/aggregate.nf / aggregate_host_counts.nf.
    def scores_args = scores_files instanceof List
        ? scores_files.collect { "--scores $it" }.join(' \\\n        ')
        : "--scores ${scores_files}"
    // Check against the stageAs names declared above, not the literal
    // 'NO_FILE' string -- that's the SOURCE file's basename, but these two
    // inputs are deliberately staged under distinct names to avoid the
    // collision described in the input: block comment above.
    def consensus_arg = consensus_matrix.name != 'consensus_matrix_or_NO_FILE' ? "--consensus-matrix ${consensus_matrix}" : ''
    def lifecycle_arg = blast_lifecycle_dir.name != 'blast_lifecycle_dir_or_NO_FILE' ? "--blast-lifecycle-dir ${blast_lifecycle_dir}" : ''
    def target_taxa_arg = params.target_taxa ? "--target-taxa '${params.target_taxa}'" : ''
    """
    aggregate_pathseq.py \\
        ${scores_args} \\
        ${consensus_arg} \\
        ${target_taxa_arg} \\
        ${lifecycle_arg} \\
        --outdir .
    """
}
