#!/usr/bin/env python3
"""
aggregate_pathseq.py

Combine per-sample GATK PathSeqPipelineSpark scores.txt tables (one
taxonomy-wide abundance table per sample — viral, bacterial, everything;
PathSeq does not do per-taxon extraction, see workflows/pathseq_verification.nf)
into a single across-sample abundance matrix, and cross-check PathSeq's calls
against the main pipeline's dual-DB Tier 1 consensus_matrix.tsv and, if
available, the BLAST offshoot's per-(sample, taxon) lifecycle_inference.tsv
calls — producing a three-way (Kraken2/Bracken consensus vs. PathSeq vs.
BLAST) concordance table.

PathSeq scores.txt format — verified directly against GATK source
(broadinstitute/gatk@master, fetched 2026-08-14), NOT assumed from memory or
from the tool's own prose Javadoc (which undercounts the columns by one):

  org.../tools/spark/pathseq/PSScorer.java, writeScoresFile():
      header = "tax_id\\ttaxonomy\\ttype\\tname\\t" + PSPathogenTaxonScore.outputHeader
      row    = tax_id + "\\t" + taxonomy_path + "\\t" + rank + "\\t" + name
               + "\\t" + <PSPathogenTaxonScore fields>

  org.../tools/spark/pathseq/PSPathogenTaxonScore.java:
      static final String outputHeader =
          String.join("\\t", "kingdom", "score", "score_normalized",
                       "reads", "unambiguous", "reference_length");

  => the real, literal on-disk header is 10 tab-separated columns:
       tax_id  taxonomy  type  name  kingdom  score  score_normalized  reads
       unambiguous  reference_length
     PathSeqScoreSpark.java's own class-level Javadoc describes only 9 of
     these in prose (it omits "kingdom", the per-taxon kingdom-name label
     used for per-kingdom score normalization) — parsing here is done by
     HEADER NAME, not fixed column position/count, specifically so a future
     GATK build reordering or renaming columns fails loudly (ValueError)
     instead of silently misassigning fields.

  PSScorer.java, writeScoresFile(), also does printStream.println(line.
  replace(" ", "_")) on the ENTIRE output line before writing — so every
  "name"/"taxonomy" value on disk already has its spaces turned into
  underscores (e.g. "Human_alphaherpesvirus_1", pipe-delimited lineages
  like "...|Human_alphaherpesvirus_1"). parse_pathseq_scores() reverses
  this (underscore -> space) on taxon_name/taxonomic_path only, so PathSeq-
  sourced names match the normal-spaced NCBI-style names already used
  elsewhere in this pipeline (consensus_matrix.tsv, target_taxa names).
  This is a best-effort reversal, not a lossless one: a taxon name that
  legitimately contains an underscore in NCBI taxonomy would be turned into
  a space too, but real NCBI viral taxon names essentially never do.

Outputs:
  pathseq_abundance_matrix.tsv — all taxa PathSeq detected, all samples
  pathseq_concordance.tsv      — per (sample, taxon) concordance across
                                  Kraken2/Bracken consensus, PathSeq, and
                                  BLAST life cycle calls (whichever are
                                  available)
"""

import re
import json
import click
import pandas as pd
from pathlib import Path


# ---------------------------------------------------------------------------
# PathSeq scores.txt parsing
# ---------------------------------------------------------------------------

SCORES_SUFFIX = '.pathseq_scores.tsv'   # modules/pathseq_score.nf: "${meta.id}.pathseq_scores.tsv"

# Real on-disk header (PSScorer.writeScoresFile + PSPathogenTaxonScore.outputHeader,
# see module docstring above) -> canonical column names used in our outputs.
# 'kingdom' is treated as optional on read (see docstring) in case a GATK build
# ever ships the 9-column prose-documented variant; every other column is required.
PATHSEQ_COLUMN_RENAME = {
    'tax_id':            'taxon_id',
    'taxonomy':          'taxonomic_path',
    'type':              'rank',
    'name':              'taxon_name',
    'kingdom':            'kingdom',
    'score':              'abundance_score',
    'score_normalized':   'score_normalized_pct',
    'reads':              'total_reads',
    'unambiguous':        'unambiguous_reads',
    'reference_length':   'reference_length',
}
PATHSEQ_NUMERIC_COLS = [
    'abundance_score', 'score_normalized_pct', 'total_reads',
    'unambiguous_reads', 'reference_length',
]
PATHSEQ_OPTIONAL_RAW_COLS = {'kingdom'}

