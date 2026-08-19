#!/usr/bin/env python3
"""
aggregate_host_counts.py

Combine featureCounts (Rsubread) and HTSeq gene-count outputs for the STAR
host-mapped reads into a single host gene expression matrix, cross-checked
between the two independent counters. Normalizes to the same STAR total
input-read denominator used by aggregate_virome.py, so host gene RPM and
viral taxon RPM are directly comparable.

Rows = genes, Columns = samples (raw counts + RPM per counter).
Also emits a per-sample concordance QC file (Pearson/Spearman between the
two counters across all genes).
"""

import re
import click
import numpy as np
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


def load_featurecounts(path):
    df = pd.read_csv(path, index_col=0)
    df.index.name = 'gene_id'
    df.columns = [re.sub(r'\.filt\.bam$', '', c) for c in df.columns]
    return df


def load_htseq(path):
    df = pd.read_csv(path, sep='\t', index_col=0)
    df.index.name = 'gene_id'
    summary = df[df.index.str.startswith('__')]
    df = df[~df.index.str.startswith('__')]
    return df, summary


@click.command()
@click.option('--featurecounts', required=True, help='featureCounts raw counts CSV (genes x samples)')
@click.option('--htseq',         required=True, help='HTSeq raw counts TSV (genes x samples)')
@click.option('--star-log', '-s', multiple=True, default=None, help='Per-sample STAR Log.final.out files (repeatable)')
@click.option('--gene-info', default=None, help='Optional gene_id/gene_name/gene_biotype lookup TSV')
@click.option('--output', '-o', required=True, help='Output file prefix (no extension)')
def main(featurecounts, htseq, star_log, gene_info, output):

    star_reads = {}
    for log_path in star_log:
        sample_id = Path(log_path).name.replace('_Log.final.out', '')
        star_reads[sample_id] = parse_star_input_reads(log_path)

    fc = load_featurecounts(featurecounts)
    hts, hts_summary = load_htseq(htseq)

    samples = sorted(set(fc.columns) | set(hts.columns))

    # --- concordance QC (per sample, across all shared genes) ---
    qc_rows = []
    for sample in samples:
        if sample not in fc.columns or sample not in hts.columns:
            continue
        shared = fc.index.intersection(hts.index)
        a = np.log1p(fc.loc[shared, sample].astype(float))
        b = np.log1p(hts.loc[shared, sample].astype(float))
        pearson_r  = a.corr(b, method='pearson')
        spearman_r = a.corr(b, method='spearman')
        qc_rows.append({
            'sample': sample,
            'pearson_r_log1p': round(pearson_r, 4),
            'spearman_r': round(spearman_r, 4),
            'n_genes_compared': len(shared),
        })
    qc_df = pd.DataFrame(qc_rows)
    qc_df.to_csv(f"{output}_qc_summary.tsv", sep='\t', index=False)

    # --- main matrix: raw + RPM per counter per sample ---
    matrix = pd.DataFrame(index=sorted(set(fc.index) | set(hts.index)))
    matrix.index.name = 'gene_id'

    for sample in samples:
        total = star_reads.get(sample)

        if sample in fc.columns:
            matrix[f'{sample}_fc_reads'] = fc[sample].reindex(matrix.index).fillna(0).astype(int)
            if total:
                matrix[f'{sample}_fc_rpm'] = (matrix[f'{sample}_fc_reads'] / total * 1e6).round(4)

        if sample in hts.columns:
            matrix[f'{sample}_htseq_reads'] = hts[sample].reindex(matrix.index).fillna(0).astype(int)
            if total:
                matrix[f'{sample}_htseq_rpm'] = (matrix[f'{sample}_htseq_reads'] / total * 1e6).round(4)

    if gene_info:
        info = pd.read_csv(gene_info, sep='\t').drop_duplicates('gene_id').set_index('gene_id')
        matrix = info.reindex(matrix.index).join(matrix)

    matrix = matrix.reset_index()

    tsv_out = f"{output}.tsv"
    csv_out = f"{output}.csv"
    matrix.to_csv(tsv_out, sep='\t', index=False)
    matrix.to_csv(csv_out, index=False)

    n_genes   = len(matrix)
    n_samples = len(samples)
    mean_r    = qc_df['pearson_r_log1p'].mean() if len(qc_df) else float('nan')
    print(f"Host gene expression matrix: {n_genes} genes x {n_samples} samples -> {tsv_out}")
    print(f"featureCounts/HTSeq concordance (mean log1p Pearson r across samples): {mean_r:.4f}")
    if len(hts_summary):
        print(f"HTSeq summary rows (unassigned/ambiguous/etc.) written are excluded from the matrix; "
              f"see raw htseq_raw.tsv for the __-prefixed rows.")


if __name__ == '__main__':
    main()
