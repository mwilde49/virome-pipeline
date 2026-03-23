#!/usr/bin/env python3
"""
filter_kraken2_report.py

Filter a Kraken2 report to retain only viral taxa above a minimum read count.
Outputs a TSV with columns: taxon_id, taxon_name, rank, reads, percent.
"""

import click
import pandas as pd


KRAKEN2_REPORT_COLS = [
    'percent', 'reads_clade', 'reads_direct', 'rank', 'taxon_id', 'taxon_name'
]

VIRAL_RANKS = {'S', 'S1', 'S2', 'G', 'G1', 'F'}  # species and below are most relevant


@click.command()
@click.option('--report',    required=True,  type=click.Path(exists=True), help='Kraken2 report file')
@click.option('--min-reads', default=5,      show_default=True,            help='Minimum direct reads to retain a taxon')
@click.option('--output',    required=True,                                 help='Output TSV path')
def main(report, min_reads, output):
    df = pd.read_csv(
        report,
        sep='\t',
        header=None,
        names=KRAKEN2_REPORT_COLS
    )

    # Strip leading whitespace from taxon_name (Kraken2 indents by clade depth)
    df['taxon_name'] = df['taxon_name'].str.strip()

    # Keep only viral domain subtree — taxon_id 10239 is Viruses
    # The report is hierarchical; filter rows that fall under rank codes for viral species
    viral_df = df[
        (df['reads_direct'] >= min_reads) &
        (df['rank'].isin(VIRAL_RANKS)) &
        (df['taxon_id'] != 0)
    ].copy()

    viral_df = viral_df[['taxon_id', 'taxon_name', 'rank', 'reads_direct', 'percent']].rename(
        columns={'reads_direct': 'reads'}
    )
    viral_df = viral_df.sort_values('reads', ascending=False)

    viral_df.to_csv(output, sep='\t', index=False)
    print(f"Retained {len(viral_df)} taxa with >= {min_reads} reads → {output}")


if __name__ == '__main__':
    main()
