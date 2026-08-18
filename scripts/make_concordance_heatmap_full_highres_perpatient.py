#!/usr/bin/env python3
"""
Kraken2 vs PathSeq concordance heatmap -- FULL HIGH-RES, PER-PATIENT variant.

Same 5 cohort-groups and same 11-taxon taxonomic-lineage row structure as
make_concordance_heatmap_full_highres.py, but each cohort's Kraken2/PathSeq
column-pair is no longer summed across its samples -- it's split into one
Kraken2/PathSeq pair PER SAMPLE, using the real per-sample values that were
already sitting in K2_RAW/PS_RAW's per-taxon lists all along (this script
adds zero new data-gathering; it's a pure re-slice of already-verified
numbers). Column headers now have three tiers instead of two: cohort name
(outer) > sample label (inner) > method name (PathSeq/Kraken2, adjacent to
the data). Thick dividers mark cohort boundaries; thin "minor" dividers mark
sample boundaries within a cohort, per explicit request.

Per-sample order (index-aligned with every taxon list in K2_RAW/PS_RAW),
each independently verified, not assumed:
  cmv:      12h, 24h, 48h, 72h -- sequential hpi order established throughout
            this project (SRR5660016-19); raw-read totals rise then fall
            across this exact order, matching the documented RPM kinetics.
  tg:       TG3, TG4, TG5, TG6, TG7 -- confirmed via direct ENA filereport
            lookup during the 2026-08-17 literature-verification pass
            (ERR2182863=TG3 ... ERR2182867=TG7, sequential); independently
            triangulated against this script's own K2_RAW/PS_RAW values --
            the VZV list's max sits at index 1 and min at index 2, matching
            the documented "TG4 highest VZV / TG5 lowest VZV" finding only
            under this exact ordering.
  ebv:      Rep 1, Rep 2 -- SRR3192396/SRR3192397 in list order; not
            distinguished further since neither replicate has a named
            biological distinction in the source ENCODE experiment.
  iad_pos:  TG3, TG12, TG4 -- explicit order comment already present in the
            source full_highres script, unchanged here.
  iad_neg:  TG13, TG2 -- same.

Normalization change from the cohort-aggregated figure: here % is computed
per SAMPLE, not per cohort -- for each sample-column, % = (taxon's raw read
count in that sample / sum of Kraken2 raw reads across every taxon shown for
that SAME sample) x 100. This is the natural per-patient analogue of the
original per-cohort methodology and is what actually exposes per-sample
composition differences (e.g. a donor with more background noise reads
lower on its dominant virus even at similar raw counts) that cohort-level
pooling hides.

Source data provenance, cross-validation status, and the 3-different-
column-orders QC lesson are identical to the parent full_highres script --
see that script's own module docstring for the full account; not repeated
here to avoid drift between the two copies.
"""

import os
import numpy as np
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
from matplotlib.colors import LinearSegmentedColormap, LogNorm
from matplotlib.patches import Rectangle

RUNS = ["cmv", "tg", "ebv", "iad_pos", "iad_neg"]
RUN_LABEL = {
    "cmv": "CMV Fibroblast\n(4 samples)",
    "tg": "TG VZV/HSV1 Ganglia\n(5 donors)",
    "ebv": "EBV Lymphoblastoid\n(2 replicates)",
    "iad_pos": "Iadorola TG\nHSV-1+ (3 donors)",
    "iad_neg": "Iadorola TG\nHSV-1− (2 donors)",
}
SAMPLE_LABELS = {
    "cmv": ["12h", "24h", "48h", "72h"],
    "tg": ["TG3", "TG4", "TG5", "TG6", "TG7"],
    "ebv": ["Rep 1", "Rep 2"],
    "iad_pos": ["TG3", "TG12", "TG4"],
    "iad_neg": ["TG13", "TG2"],
}

