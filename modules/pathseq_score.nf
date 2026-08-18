/*
 * modules/pathseq_score.nf
 *
 * Runs GATK4 PathSeqPipelineSpark (local mode) on a single sample's unaligned
 * BAM (uBAM) of STAR-unmapped, host-depleted reads, producing a taxonomy-wide
 * abundance table plus PathSeq's own filter/score metrics. Unlike the BLAST
 * verification offshoot, this classifies the ENTIRE unmapped read pool in one
 * shot (all taxa — viral, bacterial, everything); filtering down to specific
 * target taxa happens afterward in AGGREGATE_PATHSEQ by looking those taxon
 * IDs up in the output table.
 *
 * PathSeq's own host-subtraction stage is intentionally skipped: the input is
 * already host-depleted by STAR_HOST_REMOVAL upstream, so no host k-mer file
 * or host BWA image is passed (see the flag-verification comment above the
 * `gatk` invocation below for the source-cited proof that omitting both is
 * the documented/correct way to do this, not a guess).
 *
 * Inputs:
 *   meta               — sample metadata map (id)
 *   ubam                — FASTQ_TO_UBAM output: {id}.unaligned.bam
 *   microbe_bwa_image   — params.pathseq_microbe_bwa_image (BwaMemIndexImageCreator .img)
 *   microbe_fasta       — params.pathseq_microbe_fasta; only its .dict sibling is
 *                         actually consumed (PathSeqPipelineSpark does not take the
 *                         raw FASTA itself — see comment below). May arrive as a
 *                         single path or a list of paths (fasta + .dict + friends)
 *                         depending on how the calling workflow built the channel.
 *   taxonomy_file       — params.pathseq_taxonomy (PathSeqBuildReferenceTaxonomy .db)
 *
 * Outputs:
 *   scores          — {id}.pathseq_scores.tsv          (Bracken-analogous abundance table)
 *   filter_metrics  — {id}.pathseq_filter_metrics.txt
 *   score_metrics   — {id}.pathseq_score_metrics.txt
 *
 * Resource note: see conf/base.config's PATHSEQ_SCORE withName block — this is
 * the single most compute-hungry step in the offshoot (a Biostars report of
 * PathSeqPipelineSpark on this exact data shape, short-read bulk-RNA
 * STAR-unmapped reads, needed 200 GB heap and was still slow:
 * biostars.org/p/9603549).
 */

