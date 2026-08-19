#!/usr/bin/env python3
"""
extract_kraken2_reads.py

Given a Kraken2 per-read output file and one or more target taxon IDs, extract
the corresponding read IDs and write a seqtk-ready ID list.  The module then
calls seqtk to pull those reads from the host-removed FASTQ pair.

Kraken2 --output format (tab-separated):
  col 1: C / U   (classified / unclassified)
  col 2: read_id
  col 3: taxon_id  (0 if unclassified)
  col 4: read_len  ("len1|len2" for paired)
  col 5: k-mer hit string

Default target taxa: a comma-separated list passed via --taxon-ids.
Optionally also capture reads assigned to parent taxa (--include-genus).

Outputs:
  {sample_id}.{taxon_id}.read_ids.txt   — one read ID per line (for seqtk)
  {sample_id}.{taxon_id}.stats.tsv      — extraction statistics
"""

import sys
import click
from pathlib import Path
from collections import defaultdict


def parse_kmer_string(kmer_str, target_ids):
    """
    Scan the k-mer hit string for evidence of target_ids.
    Returns True if any taxon token in the k-mer string is in target_ids.

    Format: "taxon:count taxon:count ..." where taxon is a taxon_id or '|:|'
    (read boundary marker in paired mode).
    """
    for token in kmer_str.split():
        if ':' in token:
            tid_str = token.split(':')[0]
            if tid_str.lstrip('-').isdigit():
                if int(tid_str) in target_ids:
                    return True
    return False


@click.command()
@click.option('--kraken2-output', required=True, type=click.Path(exists=True),
              help='Kraken2 per-read output file ({id}.kraken2.output)')
@click.option('--taxon-ids', required=True,
              help='Comma-separated target taxon IDs (e.g. "3050292,10298")')
@click.option('--sample-id', required=True,
              help='Sample identifier for output file naming')
@click.option('--include-genus', is_flag=True, default=False,
              help='Also capture reads where any k-mer in the hit string matches a target taxon (broader, more sensitive)')
@click.option('--outdir', default='.', show_default=True,
              help='Output directory')
def main(kraken2_output, taxon_ids, sample_id, include_genus, outdir):
    target_ids = set()
    for t in taxon_ids.split(','):
        t = t.strip()
        if t.isdigit():
            target_ids.add(int(t))

    if not target_ids:
        print(f"ERROR: no valid integer taxon IDs parsed from: {taxon_ids}", file=sys.stderr)
        sys.exit(1)

    outdir_path = Path(outdir)
    outdir_path.mkdir(parents=True, exist_ok=True)

    # Group output by taxon so each taxon gets its own read list
    reads_by_taxon = defaultdict(set)
    total_classified = 0
    total_reads = 0

    with open(kraken2_output) as fh:
        for line in fh:
            line = line.rstrip('\n')
            if not line:
                continue
            parts = line.split('\t')
            if len(parts) < 4:
                continue

            total_reads += 1
            status = parts[0]  # C or U
            read_id = parts[1]
            try:
                taxon_id = int(parts[2])
            except ValueError:
                continue

            if status == 'C':
                total_classified += 1

            if taxon_id in target_ids:
                reads_by_taxon[taxon_id].add(read_id)
            elif include_genus and len(parts) >= 5:
                kmer_str = parts[4]
                if parse_kmer_string(kmer_str, target_ids):
                    # assign to first matching target taxon in kmer string
                    for token in kmer_str.split():
                        if ':' in token:
                            tid_str = token.split(':')[0]
                            if tid_str.lstrip('-').isdigit():
                                tid = int(tid_str)
                                if tid in target_ids:
                                    reads_by_taxon[tid].add(read_id)
                                    break

    # Write outputs per taxon
    stats_rows = []
    all_read_ids = set()

    for taxon_id, read_ids in reads_by_taxon.items():
        id_file = outdir_path / f"{sample_id}.{taxon_id}.read_ids.txt"
        with open(id_file, 'w') as fh:
            for rid in sorted(read_ids):
                fh.write(rid + '\n')
        all_read_ids |= read_ids
        stats_rows.append((taxon_id, len(read_ids), str(id_file)))
        print(f"  taxon {taxon_id}: {len(read_ids)} read pairs extracted → {id_file}")

    # Combined ID list (all target taxa together for seqtk)
    combined_file = outdir_path / f"{sample_id}.combined.read_ids.txt"
    with open(combined_file, 'w') as fh:
        for rid in sorted(all_read_ids):
            fh.write(rid + '\n')

    # Stats file
    stats_file = outdir_path / f"{sample_id}.extraction_stats.tsv"
    with open(stats_file, 'w') as fh:
        fh.write("sample_id\ttaxon_id\treads_extracted\ttotal_reads\ttotal_classified\tpct_of_classified\n")
        for taxon_id, n, _ in stats_rows:
            pct = 100.0 * n / total_classified if total_classified > 0 else 0.0
            fh.write(f"{sample_id}\t{taxon_id}\t{n}\t{total_reads}\t{total_classified}\t{pct:.4f}\n")

    print(f"\nTotal reads extracted (all taxa): {len(all_read_ids)} / {total_reads} total ({total_classified} classified)")
    print(f"Stats: {stats_file}")
    print(f"Combined IDs: {combined_file}")


if __name__ == '__main__':
    main()