K2_RAW = {
    "cmv": {
        "cmv":        [1588558, 3969423, 5841101, 1985167],
        "cerco_cmv":  [833, 1795, 3154, 0],
        "chimp_cmv":  [288, 236, 211, 60],
        "cmv_proxy":  [0, 0, 0, 0],
        "hervk":      [270, 102, 53, 17],
        "hsv1": [0, 12, 18, 22],
        "vzv":  [0, 0, 0, 0],
        "ebv":  [0, 0, 0, 0],
        "ebv_cross": [0, 0, 0, 0],
        "hsv2":   [0, 0, 0, 0],
        "bovine": [0, 0, 0, 0],
    },
    "tg": {
        "hsv1":  [8267423, 11707977, 17540230, 49372617, 10575993],
        "vzv":   [409012, 877025, 50682, 471534, 209184],
        "hervk": [1977, 1232, 1163, 1286, 1221],
        "cmv":   [0, 0, 0, 0, 0],
        "ebv":   [0, 0, 0, 0, 0],
        "cmv_proxy": [0, 0, 0, 0, 0],
        "ebv_cross": [0, 0, 0, 0, 0],
        "cerco_cmv": [0, 0, 0, 0, 0],
        "chimp_cmv": [0, 0, 0, 0, 0],
        "hsv2":   [0, 0, 0, 0, 0],
        "bovine": [15, 0, 0, 0, 0],
    },
    "ebv": {
        "ebv":       [250052, 184950],
        "ebv_cross": [6948, 2861],
        "cmv_proxy": [71, 90],
        "hervk":     [2549, 2513],
        "cmv":  [0, 0],
        "hsv1": [0, 0],
        "vzv":  [0, 0],
        "cerco_cmv": [0, 0],
        "chimp_cmv": [0, 0],
        "hsv2":   [0, 0],
        "bovine": [0, 0],
    },
    "iad_pos": {  # TG3, TG12, TG4
        "hsv1":  [392, 467, 11],
        "hervk": [1299, 1855, 905],
        "cmv_proxy": [14, 16, 0],
        "cmv": [0, 0, 0], "vzv": [0, 0, 0], "ebv": [0, 0, 0],
        "ebv_cross": [0, 0, 0], "cerco_cmv": [0, 0, 0], "chimp_cmv": [0, 0, 0],
        "bovine": [0, 0, 0], "hsv2": [0, 0, 0],
    },
    "iad_neg": {  # TG13, TG2
        "hsv1":  [0, 0],
        "hervk": [951, 1175],
        "cmv_proxy": [18, 18],
        "cmv": [0, 0], "vzv": [0, 0], "ebv": [0, 0],
        "ebv_cross": [0, 0], "cerco_cmv": [0, 0], "chimp_cmv": [0, 0],
        "bovine": [0, 0], "hsv2": [0, 0],
    },
}

PS_RAW = {
    "cmv": {
        "cmv":   [643233, 1133300, 1515321, 690672],
        "hervk": [256, 58, 34, 8],
        "hsv1": [0, 2, 10, 9],
        "vzv":  [0, 0, 0, 0],
        "ebv":  [0, 0, 0, 0],
        "ebv_cross": [0, 0, 0, 0],
        "hsv2":   [0, 0, 0, 0],
        "bovine": [0, 0, 0, 0],
        "cerco_cmv": [1.9333, 5.7, 1.9333, 0.4],
        "chimp_cmv": [165.35, 252.8, 338.1, 169.15],
    },
    "tg": {
        "hsv1":   [1464209.5, 1816717.6667, 2251920.3333, 7677324.5, 1910915.6667],
        "vzv":    [51931, 94193, 8026, 63180, 24633],
        "hsv2":   [0.5, 0.6667, 8.8333, 27.0, 1.6667],
        "bovine": [0, 0, 3.0, 0, 0],
        "hervk":  [162, 114, 592, 356, 178],
        "cmv":  [0, 0, 0, 0, 0],
        "ebv":  [0, 0, 0, 0, 0],
        "ebv_cross": [0, 0, 0, 0, 0],
        "cerco_cmv": [0, 0, 0, 0, 0],
        "chimp_cmv": [0, 0, 0, 0, 0],
    },
    "ebv": {
        "ebv":       [155795.3333, 118505.1667],
        "ebv_cross": [35.6667, 25.8333],
        "cmv_proxy": [0, 0],
        "hervk":     [976, 1158],
        "cmv":  [0, 0],
        "hsv1": [0, 0],
        "vzv":  [0, 0],
        "cerco_cmv": [0, 0],
        "chimp_cmv": [0, 0],
        "hsv2":   [0, 0],
        "bovine": [0, 0],
    },
    "iad_pos": {  # TG3, TG12, TG4
        "hsv1":  [219, 293, 9],
        "hervk": [811, 1301, 586],
        "cmv": [0, 0, 0], "vzv": [0, 0, 0], "ebv": [0, 0, 0],
        "ebv_cross": [0, 0, 0], "cerco_cmv": [0, 0, 0], "chimp_cmv": [0, 0, 0],
        "bovine": [0, 0, 0], "hsv2": [0, 0, 0],
    },
    "iad_neg": {  # TG13, TG2
        "hsv1":  [0, 0],
        "hervk": [477, 701],
        "cmv": [0, 0], "vzv": [0, 0], "ebv": [0, 0],
        "ebv_cross": [0, 0], "cerco_cmv": [0, 0], "chimp_cmv": [0, 0],
        "bovine": [0, 0], "hsv2": [0, 0],
    },
}

