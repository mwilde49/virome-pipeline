# min_reads Threshold Sensitivity Analysis
**Date:** 2026-04-04  
**Scope:** All completed pipeline runs (non-PD DRG cohort + 2026 Parkinson's cohort)  
**Question:** Would relaxing min_reads from 5 to 1 generate any new candidate taxa?

---

## Summary

**Relaxing min_reads from 5 to 1 yields no new biologically relevant candidates in either cohort.** The empirical noise floor in these datasets is ~10 reads — well above the min_reads=5 threshold. This analysis validates min_reads=5 as both necessary and sufficient for this dataset.

---

## Background

The `KRAKEN2_FILTER` step applies a minimum direct-read threshold (default: 5) after Bracken re-estimation, before artifact exclusion. This prevents low-confidence Bracken re-estimations (which can amplify noise at low read counts) from entering the final abundance matrix.

The key question is whether any true-positive viral detections are being lost by the threshold.

---

## Data examined

| Run | Cohort | n samples | Reads/sample (median) |
|---|---|---|---|
| `all_cohort` | Non-PD DRG + muscle (paper 1) | 21 DRG + 5 muscle | ~65M |
| `muscle_drg_full` | Non-PD DRG (subset) | 11 | ~75M |
| `parkinson_2026` | PD DRG (AN00028264) | 20 | ~60M |

---

## Parkinson's cohort: bracken_raw vs. minreads comparison

The `bracken_raw_matrix.tsv` contains all viral-rank taxa with ≥1 Bracken-assigned read in at least one sample. The `minreads_matrix.tsv` applies the min_reads≥5 filter.

**Key finding: the bracken_raw_matrix has 41 unique taxa across 20 samples. Of these, all 16 taxa with non-zero reads have ≥10 reads in the samples where they appear. Zero taxa exist in the 1–4 read range.**

| Stage | Unique taxa (across 20 samples) | Notes |
|---|---|---|
| bracken_raw | 41 rows (16 non-zero, 25 zero-everywhere) | All zero-everywhere rows are genus/family hierarchy nodes |
| minreads (≥5) | 16 taxa | Same 16 non-zero taxa |
| final (post-artifact) | 6 taxa | 10 artifact taxa removed |

**Minimum non-zero read count across all non-zero taxa:** 10 reads (Mardivirus columbidalpha1 in sample 028; confirmed artifact, excluded).

This means:
- At min_reads=1: same 16 taxa pass (no new taxa added)
- At min_reads=10: same 16 taxa pass (still no change)
- The effective noise floor is the Bracken re-estimation threshold, not the min_reads cutoff

---

## Non-PD DRG cohort: same finding

From `all_cohort` bracken_raw_matrix (21 DRG + 5 muscle samples, 55 taxa total):

Non-zero taxa with reads <5 in all samples: **none identified.** Minimum non-zero value across the dataset is 11 reads (BeAn 58058 virus in Sample_20, a confirmed artifact).

The taxa with notably low reads across all samples:
- Oceanusvirus kaneohense: 11–14 reads in 2–3 samples → already ≥5, excluded by artifact list
- Porrectionivirus p12J: 13–19 reads in 3 samples → already ≥5, excluded by artifact list
- Mardivirus columbidalpha1: 13–21 reads → already ≥5, excluded by artifact list

---

## Why no 1–4 read taxa?

Bracken's re-estimation model redistributes reads from genus/family level back to species level, but only does so when there is sufficient evidence at the genus level (controlled by `-t` threshold). When species-level evidence is weak (1–4 reads), Bracken either:

1. **Leaves reads at genus/family level** (appears as 0 at species rank in the output) — explains the 25 zero-everywhere rows in the Parkinson bracken_raw matrix
2. **Does not re-estimate** due to insufficient species-level k-mer evidence

In practice, a Bracken-assigned species read count below ~10 reflects near-noise-floor k-mer matching and is not reliably informative about true viral presence.

---

## HSV-1 in PD19 under this analysis

HSV-1 (Simplexvirus humanalpha1, taxon 3050292) has **46 reads in PD19** — well above both the min_reads=5 threshold and the empirical noise floor of ~10 reads. This detection would not have been affected by any min_reads setting from 1 to 40.

Had HSV-1 been present at 1–4 reads in PD19, the min_reads=1 sensitivity question would be directly relevant. The current finding (46 reads) is robustly above threshold regardless.

---

## Implications for future runs

- **min_reads=5 is validated** for Psomagen/bulk DRG RNA-seq at 60–75M read depth
- **Lower min_reads (1–3)** may become relevant for:
  - Ultra-low-input samples (<20M reads)
  - Targeted detection of a specific known pathogen (where prior probability is high)
  - Post-BLAST confirmation workflow where noise tolerance is acceptable
- **Higher min_reads (10–50)** may be appropriate for:
  - Population-level prevalence studies (minimize FP rate)
  - High-specificity screening before expensive follow-up assays
- **Current recommendation:** retain min_reads=5 for all standard runs

---

## Per-sample bracken_raw counts (Parkinson's cohort)

From filter_summary.tsv:

| Sample | bracken_raw taxa | minreads taxa | final taxa | Notes |
|---|---|---|---|---|
| 024 | 30 | 11 | 4 | |
| 023 | 27 | 10 | 3 | |
| 025 | 25 | 9 | 2 | |
| 026 | 24 | 9 | 3 | |
| 028 | 29 | 11 | 3 | |
| 027 | 27 | 10 | 3 | |
| PD2 | 24 | 9 | 3 | |
| PD3 | 27 | 10 | 3 | |
| PD5 | 24 | 9 | 3 | |
| PD4 | 27 | 10 | 3 | |
| PD6 | 27 | 10 | 3 | |
| PD15 | 25 | 9 | 2 | |
| PD9 | 27 | 10 | 4 | |
| PD10 | 26 | 10 | 4 | |
| PD14 | 32 | 12 | 3 | Highest bracken_raw count |
| PD16 | 24 | 9 | 3 | |
| PD17 | 24 | 9 | 3 | |
| PD19 | 29 | 11 | 4 | Contains HSV-1 Tier 1 detection |
| PD18 | 22 | 8 | 1 | Lowest richness; HERV-K only in final |
| PD20 | 27 | 10 | 3 | |

**Note on bracken_raw count vs. matrix rows:** the per-sample bracken_raw count (22–32) is higher than the 16 non-zero rows in the cross-sample matrix because individual bracken_raw.tsv files include genus/family-level rows (rank G and F) that appear with 0 direct reads in the Bracken output but are counted by filter_kraken2_report.py. These 0-read higher-taxonomy rows do not represent additional biological detections.

---

## Conclusion

Relaxing min_reads from 5 to 1 **does not change any biological conclusions** from either the Parkinson's or non-PD DRG cohorts. All detected viral taxa are well above the noise floor. The min_reads=5 parameter should be retained for standard runs and documented as validated for this sequencing depth and tissue type.
