#!/usr/bin/env python3
"""
generate_figures.py — Paper 1 figure generation (v1.3.0 fullcohort data)

Generates all four manuscript figures from fullcohort_pluspf results:
  Fig 1  — virome-pipeline architecture diagram (v1.3.0, dual-DB branch)
  Fig 2  — Multi-stage filtering funnel (15 samples)
  Fig 3  — Dual-database tier summary: Panel A (tier bar) + Panel B (Tier 2 heatmap)
  Fig 4  — HERV-K endogenous signal by tissue type and spinal level (+ p-value)

Usage:
    python3 research/paper1/generate_figures.py \
        results/fullcohort_pluspf \
        research/paper1/figures
"""

import sys
import numpy as np
import pandas as pd
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt
import matplotlib.patches as mpatches
import matplotlib.patheffects as pe
from matplotlib.patches import FancyBboxPatch, FancyArrowPatch
from pathlib import Path
from scipy import stats

# ---------------------------------------------------------------------------
# Cohort definition — 15 unique samples (AIG1390 excluded; Saad_2 excluded)
# ---------------------------------------------------------------------------

MUSCLE    = ['Sample_19', 'Sample_20', 'Sample_21', 'Sample_22', 'Sample_23']
DRG_D1    = ['donor1_L1', 'donor1_L2', 'donor1_L3', 'donor1_L4', 'donor1_L5', 'donor1_T12']
DRG_SAAD  = ['Saad_1', 'Saad_3', 'Saad_4', 'Saad_5']
SAMPLES   = MUSCLE + DRG_D1 + DRG_SAAD  # 15 samples

SAMPLE_DISPLAY = {
    'Sample_19': 'S19', 'Sample_20': 'S20', 'Sample_21': 'S21',
    'Sample_22': 'S22', 'Sample_23': 'S23',
    'donor1_L1': 'L1', 'donor1_L2': 'L2', 'donor1_L3': 'L3',
    'donor1_L4': 'L4', 'donor1_L5': 'L5', 'donor1_T12': 'T12',
    'Saad_1': 'Saad_1', 'Saad_3': 'Saad_3', 'Saad_4': 'Saad_4', 'Saad_5': 'Saad_5',
}

GROUP_COLORS = {
    'Muscle':      '#4878CF',   # steel blue
    'DRG donor1':  '#E8824C',   # coral orange
    'DRG Saad':    '#5BAD72',   # sage green
}

TIER_COLORS = {
    'shared':     '#4BAF6B',   # green
    'viral_only': '#E8824C',   # coral
    'pluspf_only': '#9DA8B7',  # muted slate
}

TIER_LABELS = {
    'shared':     'Tier 1 — Shared (both DBs)',
    'viral_only': 'Tier 2 — Viral-only (FP candidates)',
    'pluspf_only': 'Tier 3 — PlusPF-only (non-viral)',
}

TAXON_DISPLAY = {
    45617:  'Human endogenous\nretrovirus K',
    3050337: 'Human CMV\n(HHV-5) [proxy]',
    10279:  'Molluscum\ncontagiosum virus',
}

# ---------------------------------------------------------------------------
# Style defaults
# ---------------------------------------------------------------------------

plt.rcParams.update({
    'font.family':   'DejaVu Sans',
    'font.size':     9,
    'axes.spines.top':   False,
    'axes.spines.right': False,
    'axes.linewidth': 0.8,
    'xtick.major.size': 3,
    'ytick.major.size': 3,
})


# ---------------------------------------------------------------------------
# Data loaders
# ---------------------------------------------------------------------------

def load_filter_summary(results_dir):
    df = pd.read_csv(Path(results_dir) / 'virome_report' / 'filter_summary.tsv', sep='\t')
    return df[df['sample_id'].isin(SAMPLES)]


def load_db_summary(results_dir):
    df = pd.read_csv(
        Path(results_dir) / 'db_comparison' / 'db_comparison_summary.tsv', sep='\t'
    )
    return df[df['sample'].isin(SAMPLES)]


def load_fp_candidates(results_dir):
    df = pd.read_csv(
        Path(results_dir) / 'db_comparison' / 'false_positive_candidates.tsv', sep='\t'
    )
    # Keep only columns for our 15 samples
    read_cols = [f'{s}_reads' for s in SAMPLES if f'{s}_reads' in df.columns]
    return df[['taxon_id', 'taxon_name', 'viral_only_total'] + read_cols]


