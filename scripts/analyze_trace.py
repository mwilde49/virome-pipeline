#!/usr/bin/env python3
"""
analyze_trace.py — Virome pipeline execution trace analyzer

Reads a Nextflow execution_trace.tsv and produces a per-process performance
summary covering memory efficiency, CPU utilization, queue time, wall time,
and I/O throughput. Identifies right-sizing opportunities and bottlenecks.

Usage:
    python3 scripts/analyze_trace.py pipeline_info/execution_trace.tsv
    python3 scripts/analyze_trace.py pipeline_info/execution_trace.tsv --output pipeline_info/trace_summary.tsv
    python3 scripts/analyze_trace.py pipeline_info/execution_trace.tsv --base-config conf/base.config
"""

import sys
import re
import argparse
import statistics
from pathlib import Path


# ---------------------------------------------------------------------------
# Resource requests from base.config — used to compute efficiency ratios.
# Update if base.config changes.
# ---------------------------------------------------------------------------
REQUESTED = {
    'VIROME:FASTQC':               {'cpus':  4, 'memory_gb':   8},
    'VIROME:TRIMMOMATIC':          {'cpus':  8, 'memory_gb':  16},
    'VIROME:STAR_HOST_REMOVAL':    {'cpus': 16, 'memory_gb':  64},
    'VIROME:KRAKEN2_CLASSIFY':     {'cpus': 16, 'memory_gb':  64},
    'VIROME:KRAKEN2_CLASSIFY_DB2': {'cpus': 16, 'memory_gb': 110},
    'VIROME:BRACKEN':              {'cpus':  4, 'memory_gb':  16},
    'VIROME:BRACKEN_DB2':          {'cpus':  4, 'memory_gb':  16},
    'VIROME:KRAKEN2_FILTER':       {'cpus':  2, 'memory_gb':   4},
    'VIROME:KRAKEN2_FILTER_DB2':   {'cpus':  2, 'memory_gb':   4},
    'VIROME:AGGREGATE_BRACKEN':    {'cpus':  2, 'memory_gb':   8},
    'VIROME:AGGREGATE_MINREADS':   {'cpus':  2, 'memory_gb':   8},
    'VIROME:AGGREGATE':            {'cpus':  2, 'memory_gb':   8},
    'VIROME:AGGREGATE_DB2':        {'cpus':  2, 'memory_gb':   8},
    'VIROME:COMPARE_DATABASES':    {'cpus':  2, 'memory_gb':   8},
    'VIROME:MULTIQC':              {'cpus':  2, 'memory_gb':   8},
    'VIROME:REPORT':               {'cpus':  2, 'memory_gb':   8},
}


# ---------------------------------------------------------------------------
# Parsing helpers
# ---------------------------------------------------------------------------

def parse_memory(value):
    """Parse Nextflow memory string (e.g. '12.3 GB', '456 MB', '-') to GB float."""
    if not value or value.strip() in ('-', '0', ''):
        return None
    value = value.strip()
    match = re.match(r'([\d.]+)\s*(KB|MB|GB|TB|B)?', value, re.IGNORECASE)
    if not match:
        return None
    num = float(match.group(1))
    unit = (match.group(2) or 'B').upper()
    return num * {'B': 1e-9, 'KB': 1e-6, 'MB': 1e-3, 'GB': 1.0, 'TB': 1e3}[unit]


def parse_duration(value):
    """Parse Nextflow duration string (e.g. '1h 23m 4s', '2m 30s', '45s', '-') to seconds."""
    if not value or value.strip() in ('-', '0', ''):
        return None
    value = value.strip()
    total = 0.0
    for num, unit in re.findall(r'([\d.]+)\s*([hms])', value):
        total += float(num) * {'h': 3600, 'm': 60, 's': 1}[unit]
    return total if total > 0 else None


def parse_cpu(value):
    """Parse %cpu string (e.g. '1234.5%', '-') to fraction of one core (e.g. 12.3)."""
    if not value or value.strip() in ('-', '0%', ''):
        return None
    match = re.match(r'([\d.]+)%?', value.strip())
    return float(match.group(1)) / 100.0 if match else None


def parse_io(value):
    """Parse I/O string to GB float."""
    return parse_memory(value)


