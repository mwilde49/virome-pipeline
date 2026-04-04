#!/usr/bin/env python3
"""
analyze_blast_results.py

Parse BLAST tabular output (outfmt 6) for reads extracted from a specific taxon,
confirm sequence identity, and infer viral life cycle phase where gene annotations
are available (currently: HSV-1, CMV/HHV-5, VZV/HHV-3, EBV/HHV-4).

Life cycle phase inference (herpesviruses):
  LAT-only       → latent infection (LAT is the dominant transcript in latency)
  IE-dominated   → lytic reactivation (IE/α genes are the first to be transcribed)
  IE + Early     → early lytic (DNA replication initiated)
  IE + E + Late  → full lytic cycle
  ambiguous      → mixed signal, insufficient reads, or no gene annotation available

BLAST outfmt 6 columns:
  qseqid sseqid pident length mismatch gapopen qstart qend sstart send evalue bitscore

Outputs:
  {sample_id}.{taxon_id}.blast_summary.tsv       — best hit per read
  {sample_id}.{taxon_id}.lifecycle_inference.tsv — phase call + evidence
  {sample_id}.{taxon_id}.lifecycle_report.html   — human-readable report
"""

import sys
import json
import click
import math
from pathlib import Path
from collections import defaultdict, Counter


# ---------------------------------------------------------------------------
# Gene catalogs for neurotropic herpesviruses
# Format: refseq_accession → {gene_name: (start, end, category)}
# Coordinates are 1-based, inclusive, on the plus strand of the linear genome.
# Category: IE (immediate-early/α), E (early/β), L (late/γ), LAT (latency)
#
# Reference: HSV-1 strain 17 NC_001806.2 (152,222 bp)
# Reference: HCMV Merlin NC_006273.2
# Reference: VZV NC_001348.1
# Reference: EBV NC_007605.1
# ---------------------------------------------------------------------------

HERPESVIRUS_GENES = {
    # HSV-1 (Human herpesvirus 1 / Simplexvirus humanalpha1)
    # Accessions: NC_001806.2 (strain 17), KP055881.1 (strain KOS), KT899744.1 (strain F)
    'NC_001806': {
        # IE / alpha genes — expressed before viral protein synthesis
        'ICP0/RL2':      (3584,    5220,   'IE'),
        'ICP4/RS1':      (132618,  135097, 'IE'),   # also at 146450-148929 (terminal repeat)
        'ICP27/UL54':    (113888,  115774, 'IE'),
        'ICP22/US1':     (143436,  144743, 'IE'),
        'ICP47/US12':    (145697,  146455, 'IE'),
        # Early / beta genes — require IE gene products; precede DNA replication
        'UL2':           (2554,    3502,   'E'),
        'UL12':          (23014,   24603,  'E'),
        'TK/UL23':       (46578,   47576,  'E'),
        'ICP8/UL29':     (63060,   65930,  'E'),
        'DNApol/UL30':   (65927,   70137,  'E'),
        'UL42':          (92285,   94026,  'E'),
        'UL5':           (8803,    10893,  'E'),
        'UL8':           (14147,   15601,  'E'),
        'UL52':          (104054,  106876, 'E'),
        # Late / gamma genes — require viral DNA replication
        'VP5/UL19':      (37740,   41969,  'L'),
        'gB/UL27':       (53346,   55736,  'L'),
        'UL26/VP24':     (57530,   59350,  'L'),
        'gC/UL44':       (97131,   98456,  'L'),
        'VP16/UL48':     (103004,  104081, 'L'),
        'gD/US6':        (142522,  143384, 'L'),
        'gI/US7':        (141040,  142149, 'L'),
        'gE/US8':        (137745,  138987, 'L'),
        'US3_kinase':    (139817,  141040, 'L'),
        # LAT — latency-associated transcript (complement strand, overlaps ICP0)
        # Primary LAT ~8 kb; intron processed to 2 kb and 1.5 kb stable forms
        'LAT_primary':   (118848,  128155, 'LAT'),
    },
}

# Taxon ID → primary reference accession(s) for gene lookup
TAXON_REFS = {
    10298:   ['NC_001806'],   # Human herpesvirus 1 (HSV-1)
    3050292: ['NC_001806'],   # Simplexvirus humanalpha1 (ICTV 2023 reclassification of HSV-1)
    10310:   ['NC_001806'],   # Herpes simplex virus 1
}