# (label, latin/taxid, key, is_main)
TAXA = {
    "cmv":        ("Human CMV (HHV-5)", "Cytomegalovirus humanbeta5 · 10359", True),
    "cmv_proxy":  ("Baboon/NHP CMV cross-map", "Cytomegalovirus papiinebeta3 · 3050337 (K2) / 2169863", False),
    "cerco_cmv":  ("Cercopithecine CMV (bg)", "Cytomegalovirus cercopithecinebeta5 · 3050258", False),
    "chimp_cmv":  ("Chimp/Pan CMV (bg)", "Cytomegalovirus paninebeta2 · 3050334", False),
    "hsv1":       ("HSV-1 (HHV-1)", "Human alphaherpesvirus 1 · 10298", True),
    "hsv2":       ("HSV-2 (specificity ctrl)", "Human alphaherpesvirus 2 · 10310", False),
    "vzv":        ("VZV (HHV-3)", "Human alphaherpesvirus 3 · 10335", True),
    "bovine":     ("Bovine alphaherpesvirus 1 (ctrl)", "Bovine alphaherpesvirus 1 · 10320", False),
    "ebv":        ("EBV (HHV-4)", "Human gammaherpesvirus 4 · 10376", True),
    "ebv_cross":  ("Baboon/macaque EBV cross-map", "Lymphocryptovirus/Macacine gamma-4 · 3050339 / 45455", False),
    "hervk":      ("HERV-K", "Human endogenous retrovirus K · 45617 (same ID, both methods)", True),
}

DISPLAY_ORDER = [
    "cmv", "cmv_proxy", "cerco_cmv", "chimp_cmv",
    "hsv1", "hsv2",
    "vzv", "bovine",
    "ebv", "ebv_cross",
    "hervk",
]

NOT_APPLICABLE_SPECIAL = {
    ("cmv_proxy", "cmv", "ps"), ("cmv_proxy", "tg", "ps"),
    ("cmv_proxy", "iad_pos", "ps"), ("cmv_proxy", "iad_neg", "ps"),
}

# ---------------------------------------------------------------------------
# Build one column PER SAMPLE per method, tracking group spans for the
# 3-tier header and the major/minor divider lines.

col_tuples = []          # (run, sample_idx, method)
run_span = {}            # run -> (first_col, last_col) inclusive
sample_span = {}         # (run, sample_idx) -> (first_col, last_col) inclusive
ci = 0
for run in RUNS:
    run_first = ci
    for si in range(len(SAMPLE_LABELS[run])):
        s_first = ci
        col_tuples.append((run, si, "ps"))
        col_tuples.append((run, si, "k2"))
        ci += 2
        sample_span[(run, si)] = (s_first, ci - 1)
    run_span[run] = (run_first, ci - 1)
n_cols = len(col_tuples)
n_rows = len(DISPLAY_ORDER)

# Per-SAMPLE Kraken2 denominator (not per-cohort): sum of Kraken2 raw reads
# across every taxon shown, for that one sample.
total_k2_sample = {}
for run in RUNS:
    for si in range(len(SAMPLE_LABELS[run])):
        total_k2_sample[(run, si)] = sum(
            K2_RAW[run][key][si] for key in DISPLAY_ORDER if key in K2_RAW[run]
        )

values = np.full((n_rows, n_cols), np.nan)
reads = np.full((n_rows, n_cols), np.nan)
kind = np.full((n_rows, n_cols), "value", dtype=object)
annot = np.full((n_rows, n_cols), "", dtype=object)

def fmt_reads(n):
    return f"{round(n):,}"

