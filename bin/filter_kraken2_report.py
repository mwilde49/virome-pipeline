#!/usr/bin/env python3
"""
filter_kraken2_report.py

Filter a Kraken2 report to retain only viral taxa above a minimum read count.
Optionally excludes known artifact taxa from a curated exclusion list.
Outputs a TSV with columns: taxon_id, taxon_name, rank, reads, percent.
"""

import click
import pandas as pd


KRAKEN2_REPORT_COLS = [
    'percent', 'reads_clade', 'reads_direct', 'rank', 'taxon_id', 'taxon_name'
]

VIRAL_RANKS = {'S', 'S1', 'S2', 'G', 'G1', 'F'}  # species and below are most relevant


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
@click.option('--report',        required=True,  type=click.Path(exists=True), help='Kraken2 report file')
@click.option('--min-reads',     default=5,      show_default=True,            help='Minimum direct reads to retain a taxon')
@click.option('--artifact-list', default=None,   type=click.Path(exists=True), help='TSV of artifact taxon IDs to exclude')
@click.option('--output',        required=True,                                 help='Output TSV path')
def main(report, min_reads, artifact_list, output):
    df = pd.read_csv(
        report,
        sep='\t',
        header=None,
        names=KRAKEN2_REPORT_COLS
    )

    # Strip leading whitespace from taxon_name (Kraken2 indents by clade depth)
    df['taxon_name'] = df['taxon_name'].str.strip()

    viral_df = df[
        (df['reads_direct'] >= min_reads) &
        (df['rank'].isin(VIRAL_RANKS)) &
        (df['taxon_id'] != 0)
    ].copy()

    viral_df = viral_df[['taxon_id', 'taxon_name', 'rank', 'reads_direct', 'percent']].rename(
        columns={'reads_direct': 'reads'}
    )

    # Apply artifact exclusion list
    if artifact_list:
        excluded_ids = load_artifact_taxa(artifact_list)
        before = len(viral_df)
        viral_df = viral_df[~viral_df['taxon_id'].isin(excluded_ids)]
        removed = before - len(viral_df)
        if removed:
            print(f"Excluded {removed} artifact taxa")

    viral_df = viral_df.sort_values('reads', ascending=False)
    viral_df.to_csv(output, sep='\t', index=False)
    print(f"Retained {len(viral_df)} taxa with >= {min_reads} reads → {output}")


if __name__ == '__main__':
    main()