def load_herv_k(results_dir):
    """Return HERV-K raw read counts per sample from the abundance matrix."""
    df = pd.read_csv(Path(results_dir) / 'bracken_raw_matrix.tsv', sep='\t')
    row = df[df['taxon_id'] == 45617]
    if row.empty:
        raise ValueError('HERV-K taxon 45617 not found in bracken_raw_matrix.tsv')
    result = {}
    for s in SAMPLES:
        col = f'{s}_reads'
        result[s] = float(row[col].iloc[0]) if col in row.columns else 0.0
    return result


# ---------------------------------------------------------------------------
# Figure 1 — Pipeline diagram
# ---------------------------------------------------------------------------

def draw_box(ax, x, y, w, h, label, sublabel=None,
             facecolor='#E8F4FD', edgecolor='#2C7BB6',
             fontsize=8.5, dashed=False, bold=False):
    lw = 1.2 if not dashed else 0.9
    ls = '--' if dashed else '-'
    box = FancyBboxPatch((x - w/2, y - h/2), w, h,
                         boxstyle='round,pad=0.02',
                         facecolor=facecolor, edgecolor=edgecolor,
                         linewidth=lw, linestyle=ls, zorder=3)
    ax.add_patch(box)
    weight = 'bold' if bold else 'normal'
    if sublabel:
        ax.text(x, y + 0.06, label, ha='center', va='center',
                fontsize=fontsize, fontweight=weight, zorder=4)
        ax.text(x, y - 0.07, sublabel, ha='center', va='center',
                fontsize=6.5, color='#555555', zorder=4, style='italic')
    else:
        ax.text(x, y, label, ha='center', va='center',
                fontsize=fontsize, fontweight=weight, zorder=4)


def draw_arrow(ax, x1, y1, x2, y2, dashed=False, color='#444444'):
    ls = 'dashed' if dashed else 'solid'
    ax.annotate('', xy=(x2, y2), xytext=(x1, y1),
                arrowprops=dict(arrowstyle='->', color=color,
                                lw=1.0, linestyle=ls),
                zorder=2)


