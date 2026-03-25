#!/usr/bin/env python3
"""
virome_report.py

Generate summary plots and an HTML report from multi-stage viral abundance matrices.

Stages:
  bracken_raw  — all viral species detected by Bracken (no filtering)
  minreads     — after per-sample read-count threshold
  final        — after artifact exclusion (final abundance matrix)

Outputs (all in --outdir):
  heatmap.png              — top-N taxa heatmap (log10 reads), final matrix
  prevalence_bar.png       — taxa prevalence across samples, final matrix
  filtering_funnel.png     — taxa count progression per sample through filter stages
  read_attrition.png       — read counts retained at each filter stage per sample
  diversity.tsv            — per-sample richness and Shannon diversity (final)
  filter_summary.tsv       — aggregated per-sample filter stats
  summary.html             — self-contained HTML report embedding all plots
"""

import base64
import click
import os
import pandas as pd
import numpy as np
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt
import seaborn as sns
from pathlib import Path


TOP_N = 30
STAGE_LABELS = {'bracken_raw': 'Bracken raw', 'minreads': 'Min-reads', 'final': 'Final'}
STAGE_COLORS = {'bracken_raw': '#4e79a7', 'minreads': '#f28e2b', 'final': '#59a14f'}


def shannon_diversity(counts):
    counts = counts[counts > 0]
    total = counts.sum()
    if total == 0:
        return 0.0
    p = counts / total
    return -np.sum(p * np.log(p))


def read_counts_only(matrix_df):
    """Return only the _reads columns from a matrix, with taxon_name as index."""
    fixed = ['taxon_id', 'taxon_name', 'rank']
    read_cols = [c for c in matrix_df.columns if c.endswith('_reads')]
    return matrix_df.set_index('taxon_name')[read_cols]


def img_tag(path):
    """Embed a PNG as a base64 data URI for a self-contained HTML report."""
    with open(path, 'rb') as f:
        data = base64.b64encode(f.read()).decode()
    return f'<img src="data:image/png;base64,{data}" style="max-width:100%;margin:16px 0;">'


# ─── Plot helpers ─────────────────────────────────────────────────────────────

def plot_heatmap(counts, top_n, outpath):
    top_taxa = counts.sum(axis=1).nlargest(top_n).index
    top = counts.loc[top_taxa]
    log_top = np.log10(top + 1)
    fig, ax = plt.subplots(figsize=(max(8, len(counts.columns) * 0.6), max(8, top_n * 0.35)))
    sns.heatmap(log_top, ax=ax, cmap='YlOrRd', linewidths=0.3,
                cbar_kws={'label': 'log10(reads + 1)'})
    ax.set_title(f'Top {top_n} Viral Taxa — Final Abundance (log10 reads)')
    ax.set_xlabel('Sample')
    ax.set_ylabel('Taxon')
    plt.tight_layout()
    fig.savefig(outpath, dpi=150)
    plt.close(fig)


def plot_prevalence(counts, top_n, outpath):
    prevalence = (counts > 0).sum(axis=1).sort_values(ascending=False).head(top_n)
    fig, ax = plt.subplots(figsize=(10, max(6, top_n * 0.3)))
    prevalence.plot(kind='barh', ax=ax, color='steelblue')
    ax.set_xlabel('Number of Samples')
    ax.set_title(f'Top {top_n} Taxa by Prevalence (Final)')
    ax.invert_yaxis()
    plt.tight_layout()
    fig.savefig(outpath, dpi=150)
    plt.close(fig)


def plot_filtering_funnel(summary_df, outpath):
    """Grouped bar chart: taxa retained per stage, one group per sample."""
    pivot = summary_df.pivot(index='sample_id', columns='stage', values='taxa_kept')
    # Ensure stage order
    stages = [s for s in ['bracken_raw', 'minreads', 'final'] if s in pivot.columns]
    pivot = pivot[stages]

    n_samples = len(pivot)
    n_stages  = len(stages)
    width     = 0.25
    x         = np.arange(n_samples)

    fig, ax = plt.subplots(figsize=(max(8, n_samples * 0.9), 5))
    for i, stage in enumerate(stages):
        ax.bar(x + i * width, pivot[stage], width,
               label=STAGE_LABELS.get(stage, stage),
               color=STAGE_COLORS.get(stage, f'C{i}'))

    ax.set_xticks(x + width)
    ax.set_xticklabels(pivot.index, rotation=30, ha='right')
    ax.set_ylabel('Taxa retained')
    ax.set_title('Taxa Retained Through Filtering Stages')
    ax.legend()
    plt.tight_layout()
    fig.savefig(outpath, dpi=150)
    plt.close(fig)


