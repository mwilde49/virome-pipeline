#!/usr/bin/env python3
"""
score_host_reactivation.py

Compute a per-donor cGAS-STING / type-I-IFN / IL-6 / ISG "host reactivation
score" from host_gene_expression_matrix.tsv (the v2.0.0 host-quant arm
output; params.run_host_quant) and a curated gene panel
(assets/cgas_sting_ifn_panel.tsv).

Built for the Phase I STTR application (Ataraxia Bio / Price Lab) Preliminary
Data deliverable: a per-donor reactivation score, tested for correlation
against existing viral RPM data (see score_vs_viral_correlation.py).

Method (deliberately simple/explainable, not a "clever" composite score):
  1. Subset the host expression matrix to panel genes.
  2. Per sample, per gene: RPM from the chosen counter (featureCounts,
     HTSeq, or the mean of both — default: mean, since the QC file already
     tells you when the two counters disagree).
  3. raw_score = mean(log1p(RPM)) across all panel genes present in the
     matrix, per sample. log1p compresses the long right tail typical of
     RPM data so a handful of very highly expressed genes (e.g. ISG15,
     B2M) don't dominate the mean.
  4. z_score = raw_score z-scored across the samples in this run (cohort-
     relative reactivation score; requires >=2 samples to be meaningful).
  5. Per-category subscores (cGAS_STING_core / type_I_IFN_response_ISG /
     IL6_JAK_STAT3_axis) are also emitted for interpretability -- e.g. to
     see whether a high score is IFN-driven vs IL-6-driven vs both.

This is intentionally NOT a validated clinical or diagnostic score. It is a
descriptive summary statistic for hypothesis-generating correlation with
viral RPM, appropriate for a grant Preliminary Data section framed as
feasibility/exploratory, not a powered test.
"""

import re
import sys
import click
import numpy as np
import pandas as pd
from pathlib import Path


def load_panel(path):
    """Load the gene panel TSV, skipping '#'-prefixed comment/header lines."""
    df = pd.read_csv(path, sep='\t', comment='#')
    required = {'gene_id', 'gene_symbol', 'category'}
    missing = required - set(df.columns)
    if missing:
        raise click.ClickException(f"Panel file {path} is missing columns: {missing}")
    return df


def detect_samples(matrix_columns):
    """Infer sample IDs from <sample>_fc_rpm / <sample>_htseq_rpm columns."""
    samples = set()
    for c in matrix_columns:
        m = re.match(r'^(.*)_(fc|htseq)_rpm$', c)
        if m:
            samples.add(m.group(1))
    return sorted(samples)


def sample_rpm(matrix, sample, counter):
    """Return the RPM series for one sample given the requested counter."""
    fc_col    = f'{sample}_fc_rpm'
    htseq_col = f'{sample}_htseq_rpm'
    has_fc    = fc_col in matrix.columns
    has_htseq = htseq_col in matrix.columns

    if counter == 'fc':
        if not has_fc:
            raise click.ClickException(f"--counter fc requested but {fc_col} not found for sample {sample}")
        return matrix[fc_col]
    if counter == 'htseq':
        if not has_htseq:
            raise click.ClickException(f"--counter htseq requested but {htseq_col} not found for sample {sample}")
        return matrix[htseq_col]

    # counter == 'mean' (default): average whichever of the two are present
    if has_fc and has_htseq:
        return matrix[[fc_col, htseq_col]].mean(axis=1)
    if has_fc:
        return matrix[fc_col]
    if has_htseq:
        return matrix[htseq_col]
    raise click.ClickException(f"Neither {fc_col} nor {htseq_col} found for sample {sample}")


@click.command()
@click.option('--matrix',  required=True, help='host_gene_expression_matrix.tsv (or .csv) from the host-quant arm')
@click.option('--panel',   required=True, default=None,
              help='Gene panel TSV (default: assets/cgas_sting_ifn_panel.tsv next to this script\'s repo)')
@click.option('--counter', type=click.Choice(['fc', 'htseq', 'mean']), default='mean',
              help='Which counter\'s RPM to score on. Default: mean of featureCounts + HTSeq (recommended -- '
                   'check host_gene_expression_matrix_qc_summary.tsv first for per-sample concordance).')