def make_fig1(outpath):
    fig, ax = plt.subplots(figsize=(12, 9))
    ax.set_xlim(0, 12)
    ax.set_ylim(0, 12)
    ax.axis('off')
    ax.set_facecolor('white')
    fig.patch.set_facecolor('white')

    C = {
        'input':    ('#EBF5FB', '#2980B9'),
        'qc':       ('#EAF4EE', '#27AE60'),
        'align':    ('#FEF9E7', '#D4AC0D'),
        'classify': ('#F4ECF7', '#8E44AD'),
        'filter':   ('#FDEDEC', '#E74C3C'),
        'agg':      ('#EBF5FB', '#2980B9'),
        'report':   ('#F2F3F4', '#717D7E'),
        'optional': ('#FDF2E9', '#CA6F1E'),
    }

    bw, bh = 2.1, 0.42
    sbh    = 0.36
    x_main = 3.8
    x_opt  = 9.2

    # ── Main pipeline column ──────────────────────────────────────────────
    # y positions with generous spacing
    y_raw   = 11.3
    y_fqc   = 10.5
    y_trim  = 9.65
    y_star  = 8.65
    y_k2    = 7.55
    y_brk   = 6.55
    y_flt   = 5.55
    # three per-sample output files sit here:
    y_outs  = 4.45
    # then aggregate:
    y_agg   = 3.2
    y_rep   = 1.9

    main_steps = [
        (x_main, y_raw,  'Raw FASTQs',          'paired-end, 2×150 bp',              'input'),
        (x_main, y_fqc,  'FASTQC',               'read quality metrics',               'qc'),
        (x_main, y_trim, 'TRIMMOMATIC',           'adapter & quality trim',             'align'),
        (x_main, y_star, 'STAR',                  'host read depletion (GRCh38)',       'align'),
        (x_main, y_k2,   'KRAKEN2\n(viral-only DB)', 'k-mer classification — DB1',   'classify'),
        (x_main, y_brk,  'BRACKEN',               'species re-estimation — DB1',       'classify'),
        (x_main, y_flt,  'KRAKEN2_FILTER',        'min-reads + artifact exclusion',    'filter'),
    ]
    for (x, y, lbl, sub, cat) in main_steps:
        fc, ec = C[cat]
        draw_box(ax, x, y, bw, bh, lbl, sub, facecolor=fc, edgecolor=ec, bold=(cat == 'input'))

    # Vertical arrows — main column
    vert_arrows = [
        (y_raw - bh/2,   y_fqc  + bh/2),
        (y_fqc  - bh/2,  y_trim + bh/2),
        (y_trim - bh/2,  y_star + bh/2),
        (y_star - bh/2,  y_k2   + bh/2),
        (y_k2   - bh/2,  y_brk  + bh/2),
        (y_brk  - bh/2,  y_flt  + bh/2),
    ]
    for y1, y2 in vert_arrows:
        draw_arrow(ax, x_main, y1, x_main, y2)

    # Side annotations
    ax.text(1.1, y_fqc,  'FastQC\nreport',      ha='center', va='center', fontsize=7, color='#666', style='italic')
    draw_arrow(ax, x_main - bw/2, y_fqc, 1.55, y_fqc, color='#bbb')
    ax.text(1.1, y_star, 'Host reads\n(discarded)', ha='center', va='center', fontsize=7, color='#666', style='italic')
    draw_arrow(ax, x_main - bw/2, y_star, 1.55, y_star, color='#bbb')

    # KRAKEN2_FILTER → three per-sample output file boxes
    out_xs     = [1.3, 3.8, 6.3]
    out_labels = [
        '{id}.filtered.tsv\n(final — artifact excl.)',
        '{id}.minreads.tsv\n(after min-reads ≥5)',
        '{id}.bracken_raw.tsv\n(all viral species)',
    ]
    out_bw, out_bh = 2.0, 0.46
    for ox, ol in zip(out_xs, out_labels):
        draw_box(ax, ox, y_outs, out_bw, out_bh, ol,
                 fontsize=6.5, facecolor=C['report'][0], edgecolor=C['report'][1])

    # Horizontal spread from FILTER bottom → three boxes
    y_spread = y_flt - bh/2 - 0.08
    ax.plot([out_xs[0], out_xs[-1]], [y_spread, y_spread], color='#555', lw=0.9, zorder=2)
    for ox in out_xs:
        ax.annotate('', xy=(ox, y_outs + out_bh/2),
                    xytext=(ox, y_spread),
                    arrowprops=dict(arrowstyle='->', color='#555', lw=0.9), zorder=2)
    ax.plot([x_main, x_main], [y_flt - bh/2, y_spread], color='#555', lw=0.9, zorder=2)

    # AGGREGATE (main) — below the three output boxes
    draw_box(ax, x_main, y_agg, bw, bh, 'AGGREGATE',
             'final / minreads / bracken_raw matrices', facecolor=C['agg'][0], edgecolor=C['agg'][1])

    # Three output boxes → AGGREGATE (converging arrows)
    y_conv = y_outs - out_bh/2 - 0.08
    ax.plot([out_xs[0], out_xs[-1]], [y_conv, y_conv], color='#555', lw=0.9, zorder=2)
    for ox in out_xs:
        ax.plot([ox, ox], [y_outs - out_bh/2, y_conv], color='#555', lw=0.9, zorder=2)
    draw_arrow(ax, x_main, y_conv, x_main, y_agg + bh/2)

    # REPORT and MULTIQC
    draw_box(ax, 2.5, y_rep, 1.8, sbh, 'REPORT', 'summary.html',
             facecolor=C['report'][0], edgecolor=C['report'][1])
    draw_box(ax, 5.1, y_rep, 1.8, sbh, 'MULTIQC', 'multiqc_report.html',
             facecolor=C['report'][0], edgecolor=C['report'][1])
    draw_arrow(ax, 2.5, y_agg - bh/2, 2.5, y_rep + sbh/2)
    draw_arrow(ax, 5.1, y_agg - bh/2, 5.1, y_rep + sbh/2)

    # ── Optional DB2 column ───────────────────────────────────────────────
    opt_steps = [
        (x_opt, y_k2,  'KRAKEN2\n(PlusPF DB)',  'k-mer classification — DB2', 'optional'),
        (x_opt, y_brk, 'BRACKEN',                'species re-estimation — DB2', 'optional'),
        (x_opt, y_flt, 'KRAKEN2_FILTER',         'min-reads + artifact excl. — DB2', 'optional'),
        (x_opt, y_agg, 'AGGREGATE_DB2',           'PlusPF abundance matrix', 'optional'),
    ]
    for (x, y, lbl, sub, cat) in opt_steps:
        fc, ec = C[cat]
        draw_box(ax, x, y, bw, bh, lbl, sub, facecolor=fc, edgecolor=ec, dashed=True)

    # Arrow from STAR → DB2 branch
    draw_arrow(ax, x_main + bw/2, y_star, x_opt - bw/2, y_k2 + bh/2,
               dashed=True, color='#CA6F1E')
    ax.text(6.7, 8.25, 'optional\n(params.kraken2_db2)', ha='center', va='center',
            fontsize=6.5, color='#CA6F1E', style='italic')

    # DB2 vertical arrows
    for y1, y2 in [(y_k2 - bh/2, y_brk + bh/2),
                   (y_brk - bh/2, y_flt + bh/2),
                   (y_flt - bh/2, y_agg + bh/2)]:
        draw_arrow(ax, x_opt, y1, x_opt, y2, dashed=True, color='#CA6F1E')

    # COMPARE_DATABASES — between the two AGGREGATE boxes at y_rep level
    x_cmp = 7.6
    draw_box(ax, x_cmp, y_rep, 2.1, sbh, 'COMPARE_DATABASES', 'Tier 1/2/3 per taxon',
             facecolor=C['optional'][0], edgecolor=C['optional'][1], dashed=True)

    # AGGREGATE_DB2 → COMPARE_DATABASES
    draw_arrow(ax, x_opt, y_agg - bh/2, x_cmp, y_rep + sbh/2, dashed=True, color='#CA6F1E')
    # AGGREGATE (main) → COMPARE_DATABASES
    draw_arrow(ax, x_main + bw/2, y_agg, x_cmp - 1.05, y_rep + sbh/2,
               dashed=True, color='#CA6F1E')
    # COMPARE → REPORT (comparison results feed into HTML report)
    draw_arrow(ax, x_cmp - 1.05, y_rep, 2.5 + 0.9, y_rep, dashed=True, color='#CA6F1E')

    # Output files below COMPARE_DATABASES
    cmp_outs = [
        ('consensus_matrix.tsv\n(Tier 1 — shared)', 6.9),
        ('false_positive_candidates.tsv\n(Tier 2 — viral-only)', 8.8),
    ]
    for ol, ox in cmp_outs:
        draw_box(ax, ox, 0.85, 2.1, 0.44, ol, fontsize=6,
                 facecolor=C['report'][0], edgecolor=C['report'][1], dashed=True)
        draw_arrow(ax, ox, y_rep - sbh/2, ox, 0.85 + 0.22, dashed=True, color='#CA6F1E')

    # Legend
    legend_items = [
        mpatches.Patch(facecolor=C['qc'][0],       edgecolor=C['qc'][1],       label='QC'),
        mpatches.Patch(facecolor=C['align'][0],    edgecolor=C['align'][1],    label='Alignment / host depletion'),
        mpatches.Patch(facecolor=C['classify'][0], edgecolor=C['classify'][1], label='Taxonomic classification'),
        mpatches.Patch(facecolor=C['filter'][0],   edgecolor=C['filter'][1],   label='Filtering'),
        mpatches.Patch(facecolor=C['agg'][0],      edgecolor=C['agg'][1],      label='Aggregation / output'),
        mpatches.Patch(facecolor=C['report'][0],   edgecolor=C['report'][1],   label='Reports / output files'),
        mpatches.Patch(facecolor=C['optional'][0], edgecolor=C['optional'][1],
                       label='Optional dual-DB branch', linestyle='--', linewidth=0.9),
    ]
    ax.legend(handles=legend_items, loc='lower left', fontsize=7.5,
              frameon=True, framealpha=0.95, edgecolor='#cccccc',
              bbox_to_anchor=(0.0, 0.0))

    ax.set_title('Figure 1 — virome-pipeline Data Flow (v1.3.0)',
                 fontsize=12, fontweight='bold', pad=8)

    fig.savefig(outpath, dpi=200, bbox_inches='tight', facecolor='white')
    plt.close(fig)
    print(f'Fig 1 → {outpath}')


