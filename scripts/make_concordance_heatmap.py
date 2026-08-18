#!/usr/bin/env python3
"""
Kraken2 vs PathSeq concordance heatmap -- static figure (PNG + PDF).

Normalization (per explicit spec): for each cohort/run, define
    TOTAL_K2(run) = sum of Kraken2 raw read counts, summed across all
                    samples in that run, for every taxon plotted for that run.
Both the PathSeq column and the Kraken2 column for that run are then expressed
as (taxon raw reads / TOTAL_K2(run)) x 100 -- i.e. BOTH methods share the same
denominator (Kraken2's own total), so the two columns are directly comparable
on one shared color scale. This deliberately does NOT use PathSeq's own
score_normalized (which is normalized against PathSeq's much larger
background-inclusive read pool) -- the whole point is to expose PathSeq's
raw-count sensitivity relative to Kraken2's, not to let each method flatter
itself against its own denominator.

Source data: docs/pathseq_validation_results_2026-08-15.md and
research/cmv_taxonomy_investigation.md (both already fact-checked earlier in
this investigation -- see the 2026-08-16 correction note in the results doc
for the one transcription error caught and fixed).
"""

import numpy as np
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
from matplotlib.colors import LinearSegmentedColormap, LogNorm
from matplotlib.patches import Rectangle

# ---------------------------------------------------------------------------
# Raw per-sample read counts (Kraken2 = raw classified reads; PathSeq = raw
# "mean reads" field from pathseq_abundance_matrix.tsv's aggregated blocks).
# ---------------------------------------------------------------------------

RUNS = ["cmv", "tg", "ebv"]
RUN_LABEL = {"cmv": "CMV Fibroblast\n(4 samples)", "tg": "TG Ganglia\n(5 donors)",
             "ebv": "EBV Lymphoblastoid\n(2 replicates)"}

K2_RAW = {
    "cmv": {
        "cmv":        [1588558, 3969423, 5841101, 1985167],
        "cerco_cmv":  [833, 1795, 3154, 0],
        "chimp_cmv":  [288, 236, 211, 60],
        "cmv_proxy":  [0, 0, 0, 0],
        # Cross-validation (2026-08-16): CMV cohort checked for the other
        # cohorts' expected taxa too, not just assumed n/a. HSV-1 is a real,
        # non-zero, time-course-tracking finding (see research doc); VZV/EBV
        # confirmed true-negative (0 reads, not "never checked").
        "hsv1": [0, 12, 18, 22],
        "vzv":  [0, 0, 0, 0],
        "ebv":  [0, 0, 0, 0],
        "ebv_cross": [0, 0, 0, 0],  # confirmed true-negative, 2026-08-16
    },
    "tg": {
        "hsv1": [8267423, 11707977, 17540230, 49372617, 10575993],
        "vzv":  [409012, 877025, 50682, 471534, 209184],
        "cmv":  [0, 0, 0, 0, 0],  # confirmed true-negative, 2026-08-16
        "ebv":  [0, 0, 0, 0, 0],  # confirmed true-negative, 2026-08-16
        "cmv_proxy": [0, 0, 0, 0, 0],  # confirmed true-negative, 2026-08-16
        "ebv_cross": [0, 0, 0, 0, 0],  # confirmed true-negative, 2026-08-16
        "cerco_cmv": [0, 0, 0, 0, 0],  # confirmed true-negative, 2026-08-16
        "chimp_cmv": [0, 0, 0, 0, 0],  # confirmed true-negative, 2026-08-16
    },
    "ebv": {
        "ebv":       [250052, 184950],
        "ebv_cross": [6948, 2861],
        "cmv_proxy": [71, 90],
        "cmv":  [0, 0],  # confirmed true-negative, 2026-08-16
        "hsv1": [0, 0],  # confirmed true-negative, 2026-08-16
        "vzv":  [0, 0],  # confirmed true-negative, 2026-08-16
        "cerco_cmv": [0, 0],  # confirmed true-negative, 2026-08-16
        "chimp_cmv": [0, 0],  # confirmed true-negative, 2026-08-16
    },
}

