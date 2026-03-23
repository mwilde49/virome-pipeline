/*
 * workflows/virome.nf
 * Main VIROME workflow — connects all modules in sequence.
 */

nextflow.enable.dsl = 2

include { FASTQC            } from '../modules/fastqc'
include { TRIMMOMATIC       } from '../modules/trimmomatic'
include { STAR_HOST_REMOVAL } from '../modules/star_host_removal'
include { KRAKEN2_CLASSIFY  } from '../modules/kraken2_classify'
include { KRAKEN2_FILTER    } from '../modules/kraken2_filter'
include { AGGREGATE         } from '../modules/aggregate'
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
    // Step 5 — Filter low-confidence / low-count taxa
    // -------------------------------------------------------------------------
    KRAKEN2_FILTER(ch_kraken2_reports, ch_artifact_list)
    ch_filtered = KRAKEN2_FILTER.out.filtered

    // -------------------------------------------------------------------------
    // Step 6 — Aggregate across samples into abundance matrix
    // -------------------------------------------------------------------------
    ch_all_filtered = ch_filtered
        .map { meta, tsv -> tsv }
        .collect()

    AGGREGATE(ch_all_filtered)

    // -------------------------------------------------------------------------
    // Step 7 — MultiQC and final report
    // -------------------------------------------------------------------------
    ch_multiqc_inputs = ch_fastqc_raw_zip
        .map { meta, zips -> zips }
        .mix(
            ch_trim_logs.map  { meta, log -> log },
            ch_star_logs.map  { meta, log -> log },
            ch_kraken2_reports.map { meta, report -> report }
        )
        .collect()

    MULTIQC(ch_multiqc_inputs)

    REPORT(
        AGGREGATE.out.matrix,
        file(params.samplesheet)
    )

    emit:
    abundance_matrix = AGGREGATE.out.matrix
    multiqc_report   = MULTIQC.out.report
    report_dir       = REPORT.out.report_dir
}
