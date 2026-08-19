/*
 * lib/provenance.nf
 *
 * Shared provenance-generation helpers for all three entry points
 * (main.nf, blast_verify.nf, pathseq_verify.nf). Produces
 * ${params.outdir}/provenance/{manifest.json,PROVENANCE_README.md}, entirely
 * pipeline-native — no dependency on the mwilde49/hpc framework's
 * bin/lib/provenance.sh (which produces a similar bundle, but only for
 * tjp-launch-driven runs, under /work/$USER/pipelines/virome/runs/<ts>/, not
 * ${outdir}). This is the standalone equivalent for direct
 * `nextflow run main.nf ...` invocations with no framework/SLURM involved at
 * all (the motivating case: the "gataca" non-framework machine).
 *
 * All functions here read the implicit Nextflow bindings (`params`,
 * `workflow`, `projectDir`, `log`) directly rather than receiving them as
 * arguments — matching this repo's existing convention for helper functions
 * defined in an included .nf file (workflows/blast_verification.nf's
 * get_target_taxa() references params.target_taxa the same way). This is not
 * just style: passing `workflow`/`params` as explicit positional arguments
 * into a function called from inside a `workflow.onComplete { }` closure was
 * tried first and failed at runtime specifically on the early-abort path
 * (`params` resolved to null inside the callee, NPE on `params.outdir`) —
 * apparently `workflow.onComplete`'s closure invocation does not reliably
 * thread explicit arguments through to functions defined in a separately
 * included module file. Implicit access does not have this problem.
 *
 * manifest.json + PROVENANCE_README.md are both written from a
 * `workflow.onComplete { }` block registered as the FIRST statement in each
 * entry-point script's `workflow { }` body (before any param
 * validation/error), because (a) several required fields — complete
 * timestamp, duration, exit status, success/failure — are only known once
 * the run has finished, and (b) an onComplete handler only fires if it was
 * actually registered before the run ended, so it must be registered before
 * any `error "..."` call that might abort the run early. generateProvenance()
 * below is the single function each entry point calls from its onComplete
 * handler.
 *
 * The third provenance artifact, software_versions.yml, is NOT produced
 * here — it comes from an ordinary mid-pipeline process,
 * modules/capture_software_versions.nf, which each workflow file
 * (workflows/virome.nf, workflows/blast_verification.nf,
 * workflows/pathseq_verification.nf) invokes using the tool-spec builder
 * functions below (mainToolSpecs / blastToolSpecs / pathseqToolSpecs). It
 * publishes straight to provenance/ alongside these two files, and
 * writeProvenanceReadme() reads it back in (if present) to embed in the
 * README.
 *
 * KNOWN LIMITATION (see also PROVENANCE_README.md's own "Known limitation"
 * section, written into every run): Nextflow cannot capture a full raw
 * console-log transcript of its own invoking shell from within itself —
 * there is no supported hook for a running pipeline to intercept the
 * stdout/stderr of the shell that launched it. The framework's
 * CONSOLE_LOG.txt only works because bin/lib/provenance.sh wraps the
 * invocation from OUTSIDE Nextflow. Pipeline-native provenance can capture
 * everything Nextflow itself knows (params, versions, timing, exit status,
 * git commit, samplesheet checksum, etc.) but not that. Documented as a
 * `2>&1 | tee` recommendation, not implemented as code.
 */

// Nextflow's script parser does not support top-level Groovy `import`
// declarations in module .nf files -- fully-qualified names are used inline
// instead (groovy.json.JsonOutput, java.time.Instant,
// java.security.MessageDigest) wherever needed below.

// ---------------------------------------------------------------------------
// Tool-spec builders — one per entry point, consumed by
// modules/capture_software_versions.nf's CAPTURE_SOFTWARE_VERSIONS process.
// Each spec is [ label, container_path, version_command ]. Scoped to exactly
// the containers each entry point's workflow actually uses (see this repo's
// CLAUDE.md "Architecture" section for the per-entry-point container list).
// ---------------------------------------------------------------------------

