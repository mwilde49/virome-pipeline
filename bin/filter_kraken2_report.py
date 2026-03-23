#!/usr/bin/env python3
"""
filter_kraken2_report.py

Filter a Bracken/Kraken2 report through three progressive stages and emit
intermediate TSVs so that each filtering step can be tracked in the report.

Outputs (all written automatically alongside --output):
  {id}.bracken_raw.tsv        — all viral ranks, no read-count threshold
  {id}.minreads.tsv           — after min-reads filter, before artifact exclusion
  {id}.filtered.tsv           — final: min-reads + artifact exclusion (= --output)
  {id}.filter_summary.tsv     — per-stage counts table
  {id}.artifacts_removed.tsv  — taxa removed by artifact exclusion (may be empty)
"""

import click
import pandas as pd
from pathlib import Path


KRAKEN2_REPORT_COLS = [
    'percent', 'reads_clade', 'reads_direct', 'rank', 'taxon_id', 'taxon_name'
]

VIRAL_RANKS = {'S', 'S1', 'S2', 'G', 'G1', 'F'}


def load_artifact_taxa(artifact_list):
    """Load artifact taxon IDs from a TSV file, ignoring comment lines."""
    excluded = set()
    with open(artifact_list) as f:
        for line in f:
            line = line.strip()
            if not line or line.startswith('#'):
                continue
            parts = line.split('\t')
            try:
                excluded.add(int(parts[0]))
            except (ValueError, IndexError):
                pass
    return excluded


@click.command()
@click.option('--report',     required=True,  type=click.Path(exists=True), help='Kraken2/Bracken report file')
@click.option('--sample-id',  required=True,                                help='Sample identifier (used in filter_summary.tsv)')
@click.option('--min-reads',  default=5,      show_default=True,            help='Minimum direct reads to retain a taxon')
@click.option('--artifact-list', default=None, type=click.Path(exists=True), help='TSV of artifact taxon IDs to exclude')
@click.option('--output',     required=True,                                 help='Final filtered output TSV path ({id}.filtered.tsv)')
def main(report, sample_id, min_reads, artifact_list, output):
    # Derive output prefix (strip .filtered.tsv or use stem)
    out_path = Path(output)
    prefix = str(out_path.parent / out_path.name.replace('.filtered.tsv', ''))

    df = pd.read_csv(report, sep='\t', header=None, names=KRAKEN2_REPORT_COLS)
    df['taxon_name'] = df['taxon_name'].str.strip()

    # ── Stage 1: bracken_raw — viral ranks only, no threshold ────────────────
    bracken_raw = df[
        (df['rank'].isin(VIRAL_RANKS)) &
        (df['taxon_id'] != 0)
    ].copy()
    bracken_raw = bracken_raw[['taxon_id', 'taxon_name', 'rank', 'reads_direct', 'percent']].rename(
        columns={'reads_direct': 'reads'}
    ).sort_values('reads', ascending=False)
    bracken_raw.to_csv(f"{prefix}.bracken_raw.tsv", sep='\t', index=False)

    # ── Stage 2: minreads — apply read-count threshold ────────────────────────
    minreads_df = bracken_raw[bracken_raw['reads'] >= min_reads].copy()
    minreads_df.to_csv(f"{prefix}.minreads.tsv", sep='\t', index=False)

    # ── Stage 3: final — apply artifact exclusion ──────────────────────────────
    artifacts_df = pd.DataFrame(columns=['taxon_id', 'taxon_name', 'rank', 'reads'])
    final_df = minreads_df.copy()
    if artifact_list:
        excluded_ids = load_artifact_taxa(artifact_list)
        mask = final_df['taxon_id'].isin(excluded_ids)
        artifacts_df = final_df[mask].copy()
        final_df = final_df[~mask].copy()
        if len(artifacts_df):
            print(f"Excluded {len(artifacts_df)} artifact taxa")

    final_df.to_csv(output, sep='\t', index=False)
    artifacts_df.to_csv(f"{prefix}.artifacts_removed.tsv", sep='\t', index=False)

    # ── Filter summary ─────────────────────────────────────────────────────────
    summary = pd.DataFrame([
        {'sample_id': sample_id, 'stage': 'bracken_raw',
         'taxa_kept': len(bracken_raw),    'reads_retained': int(bracken_raw['reads'].sum())},
        {'sample_id': sample_id, 'stage': 'minreads',
         'taxa_kept': len(minreads_df),    'reads_retained': int(minreads_df['reads'].sum())},
        {'sample_id': sample_id, 'stage': 'final',
         'taxa_kept': len(final_df),       'reads_retained': int(final_df['reads'].sum())},
    ])
    summary.to_csv(f"{prefix}.filter_summary.tsv", sep='\t', index=False)

    print(f"bracken_raw={len(bracken_raw)} | minreads={len(minreads_df)} | final={len(final_df)} → {output}")


if __name__ == '__main__':
    main()
