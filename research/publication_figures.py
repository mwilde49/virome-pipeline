#!/usr/bin/env python3
"""
publication_figures.py

Generate 5 publication-quality figures from the all-cohort virome results.

Usage:
    python3 research/publication_figures.py results/all_cohort/results research/figures

Usable samples (15):
  Muscle (5):    Sample_19–23
  DRG donor1 (6): donor1_L1–L5, donor1_T12
  DRG Saad (4):  Saad_1, Saad_3, Saad_4, Saad_5

Excluded:
  AIG1390_* — confirmed duplicate of donor1
  Saad_2    — failed library (phiX174 spike-in detected, anomalous taxa)
"""

import sys
import numpy as np
import pandas as pd
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt
import matplotlib.patches as mpatches
import seaborn as sns
from pathlib import Path

# ── Sample sets ───────────────────────────────────────────────────────────────
MUSCLE   = ['Sample_19', 'Sample_20', 'Sample_21', 'Sample_22', 'Sample_23']
DRG_D1   = ['donor1_L1', 'donor1_L2', 'donor1_L3', 'donor1_L4', 'donor1_L5', 'donor1_T12']
DRG_SAAD = ['Saad_1', 'Saad_3', 'Saad_4', 'Saad_5']
USABLE   = MUSCLE + DRG_D1 + DRG_SAAD

# Spinal level order for donor1 (cervical→thoracic→lumbar)
DRG_D1_ORDER = ['donor1_T12', 'donor1_L1', 'donor1_L2', 'donor1_L3', 'donor1_L4', 'donor1_L5']

TISSUE_COLORS = {
    'Muscle':    '#4C9BE8',   # steel blue
    'DRG donor1': '#E8824C',  # coral
    'DRG Saad':  '#4CBF7A',   # sea green
}

def tissue_of(sample):
    if sample in MUSCLE:   return 'Muscle'
    if sample in DRG_D1:   return 'DRG donor1'
    if sample in DRG_SAAD: return 'DRG Saad'
    return 'Other'

# ── Data loaders ──────────────────────────────────────────────────────────────
def load_rpm(path):
    """Return taxa × samples RPM dataframe (usable samples only, taxa with any signal)."""
    df = pd.read_csv(path, sep='\t')
    df = df[df['rank'] == 'S']
    df = df.set_index('taxon_name')
    rpm_cols = [c for c in df.columns if c.endswith('_rpm')]
    rpm = df[rpm_cols].rename(columns=lambda c: c.replace('_rpm', ''))
    rpm = rpm[[c for c in USABLE if c in rpm.columns]]
    rpm = rpm[rpm.sum(axis=1) > 0]
    return rpm

def load_reads(path):
    """Return taxa × samples read count dataframe (usable samples only)."""
    df = pd.read_csv(path, sep='\t')
    df = df[df['rank'] == 'S']
    df = df.set_index('taxon_name')
    rc_cols = [c for c in df.columns if c.endswith('_reads')]
    rc = df[rc_cols].rename(columns=lambda c: c.replace('_reads', ''))
    rc = rc[[c for c in USABLE if c in rc.columns]]
    rc = rc[rc.sum(axis=1) > 0]
    return rc

def load_filter_summary(path):
    df = pd.read_csv(path, sep='\t')
    return df[df['sample_id'].isin(USABLE)]