def mainToolSpecs() {
    def dir = params.container_dir
    def specs = [
        [ 'FastQC',              "${dir}/fastqc.sif",      'fastqc --version' ],
        [ 'Trimmomatic',         "${dir}/trimmomatic.sif", 'trimmomatic -version' ],
        [ 'STAR',                "${dir}/star.sif",        'STAR --version' ],
        [ 'Kraken2',             "${dir}/kraken2.sif",     'kraken2 --version' ],
        [ 'Bracken',             "${dir}/bracken.sif",     'bracken -v' ],
        [ 'Python (python.sif)', "${dir}/python.sif",      'python3 --version' ],
        [ 'MultiQC',             "${dir}/multiqc.sif",     'multiqc --version' ],
    ]
    if (params.run_host_quant) {
        specs << [ 'sambamba (host_quant.sif)', "${dir}/host_quant.sif", 'sambamba --version' ]
        specs << [ 'bedtools (host_quant.sif)', "${dir}/host_quant.sif", 'bedtools --version' ]
        specs << [ 'samtools (host_quant.sif)', "${dir}/host_quant.sif", 'samtools --version' ]
        specs << [ 'R (host_quant.sif)',        "${dir}/host_quant.sif", 'R --version' ]
        specs << [ 'Rsubread (host_quant.sif)', "${dir}/host_quant.sif", 'Rscript -e \'cat(as.character(packageVersion("Rsubread")))\'' ]
        specs << [ 'HTSeq (host_quant.sif)',    "${dir}/host_quant.sif", 'htseq-count --version' ]
    }
    return specs
}

def blastToolSpecs() {
    def dir = params.container_dir
    return [
        [ 'BLASTn (blast.sif)',   "${dir}/blast.sif", 'blastn -version' ],
        [ 'seqtk (blast.sif)',    "${dir}/blast.sif", 'seqtk' ],       // no --version flag; bare invocation prints usage+version to stderr
        [ 'minimap2 (blast.sif)', "${dir}/blast.sif", 'minimap2 --version' ],
        [ 'samtools (blast.sif)', "${dir}/blast.sif", 'samtools --version' ],
    ]
}

def pathseqToolSpecs() {
    def dir = params.container_dir
    return [
        [ 'GATK / PathSeq (pathseq.sif)', "${dir}/pathseq.sif", 'gatk --version' ],
    ]
}

// ---------------------------------------------------------------------------
// Internal helpers
// ---------------------------------------------------------------------------

def sha256File(String path) {
    try {
        def f = new File(path)
        if (!f.exists() || !f.isFile()) return null
        // Samplesheets are small CSVs -- reading the whole file into memory
        // for hashing is fine; avoids Nextflow's script-parser restrictions
        // on low-level Java array-literal syntax (`new byte[N]`).
        def digest = java.security.MessageDigest.getInstance('SHA-256')
        return digest.digest(f.bytes).encodeHex().toString()
    } catch (Exception e) {
        return null
    }
}

def resolveGitCommit() {
    // Prefer Nextflow's own git-awareness (workflow.commitId is populated when
    // Nextflow itself pulled the pipeline from a git repo, e.g. `nextflow run
    // org/repo`). This repo is normally run as a local checkout
    // (`nextflow run main.nf`), so workflow.commitId is typically null —
    // that's expected, not an error; fall back to asking git directly.
    if (workflow.commitId) {
        return [ commit: workflow.commitId, source: 'workflow.commitId' ]
    }
    try {
        def proc = [ 'git', '-C', projectDir.toString(), 'rev-parse', 'HEAD' ].execute()
        def out  = proc.text
        proc.waitForOrKill(10000)
        if (proc.exitValue() == 0 && out?.trim()) {
            return [ commit: out.trim(), source: 'git rev-parse HEAD (fallback)' ]
        }
        return [ commit: null, source: "git rev-parse HEAD failed (exit ${proc.exitValue()})" ]
    } catch (Exception e) {
        return [ commit: null, source: "git rev-parse HEAD failed (${e.message})" ]
    }
}

