/*
 * modules/telescope_assign.nf
 *
 * Runs `telescope assign` (Bendall et al. 2019, mlbendall/telescope) against
 * the multi-mapper-permissive BAM from STAR_REALIGN_MULTIMAP and a TE/HERV
 * locus annotation GTF, producing an EM-reassigned per-locus read count.
 *
 * Output: ONE file, `<sample>-telescope_report.tsv` -- CORRECTED 2026-09-18 by
 * the synthetic-data smoke test. git master's telescope/utils/model.py
 * (fetched directly, pre-build) showed a two-file split (run_stats.tsv +
 * TE_counts.tsv, no `final_count` column) -- but that's unreleased dev code.
 * bioconda's actual shipped 1.0.3 (what containers/telescope.def installs)
 * produces the OLDER single-file format instead, confirmed by inspecting a
 * real run's output directly: a `## RunInfo\t...` comment line, then a
 * tab-separated table with a `final_count` column (transcript,
 * transcript_length, final_count, final_conf, final_prop, init_aligned,
 * unique_count, init_best, init_best_random, init_best_avg, init_prop) plus
 * a `__no_feature` row for unassigned fragments. See
 * bin/aggregate_telescope.py's module docstring for the parsing details.
 *
 * reassign_mode (params.telescope_reassign_mode, default 'exclude' -- the
 * tool's own default): governs how the EM-fit proportions are converted into
 * final integer-ish counts for ambiguous/multi-mapped fragments. 'exclude'
 * drops fragments that remain ambiguous after EM fitting rather than
 * fractionally splitting them -- conservative, and what most published
 * Telescope papers use, but a real choice with downstream-analysis
 * consequences. Exposed as a param rather than hardcoded so it's easy to
 * revisit once real data is in hand.
 *
 * --ncpu is passed for forward-compatibility but per telescope's own
 * argparse help text ("Multiple cores not supported yet") is currently a
 * no-op -- do not expect this process to actually parallelize internally.
 */

process TELESCOPE_ASSIGN {
    tag "${meta.id}"

    container "${params.container_dir}/telescope.sif"

    input:
    tuple val(meta), path(bam)
    path  telescope_annotation

    output:
    tuple val(meta), path("${meta.id}-telescope_report.tsv"),  emit: report

    script:
    def reassign_mode = params.telescope_reassign_mode ?: 'exclude'
    """
    # telescope assign fetches per-locus via pysam's indexed random access
    # (confirmed by a real synthetic-data run, 2026-09-18: fails outright
    # with "fetch called on bamfile without index" otherwise) -- the BAM
    # must be coordinate-sorted (see modules/star_realign_multimap.nf) AND
    # indexed here.
    samtools index ${bam}

    telescope assign \\
        --exp_tag ${meta.id} \\
        --outdir . \\
        --ncpu ${task.cpus} \\
        --reassign_mode ${reassign_mode} \\
        ${bam} \\
        ${telescope_annotation}
    """
}