# Columns PSScorer.java's line.replace(" ", "_") mangled on disk (see module
# docstring) -- reversed on read so PathSeq-sourced names display consistently
# with the normal-spaced names used elsewhere in this pipeline.
PATHSEQ_UNDERSCORE_MANGLED_COLS = ['taxon_name', 'taxonomic_path']


def sample_id_from_scores_path(path):
    """{sample_id}.pathseq_scores.tsv -> sample_id (per modules/pathseq_score.nf)."""
    name = Path(path).name
    if name.endswith(SCORES_SUFFIX):
        return name[: -len(SCORES_SUFFIX)]
    return Path(path).stem


def parse_pathseq_scores(path):
    """Parse one sample's PathSeq scores.txt into a canonically-named DataFrame."""
    df = pd.read_csv(path, sep='\t', dtype=str)

    required_missing = [
        raw for raw in PATHSEQ_COLUMN_RENAME
        if raw not in df.columns and raw not in PATHSEQ_OPTIONAL_RAW_COLS
    ]
    if required_missing:
        raise ValueError(
            f"{path}: PathSeq scores.txt is missing expected column(s) {required_missing}. "
            f"Found columns: {list(df.columns)}. This script parses by header name against "
            f"the GATK source cited in its module docstring — if GATK's scores.txt format has "
            f"changed, re-verify against PSScorer.java/PSPathogenTaxonScore.java before trusting "
            f"this output."
        )

    df = df.rename(columns=PATHSEQ_COLUMN_RENAME)
    if 'kingdom' not in df.columns:
        df['kingdom'] = ''

    # Undo PSScorer.java's line.replace(" ", "_") (see module docstring).
    for col in PATHSEQ_UNDERSCORE_MANGLED_COLS:
        df[col] = df[col].str.replace('_', ' ', regex=False)

    for col in PATHSEQ_NUMERIC_COLS:
        df[col] = pd.to_numeric(df[col], errors='coerce')

    df['taxon_id'] = df['taxon_id'].astype(str).str.strip()
    return df


# ---------------------------------------------------------------------------
# Kraken2/Bracken Tier 1 consensus_matrix.tsv (produced by compare_db_results.py)
# ---------------------------------------------------------------------------

def load_consensus_matrix(path):
    """
    consensus_matrix.tsv columns (bin/compare_db_results.py):
      taxon_id (index/first col), taxon_name, <sample>_reads [, <sample>_reads ...]
    Returns (df indexed by str taxon_id, list of sample_ids with a *_reads column).
    """
    df = pd.read_csv(path, sep='\t', dtype=str)
    id_col = df.columns[0]  # written via pandas to_csv(index=True); index name is 'taxon_id'
    df = df.rename(columns={id_col: 'taxon_id'})
    df['taxon_id'] = df['taxon_id'].astype(str).str.strip()

    read_cols = [c for c in df.columns if c.endswith('_reads')]
    for c in read_cols:
        df[c] = pd.to_numeric(df[c], errors='coerce').fillna(0)
    samples = [c[: -len('_reads')] for c in read_cols]

    return df.set_index('taxon_id'), samples


def resolve_target_taxa(target_taxa_str, consensus_df):
    """
    Mirror workflows/blast_verification.nf's get_target_taxa() precedence:
    explicit --target-taxa wins over consensus_matrix-derived taxa. Returns
    (list of taxon_id str, dict taxon_id -> taxon_name). Empty list means
    "no explicit/consensus target list given" — caller falls back to
    whatever PathSeq itself detected.
    """
    if target_taxa_str:
        ids = [t.strip() for t in target_taxa_str.split(',') if t.strip()]
        return ids, {t: f"taxon_{t}" for t in ids}

    if consensus_df is not None and len(consensus_df):
        names = consensus_df['taxon_name'].to_dict() if 'taxon_name' in consensus_df.columns else {}
        return list(consensus_df.index), names

    return [], {}


