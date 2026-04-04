#!/usr/bin/env nextflow

/*
 * blast_verify.nf — Entry point for the BLAST verification offshoot pipeline.
 *
 * Confirms identity and infers viral life cycle phase for candidate taxa from
 * a completed virome-pipeline dual-DB run. By default processes all Tier 1
 * (shared / consensus) taxa from the prior run's consensus_matrix.tsv.
 *
 * Usage:
 *   nextflow run blast_verify.nf -profile slurm -params-file assets/config_blast_pd19.yaml
 *
 * Samplesheet CSV format (sample,kraken2_output,fastq_r1,fastq_r2):
 *   The kraken2_output column must point to the per-read Kraken2 assignment
 *   file ({id}.kraken2.output) from the KRAKEN2_CLASSIFY step of the main run.
 *   The fastq_r1/r2 columns should point to the STAR-unmapped (host-removed)
 *   FASTQ files from STAR_HOST_REMOVAL.
 *
 *   If the main pipeline was run without publishDir on these intermediate files,
 *   locate them in the Nextflow work directory:
 *     find /scratch/juno/$USER/nf_work -name "PD19.kraken2.output" 2>/dev/null
 *     find /scratch/juno/$USER/nf_work -name "PD19_unmapped_R1.fastq.gz" 2>/dev/null
 *
 *   Alternatively, re-run the main pipeline with params.save_kraken2_output=true
 *   and params.save_unmapped_reads=true to publish these files to outdir.
 *
 * Required params:
 *   samplesheet        — path to samplesheet CSV
 *   outdir             — output directory
 *   blast_db_dir       — path to BLAST nt database directory on Juno:
 *                        /groups/tprice/pipelines/references/blast_nt/
 *   AND one of:
 *   consensus_matrix   — path to consensus_matrix.tsv from main pipeline run
 *   target_taxa        — comma-separated taxon IDs
 */

nextflow.enable.dsl = 2

include { BLAST_VERIFICATION } from './workflows/blast_verification'

workflow {

    if (!params.samplesheet) error "Please provide --samplesheet <path>"
    if (!params.outdir)      error "Please provide --outdir <path>"

    Channel
        .fromPath(params.samplesheet)
        .splitCsv(header: true, strip: true)
        .map { row ->
            def meta         = [ id: row.sample ]
            def kraken2_out  = file(row.kraken2_output, checkIfExists: true)
            def r1           = file(row.fastq_r1,       checkIfExists: true)
            def r2           = file(row.fastq_r2,       checkIfExists: true)
            [ meta, kraken2_out, r1, r2 ]
        }
        .set { ch_samples }

    BLAST_VERIFICATION(ch_samples)
}
