#!/usr/bin/env python3
"""
compare_db_results.py

Compare viral-only vs PlusPF Kraken2 database results across all three
filtering stages. Classifies each taxon into one of three tiers:

  shared          — detected in both databases (high-confidence signal)
  viral_only      — detected only in viral-only DB (false positive candidates)
  pluspf_only     — detected only in PlusPF DB (rare; warrants investigation)

Outputs:
  db_comparison.tsv           — per-taxon tier classification + read counts from both DBs
  consensus_matrix.tsv        — final-stage taxa present in both DBs (primary result for paper 2)
  false_positive_candidates.tsv — taxa present only in viral-only final output
  db_comparison_summary.tsv   — per-sample tier counts (for report/figure)
  db_comparison.png           — stacked bar chart: shared vs viral-only-only per sample
"""

import click
import numpy as np
import pandas as pd
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt
from pathlib import Path


TIER_COLORS = {
    'shared':       '#4CBF7A',   # green  — high confidence
    'viral_only':   '#E8824C',   # orange — false positive candidate
    'pluspf_only':  '#9B59B6',   # purple — investigate
}


def load_matrix(path, label):
    """Load abundance matrix, return reads-only dataframe keyed by taxon_id."""
    df = pd.read_csv(path, sep='\t')
    df = df[df['rank'] == 'S'].copy()
    read_cols = [c for c in df.columns if c.endswith('_reads')]
    result = df.set_index('taxon_id')[['taxon_name'] + read_cols]
    result.columns = ['taxon_name'] + [f"{label}:{c}" for c in read_cols]
    return result


def classify_tier(viral_total, pluspf_total):
    if viral_total > 0 and pluspf_total > 0:
        return 'shared'
    if viral_total > 0 and pluspf_total == 0:
        return 'viral_only'
    return 'pluspf_only'


def per_sample_tier_counts(comparison_df, samples):
    """For each sample, count taxa in each tier."""
    rows = []
    for sample in samples:
        v_col = f"viral_only:{sample}_reads"
        p_col = f"pluspf:{sample}_reads"
        for tier in ['shared', 'viral_only', 'pluspf_only']:
            mask = comparison_df['tier'] == tier
            v_present = comparison_df.loc[mask, v_col] > 0 if v_col in comparison_df.columns else pd.Series(False)
            p_present = comparison_df.loc[mask, p_col] > 0 if p_col in comparison_df.columns else pd.Series(False)
            if tier == 'shared':
                count = (v_present & p_present).sum()
            elif tier == 'viral_only':
                count = (v_present & ~p_present).sum()
            else:
                count = (~v_present & p_present).sum()
            rows.append({'sample': sample, 'tier': tier, 'taxa_count': int(count)})
    return pd.DataFrame(rows)


def plot_comparison(summary_df, samples, outpath):
    """Stacked bar chart showing tier breakdown per sample."""
    pivot = summary_df.pivot(index='sample', columns='tier', values='taxa_count').reindex(samples).fillna(0)

    tiers = [t for t in ['shared', 'viral_only', 'pluspf_only'] if t in pivot.columns]
    tier_labels = {'shared': 'Shared (both DBs)', 'viral_only': 'Viral-only DB only', 'pluspf_only': 'PlusPF only'}

    x = np.arange(len(samples))
    fig, ax = plt.subplots(figsize=(max(9, len(samples) * 0.8), 5))

    bottom = np.zeros(len(samples))
    for tier in tiers:
        vals = pivot[tier].values
        ax.bar(x, vals, bottom=bottom,
               label=tier_labels.get(tier, tier),
               color=TIER_COLORS.get(tier, '#aaaaaa'),
               edgecolor='white', linewidth=0.5)
        bottom += vals

    ax.set_xticks(x)
    ax.set_xticklabels(samples, rotation=35, ha='right', fontsize=9)
    ax.set_ylabel('Taxa detected (final filtered stage)', fontsize=10)
    ax.set_title('Database comparison: viral-only vs PlusPF competitive classification\n'
                 'Shared taxa = high-confidence signal; Viral-only = false positive candidates',
                 fontsize=10, pad=10)
    ax.legend(fontsize=9, framealpha=0.8)
    ax.spines[['top', 'right']].set_visible(False)
    plt.tight_layout()
    fig.savefig(outpath, dpi=150, bbox_inches='tight')
    plt.close(fig)