# ---------------------------------------------------------------------------
# Figure 2 — Filtering funnel
# ---------------------------------------------------------------------------

def make_fig2(results_dir, outpath):
    fsum = load_filter_summary(results_dir)

    # Build ordered DataFrame
    rows = []
    for s in SAMPLES:
        for stage in ['bracken_raw', 'minreads', 'final']:
            r = fsum[(fsum['sample_id'] == s) & (fsum['stage'] == stage)]
            rows.append({
                'sample': s,
                'stage':  stage,
                'taxa':   int(r['taxa_kept'].iloc[0]) if len(r) else 0,
            })
    df = pd.DataFrame(rows)

    stage_colors = {
        'bracken_raw': '#AED6F1',
        'minreads':    '#2980B9',
        'final':       '#1A5276',
    }
    stage_labels = {
        'bracken_raw': 'Bracken raw',
        'minreads':    'After min-reads (≥5)',
        'final':       'After artifact exclusion',
    }

    group_breaks = [len(MUSCLE), len(MUSCLE) + len(DRG_D1)]

    fig, ax = plt.subplots(figsize=(13, 4.5))

    x = np.arange(len(SAMPLES))
    width = 0.26
    offsets = [-width, 0, width]

    for i, stage in enumerate(['bracken_raw', 'minreads', 'final']):
        vals = [df[(df['sample'] == s) & (df['stage'] == stage)]['taxa'].iloc[0]
                for s in SAMPLES]
        ax.bar(x + offsets[i], vals, width,
               color=stage_colors[stage], label=stage_labels[stage],
               edgecolor='white', linewidth=0.4)

    # Group separator lines
    for gb in group_breaks:
        ax.axvline(gb - 0.5, color='#bbbbbb', lw=0.8, ls='--')

    # Group labels
    group_centers = [
        len(MUSCLE) / 2 - 0.5,
        len(MUSCLE) + len(DRG_D1) / 2 - 0.5,
        len(MUSCLE) + len(DRG_D1) + len(DRG_SAAD) / 2 - 0.5,
    ]
    group_names = ['Skeletal Muscle', 'DRG — donor1', 'DRG — Saad']
    # Compute y position from data, not from (unset) ylim
    all_bracken_raw = [
        df[(df['sample'] == s) & (df['stage'] == 'bracken_raw')]['taxa'].iloc[0]
        for s in SAMPLES
    ]
    y_label = max(all_bracken_raw) * 1.06
    for cx, gn in zip(group_centers, group_names):
        ax.text(cx, y_label, gn, ha='center', va='bottom', fontsize=8.5,
                fontweight='bold', color='#333333')

    y_max    = max(all_bracken_raw)
    y_labels = y_max * 1.06
    y_lim    = y_max * 1.20

    ax.set_xticks(x)
    ax.set_xticklabels([SAMPLE_DISPLAY[s] for s in SAMPLES], fontsize=8)
    ax.set_ylabel('Taxa detected', fontsize=10)
    ax.set_ylim(0, y_lim)

    # Group labels — placed at a fixed y well above the tallest bar
    for cx, gn in zip(group_centers, group_names):
        ax.text(cx, y_labels, gn, ha='center', va='bottom',
                fontsize=8.5, fontweight='bold', color='#333333')

    ax.set_title('Figure 2 — Filtering Funnel: Taxa Retained at Each Stage', fontsize=11, pad=8)

    # Legend below x-axis tick labels (outside the axes area)
    handles, labels = ax.get_legend_handles_labels()
    ax.legend(handles, labels, fontsize=8.5, frameon=True, framealpha=0.92,
              edgecolor='#ddd', ncol=3,
              loc='upper center', bbox_to_anchor=(0.5, -0.14))

    # Saad_1 flag annotation
    saad1_idx = SAMPLES.index('Saad_1')
    ax.annotate('QC outlier', xy=(saad1_idx, 3), xytext=(saad1_idx - 1.8, 22),
                fontsize=6.5, color='#888', style='italic',
                arrowprops=dict(arrowstyle='->', color='#aaa', lw=0.7))

    fig.tight_layout()
    fig.subplots_adjust(bottom=0.20)
    fig.savefig(outpath, dpi=200, bbox_inches='tight')
    plt.close(fig)
    print(f'Fig 2 → {outpath}')


