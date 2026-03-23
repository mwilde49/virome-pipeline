#!/usr/bin/env python3
"""
virome_report.py

Generate summary plots and an HTML report from the viral abundance matrix.

Outputs (all in --outdir):
  - heatmap.png          — top-N taxa heatmap (log10 reads)
  - prevalence_bar.png   — taxa prevalence across samples
  - diversity.tsv        — per-sample richness and Shannon diversity
  - summary.html         — self-contained HTML report embedding plots
"""

import click
import math
import os
import pandas as pd
import numpy as np
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt
import seaborn as sns
from pathlib import Path


TOP_N = 30


def shannon_diversity(counts):
    counts = counts[counts > 0]
    total = counts.sum()
    if total == 0:
        return 0.0
    p = counts / total
    return -np.sum(p * np.log(p))


@click.command()
@click.option('--matrix',   required=True, type=click.Path(exists=True), help='Viral abundance matrix TSV')
@click.option('--metadata', required=True, type=click.Path(exists=True), help='Samplesheet CSV (sample,fastq_r1,fastq_r2)')
@click.option('--outdir',   required=True,                                help='Output directory')
@click.option('--top-n',    default=TOP_N, show_default=True,             help='Number of top taxa to include in heatmap')
def main(matrix, metadata, outdir, top_n):
    Path(outdir).mkdir(parents=True, exist_ok=True)

    df = pd.read_csv(matrix, sep='\t')
    meta = pd.read_csv(metadata)[['sample']]

    # Identify sample columns
    fixed_cols = ['taxon_id', 'taxon_name', 'rank']
    sample_cols = [c for c in df.columns if c not in fixed_cols]

    counts = df.set_index('taxon_name')[sample_cols]

    # --- Heatmap (top N by total reads) ---
    top_taxa = counts.sum(axis=1).nlargest(top_n).index
    top_counts = counts.loc[top_taxa]
    log_counts = np.log10(top_counts + 1)

    fig, ax = plt.subplots(figsize=(max(8, len(sample_cols) * 0.6), max(8, top_n * 0.35)))
    sns.heatmap(log_counts, ax=ax, cmap='YlOrRd', linewidths=0.3,
                cbar_kws={'label': 'log10(reads + 1)'})
    ax.set_title(f'Top {top_n} Viral Taxa by Read Count')
    ax.set_xlabel('Sample')
    ax.set_ylabel('Taxon')
    plt.tight_layout()
    heatmap_path = os.path.join(outdir, 'heatmap.png')
    fig.savefig(heatmap_path, dpi=150)
    plt.close(fig)

    # --- Prevalence bar ---
    prevalence = (counts > 0).sum(axis=1).sort_values(ascending=False).head(top_n)
    fig, ax = plt.subplots(figsize=(10, max(6, top_n * 0.3)))
    prevalence.plot(kind='barh', ax=ax, color='steelblue')
    ax.set_xlabel('Number of Samples')
    ax.set_title(f'Top {top_n} Taxa by Prevalence')
    ax.invert_yaxis()
    plt.tight_layout()
    prev_path = os.path.join(outdir, 'prevalence_bar.png')
    fig.savefig(prev_path, dpi=150)
    plt.close(fig)

    # --- Diversity table ---
    diversity = pd.DataFrame({
        'sample':   sample_cols,
        'richness': [int((counts[s] > 0).sum()) for s in sample_cols],
        'shannon':  [round(shannon_diversity(counts[s]), 4) for s in sample_cols],
        'total_viral_reads': [int(counts[s].sum()) for s in sample_cols],
    })
    div_path = os.path.join(outdir, 'diversity.tsv')
    diversity.to_csv(div_path, sep='\t', index=False)

    # --- Minimal HTML report ---
    html = _build_html(top_n, sample_cols, diversity)
    html_path = os.path.join(outdir, 'summary.html')
    with open(html_path, 'w') as f:
        f.write(html)

    print(f"Report written to {outdir}/")


def _build_html(top_n, sample_cols, diversity):
    rows = '\n'.join(
        f"<tr><td>{r['sample']}</td><td>{r['total_viral_reads']:,}</td>"
        f"<td>{r['richness']}</td><td>{r['shannon']:.4f}</td></tr>"
        for _, r in diversity.iterrows()
    )
    return f"""<!DOCTYPE html>
<html lang="en">
<head><meta charset="UTF-8"><title>Virome Report</title>
<style>
  body {{ font-family: Arial, sans-serif; margin: 40px; }}
  table {{ border-collapse: collapse; width: 100%; }}
  th, td {{ border: 1px solid #ccc; padding: 8px 12px; text-align: left; }}
  th {{ background: #f0f0f0; }}
  img {{ max-width: 100%; margin: 20px 0; }}
</style></head>
<body>
<h1>DRG Virome Report</h1>
<p>{len(sample_cols)} samples | Top {top_n} taxa shown</p>

<h2>Diversity Summary</h2>
<table>
  <tr><th>Sample</th><th>Total Viral Reads</th><th>Richness</th><th>Shannon Diversity</th></tr>
  {rows}
</table>

<h2>Top {top_n} Taxa — Abundance Heatmap</h2>
<img src="heatmap.png" alt="Heatmap">

<h2>Top {top_n} Taxa — Prevalence</h2>
<img src="prevalence_bar.png" alt="Prevalence">
</body></html>
"""


if __name__ == '__main__':
    main()
