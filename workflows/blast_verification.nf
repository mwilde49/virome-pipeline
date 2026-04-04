/*
 * workflows/blast_verification.nf
 *
 * BLAST Verification Offshoot — confirms identity and infers viral life cycle
 * phase for candidate taxa detected by the main virome pipeline.
 *
 * By default, processes ALL Tier 1 (shared / consensus) taxa from a
 * consensus_matrix.tsv produced by a previous dual-DB pipeline run.
 * Override with params.target_taxa for explicit taxon IDs.
 *
 * Input samplesheet format (CSV):
 *   sample,kraken2_output,fastq_r1,fastq_r2
 *   PD19,/path/to/PD19.kraken2.output,/path/to/PD19_unmapped_R1.fastq.gz,...
 *
 * Required params:
 *   params.blast_db_dir        — path to directory containing BLAST nt database
 *   params.blast_db_name       — database name within the dir (default: 'nt')
 *   AND one of:
 *   params.consensus_matrix    — path to consensus_matrix.tsv from main pipeline
 *   params.target_taxa         — comma-separated taxon IDs (e.g. "3050292,10298")
 *
 * Optional params:
 *   params.viral_refs_dir      — path to dir of viral reference genomes (FASTA)
 *                                Files must be named {taxon_id}.fa or {taxon_id}.fasta
 *   params.blast_evalue        — default 1e-5
 *   params.blast_max_targets   — default 10
 *   params.blast_word_size     — default 28
 *   params.blast_perc_identity — default 80 (pre-filter, use pident_threshold=90 for confirmation)
 *   params.blast_max_reads     — subsample extracted reads (0 = no limit, default)
 *   params.blast_include_genus — also extract reads with taxon evidence in k-mer string (default: false)
 *   params.blast_pident_threshold — min identity for confirmation/lifecycle (default: 90.0)
 *   params.blast_evalue_threshold — max E-value for confirmation/lifecycle (default: 1e-5)
 */

nextflow.enable.dsl = 2

include { EXTRACT_KRAKEN2_READS } from '../modules/extract_kraken2_reads'
include { BLAST_VERIFY          } from '../modules/blast_verify'
include { BLAST_ANALYZE         } from '../modules/blast_analyze'


// ---------------------------------------------------------------------------
// Helper: parse target taxa from consensus_matrix.tsv or explicit list
// ---------------------------------------------------------------------------

def get_target_taxa() {
    def taxa = []   // list of [ taxon_id (int), taxon_name (str) ]

    if (params.target_taxa) {
        params.target_taxa.split(',').each { t ->
            t = t.trim()
            if (t.isInteger()) {
                taxa << [ t.toInteger(), "taxon_${t}" ]
            }
        }
        if (taxa) log.info "BLAST targets (explicit): ${taxa*.get(0).join(', ')}"
        return taxa
    }

    if (params.consensus_matrix) {
        def f = file(params.consensus_matrix, checkIfExists: true)
        def lines = f.readLines()
        if (lines.size() < 2) {
            log.warn "consensus_matrix.tsv appears empty — no targets to verify"
            return taxa
        }
        lines[1..-1].each { line ->
            def parts = line.split('\t')
            if (parts.size() >= 2) {
                def tid_str = parts[0].trim()
                def tname   = parts[1].trim()
                if (tid_str.isInteger()) {
                    taxa << [ tid_str.toInteger(), tname ]
                }
            }
        }
        if (taxa) log.info "BLAST targets from consensus_matrix: ${taxa*.get(0).join(', ')}"
        return taxa
    }

    error "Either params.consensus_matrix or params.target_taxa must be specified"
}


// ---------------------------------------------------------------------------
// Workflow
// ---------------------------------------------------------------------------

workflow BLAST_VERIFICATION {

    take:
    ch_samples  // [ meta(id), path(kraken2_output), path(r1), path(r2) ]

    main:

    if (!params.blast_db_dir) error "params.blast_db_dir is required"

    ch_blast_db = file(params.blast_db_dir, checkIfExists: true)
    ch_viral_refs = params.viral_refs_dir
        ? file(params.viral_refs_dir, checkIfExists: true)
        : file("$projectDir/assets/NO_FILE")

    // Resolve target taxa
    def target_taxa = get_target_taxa()
    if (!target_taxa) error "No target taxa found. Set params.target_taxa or params.consensus_matrix."

    // Expand samples × target_taxa to get one channel entry per (sample, taxon) pair
    ch_extract_inputs = ch_samples
        .flatMap { meta, kraken2_out, r1, r2 ->
            target_taxa.collect { taxon_id, taxon_name ->
                def new_meta = meta + [taxon_id: taxon_id, taxon_name: taxon_name]
                [ new_meta, kraken2_out, r1, r2 ]
            }
        }

    // Step 1: extract reads for each (sample, taxon) pair
    EXTRACT_KRAKEN2_READS(ch_extract_inputs)

    // Step 2: BLAST extracted reads
    BLAST_VERIFY(
        EXTRACT_KRAKEN2_READS.out.reads,
        ch_blast_db
    )

    // Step 3: analyze BLAST results + infer life cycle
    // Join blast results with extracted reads (same meta key) for minimap2
    ch_analyze_input = BLAST_VERIFY.out.results
        .join(EXTRACT_KRAKEN2_READS.out.reads, by: 0)

    BLAST_ANALYZE(
        ch_analyze_input.map { meta, blast, r1, r2 -> [ meta, blast ] },
        ch_analyze_input.map { meta, blast, r1, r2 -> [ meta, r1, r2 ] },
        ch_viral_refs
    )

    emit:
    blast_summary    = BLAST_ANALYZE.out.blast_summary
    lifecycle_tsv    = BLAST_ANALYZE.out.lifecycle_tsv
    lifecycle_report = BLAST_ANALYZE.out.lifecycle_report
}
