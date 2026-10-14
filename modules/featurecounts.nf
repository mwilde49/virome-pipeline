process FEATURECOUNTS {

    container "${params.container_dir}/host_quant.sif"

    publishDir "${params.outdir}/host_quant", mode: 'copy'

    input:
    path bams  // collection of per-sample dedup/filtered BAMs (all samples, one job)
    path gtf

    output:
    path "featurecounts_raw.csv",          emit: matrix
    path "featurecounts_raw.summary.csv",  emit: summary

    script:
    """
    # Rsubread's featureCounts() (inside bin/featurecounts_host.R, baked into
    # host_quant.sif) processes every sample's BAM in ONE batch call -- unlike
    # the per-sample Bracken case, a single BAM with zero properly-paired reads
    # left after DEDUP_FILTER_HOST's dedup+filter steps makes it hard-error
    # ("No paired-end reads were detected in paired-end read library") and
    # halts the WHOLE call, losing every other sample's counts too, not just
    # the bad one's. Real case: 118T8R (Thoracic DRG, 2026-10-13) -- already a
    # known near-zero-signal sample per the viral-arm screen, so an empty BAM
    # here isn't a surprise. Fix: pre-filter with samtools (already in this
    # container) before the batch call -- move out any BAM with zero
    # primary, paired-flagged reads, run featureCounts on the rest, then
    # synthesize a zero-count column for each excluded sample so the output
    # matrix still covers the full cohort. No R-script change, no container
    # rebuild -- pure shell logic in this process script.
    mkdir -p excluded_bams
    : > excluded_samples.txt
    for bam in *.bam; do
        paired_reads=\$(samtools view -c -f 1 -F 0x900 "\$bam")
        if [ "\$paired_reads" -eq 0 ]; then
            echo "\$(basename "\$bam" .bam) has 0 primary paired-end reads -- excluding from featureCounts batch call, will synthesize zero counts" >&2
            echo "\$(basename "\$bam" .bam)" >> excluded_samples.txt
            mv "\$bam" excluded_bams/
        fi
    done

    featurecounts_host.R . ${gtf} true ${task.cpus} featurecounts_raw.csv

    while read -r sample; do
        [ -z "\$sample" ] && continue
        awk -F',' -v OFS=',' -v s="\$sample" 'NR==1{print \$0, s} NR>1{print \$0, 0}' \\
            featurecounts_raw.csv > tmp_fc.csv && mv tmp_fc.csv featurecounts_raw.csv
        awk -F',' -v OFS=',' -v s="\$sample" 'NR==1{print \$0, s} NR>1{print \$0, 0}' \\
            featurecounts_raw.summary.csv > tmp_fc_summary.csv && mv tmp_fc_summary.csv featurecounts_raw.summary.csv
    done < excluded_samples.txt
    """
}