PS_RAW = {
    "cmv": {
        "cmv": [643233, 1133300, 1515321, 690672],
        # cmv_proxy: not applicable (10359 IS the real signal here)
        # HSV-1 cross-validation: corroborates the Kraken2 finding above --
        # same real, near-zero-then-rising pattern, independently observed.
        "hsv1": [0, 2, 10, 9],
        "vzv":  [0, 0, 0, 0],
        "ebv":  [0, 0, 0, 0],
        "ebv_cross": [0, 0, 0, 0],  # confirmed true-negative, 2026-08-16
        # Real PathSeq-specific taxon IDs (distinct from Kraken2's, same
        # taxonomy-vintage pattern as every other cross-species taxon here):
        "cerco_cmv": [1.9333, 5.7, 1.9333, 0.4],       # taxon 50292
        "chimp_cmv": [165.35, 252.8, 338.1, 169.15],   # taxon 188763
    },
    "tg": {
        "hsv1": [1464209.5, 1816717.6667, 2251920.3333, 7677324.5, 1910915.6667],
        "vzv":  [51931, 94193, 8026, 63180, 24633],
        "cmv":  [0, 0, 0, 0, 0],  # confirmed true-negative, 2026-08-16
        "ebv":  [0, 0, 0, 0, 0],  # confirmed true-negative, 2026-08-16
        "ebv_cross": [0, 0, 0, 0, 0],  # confirmed true-negative, 2026-08-16
        "cerco_cmv": [0, 0, 0, 0, 0],  # confirmed true-negative, 2026-08-16
        "chimp_cmv": [0, 0, 0, 0, 0],  # confirmed true-negative, 2026-08-16
        # cmv_proxy: not applicable, no distinct PathSeq taxon (see CMV row)
    },
    "ebv": {
        "ebv":       [155795.3333, 118505.1667],
        "ebv_cross": [35.6667, 25.8333],
        "cmv_proxy": [0, 0],
        "cmv":  [0, 0],  # confirmed true-negative, 2026-08-16
        "hsv1": [0, 0],  # confirmed true-negative, 2026-08-16
        "vzv":  [0, 0],  # confirmed true-negative, 2026-08-16
        "cerco_cmv": [0, 0],  # confirmed true-negative, 2026-08-16
        "chimp_cmv": [0, 0],  # confirmed true-negative, 2026-08-16
    },
}

TAXA = [
    ("Human CMV (HHV-5)", "Cytomegalovirus humanbeta5 · 10359", "cmv"),
    ("HSV-1 (HHV-1)", "Human alphaherpesvirus 1 · 10298", "hsv1"),
    ("VZV (HHV-3)", "Human alphaherpesvirus 3 · 10335", "vzv"),
    ("EBV (HHV-4)", "Human gammaherpesvirus 4 · 10376", "ebv"),
    ("Baboon/NHP CMV cross-map", "Cytomegalovirus papiinebeta3 · 3050337", "cmv_proxy"),
    ("Baboon/macaque EBV cross-map", "Lymphocryptovirus/Macacine gamma-4 · 3050339 / 45455", "ebv_cross"),
    ("Cercopithecine CMV (bg)", "Cytomegalovirus cercopithecinebeta5 · 3050258", "cerco_cmv"),
    ("Chimp/Pan CMV (bg)", "Cytomegalovirus paninebeta2 · 3050334", "chimp_cmv"),
]
TAXA_BY = {t[2]: t for t in TAXA}

# Display order: group-header rows interleaved with data rows (matches the
# same pattern already used successfully in the interactive HTML version --
# a horizontal, full-width section label instead of a rotated side label
# that has no room to avoid its neighbor at this row density).
DISPLAY_ROWS = [
    ("header", "Primary signal"),
    ("data", "cmv"), ("data", "hsv1"), ("data", "vzv"), ("data", "ebv"),
    ("header", "Cross-species artifacts (reference-imbalance)"),
    ("data", "cmv_proxy"), ("data", "ebv_cross"),
    ("header", "Within-genus background (Cytomegalovirus spp.)"),
    ("data", "cerco_cmv"), ("data", "chimp_cmv"),
]

# Every taxon is now relevant (real, checked data) in every cohort -- each
# was cross-validated as a positive/negative control against the other two
# cohorts, 2026-08-16 (see docs/pathseq_validation_results_2026-08-15.md).
# Only two cells remain genuinely not-applicable rather than checked-and-
# zero: see NOT_APPLICABLE_SPECIAL below.
_ALL_TAXA = {"cmv", "hsv1", "vzv", "ebv", "cmv_proxy", "ebv_cross", "cerco_cmv", "chimp_cmv"}
RELEVANT = {"cmv": _ALL_TAXA, "tg": _ALL_TAXA, "ebv": _ALL_TAXA}
NO_DATA = set()  # every remaining cell filled with real data, 2026-08-16
# Both remaining n/a cells are conceptual, not missing data: PathSeq has no
# taxon distinct from 10359 (Human CMV) representing Kraken2's specific
# proxy-species artifact, so "does the proxy appear" isn't a question
# PathSeq's own taxonomy can separately answer -- in the CMV cohort that's
# because 10359 already IS the correctly-identified real signal (tracked in
# the Human CMV row); in the TG cohort the equivalent genus-level question is
# already answered by the Human CMV row's confirmed 0%.
NOT_APPLICABLE_SPECIAL = {("cmv_proxy", "cmv", "ps"), ("cmv_proxy", "tg", "ps")}