// Recursively coerce an arbitrary params value tree into something
// groovy.json.JsonOutput can serialize cleanly (params can hold Strings,
// Numbers, Booleans, null, nested Maps/Lists, and occasionally GString/Path
// objects depending on how a value was set — those get stringified).
def sanitizeForJson(obj) {
    if (obj == null) return null
    if (obj instanceof Map) {
        def out = [:]
        obj.each { k, v -> out[k.toString()] = sanitizeForJson(v) }
        return out
    }
    if (obj instanceof Collection) {
        return obj.collect { sanitizeForJson(it) }
    }
    if (obj instanceof Number || obj instanceof Boolean || obj instanceof String) {
        return obj
    }
    return obj.toString()
}

def provenanceSignposts(entryPoint) {
    def rows = []
    if (entryPoint == 'main') {
        rows << [ 'results/',          'Final abundance matrices (viral_abundance_matrix.tsv, minreads_matrix.tsv, bracken_raw_matrix.tsv) + virome_report/ HTML summary' ]
        rows << [ 'multiqc/',          'MultiQC aggregate QC report' ]
        rows << [ 'pipeline_info/',    'Nextflow execution_report.html / execution_timeline.html / pipeline_dag.html / execution_trace.tsv' ]
        rows << [ 'provenance/',       'This directory -- manifest.json, software_versions.yml, PROVENANCE_README.md' ]
        if (params.kraken2_db2) {
            rows << [ 'results/db_comparison/', 'Dual-DB Tier 1/2/3 comparison outputs (consensus_matrix.tsv, false_positive_candidates.tsv, db_comparison_summary.tsv, db_comparison.png)' ]
        }
        if (params.run_host_quant) {
            rows << [ 'host_quant/',                             'Per-sample raw featureCounts (featurecounts_raw.csv) and HTSeq (htseq_raw.tsv) output, all samples in one job each' ]
            rows << [ 'results/host_gene_expression_matrix.tsv', 'Merged featureCounts+HTSeq host gene expression matrix (+ *_qc_summary.tsv concordance check)' ]
        }
        if (params.save_kraken2_output) {
            rows << [ 'kraken2_output/', 'Per-sample Kraken2 per-read output files (input to blast_verify.nf)' ]
        }
        if (params.save_unmapped_reads) {
            rows << [ 'star_unmapped/', 'Per-sample STAR-unmapped (host-depleted) FASTQ pairs (input to blast_verify.nf / pathseq_verify.nf)' ]
        }
    } else if (entryPoint == 'blast_verify') {
        rows << [ 'blast_verification/<sample>/<taxon_id>/', 'Per-(sample,taxon) blast_summary.tsv, lifecycle_inference.tsv, lifecycle_report.html (+ optional coverage_bam/coverage_stats)' ]
        rows << [ 'pipeline_info/', 'Nextflow execution_report.html / execution_timeline.html / pipeline_dag.html / execution_trace.tsv' ]
        rows << [ 'provenance/',    'This directory -- manifest.json, software_versions.yml, PROVENANCE_README.md' ]
    } else if (entryPoint == 'pathseq_verify') {
        rows << [ 'pathseq_verification/<sample>/',                    'Per-sample raw PathSeq output' ]
        rows << [ 'pathseq_verification/pathseq_abundance_matrix.tsv', 'Taxonomy-wide abundance matrix, all samples merged' ]
        rows << [ 'pathseq_verification/pathseq_concordance.tsv',      'Kraken2 / BLAST / PathSeq concordance table' ]
        rows << [ 'pipeline_info/', 'Nextflow execution_report.html / execution_timeline.html / pipeline_dag.html / execution_trace.tsv' ]
        rows << [ 'provenance/',    'This directory -- manifest.json, software_versions.yml, PROVENANCE_README.md' ]
    }
    return rows
}