# ── Figure 1: Library size overview ──────────────────────────────────────────
def fig1_library_sizes(fsum, outpath):
    """
    Total viral reads retained (bracken_raw stage) per sample,
    grouped and coloured by tissue type.
    """
    raw = fsum[fsum['stage'] == 'bracken_raw'][['sample_id', 'reads_retained']].copy()
    raw['tissue'] = raw['sample_id'].map(tissue_of)

    # Order: muscle → DRG donor1 (T12→L5) → DRG Saad
    order = MUSCLE + DRG_D1_ORDER + DRG_SAAD
    raw = raw.set_index('sample_id').reindex(order).reset_index()
    colors = [TISSUE_COLORS[tissue_of(s)] for s in raw['sample_id']]

    fig, ax = plt.subplots(figsize=(13, 4.5))
    bars = ax.bar(range(len(raw)), raw['reads_retained'] / 1000, color=colors, edgecolor='white', linewidth=0.5)
    ax.set_xticks(range(len(raw)))
    ax.set_xticklabels(raw['sample_id'], rotation=35, ha='right', fontsize=9)
    ax.set_ylabel('Viral reads classified (× 10³)', fontsize=11)
    ax.set_title('Figure 1  —  Viral Read Yield per Sample (Bracken, before filtering)', fontsize=12, pad=10)

    # Group separators
    for x in [len(MUSCLE) - 0.5, len(MUSCLE) + len(DRG_D1) - 0.5]:
        ax.axvline(x, color='grey', lw=0.8, ls='--', alpha=0.5)

    legend_patches = [mpatches.Patch(color=v, label=k) for k, v in TISSUE_COLORS.items()]
    ax.legend(handles=legend_patches, fontsize=9, framealpha=0.7)
    ax.spines[['top', 'right']].set_visible(False)
    plt.tight_layout()
    fig.savefig(outpath, dpi=200, bbox_inches='tight')
    plt.close(fig)
    print(f"  Fig 1 → {outpath}")

# ── Figure 2: Filtering funnel ────────────────────────────────────────────────
def fig2_filtering_funnel(fsum, outpath):
    """
    Taxa count per filtering stage per sample (grouped bars).
    """
    stage_order = ['bracken_raw', 'minreads', 'final']
    stage_labels = {'bracken_raw': 'Bracken raw', 'minreads': 'After min-reads (≥5)', 'final': 'After artifact exclusion'}
    stage_colors = {'bracken_raw': '#AACBE8', 'minreads': '#5A9ED4', 'final': '#1A5C9E'}

    order = MUSCLE + DRG_D1_ORDER + DRG_SAAD
    n = len(order)
    x = np.arange(n)
    width = 0.26

    fig, ax = plt.subplots(figsize=(14, 5))
    for i, stage in enumerate(stage_order):
        vals = []
        for s in order:
            row = fsum[(fsum['sample_id'] == s) & (fsum['stage'] == stage)]
            vals.append(int(row['taxa_kept'].iloc[0]) if len(row) else 0)
        ax.bar(x + (i - 1) * width, vals, width, label=stage_labels[stage],
               color=stage_colors[stage], edgecolor='white', linewidth=0.4)

    ax.set_xticks(x)
    ax.set_xticklabels(order, rotation=35, ha='right', fontsize=9)
    ax.set_ylabel('Taxa detected', fontsize=11)
    ax.set_title('Figure 2  —  Filtering Funnel: Taxa Retained at Each Stage', fontsize=12, pad=10)

    for xv in [len(MUSCLE) - 0.5, len(MUSCLE) + len(DRG_D1) - 0.5]:
        ax.axvline(xv, color='grey', lw=0.8, ls='--', alpha=0.5)

    ax.legend(fontsize=9, framealpha=0.7)
    ax.spines[['top', 'right']].set_visible(False)
    plt.tight_layout()
    fig.savefig(outpath, dpi=200, bbox_inches='tight')
    plt.close(fig)
    print(f"  Fig 2 → {outpath}")

