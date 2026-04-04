/*
 * modules/blast_analyze.nf
 *
 * Analyze BLAST results to:
 *   1. Confirm taxon identity (% identity, E-value, alignment coverage)
 *   2. Map reads to the viral reference genome with minimap2 (if available)
 *   3. Infer viral life cycle phase from gene coverage patterns
 *
 * Outputs (per sample × taxon):
 *   blast_summary     — per-read best BLAST hit with gene annotation
 *   lifecycle_tsv     — structured phase call + evidence
 *   lifecycle_report  — self-contained HTML report (embedded in results)
 *   coverage_bam      — minimap2 alignment to reference (optional, if params.viral_refs_dir is set)
 *   coverage_stats    — samtools coverage output (optional)
 *
 * Parameters:
 *   params.blast_pident_threshold   — min % identity for confirmation (default: 90.0)
 *   params.blast_evalue_threshold   — max E-value for confirmation (default: 1e-5)
 *   params.viral_refs_dir           — path to dir of reference viral genomes (FASTA); optional
 *                                     Expected filename: {taxon_id}.fa or {taxon_id}.fasta
 *                                     If not set, minimap2 coverage step is skipped.
 */

process BLAST_ANALYZE {
    tag "${meta.id}:${meta.taxon_id}"

    container "${params.container_dir}/blast.sif"

    publishDir "${params.outdir}/blast_verification/${meta.id}/${meta.taxon_id}", mode: 'copy'

    input:
    tuple val(meta), path(blast_results)
    tuple val(meta2), path(r1), path(r2)   // extracted reads for minimap2
    path  viral_refs_dir                    // optional reference genomes dir

    output:
    tuple val(meta), path("${meta.id}.${meta.taxon_id}.blast_summary.tsv"),        emit: blast_summary
    tuple val(meta), path("${meta.id}.${meta.taxon_id}.lifecycle_inference.tsv"),   emit: lifecycle_tsv
    tuple val(meta), path("${meta.id}.${meta.taxon_id}.lifecycle_report.html"),     emit: lifecycle_report
    tuple val(meta), path("${meta.id}.${meta.taxon_id}.coverage.bam"),              emit: coverage_bam,   optional: true
    tuple val(meta), path("${meta.id}.${meta.taxon_id}.coverage_stats.tsv"),        emit: coverage_stats, optional: true

    script:
    def pident    = params.blast_pident_threshold  ?: 90.0
    def evalue    = params.blast_evalue_threshold  ?: '1e-5'
    def has_refs  = params.viral_refs_dir          ? true : false
    """
    # Step 1: Analyze BLAST hits — identity confirmation + life cycle inference
    analyze_blast_results.py \\
        --blast-results ${blast_results} \\
        --sample-id "${meta.id}" \\
        --taxon-id  ${meta.taxon_id} \\
        --taxon-name "${meta.taxon_name ?: 'Unknown'}" \\
        --pident-threshold ${pident} \\
        --evalue-threshold ${evalue} \\
        --outdir .

    # Step 2: minimap2 coverage mapping (only if reference genome is available)
    REF_FA=""
    if [[ "${has_refs}" == "true" ]]; then
        for ext in fa fasta; do
            candidate="${viral_refs_dir}/${meta.taxon_id}.\${ext}"
            if [[ -f "\${candidate}" ]]; then
                REF_FA="\${candidate}"
                break
            fi
        done
    fi

    if [[ -n "\${REF_FA}" ]]; then
        echo "Mapping reads to reference: \${REF_FA}" >&2

        # Combine R1+R2 as single-end for coverage (genome is small, overlap expected)
        seqtk seq -a ${r1} > mapped_query.fa
        seqtk seq -a ${r2} >> mapped_query.fa

        minimap2 -a -x sr "\${REF_FA}" mapped_query.fa \\
            | samtools sort -@ ${task.cpus} \\
            | samtools view -bS -F 4 \\
            > ${meta.id}.${meta.taxon_id}.coverage.bam

        samtools index ${meta.id}.${meta.taxon_id}.coverage.bam

        # Coverage statistics per reference position
        samtools coverage ${meta.id}.${meta.taxon_id}.coverage.bam \\
            > ${meta.id}.${meta.taxon_id}.coverage_stats.tsv
    else
        echo "No reference genome found for taxon ${meta.taxon_id} — skipping minimap2 step" >&2
    fi
    """
}
