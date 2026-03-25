#!/usr/bin/env python3
"""
pluspf_comparison.py

Compare viral-only vs PlusPF Kraken2 database results for the 3-sample
subset (Sample_20, donor1_L4, Saad_1). Generates a side-by-side table and
figure for the paper showing false positive reduction with competitive
classification.

Usage:
    python3 research/paper1/pluspf_comparison.py \\
        results/all_cohort/results \\
        results/pluspf_comparison/results \\
        research/paper1/figures

Outputs:
    pluspf_comparison_table.tsv   — per-taxon RPM in viral-only vs PlusPF
    pluspf_taxa_counts.tsv        — taxa count per stage per sample, both DBs
    fig_pluspf_comparison.png     — bar chart figure for paper
"""

import sys
import numpy as np
import pandas as pd
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt
import matplotlib.patches as mpatches
from pathlib import Path

SAMPLES = ['Sample_20', 'donor1_L4', 'Saad_1']
SAMPLE_LABELS = {
    'Sample_20': 'Sample_20\n(muscle)',
    'donor1_L4': 'donor1_L4\n(DRG, L4)',
    'Saad_1':    'Saad_1\n(DRG, Saad)',
}
STAGES = ['bracken_raw', 'minreads', 'final']
STAGE_LABELS = {'bracken_raw': 'Bracken raw', 'minreads': 'After min-reads', 'final': 'After artifact excl.'}


def load_filter_summary(results_dir, samples):
    path = Path(results_dir) / 'virome_report' / 'filter_summary.tsv'
    df = pd.read_csv(path, sep='\t')
    return df[df['sample_id'].isin(samples)]


def load_bracken_raw_rpm(results_dir, samples):
    path = Path(results_dir) / 'bracken_raw_matrix.tsv'
    df = pd.read_csv(path, sep='\t')
    df = df[df['rank'] == 'S']
    rpm_cols = [f"{s}_rpm" for s in samples if f"{s}_rpm" in df.columns]
    df = df[['taxon_id', 'taxon_name'] + rpm_cols]
    df = df.rename(columns={f"{s}_rpm": s for s in samples})
    return df[df[samples].sum(axis=1) > 0].set_index('taxon_name')


def main():
    if len(sys.argv) < 4:
        print(__doc__)
        sys.exit(1)

    viral_dir  = sys.argv[1]
    pluspf_dir = sys.argv[2]
    outdir     = Path(sys.argv[3])
    outdir.mkdir(parents=True, exist_ok=True)

    # ── Load filter summaries ─────────────────────────────────────────────────
    viral_fsum  = load_filter_summary(viral_dir,  SAMPLES)
    pluspf_fsum = load_filter_summary(pluspf_dir, SAMPLES)

    # ── Taxa count comparison table ───────────────────────────────────────────
    rows = []
    for sample in SAMPLES:
        for stage in STAGES:
            v = viral_fsum[(viral_fsum['sample_id'] == sample) & (viral_fsum['stage'] == stage)]
            p = pluspf_fsum[(pluspf_fsum['sample_id'] == sample) & (pluspf_fsum['stage'] == stage)]
            rows.append({
                'sample':        sample,
                'stage':         stage,
                'viral_only_taxa':  int(v['taxa_kept'].iloc[0]) if len(v) else 0,
                'pluspf_taxa':      int(p['taxa_kept'].iloc[0]) if len(p) else 0,
            })
    counts_df = pd.DataFrame(rows)
    counts_df['taxa_removed'] = counts_df['viral_only_taxa'] - counts_df['pluspf_taxa']
    counts_df['pct_reduction'] = (counts_df['taxa_removed'] / counts_df['viral_only_taxa'] * 100).round(1)
    counts_df.to_csv(outdir / 'pluspf_taxa_counts.tsv', sep='\t', index=False)
    print(f"Taxa count table → {outdir}/pluspf_taxa_counts.tsv")
    print(counts_df.to_string(index=False))

    # ── RPM comparison for bracken_raw (full false positive picture) ──────────
    viral_rpm  = load_bracken_raw_rpm(viral_dir,  SAMPLES)
    pluspf_rpm = load_bracken_raw_rpm(pluspf_dir, SAMPLES)

    all_taxa = viral_rpm.index.union(pluspf_rpm.index)
    compare = pd.DataFrame(index=all_taxa)
    for s in SAMPLES:
        compare[f"{s}_viral"]  = viral_rpm[s]  if s in viral_rpm.columns  else np.nan
        compare[f"{s}_pluspf"] = pluspf_rpm[s] if s in pluspf_rpm.columns else np.nan
    compare = compare.fillna(0)
    compare.to_csv(outdir / 'pluspf_comparison_table.tsv', sep='\t')
    print(f"RPM comparison table → {outdir}/pluspf_comparison_table.tsv")

    # ── Figure: taxa count per stage, grouped bars ────────────────────────────
    raw_stage = counts_df[counts_df['stage'] == 'bracken_raw']

    x = np.arange(len(SAMPLES))
    width = 0.35
    fig, ax = plt.subplots(figsize=(9, 5))

    bars_v = ax.bar(x - width/2, raw_stage.set_index('sample').loc[SAMPLES, 'viral_only_taxa'],
                    width, label='Viral-only DB', color='#E8824C', edgecolor='white')
    bars_p = ax.bar(x + width/2, raw_stage.set_index('sample').loc[SAMPLES, 'pluspf_taxa'],
                    width, label='PlusPF standard DB', color='#4C9BE8', edgecolor='white')

    ax.set_xticks(x)
    ax.set_xticklabels([SAMPLE_LABELS[s] for s in SAMPLES], fontsize=10)
    ax.set_ylabel('Taxa detected (Bracken raw, before filtering)', fontsize=10)
    ax.set_title('Viral taxa detected: viral-only vs. PlusPF competitive classification', fontsize=11, pad=10)
    ax.legend(fontsize=9)
    ax.spines[['top', 'right']].set_visible(False)

    # Annotate % reduction
    for i, s in enumerate(SAMPLES):
        row = raw_stage[raw_stage['sample'] == s].iloc[0]
        if row['viral_only_taxa'] > 0:
            ax.text(i, max(row['viral_only_taxa'], row['pluspf_taxa']) + 0.5,
                    f"−{row['pct_reduction']}%",
                    ha='center', fontsize=8.5, color='#444444')

    plt.tight_layout()
    outpath = outdir / 'fig_pluspf_comparison.png'
    fig.savefig(outpath, dpi=200, bbox_inches='tight')
    plt.close(fig)
    print(f"Figure → {outpath}")


if __name__ == '__main__':
    main()
