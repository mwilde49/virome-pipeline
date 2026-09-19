#!/usr/bin/env python3
"""
aggregate_telescope.py

Merge per-sample Telescope (Bendall et al. 2019) locus-level count files into
a single locus x sample matrix, for downstream DESeq2/edgeR analysis (see
HERVK/experimental_roadmap.md, Phase 1 Experiment 1).

`telescope assign` (bioconda telescope==1.0.3, containers/telescope.def)
writes ONE report per sample, `<exp_tag>-telescope_report.tsv` -- verified
directly against a real run's output, 2026-09-18 (NOT git master's source:
git master's telescope/utils/model.py describes a different, unreleased
two-file split with no `final_count` column -- that's dev code ahead of what
bioconda actually ships; trust the real output over either version's source
if they ever disagree again):

  Line 1: `## RunInfo\tversion:1.0.3\tnmap_idx:...\t...` -- run-level stats
          comment, not part of the table.
  Line 2+: tab-separated table, columns (in order):
          transcript, transcript_length, final_count, final_conf, final_prop,
          init_aligned, unique_count, init_best, init_best_random,
          init_best_avg, init_prop
          Plus a `__no_feature` row -- fragments that didn't overlap any
          annotated locus. Not a real locus; excluded from the matrix, but
          its final_count is reported as a per-sample QC line (fraction of
          fragments unassigned).

final_count is the actual EM-reassigned read count per locus (governed by
--reassign_mode, see modules/telescope_assign.nf) -- the column DESeq2/edgeR
expect, not final_prop (an EM-fit proportion, not a count) or any of the
init_* diagnostic columns.

Rows = HML-2/TE loci, columns = samples (raw counts, + RPM if STAR
realignment logs are supplied -- same STAR total-input-reads denominator
convention as aggregate_virome.py / aggregate_host_counts.py, for direct
cross-matrix comparability).
"""

import re
import click
import pandas as pd
from pathlib import Path


REPORT_SUFFIX = '-telescope_report.tsv'  # modules/telescope_assign.nf: "${meta.id}-telescope_report.tsv"
NO_FEATURE = '__no_feature'


def sample_id_from_report_path(path):
    """<sample_id>-telescope_report.tsv -> sample_id (per modules/telescope_assign.nf)."""
    name = Path(path).name
    if name.endswith(REPORT_SUFFIX):
        return name[: -len(REPORT_SUFFIX)]
    return Path(path).stem


def load_telescope_report(path):
    """Returns (counts: Series[transcript -> final_count], no_feature_count: int).

    Line 1 is a '## RunInfo...' comment, not part of the table -- skip it
    explicitly rather than relying on pandas' comment-char handling, since
    '#' could in principle appear elsewhere.
    """
    with open(path) as f:
        first_line = f.readline()
        if not first_line.startswith('## RunInfo'):
            raise ValueError(
                f"{path}: expected a '## RunInfo' comment on line 1 (telescope "
                f"assign's own report format), found: {first_line[:80]!r}. "
                f"Re-verify against a real telescope assign run if this format changed."
            )
        df = pd.read_csv(f, sep='\t')

    missing = {'transcript', 'final_count'} - set(df.columns)
    if missing:
        raise ValueError(
            f"{path}: telescope_report.tsv is missing expected column(s) {missing}. "
            f"Found columns: {list(df.columns)}. This script parses by header name "
            f"against a real telescope assign 1.0.3 run (see module docstring) -- "
            f"re-verify against upstream if Telescope's output format changed."
        )

    df = df.set_index('transcript')
    no_feature_count = int(df.loc[NO_FEATURE, 'final_count']) if NO_FEATURE in df.index else 0
    counts = df.drop(index=NO_FEATURE, errors='ignore')['final_count']
    return counts, no_feature_count


def parse_star_input_reads(log_path):
    """Extract 'Number of input reads' from a STAR Log.final.out file.

    Same parsing convention as bin/aggregate_host_counts.py's
    parse_star_input_reads(), duplicated here rather than imported since each
    bin/ script is baked standalone into its own container (see
    containers/telescope.def vs containers/host_quant.sif's %files).
    """
    with open(log_path) as f:
        for line in f:
            if 'Number of input reads' in line:
                match = re.search(r'\|\s*(\d+)', line)
                if match:
                    return int(match.group(1))
    raise ValueError(f"Could not parse input reads from {log_path}")


@click.command()
@click.option('--counts', '-i', multiple=True, required=True, type=click.Path(exists=True),
              help='Per-sample Telescope *-telescope_report.tsv files (repeatable). '
                   'Filename must be <sample_id>-telescope_report.tsv '
                   '(modules/telescope_assign.nf convention) so the sample ID can be recovered.')
@click.option('--star-log', '-s', multiple=True, default=None, type=click.Path(exists=True),
              help='Optional per-sample STAR_REALIGN_MULTIMAP Log.final.out files (repeatable, '
                   '<sample_id>_Log.final.out). If provided for a sample, an RPM column is '
                   'added using STAR total-input-reads as denominator, same convention as '
                   'aggregate_virome.py / aggregate_host_counts.py. Samples without a matching '
                   'log get raw counts only, no error.')
@click.option('--output', '-o', required=True, help='Output matrix path (TSV)')
def main(counts, star_log, output):
    star_reads = {}
    for log_path in star_log:
        sample_id = Path(log_path).name.replace('_Log.final.out', '')
        star_reads[sample_id] = parse_star_input_reads(log_path)

    per_sample = {}
    no_feature_by_sample = {}
    for f in counts:
        sample_id = sample_id_from_report_path(f)
        per_sample[sample_id], no_feature_by_sample[sample_id] = load_telescope_report(f)
    print(f"Parsed {len(per_sample)} sample telescope_report.tsv file(s)")
    for sample_id, n in no_feature_by_sample.items():
        total = per_sample[sample_id].sum() + n
        pct = (100.0 * n / total) if total else 0.0
        print(f"  {sample_id}: {n} fragments unassigned to any locus ({pct:.1f}% of {total})")

    if not per_sample:
        pd.DataFrame(columns=['locus']).to_csv(output, sep='\t', index=False)
        print(f"No input files -- wrote empty matrix -> {output}")
        return

    matrix = pd.DataFrame(per_sample).fillna(0)
    matrix.index.name = 'locus'

    for sample_id in matrix.columns:
        matrix = matrix.rename(columns={sample_id: f'{sample_id}_reads'})
        if sample_id in star_reads and star_reads[sample_id] > 0:
            matrix[f'{sample_id}_rpm'] = (
                matrix[f'{sample_id}_reads'] / star_reads[sample_id] * 1_000_000
            ).round(4)

    matrix = matrix.sort_index()
    matrix.reset_index().to_csv(output, sep='\t', index=False)

    n_samples = len(per_sample)
    n_rpm = len(star_reads)
    print(f"Telescope locus matrix: {len(matrix)} loci x {n_samples} sample(s) -> {output}")
    if n_rpm:
        print(f"  RPM computed for {n_rpm}/{n_samples} sample(s) (STAR log provided)")
    if n_rpm < n_samples:
        missing = set(per_sample) - set(star_reads)
        print(f"  No STAR log provided for: {', '.join(sorted(missing))} -- raw counts only")


if __name__ == '__main__':
    main()