@click.option('--output', '-o', required=True, help='Output file prefix (no extension)')
def main(matrix, panel, counter, output):

    sep = '\t' if str(matrix).endswith('.tsv') else ','
    mat = pd.read_csv(matrix, sep=sep)
    if 'gene_id' not in mat.columns:
        raise click.ClickException(f"{matrix} has no gene_id column -- is this a host_gene_expression_matrix file?")

    panel_df = load_panel(panel)
    panel_ids = set(panel_df['gene_id'])

    samples = detect_samples(mat.columns)
    if not samples:
        raise click.ClickException(f"Could not detect any <sample>_fc_rpm / <sample>_htseq_rpm columns in {matrix}")

    sub = mat[mat['gene_id'].isin(panel_ids)].copy()
    n_panel_total   = len(panel_df)
    n_panel_in_matrix = sub['gene_id'].nunique()

    if n_panel_in_matrix == 0:
        print(f"WARNING: 0 of {n_panel_total} panel genes found in {matrix}. "
              f"Score will be all-NaN. (Expected if the matrix was produced against a "
              f"partial/toy reference, e.g. a single-chromosome smoke test.)", file=sys.stderr)

    # attach category (a gene_id could in principle map to >1 category row if the
    # panel file were malformed; guard with drop_duplicates on gene_id+category)
    cat_map = panel_df[['gene_id', 'category']].drop_duplicates()

    # explode multi-category rows (categories are ';'-joined in the panel file)
    cat_long = cat_map.assign(category=cat_map['category'].str.split(';')).explode('category')

    score_rows = []
    subscore_rows = []
    for s in samples:
        rpm = sample_rpm(sub, s, counter)
        log1p_rpm = np.log1p(rpm)
        n_detected = int((rpm > 0).sum())

        score_rows.append({
            'sample': s,
            'raw_score_mean_log1p_rpm': round(float(log1p_rpm.mean()), 4) if len(log1p_rpm) else float('nan'),
            'n_panel_genes_detected': n_detected,
            'n_panel_genes_in_matrix': n_panel_in_matrix,
            'n_panel_genes_total': n_panel_total,
            'counter_used': counter,
        })

        tmp = sub[['gene_id']].copy()
        tmp['log1p_rpm'] = log1p_rpm.values
        tmp = tmp.merge(cat_long, on='gene_id', how='left')
        for cat, grp in tmp.groupby('category'):
            subscore_rows.append({
                'sample': s,
                'category': cat,
                'subscore_mean_log1p_rpm': round(float(grp['log1p_rpm'].mean()), 4) if len(grp) else float('nan'),
                'n_genes_in_category_detected': int((grp['log1p_rpm'] > 0).sum()),
                'n_genes_in_category': len(grp),
            })

    score_df = pd.DataFrame(score_rows)

    # cohort z-score (needs >=2 samples with a non-NaN raw score to be meaningful)
    valid = score_df['raw_score_mean_log1p_rpm'].notna()
    if valid.sum() >= 2:
        mu = score_df.loc[valid, 'raw_score_mean_log1p_rpm'].mean()
        sd = score_df.loc[valid, 'raw_score_mean_log1p_rpm'].std(ddof=1)
        score_df['z_score'] = np.where(
            valid & (sd > 0), (score_df['raw_score_mean_log1p_rpm'] - mu) / sd, np.nan
        )
    else:
        score_df['z_score'] = float('nan')
        print("WARNING: fewer than 2 samples with a valid score -- z_score is undefined (all NaN). "
              "The z-score is cohort-relative and requires a real multi-sample cohort run.", file=sys.stderr)

    score_out = f"{output}.tsv"
    score_df.to_csv(score_out, sep='\t', index=False)

    subscore_df = pd.DataFrame(subscore_rows)
    subscore_out = f"{output}_by_category.tsv"
    subscore_df.to_csv(subscore_out, sep='\t', index=False)

    print(f"Host reactivation score: {len(samples)} samples, "
          f"{n_panel_in_matrix}/{n_panel_total} panel genes found in matrix -> {score_out}")
    print(f"Per-category subscores -> {subscore_out}")


if __name__ == '__main__':
    main()
