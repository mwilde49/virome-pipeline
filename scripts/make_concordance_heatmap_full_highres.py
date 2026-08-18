#!/usr/bin/env python3
"""
Kraken2 vs PathSeq concordance heatmap -- FULL HIGH-RES variant.

Adds a 4th real-world cohort to the 3-cohort highres figure: the Iadorola
et al. human trigeminal ganglia cohort (BioProject SRP113004), scoped to a
5-donor "batch1" subset run ahead of the full 16-donor cohort. Per explicit
request, this cohort is NOT one column-pair -- it's split into two, by real
Kraken2 dual-DB Tier-1 HSV-1 status:
    Iadorola HSV+ (TG3, TG12, TG4)  -- 392, 467, 11 Kraken2 HSV-1 reads
    Iadorola HSV- (TG13, TG2)        -- 0, 0 Kraken2 HSV-1 reads
Both PathSeq-confirmed (see docs/pathseq_validation_results_2026-08-15.md for
the full concordance table) -- full agreement between tools once a real
column-order bug was caught and fixed (see QC note below).

Same normalization as the other scripts: TOTAL_K2(column) = sum of Kraken2
raw reads across every taxon shown for that column. As of 2026-08-17, both
new Iadorola columns are fully cross-validated -- every taxon in this figure
checked against both tools for TG13/TG2/TG3/TG12/TG4. One real, non-zero
finding: the CMV-proxy artifact (3050337) recurs here too -- reads 18, 18,
14, 16, 0 across TG13/TG2/TG3/TG12/TG4 -- a 4th independent cohort showing
this same low-titer artifact (after the original DRG/muscle samples,
cmv_fibroblast's absence-as-control, and ebv_gm12878's trace background).
Everything else (cmv, vzv, ebv, ebv_cross, cerco_cmv, chimp_cmv, bovine,
hsv2) is a confirmed true-negative in both tools, not an unchecked
assumption -- including one false-positive worth remembering: PathSeq's
"10376" grep hit was Cellvibrio, a bacterial background taxon whose own
read-count VALUE happened to contain those digits, not real EBV signal.

QC note (important, kept here for anyone re-deriving these numbers): THREE
different real output files for this one batch used THREE different sample
column orderings --
  consensus_matrix.tsv:        TG13, TG2, TG3, TG12, TG4  (Nextflow/Bracken's
                                own aggregation order, not alphabetical)
  bracken_raw_matrix.tsv:      TG13, TG2, TG3, TG12, TG4  (same as above)
  pathseq_abundance_matrix.tsv: TG12, TG13, TG2, TG3, TG4  (alphabetical --
                                bin/aggregate_pathseq.py does
                                long_df.sort_values('sample_id').groupby(...),
                                and as STRINGS "TG12" < "TG13" < "TG2" < "TG3"
                                < "TG4" -- the first cohort in this whole
                                project where alphabetical order didn't
                                coincide with numeric/samplesheet order).
Reading the PathSeq HSV-1 row against the wrong (consensus-matrix) order
briefly looked like a major Kraken2/PathSeq discordance -- it was purely a
column-attribution bug, caught by demanding an explicit `head -1` on both
files before trusting either. Every number below is post-correction, header-
verified.
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
    "tg": "TG Ganglia\n(5 donors)",
    "ebv": "EBV Lymphoblastoid\n(2 replicates)",
    "iad_pos": "Iadorola TG\nHSV-1+ (3 donors)",
    "iad_neg": "Iadorola TG\nHSV-1− (2 donors)",
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
    # Iadorola batch1, real values, bracken_raw_matrix.tsv header-confirmed
    # order (TG13, TG2, TG3, TG12, TG4), 2026-08-16. Full cross-validation
    # (2026-08-17): cmv/vzv/ebv/ebv_cross/cerco_cmv/chimp_cmv/bovine/hsv2 all
    # confirmed true-negative. cmv_proxy is the one real, non-zero exception --
    # a 4th independent cohort now showing the same low-titer CMV-proxy
    # artifact (after the original DRG/muscle samples, cmv_fibroblast's
    # absence-as-control, and ebv_gm12878's trace background) -- real reads:
    # TG13=18, TG2=18, TG3=14, TG12=16, TG4=0.
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
    # Iadorola batch1, real values, pathseq_abundance_matrix.tsv header-
    # confirmed order (TG12, TG13, TG2, TG3, TG4), 2026-08-16. Full cross-
    # validation (2026-08-17): all remaining taxa confirmed true-negative
    # (the one "10376" grep hit was Cellvibrio -- a bacterial background
    # taxon whose own read-count VALUE happened to contain those digits, not
    # real EBV signal, same false-positive pattern already identified once
    # before in the cmv_fibroblast PathSeq output). cmv_proxy intentionally
    # omitted -- PathSeq has no taxon distinct from 10359 for it, same as
    # every other cohort (see NOT_APPLICABLE_SPECIAL).
    "iad_pos": {  # TG3, TG12, TG4 (order within the list doesn't matter -- summed)
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

_ALL_TAXA = {"cmv", "hsv1", "vzv", "ebv", "cmv_proxy", "ebv_cross",
             "cerco_cmv", "chimp_cmv", "hsv2", "bovine", "hervk"}
RELEVANT = {
    "cmv": _ALL_TAXA, "tg": _ALL_TAXA, "ebv": _ALL_TAXA,
    # Iadorola batch1: full cross-validation complete as of 2026-08-17 (all
    # 9 taxa checked against both tools -- see K2_RAW/PS_RAW comments).
    "iad_pos": _ALL_TAXA,
    "iad_neg": _ALL_TAXA,
}

NO_DATA = set()
NOT_APPLICABLE_SPECIAL = {
    ("cmv_proxy", "cmv", "ps"), ("cmv_proxy", "tg", "ps"),
    ("cmv_proxy", "iad_pos", "ps"), ("cmv_proxy", "iad_neg", "ps"),
}
PENDING = set()

# ---------------------------------------------------------------------------

total_k2 = {run: sum(sum(v) for v in K2_RAW[run].values()) for run in RUNS}

col_tuples = []
for run in RUNS:
    col_tuples += [(run, "ps"), (run, "k2")]
n_cols = len(col_tuples)
n_rows = len(DISPLAY_ORDER)

values = np.full((n_rows, n_cols), np.nan)
reads = np.full((n_rows, n_cols), np.nan)
kind = np.full((n_rows, n_cols), "value", dtype=object)
annot = np.full((n_rows, n_cols), "", dtype=object)

def fmt_reads(n):
    return f"{round(n):,}"

for ri, key in enumerate(DISPLAY_ORDER):
    for ci, (run, method) in enumerate(col_tuples):
        if (key, run, method) in PENDING:
            kind[ri, ci] = "pending"; annot[ri, ci] = "pending"; continue
        if key not in RELEVANT[run]:
            kind[ri, ci] = "na"; annot[ri, ci] = "n/a"; continue
        if (key, run, method) in NO_DATA:
            kind[ri, ci] = "nodata"; annot[ri, ci] = "no data"; continue
        if (key, run, method) in NOT_APPLICABLE_SPECIAL:
            kind[ri, ci] = "na"; annot[ri, ci] = "n/a†"; continue

        raw_sum = sum(K2_RAW[run].get(key, [])) if method == "k2" else sum(PS_RAW[run].get(key, []))
        pct = 100.0 * raw_sum / total_k2[run]
        values[ri, ci] = pct
        reads[ri, ci] = raw_sum
        if pct == 0:
            kind[ri, ci] = "zero"; annot[ri, ci] = "0%"
        else:
            kind[ri, ci] = "value"
            if pct >= 10:
                annot[ri, ci] = f"{pct:.2f}%"
            elif pct >= 0.1:
                annot[ri, ci] = f"{pct:.3f}%"
            elif pct >= 0.001:
                annot[ri, ci] = f"{pct:.4f}%"
            else:
                annot[ri, ci] = f"{pct:.2e}%"

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

# --- layout, computed from fixed absolute-inch margins so it scales cleanly
# with column count (5 cohort-pairs = 10 columns, vs. the 3-cohort/6-column
# original) instead of hand-recomputed fractions ---
LABEL_W_IN = 3.468
COL_W_IN = 1.2807
RIGHT_MARGIN_IN = 2.448
AX_BOTTOM_IN = 2.256
AX_H_IN = 5.264
FIG_H = 9.4

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
    for ci in range(n_cols):
        k = kind[ri, ci]
        if k in ("na", "nodata"):
            ax.add_patch(Rectangle((ci - 0.5, ri - 0.5), 1, 1,
                                    facecolor=HATCH_FACE, edgecolor=HATCH_LINE,
                                    hatch="////", linewidth=0.6, zorder=2))
            ax.text(ci, ri, annot[ri, ci], ha="center", va="center",
                     fontsize=7.6, color=MUTED, zorder=3,
                     style="italic" if k == "nodata" else "normal")
        else:
            rgba = cmap(norm(color_values[ri, ci]))
            lum = 0.2126 * rgba[0] + 0.7152 * rgba[1] + 0.0722 * rgba[2]
            txt_color = INK if lum > 0.55 else "#ffffff"
            sub_color = MUTED if txt_color == INK else HATCH_LINE
            ax.text(ci, ri - 0.15, annot[ri, ci], ha="center", va="center",
                     fontsize=8.6, fontweight="bold", color=txt_color, zorder=3)
            ax.text(ci, ri + 0.17, f"({fmt_reads(reads[ri, ci])})", ha="center", va="center",
                     fontsize=6.3, fontweight="normal", color=sub_color, zorder=3)

ax.set_xticks(np.arange(-0.5, n_cols, 1), minor=True)
ax.set_yticks(np.arange(-0.5, n_rows, 1), minor=True)
ax.grid(which="minor", color=GRID, linewidth=2.2)
ax.tick_params(which="minor", length=0)

for gi in range(1, len(RUNS)):
    ax.axvline(gi * 2 - 0.5, color=INK, linewidth=1.4, zorder=4)

for ri, key in enumerate(DISPLAY_ORDER):
    if TAXA[key][2] and ri > 0:
        ax.axhline(ri - 0.5, color=INK, linewidth=1.2, zorder=4)
ax.axhline(-0.5, color=INK, linewidth=1.2, zorder=4)
ax.axhline(n_rows - 0.5, color=INK, linewidth=1.2, zorder=4)

# Method labels ("PathSeq"/"Kraken2") -- manually positioned at a fixed data
# coordinate rather than matplotlib's automatic top-tick mechanism, which
# anchors to the axes' physical bounding-box edge and can render outside the
# white header region instead of inside it. Text at a real y-coordinate
# (same technique already used for the cohort-name headers below) guarantees
# it stays inside the visible axes area.
for ci, (run, method) in enumerate(col_tuples):
    ax.text(ci, -1.95, "PathSeq" if method == "ps" else "Kraken2",
             ha="center", va="center", fontsize=8.6, fontweight="600", color=INK2)
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

for gi, run in enumerate(RUNS):
    xc = gi * 2 + 0.5
    ax.text(xc, -1.15, RUN_LABEL[run], ha="center", va="center",
             fontsize=9.6, fontweight="700", color=INK, linespacing=1.3)

ax.set_xlim(-0.5, n_cols - 0.5)
ax.set_ylim(n_rows - 0.5, -2.15)

# --- colorbar / legends ------------------------------------------------------
cax = fig.add_axes([cax_left, AX_BOTTOM, cax_w, AX_H])
cb = fig.colorbar(im, cax=cax)
cb.set_label("% of that run's total Kraken2-positive reads (log scale)",
             fontsize=8.6, color=INK2, labelpad=10)
cb.ax.tick_params(labelsize=7.6, color=INK2, labelcolor=INK2)
cb.outline.set_visible(False)

leg_ax1 = fig.add_axes([leg_left, 0.095, leg_w, 0.028])
leg_ax1.add_patch(Rectangle((0, 0), 1, 1, facecolor=HATCH_FACE, edgecolor=HATCH_LINE,
                             hatch="////", linewidth=0.6))
leg_ax1.set_xlim(0, 1); leg_ax1.set_ylim(0, 1); leg_ax1.axis("off")
fig.text(leg_text_x, 0.109, "n/a or\nno data", fontsize=7.2, color=MUTED, va="center")

# --- title / footer ----------------------------------------------------------
fig.text(TITLE_X, 0.965, "Kraken2 × PathSeq Concordance — Full High-Resolution", fontsize=17.5,
          fontweight="800", color=INK, va="top")
fig.text(TITLE_X, 0.913,
          "Rows grouped by taxonomic lineage — each main virus (bold) with every related sub-taxon indented\n"
          "directly beneath it. Now 5 cohorts: the original 3, plus the Iadorola et al. TG cohort split into its\n"
          "own real Kraken2-confirmed HSV-1-positive and HSV-1-negative columns (not lumped as one cohort).",
          fontsize=9.2, color=INK2, linespacing=1.5, va="top")

footer = (
    "Normalization: for each column, % = (taxon's raw read count ÷ sum of Kraken2 raw reads across every taxon\n"
    "shown for that column) × 100, applied identically to both PathSeq and Kraken2. Iadorola HSV+ = TG3+TG12+TG4\n"
    "summed; HSV− = TG13+TG2 summed — real per-donor Tier-1 Kraken2 calls, PathSeq-confirmed concordant on every\n"
    "donor (see docs/pathseq_validation_results_2026-08-15.md). Full cross-validation complete for both new\n"
    "columns (2026-08-17) — every taxon in this figure checked against both tools. One real, non-zero finding:\n"
    "the CMV-proxy artifact (3050337) recurs here too, a 4th independent cohort showing it (after the original\n"
    "DRG/muscle samples, cmv_fibroblast's absence-as-control, and ebv_gm12878's trace background). Everything\n"
    "else in both new columns is a confirmed true-negative, not an unchecked assumption.\n"
    "QC note: three real output files for this one batch used three DIFFERENT sample column orders (see this\n"
    "script's module docstring) — every number here is header-verified against the actual file, not assumed\n"
    "from samplesheet order, after an initial mis-read briefly looked like a real Kraken2/PathSeq discordance.\n"
    "† PathSeq has no taxon distinct from 10359 representing Kraken2's specific proxy-species artifact — the\n"
    "Human CMV row's own value already answers the equivalent question in every cohort it applies to.\n"
    "Source: docs/pathseq_validation_results_2026-08-15.md, research/cmv_taxonomy_investigation.md."
)
fig.text(TITLE_X, 0.022, footer, fontsize=6.9, color=MUTED, linespacing=1.42)

OUTBASE = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "docs", "figures",
                        "full_highres_kraken_pathseq_concordance_heatmap")
fig.savefig(OUTBASE + ".png", dpi=400, facecolor=PAGE)
fig.savefig(OUTBASE + ".pdf", facecolor=PAGE)
print("done")
print("FIG_W:", FIG_W)
print("TOTAL_K2:", total_k2)