# ---------------------------------------------------------------------------
# Figure 3 — Dual-database tier summary (Panel A + Panel B)
# ---------------------------------------------------------------------------

def make_fig3(results_dir, outpath):
    db_sum = load_db_summary(results_dir)
    fp     = load_fp_candidates(results_dir)

    # ── Panel A: stacked tier bar chart ──────────────────────────────────
    tiers = ['shared', 'viral_only', 'pluspf_only']
    pivot = db_sum.pivot(index='sample', columns='tier', values='taxa_count').fillna(0)
    pivot = pivot.reindex(SAMPLES)

    # ── Panel B: Tier 2 heatmap ───────────────────────────────────────────
    taxon_ids = [45617, 3050337, 10279]
    heatmap_rows = []
    for tid in taxon_ids:
        row = fp[fp['taxon_id'] == tid]
        counts = []
        for s in SAMPLES:
            col = f'{s}_reads'
            counts.append(float(row[col].iloc[0]) if not row.empty and col in row.columns else 0.0)
        heatmap_rows.append(counts)
    heat_arr = np.array(heatmap_rows)   # shape: (3, 15)
    heat_log  = np.log10(heat_arr + 1)

    group_breaks  = [len(MUSCLE), len(MUSCLE) + len(DRG_D1)]
    group_centers = [len(MUSCLE)/2 - 0.5,
                     len(MUSCLE) + len(DRG_D1)/2 - 0.5,
                     len(MUSCLE) + len(DRG_D1) + len(DRG_SAAD)/2 - 0.5]
    group_names   = ['Muscle', 'DRG donor1', 'DRG Saad']

    fig = plt.figure(figsize=(15, 6))
    # Panel A uses a broken y-axis (top = Tier 3 scale, bottom = Tier 2 scale)
    from matplotlib.gridspec import GridSpec
    gs = GridSpec(1, 2, figure=fig, width_ratios=[1, 1.5], wspace=0.32)

    # Split axes for Panel A
    ax_top = fig.add_subplot(gs[0])   # full panel A (we'll use symlog scale)
    ax2    = fig.add_subplot(gs[1])   # Panel B heatmap

    # — Panel A: grouped bars (Tier 2 and Tier 3 side-by-side to show both scales) —
    ax = ax_top
    x  = np.arange(len(SAMPLES))
    w  = 0.38

    t2_vals = pivot['viral_only'].values  if 'viral_only'  in pivot.columns else np.zeros(len(SAMPLES))
    t3_vals = pivot['pluspf_only'].values if 'pluspf_only' in pivot.columns else np.zeros(len(SAMPLES))

    ax.bar(x - w/2, t2_vals, w, color=TIER_COLORS['viral_only'],
           label=TIER_LABELS['viral_only'], edgecolor='white', linewidth=0.3)
    ax.bar(x + w/2, t3_vals, w, color=TIER_COLORS['pluspf_only'],
           label=TIER_LABELS['pluspf_only'], edgecolor='white', linewidth=0.3)

    # Tier 1 = 0 label as a horizontal zero line with annotation
    ax.axhline(0, color='#4BAF6B', lw=1.5, ls='-', zorder=5)
    ax.text(len(SAMPLES) - 1, 3,
            'Tier 1 (shared) = 0\nin all 15 samples',
            ha='right', va='bottom', fontsize=7.5, color='#4BAF6B', fontweight='bold',
            bbox=dict(facecolor='white', edgecolor='#4BAF6B',
                      boxstyle='round,pad=0.25', linewidth=0.8, alpha=0.92))

    for gb in group_breaks:
        ax.axvline(gb - 0.5, color='#bbbbbb', lw=0.8, ls='--')

    y_label = max(t3_vals) * 1.04
    for cx, gn in zip(group_centers, group_names):
        ax.text(cx, y_label, gn, ha='center', va='bottom',
                fontsize=8, fontweight='bold', color='#333')

    ax.set_xticks(x)
    ax.set_xticklabels([SAMPLE_DISPLAY[s] for s in SAMPLES], fontsize=7,
                        rotation=45, ha='right')
    ax.set_ylabel('Taxa count', fontsize=9.5)
    ax.set_ylim(-5, y_label * 1.13)
    ax.legend(fontsize=7.5, loc='upper left', frameon=True,
              framealpha=0.92, edgecolor='#ddd', ncol=1)
    ax.set_title('A  Confidence tier taxa counts per sample\n'
                 '    (Tier 1 = 0 for all samples; left bar = Tier 2, right bar = Tier 3)',
                 fontsize=9, loc='left', pad=5)

    # — Panel B: Tier 2 heatmap —
    im = ax2.imshow(heat_log, aspect='auto', cmap='YlOrRd', vmin=0, vmax=4)

    ax2.set_xticks(np.arange(len(SAMPLES)))
    ax2.set_xticklabels([SAMPLE_DISPLAY[s] for s in SAMPLES],
                         fontsize=7.5, rotation=45, ha='right')
    ax2.set_yticks(np.arange(len(taxon_ids)))
    ax2.set_yticklabels([TAXON_DISPLAY[tid] for tid in taxon_ids], fontsize=9)

    # Annotate read counts
    for i in range(len(taxon_ids)):
        for j in range(len(SAMPLES)):
            v = heat_arr[i, j]
            if v > 0:
                color = 'white' if heat_log[i, j] > 2.5 else '#333333'
                ax2.text(j, i, str(int(v)), ha='center', va='center',
                         fontsize=6, color=color)

    # Group separator lines
    for gb in group_breaks:
        ax2.axvline(gb - 0.5, color='white', lw=1.8)

    # Group labels above heatmap
    for cx, gn in zip(group_centers, group_names):
        ax2.text(cx, -0.65, gn, ha='center', va='bottom',
                 fontsize=8, fontweight='bold', color='#333',
                 transform=ax2.get_xaxis_transform())

    # "Tier 2" badge on the right of each row
    for i in range(len(taxon_ids)):
        ax2.text(len(SAMPLES) - 0.3, i, '  Tier 2',
                 ha='left', va='center', fontsize=7,
                 color=TIER_COLORS['viral_only'], fontweight='bold',
                 transform=ax2.transData)

    cbar = fig.colorbar(im, ax=ax2, fraction=0.022, pad=0.01)
    cbar.set_label('log₁₀(reads + 1)', fontsize=8)
    cbar.ax.tick_params(labelsize=7)

    ax2.set_title('B  Tier 2 taxon read counts across cohort\n'
                  '    (all absent from competitive PlusPF classification)',
                  fontsize=9, loc='left', pad=5)

    fig.suptitle('Figure 3 — Dual-Database Classification: Tier Distribution and False Positive Characterization',
                 fontsize=11, fontweight='bold', y=1.02)
    fig.savefig(outpath, dpi=200, bbox_inches='tight')
    plt.close(fig)
    print(f'Fig 3 → {outpath}')


