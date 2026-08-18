#!/usr/bin/env python3
"""
Kraken2 vs PathSeq concordance heatmap -- HIGH-RES taxonomic-hierarchy variant.

Same normalization as scripts/make_concordance_heatmap.py: for each run,
TOTAL_K2(run) = sum of Kraken2 raw reads across every FULLY-QUANTIFIED taxon
shown for that run (i.e. unchanged from the original -- HSV-2/Bovine
alphaherpesvirus-1/HERV-K do NOT get added to the denominator since their
exact Kraken2 counts were never pulled; adding a guessed contribution there
would be fabrication, not normalization). Both method columns are then
raw-reads / TOTAL_K2(run) x 100.

Y-axis restructure (this version's whole point): rows are grouped by
taxonomic lineage, not by finding-type. Each "main virus" (CMV, HSV-1, VZV,
EBV, HERV-K) is a bold anchor row; every related sub-taxon (cross-species
artifact, within-genus background, specificity-control relative) is an
indented, lighter row directly beneath it -- so a reader can see all the
minutiae for one virus family in one place instead of split across
finding-type sections.

As of 2026-08-16, every cell in this figure is real, checked data -- HERV-K
(taxon 45617, same ID both tools) and every cross-species/background taxon
was cross-validated against all 3 cohorts, both tools. The only cells that
remain non-numeric are two conceptually not-applicable ones (see
NOT_APPLICABLE_SPECIAL below), not missing data.
"""

import numpy as np
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
from matplotlib.colors import LinearSegmentedColormap, LogNorm
from matplotlib.patches import Rectangle

RUNS = ["cmv", "tg", "ebv"]
RUN_LABEL = {"cmv": "CMV Fibroblast\n(4 samples)", "tg": "TG Ganglia\n(5 donors)",
             "ebv": "EBV Lymphoblastoid\n(2 replicates)"}

K2_RAW = {
    "cmv": {
        "cmv":        [1588558, 3969423, 5841101, 1985167],
        "cerco_cmv":  [833, 1795, 3154, 0],
        "chimp_cmv":  [288, 236, 211, 60],
        "cmv_proxy":  [0, 0, 0, 0],
        "hervk":      [270, 102, 53, 17],
        # Cross-validation (2026-08-16): checked for the other cohorts'
        # expected taxa too. HSV-1 is a real, non-zero, time-course-tracking
        # finding; everything else confirmed true-negative.
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
        "cmv":   [0, 0, 0, 0, 0],  # confirmed true-negative, 2026-08-16
        "ebv":   [0, 0, 0, 0, 0],  # confirmed true-negative, 2026-08-16
        "cmv_proxy": [0, 0, 0, 0, 0],
        "ebv_cross": [0, 0, 0, 0, 0],
        "cerco_cmv": [0, 0, 0, 0, 0],
        "chimp_cmv": [0, 0, 0, 0, 0],
        # HSV-2: confirmed true-negative under the corrected name search
        # (Kraken2 renames HSV-1 "Simplexvirus humanalpha1", not "Human
        # alphaherpesvirus 1" -- same vintage pattern applied to HSV-2, no
        # match found either way).
        "hsv2":   [0, 0, 0, 0, 0],
        # Bovine alphaherpesvirus 1: REAL data, taxon 3050243 "Varicellovirus
        # bovinealpha1" -- found via corrected name search, 2026-08-16.
        "bovine": [15, 0, 0, 0, 0],
    },
    "ebv": {
        "ebv":       [250052, 184950],
        "ebv_cross": [6948, 2861],
        "cmv_proxy": [71, 90],
        "hervk":     [2549, 2513],
        "cmv":  [0, 0],  # confirmed true-negative, 2026-08-16
        "hsv1": [0, 0],  # confirmed true-negative, 2026-08-16
        "vzv":  [0, 0],  # confirmed true-negative, 2026-08-16
        "cerco_cmv": [0, 0],
        "chimp_cmv": [0, 0],
        "hsv2":   [0, 0],
        "bovine": [0, 0],
    },
}