# ---------------------------------------------------------------------------
# BLAST offshoot lifecycle_inference.tsv (bin/analyze_blast_results.py)
# ---------------------------------------------------------------------------

LIFECYCLE_FILENAME_RE = re.compile(r'^(?P<sample>.+)\.(?P<taxon>\d+)\.lifecycle_inference\.tsv$')


def load_blast_lifecycle(dirpath):
    """
    Discover and parse every {sample}.{taxon_id}.lifecycle_inference.tsv under
    dirpath, at any nesting depth — blast_analyze.nf's real publishDir is
    ${outdir}/blast_verification/${sample}/${taxon_id}/..., not a flat
    directory, so an rglob (not a flat glob) is required to find them from a
    blast_lifecycle_dir pointed at that publishDir root (see
    assets/config_pathseq_template.yaml).

    Returns dict {(sample_id, taxon_id): {phase, confidence, confirmed}}.
    """
    lifecycle = {}
    if not dirpath:
        return lifecycle

    for f in sorted(Path(dirpath).rglob('*.lifecycle_inference.tsv')):
        if not LIFECYCLE_FILENAME_RE.match(f.name):
            continue
        try:
            row = pd.read_csv(f, sep='\t', dtype=str).iloc[0]
        except (IndexError, pd.errors.EmptyDataError):
            continue

        sample_id = str(row.get('sample_id', '')).strip()
        taxon_id  = str(row.get('taxon_id', '')).strip()
        if not sample_id or not taxon_id:
            continue

        lifecycle[(sample_id, taxon_id)] = {
            'blast_taxon_name': row.get('taxon_name', ''),
            'blast_phase':      row.get('phase', ''),
            'blast_confidence': row.get('confidence', ''),
            'blast_confirmed':  str(row.get('identity_confirmed', '')).strip().lower() == 'true',
        }
    return lifecycle


# ---------------------------------------------------------------------------
# Abundance matrix (all taxa PathSeq detected, all samples)
# ---------------------------------------------------------------------------

def build_abundance_matrix(long_df):
    """Rows = taxa, columns = per-sample PathSeq metrics. All taxa, all samples."""
    if long_df.empty:
        return pd.DataFrame(columns=['taxon_id', 'taxon_name', 'rank', 'kingdom', 'taxonomic_path'])

    annotation = (
        long_df.sort_values('sample_id')
        .groupby('taxon_id', as_index=False)
        .agg({'taxon_name': 'first', 'rank': 'first', 'kingdom': 'first', 'taxonomic_path': 'first'})
        .set_index('taxon_id')
    )

    matrix = annotation.copy()
    for sample_id, grp in long_df.groupby('sample_id'):
        g = grp.set_index('taxon_id')
        matrix[f'{sample_id}_reads']              = g['total_reads'].reindex(matrix.index).fillna(0).astype(int)
        matrix[f'{sample_id}_unambiguous_reads']  = g['unambiguous_reads'].reindex(matrix.index).fillna(0).astype(int)
        matrix[f'{sample_id}_score']              = g['abundance_score'].reindex(matrix.index).fillna(0).round(4)
        matrix[f'{sample_id}_score_normalized_pct'] = g['score_normalized_pct'].reindex(matrix.index).fillna(0).round(4)

    read_cols = [c for c in matrix.columns if c.endswith('_reads') and not c.endswith('_unambiguous_reads')]
    matrix['_total'] = matrix[read_cols].sum(axis=1) if read_cols else 0
    matrix = matrix.sort_values('_total', ascending=False).drop(columns='_total')

    return matrix.reset_index()


# ---------------------------------------------------------------------------
# Three-way concordance table
# ---------------------------------------------------------------------------