def plot_read_attrition(summary_df, outpath):
    """Stacked bar: reads retained vs removed at each stage transition."""
    pivot = summary_df.pivot(index='sample_id', columns='stage', values='reads_retained')
    stages = [s for s in ['bracken_raw', 'minreads', 'final'] if s in pivot.columns]
    if len(stages) < 2:
        return  # not enough stages to show attrition

    pivot = pivot[stages]
    n_samples = len(pivot)
    x = np.arange(n_samples)

    fig, ax = plt.subplots(figsize=(max(8, n_samples * 0.9), 5))
    bottom = np.zeros(n_samples)
    for stage in stages:
        vals = pivot[stage].fillna(0).values
        ax.bar(x, vals, bottom=bottom,
               label=STAGE_LABELS.get(stage, stage),
               color=STAGE_COLORS.get(stage, None))
        bottom = vals  # not actually stacked — just overlay last stage

    # Simpler approach: grouped bars of reads_retained per stage
    plt.close(fig)

    width = 0.25
    fig, ax = plt.subplots(figsize=(max(8, n_samples * 0.9), 5))
    for i, stage in enumerate(stages):
        ax.bar(x + i * width, pivot[stage].fillna(0), width,
               label=STAGE_LABELS.get(stage, stage),
               color=STAGE_COLORS.get(stage, f'C{i}'))

    ax.set_xticks(x + width)
    ax.set_xticklabels(pivot.index, rotation=30, ha='right')
    ax.set_ylabel('Reads retained')
    ax.set_title('Viral Reads Retained Through Filtering Stages')
    ax.legend()
    plt.tight_layout()
    fig.savefig(outpath, dpi=150)
    plt.close(fig)


# ─── HTML builder ─────────────────────────────────────────────────────────────

def _diversity_rows(diversity):
    return '\n'.join(
        f"<tr><td>{r['sample']}</td><td>{r['total_viral_reads']:,}</td>"
        f"<td>{r['richness']}</td><td>{r['shannon']:.4f}</td></tr>"
        for _, r in diversity.iterrows()
    )


def _funnel_rows(summary_df):
    pivot = summary_df.pivot(index='sample_id', columns='stage', values='taxa_kept').reset_index()
    rows = []
    for _, r in pivot.iterrows():
        raw   = int(r.get('bracken_raw', 0))
        mr    = int(r.get('minreads',    0))
        final = int(r.get('final',       0))
        rows.append(
            f"<tr><td>{r['sample_id']}</td><td>{raw}</td><td>{mr}</td><td>{final}</td>"
            f"<td>{raw - final}</td></tr>"
        )
    return '\n'.join(rows)


def build_html(outdir, top_n, sample_cols, diversity, summary_df,
               heatmap_path, prev_path, funnel_path, attrition_path,
               comparison_plot=None):
    plots_html = ''
    for path, caption in [
        (heatmap_path,   f'Top {top_n} Taxa — Abundance Heatmap (Final)'),
        (prev_path,      f'Top {top_n} Taxa — Prevalence (Final)'),
        (funnel_path,    'Taxa Retained Through Filtering Stages'),
        (attrition_path, 'Viral Reads Retained Through Filtering Stages'),
    ]:
        if path and os.path.exists(path):
            plots_html += f'<h2>{caption}</h2>\n{img_tag(path)}\n'

    funnel_table = ''
    if summary_df is not None and not summary_df.empty:
        funnel_table = f"""
<h2>Filtering Funnel Summary</h2>
<table>
  <tr>
    <th>Sample</th>
    <th>Bracken raw</th>
    <th>After min-reads</th>
    <th>Final</th>
    <th>Total removed</th>
  </tr>
  {_funnel_rows(summary_df)}
</table>
"""

    db_comparison_html = ''
    if comparison_plot and os.path.exists(comparison_plot):
        db_comparison_html = f"""
<h2>Dual-Database Comparison (viral-only vs PlusPF)</h2>
<p>Taxa are classified into three tiers based on detection across both Kraken2 databases:
<span style="color:#4CBF7A;font-weight:bold">&#9632; Shared</span> — detected in both databases (high-confidence signal);
<span style="color:#E8824C;font-weight:bold">&#9632; Viral-only</span> — detected only in viral-only DB (false positive candidates);
<span style="color:#9B59B6;font-weight:bold">&#9632; PlusPF only</span> — detected only in PlusPF DB (warrants investigation).
Full comparison table and consensus matrix in <code>results/db_comparison/</code>.</p>
{img_tag(comparison_plot)}
"""

    return f"""<!DOCTYPE html>
<html lang="en">
<head><meta charset="UTF-8"><title>Virome Report</title>
<style>
  body {{ font-family: Arial, sans-serif; margin: 40px; max-width: 1200px; }}
  h1   {{ color: #2c3e50; }}
  h2   {{ color: #34495e; border-bottom: 1px solid #eee; padding-bottom: 4px; }}
  table {{ border-collapse: collapse; width: 100%; margin-bottom: 24px; }}
  th, td {{ border: 1px solid #ccc; padding: 8px 12px; text-align: left; }}
  th {{ background: #f0f0f0; }}
  img {{ max-width: 100%; }}
</style></head>
<body>
<h1>DRG Virome Report</h1>
<p>{len(sample_cols)} samples | Top {top_n} taxa shown in plots</p>

<h2>Diversity Summary (Final filtered matrix)</h2>
<table>
  <tr><th>Sample</th><th>Total Viral Reads</th><th>Richness</th><th>Shannon Diversity</th></tr>
  {_diversity_rows(diversity)}
</table>

{funnel_table}

{db_comparison_html}

{plots_html}
</body></html>
"""


