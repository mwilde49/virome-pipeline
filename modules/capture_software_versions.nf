/*
 * modules/capture_software_versions.nf
 *
 * Part of the pipeline-native provenance/ output (see lib/provenance.nf for
 * the manifest.json / PROVENANCE_README.md half of that system). This
 * process queries REAL, live version strings from each container this run
 * actually uses, rather than hardcoding version numbers anywhere -- the
 * container .def files' base-image tags can drift from what's actually
 * baked into a locally-built .sif, so only a live probe is trustworthy.
 *
 * Deliberately has NO `container` directive of its own: its whole job is to
 * shell out to `apptainer exec <other container> <tool> --version` once per
 * tool, so it must run bare on the host, not inside one specific container.
 * This is why it needs `apptainer` on PATH wherever Nextflow itself runs --
 * true both locally (this repo's WSL2 environment, apptainer 1.4.5) and on
 * Juno (conf/slurm.config's `beforeScript = 'module load apptainer'` applies
 * to every process in the process{} scope, this one included).
 *
 * tool_specs is a List of [ label, container_path, version_command ] triples
 * built by lib/provenance.nf's mainToolSpecs() / blastToolSpecs() /
 * pathseqToolSpecs() -- one builder per entry point, each scoped to exactly
 * the containers that entry point's workflow uses. See this repo's CLAUDE.md
 * "Architecture" section for the authoritative per-entry-point container list.
 */

process CAPTURE_SOFTWARE_VERSIONS {
    tag "provenance:software_versions"

    publishDir "${params.outdir}/provenance", mode: 'copy'

    input:
    val tool_specs

    output:
    path "software_versions.yml", emit: yml

    script:
    def header = """\
set -uo pipefail
echo '# software_versions.yml' > software_versions.yml
echo '# Real tool version strings captured live at pipeline runtime via' >> software_versions.yml
echo '# apptainer exec <container> <tool> --version-style invocations' >> software_versions.yml
echo '# (modules/capture_software_versions.nf) -- not hardcoded.' >> software_versions.yml
echo "# generated_at: \$(date -u +%Y-%m-%dT%H:%M:%SZ)" >> software_versions.yml
echo '' >> software_versions.yml
"""
    def probes = tool_specs.collect { spec ->
        def label        = spec[0]
        def containerPath = spec[1]
        def versionCmd    = spec[2]
        """
echo '${label}:' >> software_versions.yml
if [ -f '${containerPath}' ]; then
    echo '  container: ${containerPath}' >> software_versions.yml
    ( timeout 60 apptainer exec '${containerPath}' ${versionCmd} 2>&1 || echo '(version command exited non-zero -- any output above this line was still captured)' ) | sed 's/^/    /' >> software_versions.yml
else
    echo '  status: container not found at ${containerPath} -- skipped' >> software_versions.yml
fi
echo '' >> software_versions.yml
"""
    }.join('\n')

    header + probes
}
