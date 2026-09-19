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
 *
 * Zero-overlap edge case (confirmed by a real thoracic_drg run, 2026-09-19,
 * sample 116TR5 -- a known near-empty library, 549 total fragments):
 * `telescope assign` exits 0 and prints "No alignments overlapping
 * annotation" / "telescope assign complete" -- but simply does NOT write
 * the report file at all in this case. Nextflow then fails the task on a
 * missing declared output, even though the underlying command "succeeded".
 * A genuinely near-empty sample should produce a correctly-formatted
 * zero-count result, not a pipeline crash -- the script below synthesizes a
 * minimal valid report (just the `__no_feature` row) when telescope itself
 * doesn't write one, matching the exact format bin/aggregate_telescope.py
 * already parses (it already handles a `__no_feature`-only report
 * gracefully, treating it as zero counts across all loci -- no changes
 * needed there).
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

    if [ ! -f "${meta.id}-telescope_report.tsv" ]; then
        echo "telescope assign produced no report file -- synthesizing a minimal zero-count one (see module header)" >&2
        {
            echo -e "## RunInfo\\tno_overlapping_annotations:true"
            echo -e "transcript\\ttranscript_length\\tfinal_count\\tfinal_conf\\tfinal_prop\\tinit_aligned\\tunique_count\\tinit_best\\tinit_best_random\\tinit_best_avg\\tinit_prop"
            echo -e "__no_feature\\t0\\t0\\t0.00\\t0\\t0\\t0\\t0\\t0\\t0.00\\t0"
        } > "${meta.id}-telescope_report.tsv"
    fi
    """
}