// ---------------------------------------------------------------------------
// manifest.json
// ---------------------------------------------------------------------------

def writeProvenanceManifest(entryPoint) {
    def provDir = new File("${params.outdir}/provenance")
    provDir.mkdirs()

    def git = resolveGitCommit()

    def samplesheetPath = params.samplesheet
    def samplesheetInfo = [ path: samplesheetPath, sha256: null, note: null ]
    if (samplesheetPath) {
        def checksum = sha256File(samplesheetPath.toString())
        samplesheetInfo.sha256 = checksum
        if (checksum == null) {
            samplesheetInfo.note = 'samplesheet not found at manifest-write time (workflow.onComplete) or unreadable -- checksum unavailable'
        }
    } else {
        samplesheetInfo.note = 'params.samplesheet was not set for this run'
    }

    def manifest = [
        entry_point      : entryPoint,
        manifest_version : 1,
        generated_at     : java.time.Instant.now().toString(),
        repository       : [
            commit              : git.commit,
            commit_source       : git.source,
            workflow_repository : workflow.repository,
            workflow_revision   : workflow.revision,
        ],
        nextflow         : [
            version      : workflow.nextflow?.version?.toString(),
            run_name     : workflow.runName,
            session_id   : workflow.sessionId?.toString(),
            command_line : workflow.commandLine,
            profile      : workflow.profile,
            work_dir     : workflow.workDir?.toString(),
        ],
        pipeline         : [
            container_dir : params.container_dir,
            params        : sanitizeForJson(params),
        ],
        samplesheet      : samplesheetInfo,
        run_status       : [
            start       : workflow.start?.toString(),
            complete    : workflow.complete?.toString(),
            duration    : workflow.duration?.toString(),
            exit_status : workflow.exitStatus,
            success     : workflow.success,
        ],
    ]

    new File(provDir, 'manifest.json').text =
        groovy.json.JsonOutput.prettyPrint(groovy.json.JsonOutput.toJson(manifest))
    return manifest
}

// ---------------------------------------------------------------------------
// PROVENANCE_README.md
// ---------------------------------------------------------------------------