process PATHSEQ_SCORE {
    tag "${meta.id}"

    container "${params.container_dir}/pathseq.sif"

    // Closure form (not bare string interpolation) -- confirmed necessary,
    // not stylistic: the repo's existing bare-interpolation pattern for a
    // per-task publishDir (e.g. modules/blast_analyze.nf's
    // `publishDir "...${meta.id}..."`) throws "No such variable: meta" under
    // Nextflow 26.04.6 (verified 2026-08-14 while smoke-testing this file
    // locally). Juno's pinned Nextflow tolerates the older bare-string form
    // fine, so blast_analyze.nf is left as-is (out of scope, not broken in
    // production) -- but the closure form is valid on any Nextflow version,
    // so it costs nothing to use it here and it's what actually works for
    // local testing against a newer Nextflow.
    publishDir { "${params.outdir}/pathseq_verification/${meta.id}" }, mode: 'copy'

    input:
    tuple val(meta), path(ubam)
    path microbe_bwa_image
    path microbe_fasta
    path taxonomy_file

    output:
    tuple val(meta), path("${meta.id}.pathseq_scores.tsv"),         emit: scores
    tuple val(meta), path("${meta.id}.pathseq_filter_metrics.txt"), emit: filter_metrics
    tuple val(meta), path("${meta.id}.pathseq_score_metrics.txt"),  emit: score_metrics

    script:
    // microbe_fasta may be staged as a single Path or a List<Path> (fasta + .dict,
    // and possibly .fai/.img siblings), depending on how the calling workflow built
    // the params.pathseq_microbe_fasta channel (see workflows/pathseq_verification.nf).
    // Either way only the .dict is actually used below: PathSeqPipelineSpark.java's
    // own class-level Javadoc lists the required inputs as "Indexed microbe reference
    // dictionary (fasta file NOT required)" (lines 66-75), and PSBwaArgumentCollection
    // .java defines a distinct, required --microbe-dict file input with no matching
    // --microbe-fasta flag at all. Repo precedent for the instanceof-List guard on an
    // optionally-multi-file `path` input: modules/aggregate_host_counts.nf's
    // `star_logs instanceof List` check.
    def fasta_inputs = microbe_fasta instanceof List ? microbe_fasta : [microbe_fasta]
    def microbe_dict = fasta_inputs.find { it.name.endsWith('.dict') }
    if (!microbe_dict) {
        // Fall back to the standard samtools/Picard/GATK naming convention
        // (reference.fasta -> reference.dict). Still verified with -f below before
        // use, so a naming mismatch fails fast with a clear message instead of a
        // cryptic GATK stack trace.
        microbe_dict = fasta_inputs[0].name.replaceFirst(/\.(fasta|fa|fna)$/, '.dict')
    }

    // JVM heap: reserve room below the Nextflow-allocated task memory for the
    // microbe BWA image's off-heap memory-mapped footprint (BWA-MEM mmaps the
    // .img file; it does not live on the JVM heap) plus Spark/container
    // overhead, actually implementing the sizing intent of the Broad's own
    // pathseq_pipeline.wdl (PathSeqAlign task: `command_mem =
    // ceil((machine_mem - size(microbe_bwa_image,"MB"))*0.8)`) rather than
    // just citing it. Unlike that WDL -- which sizes filter/align/score as
    // three separate tasks -- this module runs the combined
    // PathSeqPipelineSpark in ONE JVM, so the align stage's mmap'd microbe
    // image shares task.memory with the JVM heap directly: skipping the
    // image-size subtraction (as an earlier version of this file did, with a
    // flat "-4GB") would leave <4 GB of headroom for a ~94.6 GB mmap'd
    // region under conf/base.config's 200.GB allocation -- a likely OOM kill
    // after hours of alignment work, not a cheap failure.
    // microbe_image_gb is hardcoded to the ~94.6 GB figure documented in
    // conf/base.config's PATHSEQ_SCORE comment (and
    // docs/pathseq_and_test_datasets_2026-08-14.md's Path-A bundle sizing)
    // rather than stat'd off the staged `microbe_bwa_image` Path at
    // script-generation time: that Groovy pre-script code runs before/
    // independent of the executor's actual file-staging step (staging can
    // happen on a different node under -profile slurm), so the file is not
    // guaranteed to be readable yet. This matches the repo's existing
    // convention of comment-documented, not dynamically-computed,
    // reference-bundle size constants (see conf/base.config's "PlusPF
    // hash.k2d is 87 GB" comment). If the microbe reference bundle is ever
    // swapped for a differently-sized one, update this constant to match.
    // With conf/base.config's 200.GB: (200 - 94.6) * 0.8 = 84.32 -> Xmx=84g,
    // leaving ~116 GB of headroom for the mmap'd image + Spark/container
    // overhead (vs. 196g/4GB headroom under the old flat "-4GB" formula).
    def microbe_image_gb = 94.6d
    def xmx_gb = 16
    if (task.memory) {
        def headroom_gb = Math.floor((task.memory.toGiga() - microbe_image_gb) * 0.8).intValue()
        xmx_gb = Math.max(4, headroom_gb)
    }
    """
    # --- GATK PathSeqPipelineSpark flags verified directly against GATK
    # (broadinstitute/gatk@master) source, fetched and read 2026-08-14 -- not
    # recalled from memory. One point per CONTRACT item 5:
    #
    # (a) Host-filter skip for already-host-depleted input: --kmer-file and
    #     --filter-bwa-image are both optional / default null
    #     (PSFilterArgumentCollection.java: KMER_FILE_PATH_LONG_NAME "kmer-file"
    #     l.53-56 doc "K-mer filtering is skipped if this is not specified";
    #     FILTER_BWA_IMAGE_LONG_NAME "filter-bwa-image" l.188-191, optional=true,
    #     default null). PSFilter.java's doFilter() explicitly gates each
    #     host-filtering sub-step on the corresponding field being non-null
    #     (l.270 `if (filterArgs.kmerFilePath != null)`, l.280
    #     `if (filterArgs.indexImageFile != null)`) -- so omitting both flags
    #     cleanly SKIPS k-mer and BWA-based host subtraction rather than
    #     erroring; this is the documented/correct way to feed already
    #     host-depleted input, not an unsupported workaround. --is-host-aligned
    #     is also left at its default (false), correct since Picard FastqToSam
    #     output is unaligned.
    # (b) --microbe-bwa-image (PSBwaArgumentCollection.java,
    #     MICROBE_BWA_IMAGE_LONG_NAME "microbe-bwa-image", required) /
    #     --microbe-dict (same file, MICROBE_REF_DICT_LONG_NAME "microbe-dict",
    #     required) / --taxonomy-file (PSScoreArgumentCollection.java,
    #     TAXONOMIC_DATABASE_LONG_NAME "taxonomy-file", short -T, required).
    # (c) --scores-output (PSScoreArgumentCollection.java,
    #     SCORES_OUTPUT_LONG_NAME "scores-output", short -SO, required) /
    #     --score-metrics (SCORE_METRICS_FILE_LONG_NAME "score-metrics", short
    #     -SM, optional) / --filter-metrics (PSFilterArgumentCollection.java,
    #     FILTER_METRICS_FILE_LONG_NAME "filter-metrics", optional). Both
    #     metrics files are written UNCONDITIONALLY whenever their flag is
    #     supplied, regardless of whether any host-filtering sub-step (kmer
    #     filter / BWA filter) actually ran: PathSeqPipelineSpark.java selects
    #     a real file-writing logger vs. a no-op logger purely on whether
    #     filterArgs.filterMetricsFileUri / scoreArgs.scoreMetricsFileUri is
    #     non-null (`filterArgs.filterMetricsFileUri != null ? new
    #     PSFilterFileLogger(...) : new PSFilterEmptyLogger()`, and the
    #     analogous `if (scoreArgs.scoreMetricsFileUri != null)` for score
    #     metrics) -- there is no additional gate on kmerFilePath /
    #     indexImageFile being set. So the required (non-optional) `path(...)`
    #     output declarations for filter_metrics/score_metrics below are safe
    #     even though this module always omits --kmer-file/--filter-bwa-image.
    # (d) No --spark-master given => local mode using all cores visible in the
    #     container ("local[*]"). Confirmed as the literal default:
    #     SparkContextFactory.java's DEFAULT_SPARK_MASTER =
    #     determineDefaultSparkMaster(), which returns "local[*]" unless the
    #     (test-only) GATK_TEST_SPARK_CORES env var is set -- irrelevant here.
    #     This also matches PathSeqPipelineSpark.java's own class-level Javadoc
    #     "Local mode" usage example (l.93-110), which passes no Spark options
    #     at all; Spark-cluster args, when used, go after a bare `--`
    #     separator per that same Javadoc's "Spark cluster" example, which we
    #     never use here.
    #
    # Sources (broadinstitute/gatk@master):
    #   src/main/java/.../tools/spark/pathseq/PathSeqPipelineSpark.java
    #   src/main/java/.../tools/spark/pathseq/PSFilterArgumentCollection.java
    #   src/main/java/.../tools/spark/pathseq/PSFilter.java
    #   src/main/java/.../tools/spark/pathseq/PSBwaArgumentCollection.java
    #   src/main/java/.../tools/spark/pathseq/PSScoreArgumentCollection.java
    #   src/main/java/.../engine/spark/SparkContextFactory.java
    #   scripts/pathseq/wdl/pathseq_pipeline.wdl

    if [[ ! -f "${microbe_dict}" ]]; then
        echo "ERROR: microbe reference .dict file not found: ${microbe_dict}" >&2
        echo "  PathSeqPipelineSpark's --microbe-dict wants the sequence dictionary," >&2
        echo "  not the raw FASTA (PathSeqPipelineSpark.java Javadoc: 'Indexed microbe" >&2
        echo "  reference dictionary (fasta file NOT required)'). Ensure a .dict file" >&2
        echo "  is staged alongside whatever params.pathseq_microbe_fasta resolves to." >&2
        exit 1
    fi

    gatk --java-options "-Xmx${xmx_gb}g" PathSeqPipelineSpark \\
        --input ${ubam} \\
        --microbe-bwa-image ${microbe_bwa_image} \\
        --microbe-dict ${microbe_dict} \\
        --taxonomy-file ${taxonomy_file} \\
        --scores-output ${meta.id}.pathseq_scores.tsv \\
        --score-metrics ${meta.id}.pathseq_score_metrics.txt \\
        --filter-metrics ${meta.id}.pathseq_filter_metrics.txt \\
        --verbosity WARNING
    """
}