@click.command()
@click.option('--viral-only-matrix', required=True, type=click.Path(exists=True),
              help='Final abundance matrix from viral-only Kraken2 DB')
@click.option('--pluspf-matrix',     required=True, type=click.Path(exists=True),
              help='Final abundance matrix from PlusPF Kraken2 DB')
@click.option('--outdir',            required=True,
              help='Output directory for comparison results')
def main(viral_only_matrix, pluspf_matrix, outdir):
    outdir = Path(outdir)
    outdir.mkdir(parents=True, exist_ok=True)

    viral = load_matrix(viral_only_matrix, 'viral_only')
    pluspf = load_matrix(pluspf_matrix, 'pluspf')

    # Union of taxa across both DBs
    all_taxa = viral.index.union(pluspf.index)
    combined = viral.reindex(all_taxa).join(pluspf.reindex(all_taxa), rsuffix='_pluspf')

    # Resolve taxon_name (prefer viral_only label, fall back to pluspf)
    combined['taxon_name'] = combined['taxon_name'].combine_first(combined.get('taxon_name_pluspf'))
    if 'taxon_name_pluspf' in combined.columns:
        combined = combined.drop(columns=['taxon_name_pluspf'])
    combined = combined.fillna(0)

    # Detect sample names
    viral_read_cols  = [c for c in combined.columns if c.startswith('viral_only:') and c.endswith('_reads')]
    pluspf_read_cols = [c for c in combined.columns if c.startswith('pluspf:')     and c.endswith('_reads')]
    samples = [c.replace('viral_only:', '').replace('_reads', '') for c in viral_read_cols]

    # Total reads across samples per DB
    combined['viral_only_total'] = combined[viral_read_cols].sum(axis=1) if viral_read_cols else 0
    combined['pluspf_total']     = combined[pluspf_read_cols].sum(axis=1) if pluspf_read_cols else 0

    combined['tier'] = combined.apply(
        lambda r: classify_tier(r['viral_only_total'], r['pluspf_total']), axis=1
    )

    # ── Output tables ──────────────────────────────────────────────────────────
    out_cols = ['taxon_name', 'tier', 'viral_only_total', 'pluspf_total'] + viral_read_cols + pluspf_read_cols
    out_cols = [c for c in out_cols if c in combined.columns]
    combined[out_cols].sort_values(['tier', 'viral_only_total'], ascending=[True, False]) \
        .to_csv(outdir / 'db_comparison.tsv', sep='\t')

    # Consensus matrix: shared taxa, viral-only read columns only (clean output)
    shared = combined[combined['tier'] == 'shared']
    consensus_cols = ['taxon_name'] + viral_read_cols
    consensus_cols = [c for c in consensus_cols if c in shared.columns]
    consensus = shared[consensus_cols].rename(
        columns={c: c.replace('viral_only:', '') for c in viral_read_cols}
    )
    consensus.to_csv(outdir / 'consensus_matrix.tsv', sep='\t')

    # False positive candidates
    fp = combined[combined['tier'] == 'viral_only'][['taxon_name', 'viral_only_total'] + viral_read_cols]
    fp.rename(columns={c: c.replace('viral_only:', '') for c in viral_read_cols}) \
      .to_csv(outdir / 'false_positive_candidates.tsv', sep='\t')

    # Per-sample tier summary
    summary_df = per_sample_tier_counts(combined, samples)
    summary_df.to_csv(outdir / 'db_comparison_summary.tsv', sep='\t', index=False)

    # ── Figure ─────────────────────────────────────────────────────────────────
    plot_comparison(summary_df, samples, outdir / 'db_comparison.png')

    # ── Print summary ──────────────────────────────────────────────────────────
    tier_counts = combined['tier'].value_counts()
    print(f"Database comparison complete:")
    print(f"  Shared (both DBs):        {tier_counts.get('shared', 0)} taxa")
    print(f"  Viral-only DB only:       {tier_counts.get('viral_only', 0)} taxa (false positive candidates)")
    print(f"  PlusPF only:              {tier_counts.get('pluspf_only', 0)} taxa")
    print(f"  Consensus matrix:         {outdir}/consensus_matrix.tsv")
    print(f"  False positive candidates:{outdir}/false_positive_candidates.tsv")
    print(f"  Figure:                   {outdir}/db_comparison.png")


if __name__ == '__main__':
    main()
