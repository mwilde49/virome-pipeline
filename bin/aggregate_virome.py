#!/usr/bin/env python3
"""
aggregate_virome.py

Combine per-sample filtered Kraken2 TSVs into a single viral abundance matrix.
Rows = taxa, Columns = samples.  Values = raw read counts.
Produces both TSV and CSV outputs.
"""

import click
import pandas as pd
from pathlib import Path


@click.command()
@click.option('--input',  '-i', multiple=True, required=True, help='Per-sample filtered TSV files (repeatable)')
@click.option('--output', '-o', required=True,                help='Output file prefix (no extension)')
def main(input, output):
    frames = []

    for tsv_path in input:
        sample_id = Path(tsv_path).stem.replace('.filtered', '')
        df = pd.read_csv(tsv_path, sep='\t')
        df = df[['taxon_id', 'taxon_name', 'rank', 'reads']].copy()
        df = df.rename(columns={'reads': sample_id})
        frames.append(df.set_index(['taxon_id', 'taxon_name', 'rank']))

    if not frames:
        raise click.ClickException("No input files provided.")

    matrix = pd.concat(frames, axis=1).fillna(0).astype(int)
    matrix = matrix.reset_index()
    matrix = matrix.sort_values(matrix.columns[3:].tolist(), ascending=False)

    tsv_out = f"{output}.tsv"
    csv_out = f"{output}.csv"
    matrix.to_csv(tsv_out, sep='\t', index=False)
    matrix.to_csv(csv_out, index=False)

    n_taxa, n_samples = len(matrix), len(matrix.columns) - 3
    print(f"Abundance matrix: {n_taxa} taxa × {n_samples} samples → {tsv_out}, {csv_out}")


if __name__ == '__main__':
    main()
