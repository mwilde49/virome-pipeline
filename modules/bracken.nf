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
    # Bracken requires at least one classified-taxon row at the target rank
    # (\$params.bracken_level) to redistribute reads onto. A sample whose
    # STAR-unmapped pool is tiny and/or entirely non-viral can produce a
    # Kraken2 report that is nothing but the "unclassified" summary line --
    # a legitimate zero-detection result, not a broken input -- and bracken
    # hard-fails on it ("Error: no reads found. Please check your Kraken
    # report"), which would otherwise abort the whole cohort run. Detect
    # that case up front and pass the report through untouched instead:
    # downstream (filter_kraken2_report.py) reads bracken_report as a plain
    # Kraken2-style report and already handles zero viral-rank rows cleanly
    # (empty DataFrame -> 0 taxa, no crash).
    if ! awk -F'\\t' '\$4 == "${params.bracken_level}"' ${kraken2_report} | grep -q .; then
        echo "No rank-${params.bracken_level} reads in ${kraken2_report} -- skipping bracken (zero-detection sample), passing report through" >&2
        cp ${kraken2_report} ${meta.id}.bracken_report
        printf "name\\ttaxonomy_id\\ttaxonomy_lvl\\tkraken_assigned_reads\\tadded_reads\\tnew_est_reads\\tfraction_total_reads\\n" > ${meta.id}.bracken
    else
        bracken \\
            -d ${kraken2_db} \\
            -i ${kraken2_report} \\
            -o ${meta.id}.bracken \\
            -w ${meta.id}.bracken_report \\
            -r ${params.bracken_read_length} \\
            -l ${params.bracken_level} \\
            -t ${params.bracken_threshold}
    fi
    """
}
