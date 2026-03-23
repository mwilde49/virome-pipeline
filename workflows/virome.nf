/*
 * workflows/virome.nf
 * Main VIROME workflow — connects all modules in sequence.
 */

nextflow.enable.dsl = 2

include { FASTQC            } from '../modules/fastqc'
include { TRIMMOMATIC       } from '../modules/trimmomatic'
include { STAR_HOST_REMOVAL } from '../modules/star_host_removal'
include { KRAKEN2_CLASSIFY  } from '../modules/kraken2_classify'
include { BRACKEN           } from '../modules/bracken'
include { KRAKEN2_FILTER    } from '../modules/kraken2_filter'
include { AGGREGATE         } from '../modules/aggregate'
include { AGGREGATE as AGGREGATE_BRACKEN  } from '../modules/aggregate'
include { AGGREGATE as AGGREGATE_MINREADS } from '../modules/aggregate'
include { MULTIQC           } from '../modules/multiqc'
include { REPORT            } from '../modules/report'

workflow VIROME {

    take:
    ch_reads  // [ meta, r1, r2 ]

    main:

    // Validate required references
    if (!params.star_index)  error "params.star_index is required"
    if (!params.kraken2_db)  error "params.kraken2_db is required"

    ch_star_index    = file(params.star_index,  checkIfExists: true)
    ch_kraken2_db    = file(params.kraken2_db,  checkIfExists: true)
    ch_adapters      = file(params.adapters,     checkIfExists: true)
    ch_artifact_list = params.artifact_list
        ? file(params.artifact_list, checkIfExists: true)
        : file("$projectDir/assets/NO_FILE")

    // -------------------------------------------------------------------------
    // Step 1 — QC on raw reads
    // -------------------------------------------------------------------------
    FASTQC(ch_reads)
    ch_fastqc_raw_zip = FASTQC.out.zip

    // -------------------------------------------------------------------------
    // Step 2 — Adapter and quality trimming
    // -------------------------------------------------------------------------
    TRIMMOMATIC(ch_reads, ch_adapters)
    ch_trimmed_reads = TRIMMOMATIC.out.reads
    ch_trim_logs     = TRIMMOMATIC.out.log

    // -------------------------------------------------------------------------
    // Step 3 — Host removal (align to GRCh38, keep unmapped)
    // -------------------------------------------------------------------------
    STAR_HOST_REMOVAL(ch_trimmed_reads, ch_star_index)
    ch_unmapped_reads = STAR_HOST_REMOVAL.out.reads
    ch_star_logs      = STAR_HOST_REMOVAL.out.log

    // -------------------------------------------------------------------------
    // Step 4 — Viral classification with Kraken2
    // -------------------------------------------------------------------------
    KRAKEN2_CLASSIFY(ch_unmapped_reads, ch_kraken2_db)
    ch_kraken2_reports = KRAKEN2_CLASSIFY.out.report

    // -------------------------------------------------------------------------
    // Step 4b — Bracken abundance re-estimation
    // -------------------------------------------------------------------------
    BRACKEN(ch_kraken2_reports, ch_kraken2_db)

    // -------------------------------------------------------------------------
    // Step 5 — Filter through three stages (bracken_raw → minreads → artifacts)
    // -------------------------------------------------------------------------
    KRAKEN2_FILTER(BRACKEN.out.report, ch_artifact_list)

    // -------------------------------------------------------------------------
    // Step 6 — Aggregate each stage into its own abundance matrix
    // -------------------------------------------------------------------------
    ch_all_star_logs = ch_star_logs
        .map { meta, log -> log }
        .collect()

    ch_all_bracken_raw = KRAKEN2_FILTER.out.bracken_raw
        .map { meta, tsv -> tsv }
        .collect()

    ch_all_minreads = KRAKEN2_FILTER.out.minreads
        .map { meta, tsv -> tsv }
        .collect()

    ch_all_filtered = KRAKEN2_FILTER.out.filtered
        .map { meta, tsv -> tsv }
        .collect()

    ch_all_filter_summaries = KRAKEN2_FILTER.out.summary
        .map { meta, tsv -> tsv }
        .collect()

    AGGREGATE_BRACKEN( 'bracken_raw_matrix',      ch_all_bracken_raw, ch_all_star_logs)
    AGGREGATE_MINREADS('minreads_matrix',          ch_all_minreads,    ch_all_star_logs)
    AGGREGATE(         'viral_abundance_matrix',   ch_all_filtered,    ch_all_star_logs)

    // -------------------------------------------------------------------------
    // Step 7 — MultiQC and final report
    // -------------------------------------------------------------------------
    ch_multiqc_inputs = ch_fastqc_raw_zip
        .map { meta, zips -> zips }
        .mix(
            ch_trim_logs.map             { meta, log    -> log    },
            ch_star_logs.map             { meta, log    -> log    },
            ch_kraken2_reports.map       { meta, report -> report },
            BRACKEN.out.bracken_output.map { meta, out  -> out    }
        )
        .collect()

    MULTIQC(ch_multiqc_inputs)

    REPORT(
        AGGREGATE_BRACKEN.out.matrix,
        AGGREGATE_MINREADS.out.matrix,
        AGGREGATE.out.matrix,
        ch_all_filter_summaries,
        file(params.samplesheet)
    )

    emit:
    abundance_matrix = AGGREGATE.out.matrix
    multiqc_report   = MULTIQC.out.report
    report_dir       = REPORT.out.report_dir
}