for ri, key in enumerate(DISPLAY_ORDER):
    for ci_, (run, si, method) in enumerate(col_tuples):
        if (key, run, method) in NOT_APPLICABLE_SPECIAL:
            kind[ri, ci_] = "na"; annot[ri, ci_] = "n/a†"; continue

        src = K2_RAW[run] if method == "k2" else PS_RAW[run]
        raw = src.get(key, [None] * len(SAMPLE_LABELS[run]))[si]
        pct = 100.0 * raw / total_k2_sample[(run, si)]
        values[ri, ci_] = pct
        reads[ri, ci_] = raw
        if pct == 0:
            kind[ri, ci_] = "zero"; annot[ri, ci_] = "0%"
        else:
            kind[ri, ci_] = "value"
            if pct >= 10:
                annot[ri, ci_] = f"{pct:.2f}%"
            elif pct >= 0.1:
                annot[ri, ci_] = f"{pct:.3f}%"
            elif pct >= 0.001:
                annot[ri, ci_] = f"{pct:.4f}%"
            else:
                annot[ri, ci_] = f"{pct:.2e}%"

# ---------------------------------------------------------------------------

BLUE_STOPS = [
    "#cde2fb", "#b7d3f6", "#9ec5f4", "#86b6ef", "#6da7ec", "#5598e7",
    "#3987e5", "#2a78d6", "#256abf", "#1c5cab", "#184f95", "#104281", "#0d366b",
]
cmap = LinearSegmentedColormap.from_list("blue_seq", BLUE_STOPS, N=256)
cmap.set_bad(color="none")

EPS = 1e-3
norm = LogNorm(vmin=EPS, vmax=100.0)

color_values = np.where(values <= 0, EPS, values)
color_values = np.where(np.isnan(values), np.nan, color_values)

INK = "#0b0b0b"
INK2 = "#52514e"
MUTED = "#898781"
GRID = "#ffffff"
HATCH_FACE = "#efeee8"
HATCH_LINE = "#c9c7bd"
SURFACE = "#fcfcfb"
PAGE = "#f4f3ef"
MINOR_LINE = "#b9b7ae"

# --- layout, computed from fixed absolute-inch margins. n_cols is now 32
# (one Kraken2/PathSeq pair per sample x 16 samples across 5 cohorts) rather
# than 10, so columns are narrower and the header needs a third tier -- both
# handled by scaling the same fixed-margin approach the parent script uses. ---
LABEL_W_IN = 3.468
COL_W_IN = 0.72
RIGHT_MARGIN_IN = 2.448

# Header: 3 text tiers above the data block instead of 2. Data rows keep the
# same per-row inch height as the parent full_highres figure (0.4162 in/row);
# the header simply needs more data-unit height above y=-0.5 to fit a third
# tier, computed here rather than hand-tuned.
ROW_SCALE_IN = 0.4162          # in per data-unit, matched to the parent figure
DATA_UNITS = n_rows             # 11
HEADER_UNITS = 2.9 - 0.5        # y=-2.9 (top) to y=-0.5 (data start) = 2.4 units
TOTAL_UNITS = DATA_UNITS + HEADER_UNITS

AX_H_IN = ROW_SCALE_IN * TOTAL_UNITS
AX_BOTTOM_IN = 2.45
TOP_MARGIN_IN = 1.88
FIG_H = AX_BOTTOM_IN + AX_H_IN + TOP_MARGIN_IN

data_w_in = COL_W_IN * n_cols
FIG_W = LABEL_W_IN + data_w_in + RIGHT_MARGIN_IN

AX_LEFT = LABEL_W_IN / FIG_W
AX_W = data_w_in / FIG_W
AX_BOTTOM = AX_BOTTOM_IN / FIG_H
AX_H = AX_H_IN / FIG_H

cax_left_in = LABEL_W_IN + data_w_in + 0.476
cax_left = cax_left_in / FIG_W
cax_w = 0.272 / FIG_W

leg_left = cax_left
leg_w = 0.816 / FIG_W
leg_text_x = (cax_left_in + 0.911) / FIG_W

TITLE_X = 0.68 / FIG_W

plt.rcParams["font.family"] = "DejaVu Sans"
fig = plt.figure(figsize=(FIG_W, FIG_H), dpi=200, facecolor=PAGE)
ax = fig.add_axes([AX_LEFT, AX_BOTTOM, AX_W, AX_H])
ax.set_facecolor(SURFACE)