def writeProvenanceReadme(entryPoint, manifest) {
    def provDir = new File("${params.outdir}/provenance")
    provDir.mkdirs()

    def versionsFile  = new File(provDir, 'software_versions.yml')
    def versionsBlock = versionsFile.exists()
        ? versionsFile.text
        : "(software_versions.yml is not present -- CAPTURE_SOFTWARE_VERSIONS did not complete, most likely because this run failed before reaching it)\n"

    def statusLine = workflow.success ? 'SUCCESS' : 'FAILED'
    def signposts  = provenanceSignposts(entryPoint)

    def sb = new StringBuilder()
    sb << "# Pipeline Provenance Report\n\n"
    sb << "Entry point: `${entryPoint}`  \n"
    sb << "Run name: `${workflow.runName}`  \n"
    sb << "Status: **${statusLine}** (exit status: `${workflow.exitStatus}`)  \n"
    sb << "Started:   ${workflow.start}  \n"
    sb << "Completed: ${workflow.complete}  \n"
    sb << "Duration:  ${workflow.duration}  \n\n"

    sb << "## Invocation\n\n"
    sb << "```\n${workflow.commandLine}\n```\n\n"
    sb << "- Profile(s): `${workflow.profile}`\n"
    sb << "- Nextflow version: `${workflow.nextflow?.version}`\n"
    sb << "- Session ID: `${workflow.sessionId}`\n"
    sb << "- Work directory: `${workflow.workDir}`\n"
    sb << "- Repository commit: `${manifest.repository.commit ?: 'unknown'}` (source: ${manifest.repository.commit_source})\n\n"

    sb << "## Resolved parameters\n\n"
    sb << "Full machine-readable parameter set is in `manifest.json` (`.pipeline.params`). Key values for this run:\n\n"
    sb << "| Parameter | Value |\n|---|---|\n"
    [ 'samplesheet', 'outdir', 'container_dir', 'star_index', 'kraken2_db', 'kraken2_db2',
      'run_host_quant', 'save_kraken2_output', 'save_unmapped_reads',
      'blast_db_dir', 'consensus_matrix', 'target_taxa',
      'pathseq_microbe_bwa_image', 'pathseq_microbe_fasta', 'pathseq_taxonomy' ].each { k ->
        if (params.containsKey(k) && params[k] != null) {
            sb << "| ${k} | ${params[k]} |\n"
        }
    }
    sb << "\n"

    sb << "## Software versions\n\n"
    sb << "Real version strings queried live from this run's own containers at execution time via "
    sb << "`apptainer exec <container> <tool> --version`-style invocations "
    sb << "(`modules/capture_software_versions.nf`) -- not hardcoded. Raw capture below "
    sb << "(also saved separately as `software_versions.yml`):\n\n"
    sb << "```yaml\n${versionsBlock}```\n\n"

    sb << "## Samplesheet\n\n"
    sb << "- Path: `${manifest.samplesheet.path}`\n"
    sb << "- SHA-256: `${manifest.samplesheet.sha256 ?: 'unavailable'}`\n"
    if (manifest.samplesheet.note) {
        sb << "- Note: ${manifest.samplesheet.note}\n"
    }
    sb << "\n"

    sb << "## Output layout for this run\n\n"
    sb << "| Path (relative to `${params.outdir}`) | Contents |\n|---|---|\n"
    signposts.each { row -> sb << "| `${row[0]}` | ${row[1]} |\n" }
    sb << "\n"

    sb << "## Known limitation: no raw console-log transcript\n\n"
    sb << "This report cannot include a full raw stdout/stderr transcript of the invoking "
    sb << "shell session, equivalent to the `mwilde49/hpc` framework's `CONSOLE_LOG.txt` "
    sb << "(generated by that framework's `bin/lib/provenance.sh` for every `tjp-launch virome` "
    sb << "run). That framework-level capture works because it wraps the *outer* shell "
    sb << "invocation from *outside* Nextflow entirely. Nextflow has no supported mechanism "
    sb << "to capture its own invoking shell's stdout/stderr from *within* the pipeline -- by "
    sb << "the time any Nextflow code (including this `workflow.onComplete` block) runs, "
    sb << "console output has already gone directly to whatever terminal/redirect the user "
    sb << "chose, and there is no hook for a running pipeline to retroactively intercept it.\n\n"
    sb << "**If you need an equivalent transcript** (recommended for any run whose provenance "
    sb << "matters -- e.g. this non-framework \"gataca\" use case), wrap your own invocation:\n\n"
    sb << "```bash\n"
    sb << "nextflow run main.nf -profile standard <your args> \\\n"
    sb << "    2>&1 | tee ${params.outdir}/provenance/console_log.txt\n"
    sb << "```\n\n"
    sb << "This is a documentation recommendation, not something this pipeline can do for you "
    sb << "automatically -- see `lib/provenance.nf`'s header comment for why.\n"

    new File(provDir, 'PROVENANCE_README.md').text = sb.toString()
}

// ---------------------------------------------------------------------------
// Single entry point called from each pipeline script's workflow.onComplete{}
// ---------------------------------------------------------------------------

def generateProvenance(entryPoint) {
    if (!params.outdir) {
        log.warn "[provenance] params.outdir is not set -- skipping provenance/ generation"
        return
    }
    try {
        def manifest = writeProvenanceManifest(entryPoint)
        writeProvenanceReadme(entryPoint, manifest)
        log.info "[provenance] wrote ${params.outdir}/provenance/{manifest.json,PROVENANCE_README.md}"
    } catch (Exception e) {
        log.error "[provenance] failed to generate provenance report: ${e.message}"
    }
}