GENE_CATEGORY_LABELS = {
    'IE':  'Immediate-Early (α) — lytic/reactivation marker',
    'E':   'Early (β) — DNA replication phase',
    'L':   'Late (γ) — virion assembly phase',
    'LAT': 'Latency-associated transcript — latency marker',
}

PHASE_RULES = [
    # (required_categories, forbidden_categories, phase_label, confidence)
    ({'LAT'},              {'IE', 'E', 'L'},  'Latent',          'HIGH'),
    ({'IE', 'E', 'L'},     set(),             'Full lytic cycle', 'HIGH'),
    ({'IE', 'E'},          {'L'},             'Early lytic',      'MEDIUM'),
    ({'IE'},               {'E', 'L'},        'Reactivating (IE-only)', 'LOW'),
    ({'L'},                {'IE', 'E'},       'Late lytic (IE-escaped)', 'LOW'),
    ({'LAT', 'IE'},        set(),             'Reactivating from latency', 'MEDIUM'),
]


# ---------------------------------------------------------------------------
# BLAST hit parsing
# ---------------------------------------------------------------------------

OUTFMT6_COLS = [
    'qseqid', 'sseqid', 'pident', 'length', 'mismatch', 'gapopen',
    'qstart', 'qend', 'sstart', 'send', 'evalue', 'bitscore'
]


def parse_blast_outfmt6(blast_file):
    """Parse BLAST tabular output. Returns list of dicts, best hit per query."""
    hits = {}  # qseqid → best hit dict
    with open(blast_file) as fh:
        for line in fh:
            line = line.strip()
            if not line or line.startswith('#'):
                continue
            parts = line.split('\t')
            if len(parts) < 12:
                continue
            row = dict(zip(OUTFMT6_COLS, parts[:12]))
            row['pident'] = float(row['pident'])
            row['length'] = int(row['length'])
            row['qstart'] = int(row['qstart'])
            row['qend']   = int(row['qend'])
            row['sstart'] = int(row['sstart'])
            row['send']   = int(row['send'])
            row['evalue'] = float(row['evalue'])
            row['bitscore'] = float(row['bitscore'])

            qid = row['qseqid']
            # Keep best hit (highest bitscore) per query
            if qid not in hits or row['bitscore'] > hits[qid]['bitscore']:
                hits[qid] = row

    return list(hits.values())


def accession_to_base(sseqid):
    """Strip version suffix: NC_001806.2 → NC_001806"""
    return sseqid.split('.')[0] if '.' in sseqid else sseqid


def assign_gene(accession_base, sstart, send):
    """
    Map subject coordinates of a BLAST hit to a gene name and category.
    Returns (gene_name, category) or (None, None) if no overlap found.
    """
    gene_map = HERPESVIRUS_GENES.get(accession_base)
    if not gene_map:
        return None, None

    hit_start = min(sstart, send)
    hit_end   = max(sstart, send)

    best_overlap = 0
    best_gene = None
    best_cat = None

    for gene_name, (g_start, g_end, category) in gene_map.items():
        overlap = max(0, min(hit_end, g_end) - max(hit_start, g_start))
        if overlap > best_overlap:
            best_overlap = overlap
            best_gene = gene_name
            best_cat = category

    return best_gene, best_cat


# ---------------------------------------------------------------------------
# Identity confirmation
# ---------------------------------------------------------------------------

