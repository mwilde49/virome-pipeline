process BRACKEN {
    tag "${meta.id}"

    container "${params.container_dir}/bracken.sif"

    input:
    tuple val(meta), path(kraken2_report)
    path  kraken2_db

    output:
    tuple val(meta), path("${meta.id}.bracken"),        emit: bracken_output
    tuple val(meta), path("${meta.id}.bracken_report"), emit: report

    script:
    """
    # Bracken hard-errors ("Error: no reads found. Please check your Kraken
    # report") whenever a report doesn't carry enough classified reads at
    # params.bracken_level for it to build an abundance estimate. This is
    # NOT simply "no row exists at that rank" -- a prior version of this
    # guard checked exactly that and still missed real cases (sample
    # 116TR5, Thoracic DRG cohort, 2026-08-19: real rank-S rows present --
    # Orthobunyavirus simbuense with 2 direct reads, BeAn 58058 virus with
    # 1 -- just too few to clear bracken's own internal threshold, unrelated
    # to params.bracken_threshold=10 in any way an awk pre-check can cleanly
    # replicate). Rather than reverse-engineer bracken's internal
    # requirement in bash, just run it and catch its specific, known
    # failure message directly -- that way no future edge case in how
    # "too few reads" can manifest gets missed by an incomplete pre-check.
    # A genuine zero/near-zero-detection sample gets the original report
    # passed through untouched (downstream filter_kraken2_report.py already
    # handles zero viral-rank rows cleanly -- empty DataFrame, 0 taxa, no
    # crash); any OTHER bracken failure still aborts normally.
    set +e
    bracken \\
        -d ${kraken2_db} \\
        -i ${kraken2_report} \\
        -o ${meta.id}.bracken \\
        -w ${meta.id}.bracken_report \\
        -r ${params.bracken_read_length} \\
        -l ${params.bracken_level} \\
        -t ${params.bracken_threshold} \\
        > bracken.stdout.log 2> bracken.stderr.log
    BRACKEN_EXIT=\$?
    set -e

    if [ \$BRACKEN_EXIT -ne 0 ]; then
        if grep -q "no reads found" bracken.stderr.log; then
            echo "Bracken found insufficient classified reads in ${kraken2_report} -- treating as zero/near-zero detection, passing report through" >&2
            cp ${kraken2_report} ${meta.id}.bracken_report
            printf "name\\ttaxonomy_id\\ttaxonomy_lvl\\tkraken_assigned_reads\\tadded_reads\\tnew_est_reads\\tfraction_total_reads\\n" > ${meta.id}.bracken
        else
            cat bracken.stdout.log bracken.stderr.log >&2
            exit \$BRACKEN_EXIT
        fi
    fi
    """
}
