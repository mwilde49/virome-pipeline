#!/usr/bin/env python3
"""
plot_stages.py

Generate heatmap and prevalence bar charts for each filtering stage
(bracken_raw, minreads, final) from a virome pipeline results directory.

Usage:
    python3 plot_stages.py <results_dir> <outdir>

Example:
    python3 plot_stages.py results/muscle_drg_combined/results research/stage_plots

Options:
    --exclude SAMPLE1,SAMPLE2   Comma-separated sample IDs to drop before plotting
"""

import sys
import os
import numpy as np
import pandas as pd
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt
import seaborn as sns
from pathlib import Path

TOP_N = 30

STAGES = [
    ('bracken_raw_matrix.tsv',    'Bracken Raw (no filtering)',         'bracken_raw'),
    ('minreads_matrix.tsv',       'After Min-Reads Filter (≥5 reads)',  'minreads'),
    ('viral_abundance_matrix.tsv','Final (artifact exclusion applied)', 'final'),
]


def read_counts(df):
    read_cols = [c for c in df.columns if c.endswith('_reads')]
    return df.set_index('taxon_name')[read_cols].rename(
        columns=lambda c: c.replace('_reads', '')
    )


def plot_heatmap(counts, title, outpath, top_n=TOP_N):
    top = counts.sum(axis=1).nlargest(top_n).index
    data = np.log10(counts.loc[top] + 1)
    fig, ax = plt.subplots(figsize=(max(8, len(counts.columns) * 0.7), max(6, len(top) * 0.35)))
    sns.heatmap(data, ax=ax, cmap='YlOrRd', linewidths=0.3,
                cbar_kws={'label': 'log10(reads + 1)'})
    ax.set_title(title, fontsize=13, pad=10)
    ax.set_xlabel('Sample')
    ax.set_ylabel('')
    plt.tight_layout()
    fig.savefig(outpath, dpi=150)
    plt.close(fig)
    print(f"  heatmap    → {outpath}")


def plot_prevalence(counts, title, outpath, top_n=TOP_N):
    prevalence = (counts > 0).sum(axis=1).sort_values(ascending=False).head(top_n)
    fig, ax = plt.subplots(figsize=(10, max(5, len(prevalence) * 0.32)))
    prevalence.plot(kind='barh', ax=ax, color='steelblue')
    ax.set_xlabel('Number of Samples')
    ax.set_title(title, fontsize=13, pad=10)
    ax.invert_yaxis()
    ax.axvline(x=len(counts.columns), color='red', linestyle='--', alpha=0.4, label='all samples')
    ax.legend(fontsize=8)
    plt.tight_layout()
    fig.savefig(outpath, dpi=150)
    plt.close(fig)
    print(f"  prevalence → {outpath}")


def plot_total_reads_bar(counts, title, outpath):
    """Total viral reads per sample at this stage."""
    totals = counts.sum(axis=0).sort_values(ascending=False)
    fig, ax = plt.subplots(figsize=(max(8, len(totals) * 0.7), 4))
    totals.plot(kind='bar', ax=ax, color='teal')
    ax.set_ylabel('Total viral reads')
    ax.set_title(title, fontsize=13, pad=10)
    ax.set_xticklabels(ax.get_xticklabels(), rotation=30, ha='right')
    plt.tight_layout()
    fig.savefig(outpath, dpi=150)
    plt.close(fig)
    print(f"  total_reads→ {outpath}")


def main():
    args = [a for a in sys.argv[1:] if not a.startswith('--')]
    if len(args) < 2:
        print(__doc__)
        sys.exit(1)

    results_dir = Path(args[0])
    outdir = Path(args[1])
    outdir.mkdir(parents=True, exist_ok=True)

    exclude = set()
    for a in sys.argv[1:]:
        if a.startswith('--exclude='):
            exclude = set(a.split('=', 1)[1].split(','))
        elif a == '--exclude' and sys.argv.index(a) + 1 < len(sys.argv):
            exclude = set(sys.argv[sys.argv.index(a) + 1].split(','))
    if exclude:
        print(f"Excluding samples: {', '.join(sorted(exclude))}")

    for filename, label, stage in STAGES:
        path = results_dir / filename
        if not path.exists():
            print(f"SKIP {filename} — not found")
            continue

        print(f"\n── {label} ──")
        df = pd.read_csv(path, sep='\t')
        counts = read_counts(df)
        if exclude:
            counts = counts.drop(columns=[c for c in exclude if c in counts.columns])
        n_taxa = len(counts)
        print(f"  {n_taxa} taxa, {len(counts.columns)} samples")

        plot_heatmap(counts,    f"Top {min(TOP_N, n_taxa)} Taxa — {label}",
                     outdir / f"{stage}_heatmap.png")
        plot_prevalence(counts, f"Taxa Prevalence — {label}",
                     outdir / f"{stage}_prevalence.png")
        plot_total_reads_bar(counts, f"Total Viral Reads per Sample — {label}",
                     outdir / f"{stage}_total_reads.png")

    print(f"\nAll plots saved to {outdir}/")


if __name__ == '__main__':
    main()