masked = np.ma.masked_invalid(color_values)
im = ax.imshow(masked, cmap=cmap, norm=norm, aspect="auto", interpolation="nearest")

for ri, key in enumerate(DISPLAY_ORDER):
    for ci_ in range(n_cols):
        k = kind[ri, ci_]
        if k == "na":
            ax.add_patch(Rectangle((ci_ - 0.5, ri - 0.5), 1, 1,
                                    facecolor=HATCH_FACE, edgecolor=HATCH_LINE,
                                    hatch="////", linewidth=0.6, zorder=2))
            ax.text(ci_, ri, annot[ri, ci_], ha="center", va="center",
                     fontsize=6.6, color=MUTED, zorder=3)
        else:
            rgba = cmap(norm(color_values[ri, ci_]))
            lum = 0.2126 * rgba[0] + 0.7152 * rgba[1] + 0.0722 * rgba[2]
            txt_color = INK if lum > 0.55 else "#ffffff"
            sub_color = MUTED if txt_color == INK else HATCH_LINE
            ax.text(ci_, ri - 0.15, annot[ri, ci_], ha="center", va="center",
                     fontsize=7.4, fontweight="bold", color=txt_color, zorder=3)
            ax.text(ci_, ri + 0.17, f"({fmt_reads(reads[ri, ci_])})", ha="center", va="center",
                     fontsize=5.5, fontweight="normal", color=sub_color, zorder=3)

ax.set_xticks(np.arange(-0.5, n_cols, 1), minor=True)
ax.set_yticks(np.arange(-0.5, n_rows, 1), minor=True)
ax.grid(which="minor", color=GRID, linewidth=1.6)
ax.tick_params(which="minor", length=0)

# Major dividers -- between cohorts -- span the full header + data height, so
# each cohort's 3-tier header block reads as one bordered unit (same
# technique as the parent full_highres figure).
for run in RUNS[1:]:
    x = run_span[run][0] - 0.5
    ax.axvline(x, color=INK, linewidth=1.4, zorder=4)

# Minor dividers -- between individual samples within a cohort -- confined to
# the data rows only (not drawn through the header text tiers), per explicit
# request for "minor splits on the x axis for each sample".
for run in RUNS:
    n_samples = len(SAMPLE_LABELS[run])
    for si in range(1, n_samples):
        x = sample_span[(run, si)][0] - 0.5
        ax.vlines(x, -0.5, n_rows - 0.5, color=MINOR_LINE, linewidth=0.6, zorder=4)

for ri, key in enumerate(DISPLAY_ORDER):
    if TAXA[key][2] and ri > 0:
        ax.axhline(ri - 0.5, color=INK, linewidth=1.2, zorder=4)
ax.axhline(-0.5, color=INK, linewidth=1.2, zorder=4)
ax.axhline(n_rows - 0.5, color=INK, linewidth=1.2, zorder=4)

# --- 3-tier column headers, manually positioned at fixed data coordinates
# (not matplotlib's automatic top-tick mechanism -- see full_highres for why)
# so nothing renders outside the intended white header region. Reading top
# to bottom: cohort name (outer group) -> sample label (inner group) ->
# method name (PathSeq/Kraken2, adjacent to its own column). ---
for ci_, (run, si, method) in enumerate(col_tuples):
    ax.text(ci_, -0.95, "PathSeq" if method == "ps" else "Kraken2",
             ha="center", va="center", fontsize=7.6, fontweight="600", color=INK2)

for (run, si), (c0, c1) in sample_span.items():
    xc = (c0 + c1) / 2.0
    ax.text(xc, -1.55, SAMPLE_LABELS[run][si], ha="center", va="center",
             fontsize=8.2, fontweight="700", color=INK)

for run in RUNS:
    c0, c1 = run_span[run]
    xc = (c0 + c1) / 2.0
    ax.text(xc, -2.35, RUN_LABEL[run], ha="center", va="center",
             fontsize=10.4, fontweight="800", color=INK, linespacing=1.3)

ax.set_xticks([])
ax.set_yticks([])
for spine in ax.spines.values():
    spine.set_visible(False)