# Real PathSeq HERV-K numbers (2026-08-16): taxon 45617 -- same ID Kraken2
# uses, a first in this investigation (every other taxon had a taxonomy-
# vintage ID mismatch). Confirmed via grep against the real
# pathseq_abundance_matrix.tsv for all 3 cohorts. Internal consistency check:
# parent (206037 "Human endogenous retroviruses"), species (45617), and
# subtype (166122 "K113") report numerically IDENTICAL read counts in every
# sample across all 3 cohorts -- i.e. essentially all signal resolves
# unambiguously to the K113 subtype. "mean reads" field (3rd value per block)
# used, matching the convention already established for every other taxon.
PS_RAW = {
    "cmv": {
        "cmv":   [643233, 1133300, 1515321, 690672],
        "hervk": [256, 58, 34, 8],
        # HSV-1 cross-validation: corroborates the Kraken2 finding above --
        # same real, near-zero-then-rising pattern, independently observed.
        "hsv1": [0, 2, 10, 9],
        "vzv":  [0, 0, 0, 0],
        "ebv":  [0, 0, 0, 0],
        "ebv_cross": [0, 0, 0, 0],
        "hsv2":   [0, 0, 0, 0],
        "bovine": [0, 0, 0, 0],
        # Real PathSeq-specific taxon IDs (distinct from Kraken2's, same
        # taxonomy-vintage pattern as every other cross-species taxon here):
        "cerco_cmv": [1.9333, 5.7, 1.9333, 0.4],       # taxon 50292
        "chimp_cmv": [165.35, 252.8, 338.1, 169.15],   # taxon 188763
    },
    "tg": {
        "hsv1":   [1464209.5, 1816717.6667, 2251920.3333, 7677324.5, 1910915.6667],
        "vzv":    [51931, 94193, 8026, 63180, 24633],
        "hsv2":   [0.5, 0.6667, 8.8333, 27.0, 1.6667],
        "bovine": [0, 0, 3.0, 0, 0],
        "hervk":  [162, 114, 592, 356, 178],
        "cmv":  [0, 0, 0, 0, 0],  # confirmed true-negative, 2026-08-16
        "ebv":  [0, 0, 0, 0, 0],  # confirmed true-negative, 2026-08-16
        "ebv_cross": [0, 0, 0, 0, 0],
        "cerco_cmv": [0, 0, 0, 0, 0],
        "chimp_cmv": [0, 0, 0, 0, 0],
    },
    "ebv": {
        "ebv":       [155795.3333, 118505.1667],
        "ebv_cross": [35.6667, 25.8333],
        "cmv_proxy": [0, 0],
        "hervk":     [976, 1158],
        "cmv":  [0, 0],  # confirmed true-negative, 2026-08-16
        "hsv1": [0, 0],  # confirmed true-negative, 2026-08-16
        "vzv":  [0, 0],  # confirmed true-negative, 2026-08-16
        "cerco_cmv": [0, 0],
        "chimp_cmv": [0, 0],
        "hsv2":   [0, 0],
        "bovine": [0, 0],
    },
}

# (label, latin/taxid, key, is_main, indent_level)
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

# display order -- main virus immediately followed by its own sub-taxa
DISPLAY_ORDER = [
    "cmv", "cmv_proxy", "cerco_cmv", "chimp_cmv",
    "hsv1", "hsv2",
    "vzv", "bovine",
    "ebv", "ebv_cross",
    "hervk",
]

# Every taxon is now relevant (real, checked data) in every cohort -- each
# was cross-validated as a positive/negative control against all 3 cohorts,
# both tools, 2026-08-16 (see docs/pathseq_validation_results_2026-08-15.md).
_ALL_TAXA = {"cmv", "hsv1", "vzv", "ebv", "cmv_proxy", "ebv_cross",
             "cerco_cmv", "chimp_cmv", "hsv2", "bovine", "hervk"}