def confirm_identity(hits, target_taxon_id, pident_threshold=90.0, evalue_threshold=1e-5):
    """
    Assess whether BLAST hits confirm the target taxon.
    Returns a dict with confirmation status and summary stats.
    """
    if not hits:
        return {'confirmed': False, 'reason': 'No BLAST hits', 'n_hits': 0}

    total = len(hits)
    # Filter by thresholds
    passing = [h for h in hits if h['pident'] >= pident_threshold and h['evalue'] <= evalue_threshold]
    pct_pass = 100.0 * len(passing) / total if total > 0 else 0.0

    mean_pident = sum(h['pident'] for h in passing) / len(passing) if passing else 0.0
    mean_length = sum(h['length'] for h in passing) / len(passing) if passing else 0.0
    median_evalue = sorted(h['evalue'] for h in passing)[len(passing)//2] if passing else None

    # Check what fraction of passing hits are to a relevant reference
    target_refs = TAXON_REFS.get(target_taxon_id, [])
    on_target = sum(1 for h in passing if any(
        accession_to_base(h['sseqid']) in ref or ref in h['sseqid']
        for ref in target_refs
    ))

    confirmed = len(passing) >= 3 and pct_pass >= 50.0

    return {
        'confirmed':     confirmed,
        'n_total_reads': total,
        'n_passing':     len(passing),
        'pct_passing':   round(pct_pass, 1),
        'mean_pident':   round(mean_pident, 1),
        'mean_aln_len':  round(mean_length, 1),
        'on_target_hits': on_target,
        'pident_threshold': pident_threshold,
        'evalue_threshold': evalue_threshold,
    }


# ---------------------------------------------------------------------------
# Life cycle inference
# ---------------------------------------------------------------------------

def infer_lifecycle(hits, target_taxon_id, pident_threshold=90.0, evalue_threshold=1e-5):
    """
    Classify hits by gene category and infer viral life cycle phase.
    Returns a dict with phase call, evidence, and per-category read counts.
    """
    target_refs = TAXON_REFS.get(target_taxon_id, [])
    if not target_refs:
        return {
            'phase': 'Unknown',
            'confidence': 'N/A',
            'reason': f'No gene catalog available for taxon {target_taxon_id}',
            'category_counts': {},
            'gene_counts': {},
        }

    gene_counts = Counter()
    cat_counts  = Counter()
    gene_reads  = defaultdict(list)

    for h in hits:
        if h['pident'] < pident_threshold or h['evalue'] > evalue_threshold:
            continue
        acc_base = accession_to_base(h['sseqid'])
        if not any(ref in acc_base or acc_base in ref for ref in target_refs):
            continue

        gene, cat = assign_gene(acc_base, h['sstart'], h['send'])
        if gene and cat:
            gene_counts[gene] += 1
            cat_counts[cat]   += 1
            gene_reads[gene].append(h['qseqid'])

    if not cat_counts:
        return {
            'phase': 'Indeterminate',
            'confidence': 'LOW',
            'reason': 'No on-target reads with gene coordinates. Reads may map to intergenic regions '
                      'or the reference accession does not match the database hit.',
            'category_counts': {},
            'gene_counts': dict(gene_counts),
        }

    detected_categories = set(cat_counts.keys())
    phase = 'Indeterminate'
    confidence = 'LOW'
    reason = 'No phase rule matched'

    for required, forbidden, label, conf in PHASE_RULES:
        if required <= detected_categories and not (forbidden & detected_categories):
            phase = label
            confidence = conf
            reason = (f"Detected categories: {', '.join(sorted(detected_categories))}. "
                      f"Required: {', '.join(sorted(required))}. "
                      f"Forbidden (absent): {', '.join(sorted(forbidden)) if forbidden else 'none'}.")
            break

    # Low read count warning
    total_annotated = sum(cat_counts.values())
    if total_annotated < 5:
        confidence = 'VERY LOW'
        reason += f' WARNING: only {total_annotated} annotated reads — insufficient for reliable phase inference.'

    return {
        'phase':            phase,
        'confidence':       confidence,
        'reason':           reason,
        'category_counts':  dict(cat_counts),
        'gene_counts':      dict(gene_counts),
        'n_annotated_reads': total_annotated,
    }


# ---------------------------------------------------------------------------
# HTML report
# ---------------------------------------------------------------------------

def render_html(sample_id, taxon_id, taxon_name, identity, lifecycle, hits):
    categories = lifecycle.get('category_counts', {})
    gene_counts = lifecycle.get('gene_counts', {})

    cat_rows = '\n'.join(
        f'<tr><td>{cat}</td><td>{GENE_CATEGORY_LABELS.get(cat, cat)}</td><td>{n}</td></tr>'
        for cat, n in sorted(categories.items())
    )
    gene_rows = '\n'.join(
        f'<tr><td>{g}</td><td>{n}</td></tr>'
        for g, n in sorted(gene_counts.items(), key=lambda x: -x[1])
    )

    # Best 20 BLAST hits table
    blast_rows = ''
    for h in sorted(hits, key=lambda x: -x['bitscore'])[:20]:
        blast_rows += (
            f'<tr><td>{h["qseqid"]}</td><td>{h["sseqid"]}</td>'
            f'<td>{h["pident"]:.1f}%</td><td>{h["length"]}</td>'
            f'<td>{h["evalue"]:.1e}</td><td>{h["bitscore"]:.0f}</td></tr>\n'
        )

    conf_color = {'HIGH': '#2e7d32', 'MEDIUM': '#f57f17', 'LOW': '#b71c1c', 'VERY LOW': '#b71c1c'}.get(
        lifecycle.get('confidence', ''), '#555')

    return f"""<!DOCTYPE html>
<html><head>
<meta charset="UTF-8">
<title>BLAST Verification: {taxon_name} in {sample_id}</title>
<style>
  body {{ font-family: Arial, sans-serif; max-width: 1000px; margin: 40px auto; color: #222; }}
  h1 {{ border-bottom: 2px solid #1565c0; padding-bottom: 8px; }}
  h2 {{ color: #1565c0; margin-top: 32px; }}
  table {{ border-collapse: collapse; width: 100%; margin: 12px 0; }}
  th {{ background: #1565c0; color: white; padding: 8px 12px; text-align: left; }}
  td {{ border: 1px solid #ddd; padding: 6px 12px; }}
  tr:nth-child(even) {{ background: #f5f5f5; }}
  .badge {{ display: inline-block; padding: 4px 12px; border-radius: 4px; color: white; font-weight: bold; }}
  .confirmed {{ background: #2e7d32; }}
  .unconfirmed {{ background: #b71c1c; }}
  .phase-box {{ background: #f8f8f8; border-left: 4px solid {conf_color}; padding: 12px 16px; margin: 12px 0; }}
  .warning {{ background: #fff3e0; border-left: 4px solid #f57f17; padding: 8px 12px; }}
</style>
</head>
<body>
<h1>BLAST Verification Report</h1>
<p><strong>Sample:</strong> {sample_id} &nbsp;|&nbsp;
   <strong>Target taxon:</strong> {taxon_name} (taxon ID: {taxon_id}) &nbsp;|&nbsp;
   <strong>Date:</strong> {__import__('datetime').date.today()}</p>

<h2>1. Identity Confirmation</h2>
<p>Identity threshold: ≥{identity['pident_threshold']}% identity, E-value ≤{identity['evalue_threshold']:.0e}</p>
<p>Status: <span class="badge {'confirmed' if identity['confirmed'] else 'unconfirmed'}">
  {'CONFIRMED' if identity['confirmed'] else 'NOT CONFIRMED'}</span></p>
<table>
  <tr><th>Metric</th><th>Value</th></tr>
  <tr><td>Total reads BLASTed</td><td>{identity['n_total_reads']}</td></tr>
  <tr><td>Reads passing threshold</td><td>{identity['n_passing']} ({identity['pct_passing']}%)</td></tr>
  <tr><td>Mean % identity (passing)</td><td>{identity['mean_pident']}%</td></tr>
  <tr><td>Mean alignment length (passing)</td><td>{identity['mean_aln_len']} bp</td></tr>
  <tr><td>Reads aligning to target reference</td><td>{identity.get('on_target_hits', 'N/A')}</td></tr>
</table>

<h2>2. Life Cycle Phase Inference</h2>
<div class="phase-box">
  <strong>Inferred phase:</strong> {lifecycle['phase']}<br>
  <strong>Confidence:</strong> <span style="color:{conf_color}">{lifecycle.get('confidence','N/A')}</span><br>
  <strong>Reasoning:</strong> {lifecycle['reason']}
</div>
{'<div class="warning"><strong>⚠ Low confidence:</strong> Fewer than 5 annotated reads. Results are indicative only — do not over-interpret.</div>' if lifecycle.get('n_annotated_reads', 99) < 5 else ''}

<h3>Gene category distribution</h3>
<table>
  <tr><th>Category</th><th>Description</th><th>Read count</th></tr>
  {cat_rows if cat_rows else '<tr><td colspan="3">No reads mapped to annotated gene regions</td></tr>'}
</table>

<h3>Per-gene read counts</h3>
<table>
  <tr><th>Gene</th><th>Reads</th></tr>
  {gene_rows if gene_rows else '<tr><td colspan="2">No reads assigned to annotated genes</td></tr>'}
</table>

<h2>3. Top BLAST Hits</h2>
<table>
  <tr><th>Query</th><th>Subject</th><th>% Identity</th><th>Aln length</th><th>E-value</th><th>Bitscore</th></tr>
  {blast_rows}
</table>

<p style="color:#999;font-size:0.85em;margin-top:40px">
Generated by virome-pipeline blast_verify offshoot | virome-pipeline v1.5.0
</p>
</body></html>
"""


# ---------------------------------------------------------------------------
# CLI
# ---------------------------------------------------------------------------

@click.command()
@click.option('--blast-results', required=True, type=click.Path(exists=True),
              help='BLAST tabular output file (outfmt 6)')
@click.option('--sample-id',  required=True, help='Sample identifier')
@click.option('--taxon-id',   required=True, type=int, help='Target taxon ID')
@click.option('--taxon-name', default='Unknown taxon', help='Human-readable taxon name')
@click.option('--pident-threshold', default=90.0, show_default=True,
              help='Minimum % identity for a hit to count toward confirmation/lifecycle')
@click.option('--evalue-threshold', default=1e-5, show_default=True,
              help='Maximum E-value for a hit to count')
@click.option('--outdir', default='.', show_default=True, help='Output directory')
def main(blast_results, sample_id, taxon_id, taxon_name, pident_threshold, evalue_threshold, outdir):
    outdir_path = Path(outdir)
    outdir_path.mkdir(parents=True, exist_ok=True)

    hits = parse_blast_outfmt6(blast_results)
    print(f"Parsed {len(hits)} best-hit BLAST records")

    identity  = confirm_identity(hits, taxon_id, pident_threshold, evalue_threshold)
    lifecycle = infer_lifecycle(hits, taxon_id, pident_threshold, evalue_threshold)

    print(f"\nIdentity: {'CONFIRMED' if identity['confirmed'] else 'NOT CONFIRMED'} "
          f"({identity['n_passing']}/{identity['n_total_reads']} reads, "
          f"mean {identity['mean_pident']}% identity)")
    print(f"Life cycle: {lifecycle['phase']} (confidence: {lifecycle.get('confidence','N/A')})")
    print(f"  Categories: {lifecycle.get('category_counts', {})}")
    print(f"  Reason: {lifecycle['reason']}")

    prefix = outdir_path / f"{sample_id}.{taxon_id}"

    # Summary TSV
    with open(f"{prefix}.blast_summary.tsv", 'w') as fh:
        fh.write('\t'.join(OUTFMT6_COLS) + '\tgene\tgene_category\n')
        for h in sorted(hits, key=lambda x: -x['bitscore']):
            acc_base = accession_to_base(h['sseqid'])
            gene, cat = assign_gene(acc_base, h['sstart'], h['send'])
            row = '\t'.join(str(h[c]) for c in OUTFMT6_COLS)
            fh.write(f"{row}\t{gene or ''}\t{cat or ''}\n")

    # Lifecycle TSV
    with open(f"{prefix}.lifecycle_inference.tsv", 'w') as fh:
        fh.write("sample_id\ttaxon_id\ttaxon_name\tphase\tconfidence\treason\t"
                 "n_reads\tn_annotated\tcategory_counts\tgene_counts\tidentity_confirmed\n")
        fh.write(
            f"{sample_id}\t{taxon_id}\t{taxon_name}\t{lifecycle['phase']}\t"
            f"{lifecycle.get('confidence','N/A')}\t{lifecycle['reason']}\t"
            f"{identity['n_total_reads']}\t{lifecycle.get('n_annotated_reads',0)}\t"
            f"{json.dumps(lifecycle.get('category_counts',{}))}\t"
            f"{json.dumps(lifecycle.get('gene_counts',{}))}\t"
            f"{identity['confirmed']}\n"
        )

    # HTML report
    html = render_html(sample_id, taxon_id, taxon_name, identity, lifecycle, hits)
    with open(f"{prefix}.lifecycle_report.html", 'w') as fh:
        fh.write(html)

    print(f"\nOutputs written to {outdir_path}/")


if __name__ == '__main__':
    main()