for ri, key in enumerate(DISPLAY_ORDER):
    label, latin, is_main = TAXA[key]
    if is_main:
        ax.text(-0.62, ri, label, ha="right", va="center",
                 fontsize=10.0, fontweight="800", color=INK, transform=ax.transData)
        ax.text(-0.62, ri + 0.30, latin, ha="right", va="top",
                 fontsize=6.8, color=MUTED, style="italic", transform=ax.transData)
    else:
        ax.text(-0.62, ri, "›  " + label, ha="right", va="center",
                 fontsize=8.6, fontweight="400", color=INK2, transform=ax.transData)
        ax.text(-0.62, ri + 0.30, latin, ha="right", va="top",
                 fontsize=6.4, color=MUTED, style="italic", transform=ax.transData)

ax.set_xlim(-0.5, n_cols - 0.5)
ax.set_ylim(n_rows - 0.5, -2.9)

# --- colorbar / legends ------------------------------------------------------
cax = fig.add_axes([cax_left, AX_BOTTOM, cax_w, AX_H])
cb = fig.colorbar(im, cax=cax)
cb.set_label("% of that SAMPLE's total Kraken2-positive reads (log scale)",
             fontsize=8.6, color=INK2, labelpad=10)
cb.ax.tick_params(labelsize=7.6, color=INK2, labelcolor=INK2)
cb.outline.set_visible(False)

leg_ax1 = fig.add_axes([leg_left, 0.075, leg_w, 0.024])
leg_ax1.add_patch(Rectangle((0, 0), 1, 1, facecolor=HATCH_FACE, edgecolor=HATCH_LINE,
                             hatch="////", linewidth=0.6))
leg_ax1.set_xlim(0, 1); leg_ax1.set_ylim(0, 1); leg_ax1.axis("off")
fig.text(leg_text_x, 0.087, "n/a", fontsize=7.2, color=MUTED, va="center")

# --- title / footer ----------------------------------------------------------
fig.text(TITLE_X, 0.972, "Kraken2 × PathSeq Concordance — Full High-Resolution, Per-Sample", fontsize=17.5,
          fontweight="800", color=INK, va="top")
fig.text(TITLE_X, 0.930,
          "Same 5 cohorts and taxonomic-lineage rows as the cohort-aggregated figure, but every Kraken2/PathSeq\n"
          "pair is now split into one column-pair PER SAMPLE (thin dividers) within each cohort (thick dividers) —\n"
          "e.g. the CMV time course shows all 4 timepoints individually rather than summed into one column.",
          fontsize=9.2, color=INK2, linespacing=1.5, va="top")

footer = (
    "Normalization (changed from the cohort-aggregated figure): for each SAMPLE-column, % = (taxon's raw read\n"
    "count in that sample ÷ sum of Kraken2 raw reads across every taxon shown for that SAME sample) × 100,\n"
    "applied identically to PathSeq and Kraken2 — a per-sample denominator, not a per-cohort one, so composition\n"
    "differences between individual donors/timepoints are visible rather than pooled away.\n"
    "Sample order (index-aligned with every taxon's value list, each independently verified — see this script's\n"
    "module docstring): cmv = 12h,24h,48h,72h; tg (Depledge) = TG3,TG4,TG5,TG6,TG7 (confirmed via direct ENA\n"
    "filereport lookup + internal cross-check against this cohort's own VZV max/min); ebv = Rep 1, Rep 2;\n"
    "Iadorola HSV-1+ = TG3,TG12,TG4; Iadorola HSV-1− = TG13,TG2.\n"
    "All values are the same header-verified, fully cross-validated numbers as the cohort-aggregated full_highres\n"
    "figure — no new data gathering, purely a per-sample re-slice of already-confirmed totals.\n"
    "† PathSeq has no taxon distinct from 10359 representing Kraken2's specific proxy-species artifact — the\n"
    "Human CMV row's own value already answers the equivalent question in every cohort it applies to.\n"
    "Source: docs/pathseq_validation_results_2026-08-15.md, research/cmv_taxonomy_investigation.md."
)
fig.text(TITLE_X, 0.019, footer, fontsize=6.9, color=MUTED, linespacing=1.42)

OUTBASE = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "docs", "figures",
                        "full_highres_kraken_pathseq_concordance_heatmap_perpatient")
fig.savefig(OUTBASE + ".png", dpi=400, facecolor=PAGE)
fig.savefig(OUTBASE + ".pdf", facecolor=PAGE)
print("done")
print("FIG_W:", FIG_W, "FIG_H:", FIG_H)
print("n_cols:", n_cols)
