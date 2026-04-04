# Data Intake Report — 2026 Parkinson's DRG Cohort
**Date:** 2026-04-04
**Sequencing provider:** Psomagen (order AN00028264)
**Local path:** `C:\users\mwild\firebase2\bulk_rnaseq\2026_ParkinsonsDRG\AN00028264\`
**Juno destination:** `/groups/tprice/data/2026_ParkinsonsDRG/`

---

## Cohort Summary

| Group | Sample IDs | n |
|---|---|---|
| Parkinson's disease (DRG) | PD2, PD3, PD4, PD5, PD6, PD9, PD10, PD14, PD15, PD16, PD17, PD18, PD19, PD20 | 14 |
| Unclassified (numeric) | 023, 024, 025, 026, 027, 028 | 6 |
| **Total** | | **20** |

**⚠ Clarification needed:**
- Numeric samples (023–028): are these healthy DRG controls, a different disease group, or a different tissue? Must be confirmed before grouping in any comparative analysis.
- Missing PD IDs: PD1, PD7, PD8, PD11, PD12, PD13 are absent. Were these excluded due to QC failure, not yet delivered, or are they in a separate sequencing batch?

---

## File Inventory

| Sample | R1 size | R2 size | MD5 status |
|---|---|---|---|
| 023 | 2.0 GB | 2.0 GB | pending |
| 024 | 1.8 GB | 1.8 GB | pending |
| 025 | 1.4 GB | 1.4 GB | pending |
| 026 | 1.7 GB | 1.7 GB | pending |
| 027 | 1.9 GB | 1.8 GB | pending |
| 028 | 1.8 GB | 1.8 GB | pending |
| PD2 | 1.4 GB | 1.4 GB | pending |
| PD3 | 1.5 GB | 1.4 GB | pending |
| PD4 | 1.7 GB | 1.7 GB | pending |
| PD5 | 1.7 GB | 1.6 GB | pending |
| PD6 | 1.6 GB | 1.6 GB | pending |
| PD9 | 1.6 GB | 1.6 GB | pending |
| PD10 | 1.8 GB | 1.8 GB | pending |
| PD14 | 1.8 GB | 1.7 GB | pending |
| PD15 | 1.5 GB | 1.4 GB | pending |
| PD16 | 1.9 GB | 1.8 GB | pending |
| PD17 | 1.6 GB | 1.5 GB | pending |
| PD18 | 1.5 GB | 1.4 GB | pending |
| PD19 | 1.7 GB | 1.7 GB | pending |
| PD20 | 1.4 GB | 1.4 GB | pending |

**Total data volume:** ~68 GB (40 files)
**Library type:** Paired-end, bulk RNA-seq

---

## MD5 Verification

MD5 checksums provided by Psomagen (one .md5 file per sample, two checksums per file: R1 and R2).
Verification run: `cd <local_dir> && cat *.md5 > all.md5 && md5sum -c all.md5`

**Status:** Running at time of report generation. Update table above once complete.
After transfer to Juno, re-verify on cluster before starting pipeline run.

---

## Pipeline Run Plan

- **Pipeline version:** v1.4.0
- **Mode:** Dual-database competitive classification (viral-only + PlusPF)
- **Samplesheet:** `assets/samplesheets/samplesheet_parkinson_2026_juno.csv`
- **Run config:** `assets/config_parkinson_2026.yaml`
- **Transfer script:** `scripts/transfer_parkinson_2026.sh`
- **Expected outdir:** `/scratch/juno/maw210003/virome_parkinson_2026/`

### Transfer checklist

- [ ] Local MD5 verification complete and all OK
- [ ] GitHub auth refreshed (`gh auth login`)
- [ ] v1.4.0 pushed to origin (`git push origin main --tags`)
- [ ] FASTQs rsync'd to Juno (`bash scripts/transfer_parkinson_2026.sh`)
- [ ] Juno-side MD5 re-verification complete
- [ ] Samplesheet and config confirmed present at Juno pipeline path
- [ ] Compute node obtained (`srun --account=tprice ...`)
- [ ] Pipeline launched

### Scientific context

This is the first PD-specific DRG cohort run through virome-pipeline. Key comparisons to
the paper 1 baseline (Tier 1 = 0 in healthy/uncharacterized DRG):

- If any Tier 1 taxa appear in PD DRG: candidate viral contributors to PD neuropathy
- HERV-K DRG enrichment (5.8× over muscle in baseline): test whether PD DRG shows
  further de-repression (neuroinflammation via NF-κB is elevated in PD; could drive
  HERV-K LTR activation)
- Numeric controls (023–028), if confirmed healthy DRG, provide the first proper
  matched PD vs. control comparison in this pipeline

---

## Open Questions Before Analysis

1. **Tissue type of 023–028**: DRG? Which spinal level(s)?
2. **Clinical metadata for PD samples**: age, sex, PD subtype, Braak stage, disease duration, medications?
3. **Missing sample IDs (PD1, 7, 8, 11, 12, 13)**: excluded or forthcoming?
4. **Read length**: confirm 150 bp (assumed; Bracken is set for 150 bp in config)
5. **Strandedness**: confirm stranded library prep (affects downstream DE analysis)
