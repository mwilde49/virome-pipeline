#!/usr/bin/env python3
"""
fig_pipeline_diagram.py

Generate a publication-quality pipeline process diagram for the virome pipeline.

Usage:
    python3 research/fig_pipeline_diagram.py research/figures
"""

import sys
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt
import matplotlib.patches as mpatches
from matplotlib.patches import FancyBboxPatch, FancyArrowPatch
from pathlib import Path


# ── Colour palette ────────────────────────────────────────────────────────────
C_INPUT   = '#D6EAF8'   # pale blue  — input/output data
C_QC      = '#D5F5E3'   # pale green — QC steps
C_ALIGN   = '#FAE5D3'   # pale orange — alignment
C_CLASS   = '#EBD5F8'   # pale purple — classification
C_FILTER  = '#FDEBD0'   # pale yellow — filtering/aggregation
C_REPORT  = '#F9EBEA'   # pale red   — reporting
C_BORDER  = '#555555'

TEXT_KW   = dict(ha='center', va='center', fontsize=9, color='#222222')
BOLD_KW   = dict(ha='center', va='center', fontsize=9.5, color='#111111', fontweight='bold')


def box(ax, x, y, w, h, label, sublabel='', color=C_INPUT, bold=False):
    rect = FancyBboxPatch((x - w/2, y - h/2), w, h,
                          boxstyle='round,pad=0.02', linewidth=1,
                          edgecolor=C_BORDER, facecolor=color)
    ax.add_patch(rect)
    if sublabel:
        ax.text(x, y + h * 0.14, label, ha='center', va='center',
                fontsize=9.5, fontweight='bold', color='#111111')
        ax.text(x, y - h * 0.22, sublabel, ha='center', va='center',
                fontsize=7.5, color='#444444', style='italic')
    elif bold:
        ax.text(x, y, label, **BOLD_KW)
    else:
        ax.text(x, y, label, **TEXT_KW)


def arrow(ax, x1, y1, x2, y2, label='', color='#555555'):
    ax.annotate('', xy=(x2, y2), xytext=(x1, y1),
                arrowprops=dict(arrowstyle='->', color=color,
                                lw=1.3, connectionstyle='arc3,rad=0.0'))
    if label:
        mx, my = (x1 + x2) / 2, (y1 + y2) / 2
        ax.text(mx + 0.07, my, label, fontsize=7.5, color='#555555',
                va='center', style='italic')


def branching_arrow(ax, x1, y1, x2, y2, color='#555555'):
    """Arrow with slight curve for branching paths."""
    ax.annotate('', xy=(x2, y2), xytext=(x1, y1),
                arrowprops=dict(arrowstyle='->', color=color,
                                lw=1.1, connectionstyle='arc3,rad=0.15'))