# ---------------------------------------------------------------------------
# Build TOTAL_K2 per run, then the % matrix over DISPLAY_ROWS
# ---------------------------------------------------------------------------

total_k2 = {run: sum(sum(v) for v in K2_RAW[run].values()) for run in RUNS}

col_tuples = []
for run in RUNS:
    col_tuples += [(run, "ps"), (run, "k2")]
n_cols = len(col_tuples)
n_rows = len(DISPLAY_ROWS)

values = np.full((n_rows, n_cols), np.nan)
reads = np.full((n_rows, n_cols), np.nan)  # raw read sum backing each %, for the sub-label
kind = np.full((n_rows, n_cols), "value", dtype=object)  # value|zero|na|nodata|header
annot = np.full((n_rows, n_cols), "", dtype=object)

def fmt_reads(n):
    return f"{round(n):,}"

for ri, entry in enumerate(DISPLAY_ROWS):
    if entry[0] == "header":
        kind[ri, :] = "header"
        continue
    key = entry[1]
    for ci, (run, method) in enumerate(col_tuples):
        if key not in RELEVANT[run]:
            kind[ri, ci] = "na"; annot[ri, ci] = "n/a"; continue
        if (key, run, method) in NO_DATA:
            kind[ri, ci] = "nodata"; annot[ri, ci] = "no data"; continue
        if (key, run, method) in NOT_APPLICABLE_SPECIAL:
            kind[ri, ci] = "na"; annot[ri, ci] = "n/a†"; continue

        raw_sum = sum(K2_RAW[run][key]) if method == "k2" else sum(PS_RAW[run].get(key, []))
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
# Color mapping -- single shared blue sequential ramp, log scale
# ---------------------------------------------------------------------------

BLUE_STOPS = [
    "#cde2fb", "#b7d3f6", "#9ec5f4", "#86b6ef", "#6da7ec", "#5598e7",
    "#3987e5", "#2a78d6", "#256abf", "#1c5cab", "#184f95", "#104281", "#0d366b",
]
cmap = LinearSegmentedColormap.from_list("blue_seq", BLUE_STOPS, N=256)
cmap.set_bad(color="none")

EPS = 1e-3
VMIN, VMAX = EPS, 100.0
norm = LogNorm(vmin=VMIN, vmax=VMAX)

color_values = np.where(values <= 0, EPS, values)
color_values = np.where(np.isnan(values), np.nan, color_values)

# ---------------------------------------------------------------------------
# Plot
# ---------------------------------------------------------------------------

INK = "#0b0b0b"
INK2 = "#52514e"
MUTED = "#898781"
GRID = "#ffffff"
HATCH_FACE = "#efeee8"
HATCH_LINE = "#c9c7bd"
SURFACE = "#fcfcfb"
PAGE = "#f4f3ef"
HEADER_BG = "#e9e7df"

plt.rcParams["font.family"] = "DejaVu Sans"
fig = plt.figure(figsize=(13.2, 9.0), dpi=200, facecolor=PAGE)
AX_LEFT, AX_BOTTOM, AX_W, AX_H = 0.235, 0.195, 0.585, 0.60
ax = fig.add_axes([AX_LEFT, AX_BOTTOM, AX_W, AX_H])
ax.set_facecolor(SURFACE)

masked = np.ma.masked_invalid(color_values)
im = ax.imshow(masked, cmap=cmap, norm=norm, aspect="auto", interpolation="nearest")

for ri in range(n_rows):
    if kind[ri, 0] == "header":
        ax.add_patch(Rectangle((-0.5, ri - 0.5), n_cols, 1,
                                facecolor=HEADER_BG, edgecolor="none", zorder=2))
        ax.text(-0.5 + 0.12, ri, DISPLAY_ROWS[ri][1], ha="left", va="center",
                 fontsize=8.6, fontweight="700", color=INK2, zorder=3)
        continue
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

# gridlines
ax.set_xticks(np.arange(-0.5, n_cols, 1), minor=True)
ax.set_yticks(np.arange(-0.5, n_rows, 1), minor=True)
ax.grid(which="minor", color=GRID, linewidth=2.2)
ax.tick_params(which="minor", length=0)

# column-group separators -- confined to each contiguous data-row block so
# they don't run through (and visually cut) the header band text above them
data_blocks = []
block_start = None
for ri, e in enumerate(DISPLAY_ROWS):
    if e[0] == "data" and block_start is None:
        block_start = ri
    elif e[0] != "data" and block_start is not None:
        data_blocks.append((block_start, ri - 1))
        block_start = None
if block_start is not None:
    data_blocks.append((block_start, n_rows - 1))

for ci in (1.5, 3.5):
    for lo, hi in data_blocks:
        ax.vlines(ci, lo - 0.5, hi + 0.5, color=INK, linewidth=1.4, zorder=4)