def build_concordance(long_df, consensus_df, consensus_samples, target_taxa, target_names, lifecycle):
    """
    One row per (sample_id, taxon_id) for the candidate taxa universe:
      candidate_taxa = target_taxa (explicit --target-taxa, or all consensus_matrix
                       taxa if no explicit list) UNION any taxon_id seen in
                       blast_lifecycle_dir filenames. If that union is empty
                       (no --target-taxa, no --consensus-matrix, no
                       --blast-lifecycle-dir), falls back to every taxon PathSeq
                       itself detected, across every sample it detected in —
                       i.e. the concordance table degrades gracefully to a
                       PathSeq-only report rather than being empty.
    """
    pathseq_taxa_by_sample = {
        sample_id: grp.set_index('taxon_id')
        for sample_id, grp in long_df.groupby('sample_id')
    } if not long_df.empty else {}

    all_samples = sorted(set(pathseq_taxa_by_sample) | set(consensus_samples))

    candidate_taxa = set(target_taxa) | {t for (_, t) in lifecycle}
    fallback_used = False
    if not candidate_taxa:
        fallback_used = True
        candidate_taxa = set(long_df['taxon_id'].unique()) if not long_df.empty else set()

    rows = []
    for taxon_id in sorted(candidate_taxa):
        in_consensus = consensus_df is not None and taxon_id in consensus_df.index
        consensus_name = (
            consensus_df.loc[taxon_id, 'taxon_name']
            if in_consensus and 'taxon_name' in (consensus_df.columns if consensus_df is not None else [])
            else None
        )

        for sample_id in (all_samples if all_samples else ['']):
            pathseq_row = pathseq_taxa_by_sample.get(sample_id, pd.DataFrame()).loc[taxon_id] \
                if taxon_id in pathseq_taxa_by_sample.get(sample_id, pd.DataFrame(index=[])).index else None
            pathseq_detected = pathseq_row is not None

            kraken2_reads = None
            if in_consensus and f'{sample_id}_reads' in consensus_df.columns:
                kraken2_reads = float(consensus_df.loc[taxon_id, f'{sample_id}_reads'])
            kraken2_tier1 = bool(in_consensus and (kraken2_reads or 0) > 0)

            bl = lifecycle.get((sample_id, taxon_id))

            taxon_name = (
                (pathseq_row['taxon_name'] if pathseq_detected else None)
                or consensus_name
                or target_names.get(taxon_id)
                or (bl['blast_taxon_name'] if bl else None)
                or f"taxon_{taxon_id}"
            )

            pathseq_positive = bool(pathseq_detected and (pathseq_row['total_reads'] or 0) > 0)
            n_positive = sum([kraken2_tier1, pathseq_positive, bool(bl and bl['blast_confirmed'])])

            rows.append({
                'sample_id':                  sample_id,
                'taxon_id':                   taxon_id,
                'taxon_name':                 taxon_name,
                'in_target_taxa':             not fallback_used,
                # Gated on reads > 0 in *this* sample, not mere presence in
                # consensus_matrix.tsv (a Tier 1 taxon can have 0 reads in a
                # given sample and still be in the file) -- kept consistent
                # with n_methods_positive below.
                'kraken2_tier1_consensus':    kraken2_tier1,
                'kraken2_reads':              kraken2_reads,
                'pathseq_detected':           pathseq_detected,
                'pathseq_reads':              pathseq_row['total_reads'] if pathseq_detected else None,
                'pathseq_unambiguous_reads':  pathseq_row['unambiguous_reads'] if pathseq_detected else None,
                'pathseq_score_normalized_pct': pathseq_row['score_normalized_pct'] if pathseq_detected else None,
                'blast_available':            bl is not None,
                'blast_phase':                bl['blast_phase'] if bl else None,
                'blast_confidence':           bl['blast_confidence'] if bl else None,
                'blast_confirmed':            bl['blast_confirmed'] if bl else None,
                'n_methods_positive':         n_positive,
            })

    cols = ['sample_id', 'taxon_id', 'taxon_name', 'in_target_taxa',
            'kraken2_tier1_consensus', 'kraken2_reads',
            'pathseq_detected', 'pathseq_reads', 'pathseq_unambiguous_reads',
            'pathseq_score_normalized_pct',
            'blast_available', 'blast_phase', 'blast_confidence', 'blast_confirmed',
            'n_methods_positive']
    out = pd.DataFrame(rows, columns=cols)
    if len(out):
        out = out.sort_values(['n_methods_positive', 'taxon_id', 'sample_id'], ascending=[False, True, True])
    return out


# ---------------------------------------------------------------------------
# CLI
# ---------------------------------------------------------------------------

