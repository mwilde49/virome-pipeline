#!/usr/bin/env python3
"""
aggregate_virome.py

Combine per-sample filtered Kraken2 TSVs into a single viral abundance matrix.
Rows = taxa, Columns = samples.

Output columns per sample:
  <sample>_reads  — raw Kraken2 direct read counts
  <sample>_rpm    — reads per million trimmed reads (from STAR input reads)

Produces both TSV and CSV outputs.
"""

import re
import click
import pandas as pd
from pathlib import Path


def parse_star_input_reads(log_path):
    """Extract 'Number of input reads' from a STAR Log.final.out file."""
    with open(log_path) as f:
        for line in f:
            if 'Number of input reads' in line:
                match = re.search(r'\|\s*(\d+)', line)
                if match:
                    return int(match.group(1))
    raise ValueError(f"Could not parse input reads from {log_path}")


@click.command()
@click.option('--input',    '-i', multiple=True, required=True, help='Per-sample filtered TSV files (repeatable)')
@click.option('--star-log', '-s', multiple=True, default=None,  help='Per-sample STAR Log.final.out files (repeatable, same order as --input)')
@click.option('--output',   '-o', required=True,                help='Output file prefix (no extension)')
def main(input, star_log, output):

    # Build sample_id -> total_reads map from STAR logs
    star_reads = {}
    if star_log:
        for log_path in star_log:
            # Sample ID is the prefix before _Log.final.out
            sample_id = Path(log_path).name.replace('_Log.final.out', '')
            star_reads[sample_id] = parse_star_input_reads(log_path)

    frames = []
    for tsv_path in input:
        sample_id = Path(tsv_path).name.split('.')[0]
        df = pd.read_csv(tsv_path, sep='\t')
        df = df[['taxon_id', 'taxon_name', 'rank', 'reads']].copy()

        total = star_reads.get(sample_id)
        if total and total > 0:
            df[f'{sample_id}_reads'] = df['reads']
            df[f'{sample_id}_rpm']   = (df['reads'] / total * 1e6).round(4)
        else:
            df[f'{sample_id}_reads'] = df['reads']

        frames.append(df.set_index(['taxon_id', 'taxon_name', 'rank']).drop(columns='reads'))

    if not frames:
        raise click.ClickException("No input files provided.")

    matrix = pd.concat(frames, axis=1).fillna(0)

    # Integer-ify read count columns, keep RPM as float
    for col in matrix.columns:
        if col.endswith('_reads'):
            matrix[col] = matrix[col].astype(int)

    matrix = matrix.reset_index()

    # Sort by total reads across samples
    read_cols = [c for c in matrix.columns if c.endswith('_reads')]
    matrix['_total'] = matrix[read_cols].sum(axis=1)
    matrix = matrix.sort_values('_total', ascending=False).drop(columns='_total')

    tsv_out = f"{output}.tsv"
    csv_out = f"{output}.csv"
    matrix.to_csv(tsv_out, sep='\t', index=False)
    matrix.to_csv(csv_out, index=False)

    n_taxa    = len(matrix)
    n_samples = len(read_cols)
    rpm_note  = f" (with RPM)" if star_reads else " (no RPM — STAR logs not provided)"
    print(f"Abundance matrix: {n_taxa} taxa × {n_samples} samples{rpm_note} → {tsv_out}")


if __name__ == '__main__':
    main()