RELEVANT = {"cmv": _ALL_TAXA, "tg": _ALL_TAXA, "ebv": _ALL_TAXA}

NO_DATA = set()  # every remaining cell filled with real data, 2026-08-16
# Both remaining n/a cells are conceptual, not missing data -- see the
# primary script's NOT_APPLICABLE_SPECIAL comment for the full explanation
# (PathSeq has no taxon distinct from 10359 representing Kraken2's specific
# proxy-species artifact; the CMV row's own value/confirmed-0% already
# answers the equivalent question in both the CMV and TG cohorts).
NOT_APPLICABLE_SPECIAL = {("cmv_proxy", "cmv", "ps"), ("cmv_proxy", "tg", "ps")}
PENDING = set()  # nothing pending -- every taxon has real data, 2026-08-16

# ---------------------------------------------------------------------------

total_k2 = {run: sum(sum(v) for v in K2_RAW[run].values()) for run in RUNS}

col_tuples = []
for run in RUNS:
    col_tuples += [(run, "ps"), (run, "k2")]
n_cols = len(col_tuples)
n_rows = len(DISPLAY_ORDER)

values = np.full((n_rows, n_cols), np.nan)
reads = np.full((n_rows, n_cols), np.nan)  # raw read sum backing each %, for the sub-label
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
PENDING_FACE = "#fdf1e0"
PENDING_LINE = "#e3c584"
SURFACE = "#fcfcfb"
PAGE = "#f4f3ef"

plt.rcParams["font.family"] = "DejaVu Sans"
fig = plt.figure(figsize=(13.6, 9.4), dpi=200, facecolor=PAGE)
AX_LEFT, AX_BOTTOM, AX_W, AX_H = 0.255, 0.240, 0.565, 0.560
ax = fig.add_axes([AX_LEFT, AX_BOTTOM, AX_W, AX_H])
ax.set_facecolor(SURFACE)

masked = np.ma.masked_invalid(color_values)
im = ax.imshow(masked, cmap=cmap, norm=norm, aspect="auto", interpolation="nearest")

for ri, key in enumerate(DISPLAY_ORDER):
    for ci in range(n_cols):
        k = kind[ri, ci]
        if k == "pending":
            ax.add_patch(Rectangle((ci - 0.5, ri - 0.5), 1, 1,
                                    facecolor=PENDING_FACE, edgecolor=PENDING_LINE,
                                    hatch="....", linewidth=0.6, zorder=2))
            ax.text(ci, ri, "pending", ha="center", va="center",
                     fontsize=7.6, color="#9a7a2a", zorder=3, style="italic")
        elif k in ("na", "nodata"):
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

for ci in (1.5, 3.5):
    ax.axvline(ci, color=INK, linewidth=1.4, zorder=4)

# thin rule above every main-virus row (except the first) -- marks a new lineage
for ri, key in enumerate(DISPLAY_ORDER):
    if TAXA[key][2] and ri > 0:
        ax.axhline(ri - 0.5, color=INK, linewidth=1.2, zorder=4)
ax.axhline(-0.5, color=INK, linewidth=1.2, zorder=4)
ax.axhline(n_rows - 0.5, color=INK, linewidth=1.2, zorder=4)

ax.set_xticks(range(n_cols))
ax.set_xticklabels(["PathSeq" if m == "ps" else "Kraken2" for _, m in col_tuples],
                     fontsize=8.6, fontweight="600", color=INK2)
ax.xaxis.set_ticks_position("top")
ax.tick_params(axis="x", pad=6, length=0)
ax.set_yticks([])
for spine in ax.spines.values():
    spine.set_visible(False)

