#!/usr/bin/env python3
"""
score_vs_viral_correlation.py

Correlate a per-sample host reactivation score (from score_host_reactivation.py)
against a viral taxon's RPM abundance (from the pipeline's
viral_abundance_matrix.tsv / minreads_matrix.tsv / bracken_raw_matrix.tsv).

Adapted from the regression pattern in
results/iadorola_tg/hsv1_hervk_analysis.py (HSV-1 vs HERV-K), generalized to
take any host score file and any viral taxon_id, since the host-quant arm's
whole design point is that host RPM and viral RPM share the same STAR
input-reads denominator and are therefore directly comparable per sample.

Outputs:
  <output>.tsv  -- per-sample joined table (sample, host score, viral reads/rpm)
  <output>.png  -- scatter + regression line, annotated with n / R / R^2 / p
  Prints Pearson r, R^2, p-value, and Spearman rho to stdout.

Use --label to stamp a run-specific annotation onto the plot and stdout
banner -- e.g. pass --label "MOCK DATA -- host matrix is synthetic, not a
real pipeline result" when validating this script's logic before a genuine
host_gene_expression_matrix.tsv exists (see docs/tooling_progress_plan.md).
This script does not know or guess whether its input is real; the caller is
responsible for the --label.
"""

import sys
import click
import numpy as np
import pandas as pd
from scipy import stats
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt


@click.command()
@click.option('--score', required=True, help='host_reactivation_score.tsv from score_host_reactivation.py')
@click.option('--viral-matrix', required=True, help='viral_abundance_matrix.tsv (or minreads_matrix.tsv / bracken_raw_matrix.tsv)')
@click.option('--taxon-id', required=True, help='taxon_id to correlate against (e.g. 45617 = HERV-K, 3050292 = HSV-1)')
@click.option('--score-column', default='raw_score_mean_log1p_rpm', show_default=True,
              help='Column in --score to use (raw_score_mean_log1p_rpm or z_score)')
@click.option('--label', default=None,
              help='Free-text annotation stamped on the plot and stdout banner, e.g. to flag mock/synthetic input data.')
@click.option('--output', '-o', required=True, help='Output file prefix (no extension)')
def main(score, viral_matrix, taxon_id, score_column, label, output):

    if label:
        banner = f"*** {label} ***"
        print("=" * len(banner))
        print(banner)
        print("=" * len(banner))

    score_df = pd.read_csv(score, sep='\t')
    if score_column not in score_df.columns:
        raise click.ClickException(f"--score-column {score_column} not found in {score}. "
                                    f"Available: {list(score_df.columns)}")

    vsep = '\t' if str(viral_matrix).endswith('.tsv') else ','
    viral_df = pd.read_csv(viral_matrix, sep=vsep)
    viral_df['taxon_id'] = viral_df['taxon_id'].astype(str)
    row = viral_df[viral_df['taxon_id'] == str(taxon_id)]
    if row.empty:
        raise click.ClickException(f"taxon_id {taxon_id} not found in {viral_matrix}")
    taxon_name = row.iloc[0].get('taxon_name', str(taxon_id))

    rpm_cols = [c for c in viral_df.columns if c.endswith('_rpm')]
    sample_rpm = {}
    for c in rpm_cols:
        sample = c[:-len('_rpm')]
        sample_rpm[sample] = float(row.iloc[0][c])

    viral_long = pd.DataFrame({'sample': list(sample_rpm.keys()), 'viral_rpm': list(sample_rpm.values())})

    merged = score_df.merge(viral_long, on='sample', how='inner')
    n_score_only = len(score_df) - len(merged)
    n_viral_only = len(viral_long) - len(merged)
    if n_score_only or n_viral_only:
        print(f"NOTE: {n_score_only} sample(s) in --score not found in --viral-matrix; "
              f"{n_viral_only} sample(s) in --viral-matrix not found in --score. "
              f"Correlating on the {len(merged)} samples present in both.", file=sys.stderr)

    merged = merged.dropna(subset=[score_column, 'viral_rpm'])
    n = len(merged)
    if n < 3:
        raise click.ClickException(f"Only {n} samples with both a host score and viral RPM -- need >=3 to correlate.")

    x = merged['viral_rpm'].values.astype(float)
    y = merged[score_column].values.astype(float)

    slope, intercept, r, p_reg, se = stats.linregress(x, y)
    rho, p_spear = stats.spearmanr(x, y)

    print(f"Host score ({score_column}) vs. viral taxon {taxon_id} ({taxon_name}) RPM")
    print(f"  n = {n}")
    print(f"  Pearson  R = {r:.4f}   R^2 = {r**2:.4f}   p = {p_reg:.4g}")
    print(f"  Spearman rho = {rho:.4f}   p = {p_spear:.4g}")
    if label:
        print(f"  ({label})")

    out_tsv = f"{output}.tsv"
    merged.to_csv(out_tsv, sep='\t', index=False)

    fig, ax = plt.subplots(figsize=(7, 5.5))
    ax.scatter(x, y, s=60, color="#2c3e50", edgecolors="white", linewidths=0.7, zorder=5)
    x_fit = np.linspace(min(x), max(x), 100) if max(x) > min(x) else np.array([min(x) - 1, min(x) + 1])
    ax.plot(x_fit, slope * x_fit + intercept, color="#c0392b", lw=1.8, zorder=4,
            label=f"R={r:.3f}  R²={r**2:.3f}  p={p_reg:.3g}")
    for _, rrow in merged.iterrows():
        ax.annotate(str(rrow['sample']), (rrow['viral_rpm'], rrow[score_column]),
                    textcoords="offset points", xytext=(4, 3), fontsize=7, color="#555")
    ax.set_xlabel(f"Viral RPM -- taxon {taxon_id} ({taxon_name})")
    ax.set_ylabel(f"Host reactivation score ({score_column})")
    ax.set_title(f"Host reactivation score vs. {taxon_name} RPM (n={n})", fontsize=11, color="#2c3e50")
    ax.legend(frameon=False, fontsize=9)
    ax.spines[["top", "right"]].set_visible(False)
    fig.tight_layout()
    if label:
        import textwrap
        wrapped = "\n".join(textwrap.wrap(label, width=80))
        n_lines = wrapped.count("\n") + 1
        fig.subplots_adjust(bottom=0.12 + 0.035 * n_lines)
        fig.text(0.5, 0.01, wrapped, ha="center", va="bottom", fontsize=8,
                  color="#c0392b", fontweight="bold")
    out_png = f"{output}.png"
    fig.savefig(out_png, dpi=150)
    plt.close(fig)

    print(f"Wrote {out_tsv}")
    print(f"Wrote {out_png}")


if __name__ == '__main__':
    main()