def fmt_duration(seconds):
    if seconds is None:
        return '-'
    h = int(seconds // 3600)
    m = int((seconds % 3600) // 60)
    s = int(seconds % 60)
    if h > 0:
        return f'{h}h {m:02d}m'
    if m > 0:
        return f'{m}m {s:02d}s'
    return f'{s}s'


def fmt_gb(gb):
    if gb is None:
        return '-'
    if gb >= 1.0:
        return f'{gb:.1f} GB'
    return f'{gb * 1000:.0f} MB'


def fmt_pct(ratio):
    if ratio is None:
        return '-'
    return f'{ratio * 100:.0f}%'


def median(values):
    v = [x for x in values if x is not None]
    return statistics.median(v) if v else None


def maximum(values):
    v = [x for x in values if x is not None]
    return max(v) if v else None


def minimum(values):
    v = [x for x in values if x is not None]
    return min(v) if v else None


# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

def load_trace(path):
    rows = []
    with open(path) as f:
        header = None
        for line in f:
            line = line.rstrip('\n')
            if not line:
                continue
            fields = line.split('\t')
            if header is None:
                header = fields
                continue
            row = dict(zip(header, fields))
            rows.append(row)
    return rows


def analyze(rows):
    """Group completed tasks by process name and compute per-process stats."""
    by_process = {}
    skipped = 0

    for row in rows:
        status = row.get('status', '').upper()
        if status not in ('COMPLETED', 'CACHED'):
            skipped += 1
            continue

        process = row.get('process', 'UNKNOWN')
        # Normalize: strip any module path prefix if present
        if ':' in process:
            process = process  # keep full qualified name e.g. VIROME:FASTQC

        by_process.setdefault(process, []).append(row)

    return by_process, skipped


def summarize_process(process, task_rows):
    n = len(task_rows)

    peak_rss   = [parse_memory(r.get('peak_rss', ''))   for r in task_rows]
    realtime   = [parse_duration(r.get('realtime', '')) for r in task_rows]
    duration   = [parse_duration(r.get('duration', '')) for r in task_rows]
    cpu_frac   = [parse_cpu(r.get('%cpu', ''))          for r in task_rows]
    rchar      = [parse_io(r.get('rchar', ''))          for r in task_rows]
    wchar      = [parse_io(r.get('wchar', ''))          for r in task_rows]

    # Queue time = duration - realtime (time waiting in SLURM queue)
    queue_time = []
    for dur, rt in zip(duration, realtime):
        if dur is not None and rt is not None and dur >= rt:
            queue_time.append(dur - rt)
        else:
            queue_time.append(None)

    req = REQUESTED.get(process, {})
    req_mem_gb = req.get('memory_gb')
    req_cpus   = req.get('cpus')

    max_rss = maximum(peak_rss)
    mem_efficiency = (max_rss / req_mem_gb) if (max_rss and req_mem_gb) else None

    median_cpu_frac = median(cpu_frac)
    cpu_efficiency = (median_cpu_frac / req_cpus) if (median_cpu_frac and req_cpus) else None

    return {
        'process':          process,
        'n':                n,
        'req_mem_gb':       req_mem_gb,
        'req_cpus':         req_cpus,
        'median_realtime':  median(realtime),
        'max_realtime':     maximum(realtime),
        'median_queue':     median(queue_time),
        'max_queue':        maximum(queue_time),
        'median_peak_rss':  median(peak_rss),
        'max_peak_rss':     max_rss,
        'mem_efficiency':   mem_efficiency,
        'median_cpu_cores': median_cpu_frac,
        'cpu_efficiency':   cpu_efficiency,
        'median_rchar_gb':  median(rchar),
        'median_wchar_gb':  median(wchar),
    }


def flag_issues(s):
    flags = []
    if s['mem_efficiency'] is not None:
        if s['mem_efficiency'] < 0.25:
            flags.append(f"OVER-ALLOCATED memory (using {fmt_pct(s['mem_efficiency'])} of request)")
        elif s['mem_efficiency'] > 0.90:
            flags.append(f"NEAR memory limit ({fmt_pct(s['mem_efficiency'])} used — risk of OOM retry)")
    if s['cpu_efficiency'] is not None and s['cpu_efficiency'] < 0.40:
        flags.append(f"LOW CPU utilization ({fmt_pct(s['cpu_efficiency'])} of allocated cores)")
    if s['median_queue'] is not None and s['median_queue'] > 1800:
        flags.append(f"HIGH queue wait time (median {fmt_duration(s['median_queue'])})")
    return flags


def print_report(summaries, file=sys.stdout):
    def w(line=''):
        print(line, file=file)

    w('=' * 80)
    w('  Virome Pipeline — Execution Trace Analysis')
    w('=' * 80)
    w()

    # Sort by pipeline order approximation
    order = list(REQUESTED.keys())
    summaries.sort(key=lambda s: order.index(s['process']) if s['process'] in order else 99)

    all_flags = []

    for s in summaries:
        w(f"── {s['process']}  (n={s['n']}) " + '─' * max(0, 60 - len(s['process'])))

        req_mem_str  = f"{s['req_mem_gb']} GB"  if s['req_mem_gb']  else '?'
        req_cpu_str  = f"{s['req_cpus']} cores" if s['req_cpus']    else '?'

        w(f"  Requested:      {req_mem_str} RAM,  {req_cpu_str}")
        w(f"  Wall time:      median {fmt_duration(s['median_realtime'])}   max {fmt_duration(s['max_realtime'])}")
        w(f"  Queue wait:     median {fmt_duration(s['median_queue'])}   max {fmt_duration(s['max_queue'])}")
        w(f"  Peak memory:    median {fmt_gb(s['median_peak_rss'])}   max {fmt_gb(s['max_peak_rss'])}   "
          f"(efficiency: {fmt_pct(s['mem_efficiency'])} of request)")
        w(f"  CPU usage:      median {s['median_cpu_cores']:.1f} cores ({fmt_pct(s['cpu_efficiency'])} of allocated)"
          if s['median_cpu_cores'] else "  CPU usage:      -")
        w(f"  I/O read:       median {fmt_gb(s['median_rchar_gb'])}/task")
        w(f"  I/O write:      median {fmt_gb(s['median_wchar_gb'])}/task")

        flags = flag_issues(s)
        if flags:
            for f in flags:
                w(f"  ⚠  {f}")
            all_flags.append((s['process'], flags))

        w()

    # Right-sizing recommendations
    w('=' * 80)
    w('  Right-sizing recommendations')
    w('=' * 80)
    w()

    has_rec = False
    for s in summaries:
        max_rss = s['max_peak_rss']
        req_mem = s['req_mem_gb']
        if max_rss and req_mem:
            # Recommend 25% headroom above observed max
            recommended = max_rss * 1.25
            if recommended < req_mem * 0.70:  # at least 30% savings to bother
                saving_pct = (1 - recommended / req_mem) * 100
                w(f"  {s['process']}")
                w(f"    Current:     {req_mem} GB")
                w(f"    Observed max: {fmt_gb(max_rss)}  →  recommended: {recommended:.0f} GB  "
                  f"(saves ~{saving_pct:.0f}% — faster queue times on Juno)")
                w()
                has_rec = True

    if not has_rec:
        w('  No significant over-allocation detected.')
        w()

    # Flag summary
    if all_flags:
        w('=' * 80)
        w('  Issues flagged')
        w('=' * 80)
        w()
        for process, flags in all_flags:
            w(f"  {process}")
            for f in flags:
                w(f"    • {f}")
        w()


def write_tsv(summaries, path):
    cols = [
        'process', 'n',
        'req_mem_gb', 'req_cpus',
        'median_realtime_s', 'max_realtime_s',
        'median_queue_s', 'max_queue_s',
        'median_peak_rss_gb', 'max_peak_rss_gb',
        'mem_efficiency_pct',
        'median_cpu_cores', 'cpu_efficiency_pct',
        'median_rchar_gb', 'median_wchar_gb',
    ]
    with open(path, 'w') as f:
        f.write('\t'.join(cols) + '\n')
        for s in summaries:
            row = [
                s['process'],
                s['n'],
                s['req_mem_gb']       or '',
                s['req_cpus']         or '',
                round(s['median_realtime'],  1) if s['median_realtime']  else '',
                round(s['max_realtime'],     1) if s['max_realtime']     else '',
                round(s['median_queue'],     1) if s['median_queue']     else '',
                round(s['max_queue'],        1) if s['max_queue']        else '',
                round(s['median_peak_rss'],  2) if s['median_peak_rss']  else '',
                round(s['max_peak_rss'],     2) if s['max_peak_rss']     else '',
                round(s['mem_efficiency'] * 100, 1) if s['mem_efficiency'] else '',
                round(s['median_cpu_cores'], 2) if s['median_cpu_cores'] else '',
                round(s['cpu_efficiency'] * 100, 1) if s['cpu_efficiency'] else '',
                round(s['median_rchar_gb'],  2) if s['median_rchar_gb']  else '',
                round(s['median_wchar_gb'],  2) if s['median_wchar_gb']  else '',
            ]
            f.write('\t'.join(str(x) for x in row) + '\n')


def main():
    parser = argparse.ArgumentParser(description='Analyze Nextflow execution trace')
    parser.add_argument('trace', help='Path to execution_trace.tsv')
    parser.add_argument('--output', '-o', help='Write machine-readable TSV summary to this path')
    args = parser.parse_args()

    trace_path = Path(args.trace)
    if not trace_path.exists():
        print(f'Error: trace file not found: {trace_path}', file=sys.stderr)
        sys.exit(1)

    rows = load_trace(trace_path)
    by_process, skipped = analyze(rows)

    if skipped:
        print(f'Note: {skipped} task(s) with non-COMPLETED/CACHED status excluded from analysis.',
              file=sys.stderr)

    summaries = [summarize_process(proc, tasks) for proc, tasks in by_process.items()]

    print_report(summaries)

    if args.output:
        write_tsv(summaries, args.output)
        print(f'Machine-readable summary written to: {args.output}')


if __name__ == '__main__':
    main()