# ─── Main ─────────────────────────────────────────────────────────────────────

@click.command()
@click.option('--matrix',           required=True,  type=click.Path(exists=True), help='Final viral abundance matrix TSV')
@click.option('--bracken-matrix',   required=True,  type=click.Path(exists=True), help='Bracken-raw abundance matrix TSV')
@click.option('--minreads-matrix',  required=True,  type=click.Path(exists=True), help='Min-reads filtered abundance matrix TSV')
@click.option('--filter-summary',   multiple=True,  type=click.Path(exists=True), help='Per-sample filter_summary.tsv files (repeatable)')
@click.option('--metadata',         required=True,  type=click.Path(exists=True), help='Samplesheet CSV')
@click.option('--comparison-plot',  default=None,   type=click.Path(exists=True), help='db_comparison.png from dual-DB run (optional)')
@click.option('--outdir',           required=True,                                 help='Output directory')
@click.option('--top-n',            default=TOP_N,  show_default=True,             help='Number of top taxa in heatmap')
def main(matrix, bracken_matrix, minreads_matrix, filter_summary, metadata, comparison_plot, outdir, top_n):
    Path(outdir).mkdir(parents=True, exist_ok=True)

    final_df   = pd.read_csv(matrix,          sep='\t')
    bracken_df = pd.read_csv(bracken_matrix,  sep='\t')
    minreads_df = pd.read_csv(minreads_matrix, sep='\t')

    fixed_cols = ['taxon_id', 'taxon_name', 'rank']
    final_counts = read_counts_only(final_df)
    sample_cols  = list(final_counts.columns)

    # ── Core plots ────────────────────────────────────────────────────────────
    heatmap_path   = os.path.join(outdir, 'heatmap.png')
    prev_path      = os.path.join(outdir, 'prevalence_bar.png')
    funnel_path    = os.path.join(outdir, 'filtering_funnel.png')
    attrition_path = os.path.join(outdir, 'read_attrition.png')

    plot_heatmap(final_counts, top_n, heatmap_path)
    plot_prevalence(final_counts, top_n, prev_path)

    # ── Filter summary aggregation ────────────────────────────────────────────
    summary_df = None
    if filter_summary:
        frames = [pd.read_csv(p, sep='\t') for p in filter_summary]
        summary_df = pd.concat(frames, ignore_index=True)
        summary_df.to_csv(os.path.join(outdir, 'filter_summary.tsv'), sep='\t', index=False)

        plot_filtering_funnel(summary_df, funnel_path)
        plot_read_attrition(summary_df, attrition_path)

    # ── Diversity table ───────────────────────────────────────────────────────
    diversity = pd.DataFrame({
        'sample':           [c.replace('_reads', '') for c in sample_cols],
        'richness':         [int((final_counts[c] > 0).sum()) for c in sample_cols],
        'shannon':          [round(shannon_diversity(final_counts[c]), 4) for c in sample_cols],
        'total_viral_reads':[int(final_counts[c].sum()) for c in sample_cols],
    })
    diversity.to_csv(os.path.join(outdir, 'diversity.tsv'), sep='\t', index=False)

    # ── HTML report ───────────────────────────────────────────────────────────
    html = build_html(
        outdir, top_n, sample_cols, diversity, summary_df,
        heatmap_path, prev_path,
        funnel_path    if (summary_df is not None and os.path.exists(funnel_path))    else None,
        attrition_path if (summary_df is not None and os.path.exists(attrition_path)) else None,
        comparison_plot,
    )
    with open(os.path.join(outdir, 'summary.html'), 'w') as f:
        f.write(html)

    print(f"Report written to {outdir}/")


if __name__ == '__main__':
    main()