# thin rule under each header row (visually separates the section from its data)
for ri in range(n_rows):
    if kind[ri, 0] == "header":
        ax.axhline(ri + 0.5, color=INK, linewidth=1.1, zorder=4)
ax.axhline(-0.5, color=INK, linewidth=1.1, zorder=4)

# axis ticks/labels
ax.set_xticks(range(n_cols))
ax.set_xticklabels(["PathSeq" if m == "ps" else "Kraken2" for _, m in col_tuples],
                     fontsize=8.6, fontweight="600", color=INK2)
ax.xaxis.set_ticks_position("top")
ax.tick_params(axis="x", pad=6, length=0)

ytick_labels = [(TAXA_BY[e[1]][0] if e[0] == "data" else "") for e in DISPLAY_ROWS]
ax.set_yticks(range(n_rows))
ax.set_yticklabels(ytick_labels, fontsize=9.2, color=INK)
ax.tick_params(axis="y", length=0)
for spine in ax.spines.values():
    spine.set_visible(False)

# latin/taxid subtext under each data row's label
for ri, e in enumerate(DISPLAY_ROWS):
    if e[0] == "data":
        latin = TAXA_BY[e[1]][1]
        ax.text(-0.62, ri + 0.30, latin, ha="right", va="top",
                 fontsize=6.6, color=MUTED, transform=ax.transData, style="italic")

# cohort group headers above the PathSeq/Kraken2 sub-labels
for gi, run in enumerate(RUNS):
    xc = gi * 2 + 0.5
    ax.text(xc, -1.55, RUN_LABEL[run], ha="center", va="bottom",
             fontsize=9.6, fontweight="700", color=INK, linespacing=1.3)

ax.set_xlim(-0.5, n_cols - 0.5)
ax.set_ylim(n_rows - 0.5, -2.15)

# --- colorbar ---------------------------------------------------------------
cax = fig.add_axes([0.855, 0.195, 0.022, 0.60])
cb = fig.colorbar(im, cax=cax)
cb.set_label("% of that run's total Kraken2-positive reads (log scale)",
             fontsize=8.6, color=INK2, labelpad=10)
cb.ax.tick_params(labelsize=7.6, color=INK2, labelcolor=INK2)
cb.outline.set_visible(False)

leg_ax = fig.add_axes([0.855, 0.095, 0.075, 0.032])
leg_ax.add_patch(Rectangle((0, 0), 1, 1, facecolor=HATCH_FACE, edgecolor=HATCH_LINE,
                            hatch="////", linewidth=0.6))
leg_ax.set_xlim(0, 1); leg_ax.set_ylim(0, 1)
leg_ax.axis("off")
fig.text(0.945, 0.111, "n/a or\nno data", fontsize=7.2, color=MUTED, va="center")

# --- title / footer ----------------------------------------------------------
fig.text(0.055, 0.965, "Kraken2 × PathSeq Concordance", fontsize=18,
          fontweight="800", color=INK, va="top")
fig.text(0.055, 0.905,
          "Every taxon called across three real virus-positive validation cohorts, both methods\n"
          "expressed as a percent of that run's own Kraken2 total — the shared denominator that\n"
          "makes the two columns directly, sensitivity-comparably readable.",
          fontsize=9.4, color=INK2, linespacing=1.5, va="top")

footer = (
    "Normalization: for each run, % = (taxon's raw read count ÷ sum of Kraken2 raw reads across all rows\n"
    "shown for that run) × 100 — applied identically to both the PathSeq and Kraken2 columns, so a lower\n"
    "PathSeq % than Kraken2 % in the same row directly reflects PathSeq recovering fewer raw reads against\n"
    "the same yardstick (sensitivity), not a different unit. Every cell is now real, checked data — every\n"
    "taxon was cross-validated as a positive/negative control against all 3 cohorts, both tools (2026-08-16).\n"
    "† PathSeq has no taxon distinct from 10359 representing Kraken2's specific proxy-species artifact: in\n"
    "the CMV cohort 10359 already IS the correctly-identified real signal (see the Human CMV row); in the\n"
    "TG cohort the equivalent genus-level question is already answered by that same row's confirmed 0%.\n"
    "Source: docs/pathseq_validation_results_2026-08-15.md, research/cmv_taxonomy_investigation.md."
)
fig.text(0.055, 0.025, footer, fontsize=7.4, color=MUTED, linespacing=1.55)

import os
OUTBASE = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "docs", "figures",
                        "kraken_pathseq_concordance_heatmap")
fig.savefig(OUTBASE + ".png", dpi=300, facecolor=PAGE)
fig.savefig(OUTBASE + ".pdf", facecolor=PAGE)
print("done")
print("TOTAL_K2:", total_k2)