def main():
    outdir = Path(sys.argv[1]) if len(sys.argv) > 1 else Path('research/figures')
    outdir.mkdir(parents=True, exist_ok=True)

    fig, ax = plt.subplots(figsize=(13, 9))
    ax.set_xlim(0, 13)
    ax.set_ylim(0, 9)
    ax.axis('off')

    fig.patch.set_facecolor('#FAFAFA')

    # ── Title ─────────────────────────────────────────────────────────────────
    ax.text(6.5, 8.65, 'Virome Pipeline — Data Flow (v1.0.0)',
            ha='center', va='center', fontsize=13, fontweight='bold', color='#111111')

    # ── Column x positions ────────────────────────────────────────────────────
    # Main spine: x=3.5, branching outputs: x=7.5, x=10.0, x=12.5
    # Parallel QC arm: x=1.2

    BW = 2.0   # box width (main)
    BH = 0.52  # box height

    # ── Main pipeline spine (left-centre) ─────────────────────────────────────

    steps = [
        # (x,    y,    label,                  sublabel,           color)
        (3.5,  7.9,  'Raw FASTQs',            'paired-end, 2×150 bp',  C_INPUT),
        (3.5,  7.0,  'FASTQC',               'quality metrics',         C_QC),
        (3.5,  6.1,  'TRIMMOMATIC',           'adapter & quality trim',  C_ALIGN),
        (3.5,  5.2,  'STAR',                  'host read depletion (GRCh38)', C_ALIGN),
        (3.5,  4.3,  'KRAKEN2',              'k-mer viral classification', C_CLASS),
        (3.5,  3.4,  'BRACKEN',              'species-level re-estimation', C_CLASS),
        (3.5,  2.5,  'KRAKEN2_FILTER',       'min-reads + artifact exclusion', C_FILTER),
    ]

    for (x, y, lbl, sub, col) in steps:
        box(ax, x, y, BW, BH, lbl, sublabel=sub, color=col)

    # Arrows down the main spine
    spine_ys = [s[1] for s in steps]
    for i in range(len(spine_ys) - 1):
        arrow(ax, 3.5, spine_ys[i] - BH/2, 3.5, spine_ys[i+1] + BH/2)

    # ── QC arm (parallel to FASTQC / TRIMMOMATIC) ─────────────────────────────
    box(ax, 1.2, 7.0, 1.4, BH, 'FastQC report', color=C_QC)
    box(ax, 1.2, 6.1, 1.4, BH, 'Trimming stats', color=C_QC)
    arrow(ax, 2.5, 7.0, 1.95, 7.0, color='#aaaaaa')
    arrow(ax, 2.5, 6.1, 1.95, 6.1, color='#aaaaaa')

    # ── STAR side output ───────────────────────────────────────────────────────
    box(ax, 1.2, 5.2, 1.4, BH, 'Host-mapped\nreads (discarded)', color='#ECECEC')
    arrow(ax, 2.5, 5.2, 1.95, 5.2, color='#aaaaaa')

    # ── Three filter output channels ──────────────────────────────────────────
    # KRAKEN2_FILTER branches into 3 channels + summary + artifacts
    # Show: filtered (final), minreads, bracken_raw

    channel_y = 2.5
    branch_ys = [1.55, 1.55, 1.55]

    # Three output labels — positioned right of filter box
    chan_data = [
        (5.8,  2.75, '{id}.filtered.tsv',    'final (artifact excl.)',   C_FILTER),
        (5.8,  2.25, '{id}.minreads.tsv',     'after min-reads only',     C_FILTER),
        (5.8,  1.75, '{id}.bracken_raw.tsv',  'all viral species',        C_FILTER),
    ]
    for (cx, cy, lbl, sub, col) in chan_data:
        box(ax, cx, cy, 2.2, BH * 0.9, lbl, sublabel=sub, color=col)
        arrow(ax, 4.5, channel_y, cx - 1.1, cy, color='#888888')

    # filter_summary + artifacts_removed (small annotation boxes)
    box(ax, 5.8, 1.25, 2.2, BH * 0.75,
        '{id}.filter_summary.tsv\n{id}.artifacts_removed.tsv',
        color='#F2F3F4')
    ax.annotate('', xy=(5.8 - 1.1, 1.25), xytext=(4.5, 2.5 - BH*0.5),
                arrowprops=dict(arrowstyle='->', color='#aaaaaa', lw=1.0))

    # ── Aggregate ─────────────────────────────────────────────────────────────
    agg_data = [
        (8.8, 2.75, 'AGGREGATE\n(final)',      'viral_abundance_matrix.tsv',      C_FILTER),
        (8.8, 2.25, 'AGGREGATE\n(minreads)',   'minreads_matrix.tsv',             C_FILTER),
        (8.8, 1.75, 'AGGREGATE\n(bracken_raw)','bracken_raw_matrix.tsv',          C_FILTER),
    ]
    for (i, (ax2x, ax2y, lbl, sub, col)) in enumerate(agg_data):
        box(ax, ax2x, ax2y, 2.0, BH * 0.9, lbl, sublabel=sub, color=col)
        src_x, src_y, _, _, _ = chan_data[i]
        arrow(ax, src_x + 1.1, src_y, ax2x - 1.0, ax2y, color='#555555')

    # ── Report & MultiQC ──────────────────────────────────────────────────────
    box(ax, 11.2, 2.75, 2.0, BH, 'REPORT',
        sublabel='summary.html\ndiversity, heatmap, funnel', color=C_REPORT)
    box(ax, 11.2, 1.75, 2.0, BH, 'MULTIQC',
        sublabel='multiqc_report.html', color=C_REPORT)

    # Arrows into Report from all three aggregates
    for ax2x, ax2y, *_ in agg_data:
        arrow(ax, ax2x + 1.0, ax2y, 10.2, 2.75 if ax2y >= 2.25 else 1.75,
              color='#888888')

    # MultiQC also gets FASTQC + TRIMMOMATIC
    ax.annotate('', xy=(10.2, 1.75), xytext=(3.5, 6.1 - BH/2),
                arrowprops=dict(arrowstyle='->', color='#aaaaaa', lw=1.0,
                                connectionstyle='arc3,rad=-0.25'))

    # ── Legend ────────────────────────────────────────────────────────────────
    legend_items = [
        (C_INPUT,  'Input / output data'),
        (C_QC,     'QC steps'),
        (C_ALIGN,  'Alignment / host depletion'),
        (C_CLASS,  'Taxonomic classification'),
        (C_FILTER, 'Filtering / aggregation'),
        (C_REPORT, 'Reporting'),
    ]
    lx, ly = 0.25, 1.8
    for color, label in legend_items:
        rect = FancyBboxPatch((lx, ly), 0.28, 0.22,
                              boxstyle='round,pad=0.01', linewidth=0.8,
                              edgecolor=C_BORDER, facecolor=color)
        ax.add_patch(rect)
        ax.text(lx + 0.38, ly + 0.11, label, fontsize=7.5, va='center', color='#333333')
        ly -= 0.3

    # ── Annotation: assets ────────────────────────────────────────────────────
    ax.text(3.5, 2.0, '▲ assets/artifact_taxa.tsv\n   (22 curated entries)',
            ha='center', va='center', fontsize=7, color='#666666', style='italic')

    plt.tight_layout(pad=0.3)
    outpath = outdir / 'fig6_pipeline_diagram.png'
    fig.savefig(outpath, dpi=200, bbox_inches='tight', facecolor=fig.get_facecolor())
    plt.close(fig)
    print(f"  Fig 6 → {outpath}")


if __name__ == '__main__':
    main()