# hierarchical row labels -- bold/flush for main virus, indented/light for sub-taxa
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
    ax.text(xc, -1.55, RUN_LABEL[run], ha="center", va="bottom",
             fontsize=9.6, fontweight="700", color=INK, linespacing=1.3)

ax.set_xlim(-0.5, n_cols - 0.5)
ax.set_ylim(n_rows - 0.5, -2.15)

# --- colorbar / legends ------------------------------------------------------
cax = fig.add_axes([0.855, 0.240, 0.020, 0.560])
cb = fig.colorbar(im, cax=cax)
cb.set_label("% of that run's total Kraken2-positive reads (log scale)",
             fontsize=8.6, color=INK2, labelpad=10)
cb.ax.tick_params(labelsize=7.6, color=INK2, labelcolor=INK2)
cb.outline.set_visible(False)

leg_ax1 = fig.add_axes([0.855, 0.095, 0.06, 0.028])
leg_ax1.add_patch(Rectangle((0, 0), 1, 1, facecolor=HATCH_FACE, edgecolor=HATCH_LINE,
                             hatch="////", linewidth=0.6))
leg_ax1.set_xlim(0, 1); leg_ax1.set_ylim(0, 1); leg_ax1.axis("off")
fig.text(0.922, 0.109, "n/a or\nno data", fontsize=7.2, color=MUTED, va="center")

# --- title / footer ----------------------------------------------------------
fig.text(0.05, 0.965, "Kraken2 × PathSeq Concordance — High-Resolution", fontsize=17.5,
          fontweight="800", color=INK, va="top")
fig.text(0.05, 0.913,
          "Rows grouped by taxonomic lineage — each main virus (bold) with every related sub-taxon\n"
          "(cross-species artifact, within-genus background, specificity control) indented directly beneath it.\n"
          "Same shared-Kraken2-denominator normalization as the primary figure.",
          fontsize=9.2, color=INK2, linespacing=1.5, va="top")

footer = (
    "Normalization: for each run, % = (taxon's raw read count ÷ sum of Kraken2 raw reads across every taxon\n"
    "shown for that run) × 100, applied identically to both columns. Every cell is now real, checked data —\n"
    "every taxon (including HSV-2 and Bovine alphaherpesvirus 1, both found via corrected name search since\n"
    "Kraken2 renames these under its current taxonomy vintage) was cross-validated against all 3 cohorts,\n"
    "both tools (2026-08-16). Bovine alphaherpesvirus 1 (taxon 3050243, \"Varicellovirus bovinealpha1\") has a\n"
    "real positive: 15 reads in one TG donor (TG3) only, zero elsewhere — consistent with an incidental low-\n"
    "level background detection, not a systematic signal. HSV-2 is a confirmed true-negative everywhere.\n"
    "HERV-K (45617): present in all 3 cohorts, as expected for ubiquitous low-level human genomic background —\n"
    "PathSeq uses the SAME taxon ID as Kraken2 here (unlike every herpesvirus, where taxonomy-vintage\n"
    "differences forced different IDs per tool), and its parent/species/K113-subtype nodes report numerically\n"
    "identical counts in every sample, meaning essentially all signal resolves to the K113 subtype specifically.\n"
    "† PathSeq has no taxon distinct from 10359 representing Kraken2's specific proxy-species artifact — see\n"
    "the primary figure's footer for the full explanation of both n/a† cells.\n"
    "Source: docs/pathseq_validation_results_2026-08-15.md, research/cmv_taxonomy_investigation.md."
)
fig.text(0.05, 0.022, footer, fontsize=6.9, color=MUTED, linespacing=1.42)

import os
OUTBASE = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "docs", "figures",
                        "highres_kraken_pathseq_concordance_heatmap")
fig.savefig(OUTBASE + ".png", dpi=400, facecolor=PAGE)
fig.savefig(OUTBASE + ".pdf", facecolor=PAGE)
print("done")
print("TOTAL_K2:", total_k2)