@click.command()
@click.option('--scores', '-i', multiple=True, required=True, type=click.Path(exists=True),
              help='Per-sample PathSeq scores.txt/tsv files (repeatable). Filename must be '
                   '<sample_id>.pathseq_scores.tsv (modules/pathseq_score.nf convention) so '
                   'the sample ID can be recovered.')
@click.option('--consensus-matrix', default=None, type=click.Path(exists=True),
              help='Optional consensus_matrix.tsv (Tier 1 taxa) from a prior dual-DB main '
                   'pipeline run (same file workflows/blast_verification.nf reads).')
@click.option('--target-taxa', default=None,
              help='Optional comma-separated taxon IDs (e.g. "3050292,10298"). Takes '
                   'precedence over --consensus-matrix for defining the concordance-table '
                   'candidate taxa, mirroring workflows/blast_verification.nf get_target_taxa().')
@click.option('--blast-lifecycle-dir', default=None, type=click.Path(exists=True, file_okay=False),
              help='Optional directory (searched recursively) of BLAST offshoot '
                   '<sample>.<taxon_id>.lifecycle_inference.tsv files, for a three-way '
                   'Kraken2/PathSeq/BLAST concordance table.')
@click.option('--outdir', default='.', show_default=True, help='Output directory')
def main(scores, consensus_matrix, target_taxa, blast_lifecycle_dir, outdir):
    outdir_path = Path(outdir)
    outdir_path.mkdir(parents=True, exist_ok=True)

    frames = []
    for f in scores:
        sample_id = sample_id_from_scores_path(f)
        df = parse_pathseq_scores(f)
        df.insert(0, 'sample_id', sample_id)
        frames.append(df)
    long_df = pd.concat(frames, ignore_index=True) if frames else pd.DataFrame()
    print(f"Parsed {len(frames)} sample scores.txt file(s), {len(long_df)} total taxon rows")

    consensus_df, consensus_samples = (None, [])
    if consensus_matrix:
        consensus_df, consensus_samples = load_consensus_matrix(consensus_matrix)
        print(f"Loaded consensus_matrix: {len(consensus_df)} Tier 1 taxa, "
              f"{len(consensus_samples)} sample(s)")

    target_ids, target_names = resolve_target_taxa(target_taxa, consensus_df)
    if target_taxa:
        print(f"Target taxa (explicit --target-taxa): {', '.join(target_ids)}")
    elif target_ids:
        print(f"Target taxa (from consensus_matrix): {len(target_ids)} taxa")

    lifecycle = {}
    if blast_lifecycle_dir:
        lifecycle = load_blast_lifecycle(blast_lifecycle_dir)
        print(f"Loaded {len(lifecycle)} BLAST lifecycle_inference.tsv record(s) from "
              f"{blast_lifecycle_dir}")

    # --- pathseq_abundance_matrix.tsv (all taxa, all samples) ---
    matrix = build_abundance_matrix(long_df)
    matrix_out = outdir_path / 'pathseq_abundance_matrix.tsv'
    matrix.to_csv(matrix_out, sep='\t', index=False)
    n_samples = len(long_df['sample_id'].unique()) if not long_df.empty else 0
    print(f"PathSeq abundance matrix: {len(matrix)} taxa x {n_samples} sample(s) -> {matrix_out}")

    # --- pathseq_concordance.tsv ---
    concordance = build_concordance(long_df, consensus_df, consensus_samples,
                                     target_ids, target_names, lifecycle)
    concordance_out = outdir_path / 'pathseq_concordance.tsv'
    concordance.to_csv(concordance_out, sep='\t', index=False)

    if len(concordance):
        n_all3 = int((concordance['n_methods_positive'] == 3).sum())
        n_pathseq_only = int(((concordance['n_methods_positive'] == 1) & concordance['pathseq_detected']).sum())
        print(f"PathSeq concordance table: {len(concordance)} (sample, taxon) row(s) -> {concordance_out}")
        print(f"  All 3 methods agree (Kraken2 consensus + PathSeq + BLAST confirmed): {n_all3}")
        print(f"  PathSeq-only detections (not in consensus, not BLAST-confirmed): {n_pathseq_only}")
    else:
        print(f"PathSeq concordance table: 0 rows (no target taxa, consensus_matrix, or "
              f"blast_lifecycle_dir taxa to compare against) -> {concordance_out}")


if __name__ == '__main__':
    main()