# ── Figure 3: Final virome heatmap ───────────────────────────────────────────
def fig3_heatmap(final_rpm, outpath):
    """
    Heatmap of log10(RPM + 1) for all taxa detected in the final filtered matrix,
    15 usable samples ordered by tissue/level.
    """
    col_order = MUSCLE + DRG_D1_ORDER + DRG_SAAD
    col_order = [c for c in col_order if c in final_rpm.columns]
    data = final_rpm[col_order]
    # Drop taxa with zero total across usable samples
    data = data[data.sum(axis=1) > 0]
    # Sort by total RPM descending
    data = data.loc[data.sum(axis=1).sort_values(ascending=False).index]

    log_data = np.log10(data + 0.01)

    fig, ax = plt.subplots(figsize=(max(10, len(col_order) * 0.75), max(4, len(data) * 0.5)))
    sns.heatmap(log_data, ax=ax, cmap='YlOrRd', linewidths=0.4, linecolor='#e0e0e0',
                cbar_kws={'label': 'log₁₀(RPM + 0.01)', 'shrink': 0.6})

    # Tissue group separators (vertical)
    for xv in [len(MUSCLE), len(MUSCLE) + len(DRG_D1_ORDER)]:
        if xv < len(col_order):
            ax.axvline(xv, color='black', lw=1.2)

    ax.set_title('Figure 3  —  Virome Profile: Final Filtered Abundance (15 Samples)', fontsize=12, pad=10)
    ax.set_xlabel('')
    ax.set_ylabel('')
    ax.set_xticklabels(ax.get_xticklabels(), rotation=35, ha='right', fontsize=9)
    ax.set_yticklabels(ax.get_yticklabels(), fontsize=9)

    # Tissue labels above columns
    tissue_labels = (
        [(len(MUSCLE) / 2,        'Muscle')] +
        [(len(MUSCLE) + len(DRG_D1_ORDER) / 2, 'DRG donor1')] +
        [(len(MUSCLE) + len(DRG_D1_ORDER) + len(DRG_SAAD) / 2, 'DRG Saad')]
    )
    ax2 = ax.twiny()
    ax2.set_xlim(ax.get_xlim())
    ax2.set_xticks([p for p, _ in tissue_labels])
    ax2.set_xticklabels([l for _, l in tissue_labels], fontsize=10, fontweight='bold')
    ax2.tick_params(length=0)

    plt.tight_layout()
    fig.savefig(outpath, dpi=200, bbox_inches='tight')
    plt.close(fig)
    print(f"  Fig 3 → {outpath}")

# ── Figure 4: HERV-K tissue comparison ───────────────────────────────────────
def fig4_herv(raw_reads, outpath):
    """
    HERV-K read counts per sample, coloured by tissue type,
    with mean ± SD overlaid per group.
    """
    herv_key = 'Human endogenous retrovirus K'
    if herv_key not in raw_reads.index:
        print(f"  WARN: '{herv_key}' not found in bracken_raw matrix — skipping Fig 4")
        return

    col_order = MUSCLE + DRG_D1_ORDER + DRG_SAAD
    col_order = [c for c in col_order if c in raw_reads.columns]
    herv = raw_reads.loc[herv_key, col_order]

    fig, ax = plt.subplots(figsize=(13, 4.5))
    bar_colors = [TISSUE_COLORS[tissue_of(s)] for s in col_order]
    ax.bar(range(len(col_order)), herv.values, color=bar_colors, edgecolor='white', linewidth=0.5)

    # Group mean lines
    groups = [('Muscle', MUSCLE), ('DRG donor1', DRG_D1_ORDER), ('DRG Saad', DRG_SAAD)]
    offset = 0
    for name, members in groups:
        idxs = [i for i, s in enumerate(col_order) if s in members]
        if idxs:
            mean_val = herv.iloc[idxs].mean()
            ax.hlines(mean_val, min(idxs) - 0.4, max(idxs) + 0.4,
                      colors=TISSUE_COLORS[name], linewidths=2, linestyles='--', alpha=0.8)
        offset += len(members)

    ax.set_xticks(range(len(col_order)))
    ax.set_xticklabels(col_order, rotation=35, ha='right', fontsize=9)
    ax.set_ylabel('HERV-K reads (Bracken raw)', fontsize=11)
    ax.set_title('Figure 4  —  HERV-K Endogenous Retrovirus Signal by Tissue Type and Spinal Level', fontsize=12, pad=10)

    for xv in [len(MUSCLE) - 0.5, len(MUSCLE) + len(DRG_D1_ORDER) - 0.5]:
        ax.axvline(xv, color='grey', lw=0.8, ls='--', alpha=0.5)

    legend_patches = [mpatches.Patch(color=v, label=k) for k, v in TISSUE_COLORS.items()]
    ax.legend(handles=legend_patches, fontsize=9, framealpha=0.7)
    ax.spines[['top', 'right']].set_visible(False)
    plt.tight_layout()
    fig.savefig(outpath, dpi=200, bbox_inches='tight')
    plt.close(fig)
    print(f"  Fig 4 → {outpath}")

