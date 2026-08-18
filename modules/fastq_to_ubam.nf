/*
 * modules/fastq_to_ubam.nf
 *
 * Convert host-depleted (STAR-unmapped) paired-end FASTQ reads into an
 * unaligned BAM (uBAM) via Picard FastqToSam (bundled in GATK4), which is
 * GATK4-PathSeqPipelineSpark's documented required input format. First step
 * of the PathSeq verification offshoot (pathseq_verify.nf); output feeds
 * PATHSEQ_SCORE (modules/pathseq_score.nf).
 *
 * GATK4/Picard flags verified against primary sources before use (not from
 * memory — per CONTRACT item 5):
 *   - picard/sam/FastqToSam.java (broadinstitute/picard, master branch, raw
 *     source fetched 2026-08-14): FASTQ (shortName F1) / FASTQ2 (F2) = input
 *     R1/R2, "optionally gzipped"; OUTPUT (O) = output BAM/SAM/CRAM;
 *     SAMPLE_NAME (SM) = required, read group SM tag; READ_GROUP_NAME (RG)
 *     = required, default "A", read group ID tag; SORT_ORDER default is
 *     'queryname' (left at default here — paired reads must stay adjacent
 *     for PathSeq's downstream BWA alignment step).
 *   - nf-core/modules gatk4/fastqtosam main.nf (fetched 2026-08-14) confirms
 *     real production usage of this exact tool through the `gatk` wrapper:
 *     GATK4 double-dash long-form argument syntax (--FASTQ, --FASTQ2,
 *     --OUTPUT, --SAMPLE_NAME, --TMP_DIR), NOT the legacy Picard-jar
 *     `NAME=value` syntax — and the --java-options Xmx-sizing pattern
 *     mirrored below.
 *
 * PathSeqPipelineSpark's documented input BAM requirement is a read group
 * SM tag and a single sample per BAM — both are set explicitly here
 * (SAMPLE_NAME and READ_GROUP_NAME to meta.id) rather than relying on
 * FastqToSam's SM-optional-if-single-readgroup default behavior.
 *
 * This step performs no host filtering of any kind — the input FASTQs are
 * already host-depleted by STAR_HOST_REMOVAL upstream of the offshoot
 * samplesheet, and PathSeq's own host-subtraction stage is intentionally
 * skipped entirely in this pipeline (see PATHSEQ_SCORE).
 *
 * Inputs:
 *   meta      — sample metadata map (id)
 *   r1, r2    — STAR-unmapped (host-depleted) paired-end FASTQ.gz files
 *
 * Outputs:
 *   ubam      — {id}.unaligned.bam — queryname-sorted unaligned BAM with a
 *               single read group (SM = RG = meta.id), ready for
 *               PATHSEQ_SCORE
 */

process FASTQ_TO_UBAM {
    tag "${meta.id}"

    container "${params.container_dir}/pathseq.sif"

    input:
    tuple val(meta), path(r1), path(r2)

    output:
    tuple val(meta), path("${meta.id}.unaligned.bam"), emit: ubam

    script:
    // GATK4-wrapped Picard tools take the standard GATK4 double-dash
    // long-form argument syntax (confirmed against nf-core/modules
    // gatk4/fastqtosam main.nf — see header comment), not Picard-jar
    // NAME=value syntax. --java-options heap sizing mirrors that same
    // reference implementation: JVM default heap heuristics are unreliable
    // inside a cgroup/container memory limit, so size Xmx explicitly off
    // task.memory rather than let the JVM guess.
    def avail_mem = 3072
    if (!task.memory) {
        log.info "[FASTQ_TO_UBAM] Available memory not known for ${meta.id} — defaulting Xmx to 3072M. Set process memory to override."
    } else {
        avail_mem = (task.memory.mega * 0.8).intValue()
    }
    """
    gatk --java-options "-Xmx${avail_mem}M -XX:-UsePerfData" FastqToSam \\
        --FASTQ ${r1} \\
        --FASTQ2 ${r2} \\
        --OUTPUT ${meta.id}.unaligned.bam \\
        --SAMPLE_NAME ${meta.id} \\
        --READ_GROUP_NAME ${meta.id} \\
        --PLATFORM ILLUMINA \\
        --TMP_DIR .
    """
}