# ---------------------------------------------------------------------------
# Figure 4 — HERV-K by tissue type and spinal level
# ---------------------------------------------------------------------------

def make_fig4(results_dir, outpath):
    herv = load_herv_k(results_dir)

    muscle_vals  = [herv[s] for s in MUSCLE]
    drg_d1_vals  = [herv[s] for s in DRG_D1]
    drg_saad_vals = [herv[s] for s in DRG_SAAD]
    drg_all      = drg_d1_vals + drg_saad_vals

    # Mann-Whitney U (one-sided: DRG > muscle)
    stat, p_val = stats.mannwhitneyu(drg_all, muscle_vals, alternative='greater')

    fig, ax = plt.subplots(figsize=(11, 4.5))

    sample_order = MUSCLE + DRG_D1 + DRG_SAAD
    colors = (
        [GROUP_COLORS['Muscle']]    * len(MUSCLE) +
        [GROUP_COLORS['DRG donor1']] * len(DRG_D1) +
        [GROUP_COLORS['DRG Saad']]  * len(DRG_SAAD)
    )
    vals = [herv[s] for s in sample_order]

    x = np.arange(len(sample_order))
    bars = ax.bar(x, vals, color=colors, edgecolor='white', linewidth=0.4, width=0.72)

    # Group mean dashed lines
    groups = [
        (MUSCLE,    GROUP_COLORS['Muscle'],    'Muscle mean'),
        (DRG_D1,    GROUP_COLORS['DRG donor1'], 'DRG donor1 mean'),
        (DRG_SAAD,  GROUP_COLORS['DRG Saad'],  'DRG Saad mean'),
    ]
    offsets = [(0, len(MUSCLE) - 1),
               (len(MUSCLE), len(MUSCLE) + len(DRG_D1) - 1),
               (len(MUSCLE) + len(DRG_D1), len(sample_order) - 1)]
    for (group, col, _), (x0, x1) in zip(groups, offsets):
        mean_val = np.mean([herv[s] for s in group])
        ax.hlines(mean_val, x0 - 0.4, x1 + 0.4,
                  colors=col, linestyles='--', linewidth=1.3, alpha=0.8)
        ax.text(x1 + 0.55, mean_val, f'{mean_val:.0f}',
                va='center', fontsize=7.5, color=col,
                bbox=dict(facecolor='white', edgecolor='none', alpha=0.8, pad=1.5))

    # Group separator lines
    group_breaks = [len(MUSCLE), len(MUSCLE) + len(DRG_D1)]
    for gb in group_breaks:
        ax.axvline(gb - 0.5, color='#cccccc', lw=0.9, ls='--')

    # Layout constants
    enrichment = np.mean(drg_all) / np.mean(muscle_vals)
    p_str = 'p < 0.0001' if p_val < 0.0001 else f'p = {p_val:.4f}'
    y_max_data = max(vals)
    # Three vertical zones: bar tops, group labels, enrichment bracket
    y_group  = y_max_data * 1.06   # group name labels
    y_brk    = y_max_data * 1.21   # bracket horizontal line
    y_brk_lbl = y_max_data * 1.24  # bracket label text
    ylim_top  = y_max_data * 1.38

    group_centers = [
        len(MUSCLE) / 2 - 0.5,
        len(MUSCLE) + len(DRG_D1) / 2 - 0.5,
        len(MUSCLE) + len(DRG_D1) + len(DRG_SAAD) / 2 - 0.5,
    ]
    group_names = ['Skeletal Muscle', 'DRG — donor1\n(spinal levels)', 'DRG — Saad']
    for cx, gn in zip(group_centers, group_names):
        ax.text(cx, y_group, gn, ha='center', va='bottom',
                fontsize=8.5, fontweight='bold', color='#333')

    # Enrichment bracket: spans muscle end → DRG end
    x_left  = -0.5
    x_split = len(MUSCLE) - 0.5
    x_right = len(sample_order) - 0.5
    tick_h  = y_max_data * 0.04

    for bx in [x_left, x_split, x_right]:
        ax.plot([bx, bx], [y_brk - tick_h, y_brk], color='#555', lw=0.9)
    ax.plot([x_left, x_split],  [y_brk, y_brk], color='#555', lw=0.9)
    ax.plot([x_split, x_right], [y_brk, y_brk], color='#555', lw=0.9)
    ax.text((x_split + x_right) / 2, y_brk_lbl,
            f'{enrichment:.1f}× DRG enrichment  ({p_str}, Mann-Whitney U, one-sided)',
            ha='center', va='bottom', fontsize=8, color='#333')

    ax.set_xticks(x)
    ax.set_xticklabels([SAMPLE_DISPLAY[s] for s in sample_order], fontsize=8.5)
    ax.set_ylabel('HERV-K reads (Bracken raw)', fontsize=10)
    ax.set_ylim(0, ylim_top)

    # Legend
    legend_patches = [
        mpatches.Patch(color=GROUP_COLORS['Muscle'],    label='Skeletal muscle (n=5)'),
        mpatches.Patch(color=GROUP_COLORS['DRG donor1'], label='DRG — donor1 (n=6)'),
        mpatches.Patch(color=GROUP_COLORS['DRG Saad'],  label='DRG — Saad (n=4)'),
    ]
    ax.legend(handles=legend_patches, fontsize=8.5, loc='upper left',
              frameon=True, framealpha=0.9, edgecolor='#ddd')

    ax.set_title(
        'Figure 4 — HERV-K Endogenous Retroviral Signal by Tissue Type and Spinal Level',
        fontsize=11, pad=8)

    fig.tight_layout()
    fig.savefig(outpath, dpi=200, bbox_inches='tight')
    plt.close(fig)
    print(f'Fig 4 → {outpath}')


# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

def main():
    if len(sys.argv) < 3:
        print(__doc__)
        sys.exit(1)

    results_dir = Path(sys.argv[1])
    figures_dir = Path(sys.argv[2])
    figures_dir.mkdir(parents=True, exist_ok=True)

    print(f'Results: {results_dir}')
    print(f'Output:  {figures_dir}')
    print()

    make_fig1(figures_dir / 'fig1_pipeline_diagram.png')
    make_fig2(results_dir, figures_dir / 'fig2_filtering_funnel.png')
    make_fig3(results_dir, figures_dir / 'fig3_tier_summary.png')
    make_fig4(results_dir, figures_dir / 'fig4_herv_k.png')

    print('\nDone.')


if __name__ == '__main__':
    main()