# ── Figure 5: Hantavirus batch signal ────────────────────────────────────────
def fig5_hantavirus(raw_rpm, outpath):
    """
    Orthohantavirus oxbowense RPM per sample. Shows the batch-level
    signal in the Saad cohort vs. the single-sample spike in donor1_L2.
    """
    hanta_key = 'Orthohantavirus oxbowense'
    if hanta_key not in raw_rpm.index:
        print(f"  WARN: '{hanta_key}' not found — skipping Fig 5")
        return

    col_order = MUSCLE + DRG_D1_ORDER + DRG_SAAD
    col_order = [c for c in col_order if c in raw_rpm.columns]
    hanta = raw_rpm.loc[hanta_key, col_order]

    bar_colors = [TISSUE_COLORS[tissue_of(s)] for s in col_order]

    fig, ax = plt.subplots(figsize=(13, 4.5))
    ax.bar(range(len(col_order)), hanta.values, color=bar_colors, edgecolor='white', linewidth=0.5)
    ax.set_xticks(range(len(col_order)))
    ax.set_xticklabels(col_order, rotation=35, ha='right', fontsize=9)
    ax.set_ylabel('RPM (Bracken raw)', fontsize=11)
    ax.set_title('Figure 5  —  Orthohantavirus oxbowense RPM: Cohort Comparison\n'
                 '(Persistent signal in Saad cohort suggests batch contamination; '
                 'donor1_L2 spike may reflect index hopping)', fontsize=11, pad=10)

    for xv in [len(MUSCLE) - 0.5, len(MUSCLE) + len(DRG_D1_ORDER) - 0.5]:
        ax.axvline(xv, color='grey', lw=0.8, ls='--', alpha=0.5)

    legend_patches = [mpatches.Patch(color=v, label=k) for k, v in TISSUE_COLORS.items()]
    ax.legend(handles=legend_patches, fontsize=9, framealpha=0.7)
    ax.spines[['top', 'right']].set_visible(False)
    plt.tight_layout()
    fig.savefig(outpath, dpi=200, bbox_inches='tight')
    plt.close(fig)
    print(f"  Fig 5 → {outpath}")

# ── Main ──────────────────────────────────────────────────────────────────────
def main():
    if len(sys.argv) < 3:
        print(__doc__)
        sys.exit(1)

    results_dir = Path(sys.argv[1])
    outdir      = Path(sys.argv[2])
    outdir.mkdir(parents=True, exist_ok=True)

    print("Loading data...")
    fsum      = load_filter_summary(results_dir / 'virome_report' / 'filter_summary.tsv')
    final_rpm = load_rpm(results_dir / 'viral_abundance_matrix.tsv')
    raw_rpm   = load_rpm(results_dir / 'bracken_raw_matrix.tsv')
    raw_reads = load_reads(results_dir / 'bracken_raw_matrix.tsv')

    print(f"  {len(USABLE)} usable samples  |  "
          f"{final_rpm.shape[0]} final taxa  |  "
          f"{raw_rpm.shape[0]} bracken_raw taxa\n")

    fig1_library_sizes(fsum,      outdir / 'fig1_library_sizes.png')
    fig2_filtering_funnel(fsum,   outdir / 'fig2_filtering_funnel.png')
    fig3_heatmap(final_rpm,       outdir / 'fig3_virome_heatmap.png')
    fig4_herv(raw_reads,          outdir / 'fig4_herv_k.png')
    fig5_hantavirus(raw_rpm,      outdir / 'fig5_hantavirus.png')

    print(f"\nAll figures saved to {outdir}/")


if __name__ == '__main__':
    main()
