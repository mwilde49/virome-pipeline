# DRG Virome Project — Comprehensive State Report
**Date:** 2026-04-04
**Author:** Matthew Wilde (mwilde49)
**Pipeline version:** 1.4.0
**Affiliation:** UT Dallas, TJP group (Dr. Theodore Price Lab)

---

## Table of Contents

1. [Executive Summary](#1-executive-summary)
2. [Cohort Inventory](#2-cohort-inventory)
3. [Pipeline Maturation](#3-pipeline-maturation)
4. [Key Scientific Findings](#4-key-scientific-findings)
5. [min_reads Sensitivity Analysis](#5-min_reads-sensitivity-analysis)
6. [PD vs. Non-PD DRG Comparison](#6-pd-vs-non-pd-drg-comparison)
7. [PD19 HSV-1: Assessment and Next Steps](#7-pd19-hsv-1-assessment-and-next-steps)
8. [Open Questions and Blockers](#8-open-questions-and-blockers)
9. [Future Directions](#9-future-directions)

---

## 1. Executive Summary

The DRG Virome Project has completed its first full comparative run across two distinct clinical contexts: a non-PD baseline DRG cohort (n=21 samples, 16 unique after duplicate exclusion) and a newly acquired Parkinson's disease DRG cohort (n=20 samples from Psomagen order AN00028264). As of 2026-04-04, all pipeline runs have been completed locally, dual-database validation has been applied to both cohorts, and results have been pulled and analyzed. The pipeline has matured from a single-database Kraken2+Bracken prototype to a production-grade dual-database virome profiler with artifact exclusion, taxon remapping, HTML report generation, and a BLAST verification offshoot pipeline for Tier 1 candidate follow-up.

The scientific trajectory of this project reached a significant inflection point today with the completion of the parkinson_2026 run. For the first time across more than 40 DRG RNA-seq samples, a Tier 1 (dual-database confirmed) viral detection has been observed: HSV-1 (Simplexvirus humanalpha1, taxon 3050292) in sample PD19, with 46 reads and 1.89 RPM. This is the only sample out of 20 PD cohort samples to show any confirmed viral signal, and HSV-1 was completely absent from all 16 unique samples in the non-PD baseline cohort. The finding is biologically plausible — HSV-1 establishes latency in sensory ganglia — and is PD-specific in this dataset, but the read count is low and BLAST validation has not yet been performed. No conclusions about PD-associated viral biology should be drawn until validation is complete.

The non-PD baseline established a clear null result: Tier 1 = 0 across all 14 biologically interpretable samples, with three mechanistically explained Tier 2 false positives (HERV-K, CMV proxy, MCV). The HERV-K DRG enrichment signal (5.8x over muscle baseline) is now a robust finding across two independent DRG donor cohorts and is being reported as a primary result characterizing HERV-K expression in human sensory ganglia. The pipeline's artifact exclusion system has curated 24 taxa and has performed consistently across all runs. The project is positioned to submit a manuscript on the non-PD baseline and is generating the first comparative PD-vs-control DRG virome data in the literature.

---

## 2. Cohort Inventory

### 2.1 All Completed Pipeline Runs

| Run name | Pipeline version | Samples (n) | Tissue type | DB mode | Key finding | Status |
|---|---|---|---|---|---|---|
| `muscle_cohort` / `muscle_cohort_v3` | v1.0 | 5 (Sample_19–23) | Skeletal muscle | Single-DB | HERV-K 27–33 RPM; MCV sporadic | Complete |
| `muscle_drg_combined` | v1.0–v1.1 | 5 muscle + subset DRG | Muscle + DRG | Single-DB | DRG > muscle HERV-K | Complete |
| `muscle_drg_full` | v1.2.0 | 5 muscle + 11 DRG | Muscle + DRG | Single-DB | CMV proxy DRG-enriched; taxon remapping applied | Complete |
| `all_cohort` | v1.2.0 | 38 (21 unique + AIG1390 dupes + REJOIN) | Muscle + DRG | Single-DB | AIG1390 = donor1 confirmed duplicate | Complete |
| `pluspf_comparison` | v1.3.0 | 3 | Mixed | Dual-DB (config bug: PlusPF/PlusPF) | Config corrected post-run | Complete (superseded) |
| `pluspf_comparison_v2` | v1.3.0 | 3 | Mixed | Dual-DB (corrected) | Pilot confirms Tier 1 = 0 | Complete |
| `pluspf_v3` | v1.3.0 | 3 | Mixed | Dual-DB | Tier 1 = 0; Tier 2 = 3 | Complete |
| `fullcohort_pluspf` | v1.3.0 | 21 processed / 16 unique | Muscle + DRG | Dual-DB | **Tier 1 = 0 confirmed at cohort scale; HERV-K 5.8x DRG enrichment** | Complete |
| **`parkinson_2026`** | v1.4.0 | 20 (14 PD + 6 numeric) | DRG | Dual-DB | **Tier 1 = 1: HSV-1 in PD19 (46 reads, 1.89 RPM)** | Complete 2026-04-04 |

### 2.2 Non-PD DRG Baseline Cohort — Sample Detail

| Sample ID | Tissue | Spinal level | Group | QC status | HERV-K reads | HERV-K RPM | Tier 1 |
|---|---|---|---|---|---|---|---|
| Sample_19 | Skeletal muscle | n/a | Muscle | OK | 610 | 34.9 | 0 |
| Sample_20 | Skeletal muscle | n/a | Muscle | OK | 522 | 31.6 | 0 |
| Sample_21 | Skeletal muscle | n/a | Muscle | OK | 757 | 27.2 | 0 |
| Sample_22 | Skeletal muscle | n/a | Muscle | OK | 510 | 29.4 | 0 |
| Sample_23 | Skeletal muscle | n/a | Muscle | OK | 747 | 33.4 | 0 |
| donor1_L1 | DRG | L1 | Donor 1 | OK | 2,637 | 36.7 | 0 |
| donor1_L2 | DRG | L2 | Donor 1 | OK | 1,912 | 28.4 | 0 |
| donor1_L3 | DRG | L3 | Donor 1 | Flagged (anomalous) | 4,502 | 49.1 | 0 |
| donor1_L4 | DRG | L4 | Donor 1 | OK | 4,532 | 56.2 | 0 |
| donor1_L5 | DRG | L5 | Donor 1 | OK | 7,725 | 46.7 | 0 |
| donor1_T12 | DRG | T12 | Donor 1 | OK | 1,772 | 57.7 | 0 |
| Saad_1 | DRG | mixed | Saad | QC outlier (430K bracken_raw reads) | 4,117 | 49.8 | 0 |
| Saad_2 | DRG | mixed | Saad | **Library failure** (HERV-K = 0) | 0 | 0.0 | 0 |
| Saad_3 | DRG | mixed | Saad | OK | 5,272 | 63.4 | 0 |
| Saad_4 | DRG | mixed | Saad | OK | 2,474 | 115.7* | 0 |
| Saad_5 | DRG | mixed | Saad | Moderate contamination | 1,759 | 61.9 | 0 |
| AIG1390_L1–T12 | DRG | L1–L4, T12 | AIG1390 | **Excluded (confirmed duplicate of donor1)** | n/a | n/a | n/a |

*Saad_4 RPM elevated by small library size; raw reads (2,474) are within normal range.

Note: Donor1_L3 shows an anomalous profile — HERV-K at 49.1 RPM (not zero), but high artifact signals (Gihfavirus, Kinglevirus, Betafusellovirus, Steinhofvirus, Colossusvirus, Chalconvirus). This pattern suggests contamination rather than true DRG biology; this sample should be interpreted with caution.

**Biologically interpretable non-PD samples: 14** (16 unique minus Saad_2 library failure, minus Saad_1 as flagged outlier for quantitative comparisons).

### 2.3 Parkinson's DRG Cohort — Sample Detail

Sequencing provider: Psomagen (order AN00028264). Received and MD5-verified 2026-04-04. Run: `parkinson_2026`, v1.4.0, dual-DB mode.

| Sample ID | Group | Bracken raw reads | Final reads | Tier 1 | Tier 2 (viral-only) | HERV-K RPM |
|---|---|---|---|---|---|---|
| 023 | Unclassified | 27 | 3 | 0 | 3 | 34.1 |
| 024 | Unclassified | 30 | 4 | 0 | 4 | 31.4 |
| 025 | Unclassified | 25 | 2 | 0 | 2 | 31.3 |
| 026 | Unclassified | 24 | 3 | 0 | 3 | 37.9 |
| 027 | Unclassified | 27 | 3 | 0 | 3 | 34.6 |
| 028 | Unclassified | 29 | 3 | 0 | 3 | 37.8 |
| PD2 | PD | 24 | 3 | 0 | 3 | 24.3 |
| PD3 | PD | 27 | 3 | 0 | 3 | 39.7 |
| PD4 | PD | 27 | 3 | 0 | 3 | 39.9 |
| PD5 | PD | 24 | 3 | 0 | 3 | 39.2 |
| PD6 | PD | 27 | 3 | 0 | 3 | 37.3 |
| PD9 | PD | 27 | 4 | 0 | 4 | 38.2 |
| PD10 | PD | 26 | 4 | 0 | 4 | 29.4 |
| PD14 | PD | 32 | 3 | 0 | 3 | 27.5 |
| PD15 | PD | 25 | 2 | 0 | 2 | 34.2 |
| PD16 | PD | 24 | 3 | 0 | 3 | 28.6 |
| PD17 | PD | 24 | 3 | 0 | 3 | 26.8 |
| PD18 | PD | 22 | 1 | 0 | 1 | 24.9 |
| **PD19** | **PD** | **29** | **4** | **1 (HSV-1, 46 reads)** | **3** | **26.9** |
| PD20 | PD | 27 | 3 | 0 | 3 | 28.9 |

Missing PD IDs: PD1, PD7, PD8, PD11, PD12, PD13 — absent from delivery; reason unconfirmed (QC failure, second batch, or excluded by provider).

---

## 3. Pipeline Maturation

### 3.1 Version History

| Version | Key additions | Date (approx.) |
|---|---|---|
| **v1.0** | FASTQC → TRIMMOMATIC → STAR host removal → KRAKEN2 → BRACKEN → KRAKEN2_FILTER → AGGREGATE → REPORT; single DB; basic HTML report | 2025 Q4 |
| **v1.1** | Bug fixes; stageInMode = 'copy' added; procps in containers; SLURM profile stabilized | Early 2026 |
| **v1.2.0** | `assets/taxon_remap.tsv` — display name remapping for misleading taxa (CMV proxy); `assets/artifact_taxa.tsv` — curated exclusion list (24 taxa at v1.2); remap applied across all three output matrices | 2026-01 |
| **v1.3.0** | Dual-database parallel branch (viral-only + PlusPF); three-tier output (Tier 1/2/3); `bin/compare_db_results.py`; `consensus_matrix.tsv`, `false_positive_candidates.tsv`, `db_comparison.tsv`; `db_comparison.png` in HTML report; validated across full 15-sample cohort (Tier 1 = 0) | 2026-03 |
| **v1.4.0** | Manuscript figures (`research/paper1/figures/`); conference abstract (500-word, submitted format); lab presentation (Powerpoint via `generate_presentation.py`); literature review completed; full-cohort PlusPF analysis used for figure generation; SRA submission prep | 2026-03-28 |
| **BLAST offshoot** | `blast_verify.nf` pipeline built today (2026-04-04): Tier 1 candidate identity confirmation, read-to-genome mapping, herpesvirus life cycle phase inference (IE/E/L/LAT gene classification); run config `assets/config_blast_pd19.yaml` | 2026-04-04 |

### 3.2 Architecture as of v1.4.0

The pipeline is a 7-step Nextflow DSL2 workflow running on the Juno HPC cluster via SLURM and Apptainer. All processes use separate container images. The dual-DB branch (DB2) is inactive by default and activates via a single `kraken2_db2` parameter.

```
raw FASTQs → FASTQC → TRIMMOMATIC → STAR_HOST_REMOVAL → KRAKEN2_CLASSIFY (DB1) → BRACKEN → KRAKEN2_FILTER ─┬→ AGGREGATE(final)
                                                         └→ KRAKEN2_CLASSIFY (DB2) → BRACKEN → KRAKEN2_FILTER ─┼→ AGGREGATE(pluspf)
                                                                                                                ├→ AGGREGATE(minreads)
                                                                                                                └→ AGGREGATE(bracken_raw)
                                                                                         └──────────────────────→ COMPARE_DATABASES → REPORT → MULTIQC
```

Five output channels per sample from KRAKEN2_FILTER: `filtered`, `bracken_raw`, `minreads`, `summary`, `artifacts`. Three abundance matrices produced per run: `viral_abundance_matrix.tsv` (primary), `minreads_matrix.tsv`, `bracken_raw_matrix.tsv`.

### 3.3 Artifact Exclusion System

`assets/artifact_taxa.tsv` contains 24 entries across these categories:
- Ruminant orthobunyaviruses (Schmallenberg, Simbu-related) — bovine k-mer cross-mapping
- Insect baculoviruses — Lepidoptera-derived k-mers found in neural tissue transcripts
- Environmental metagenome viruses (Gihfavirus, Kinglevirus) — DRG-exclusive, neuronal transcript k-mer artifacts
- Hantaviruses (Orthohantavirus oxbowense 3052491 + Oxbow virus 660954) — confirmed k-mer cross-mapping present in all tissue types
- Avian herpesviruses, giant amoeba viruses (Pandoravirus, Colossusvirus, Chalconvirus) — no biological plausibility in human DRG
- Phages — environmental contamination

The exclusion list is validated by minreads_matrix.tsv (artifacts present pre-exclusion, absent post-exclusion). ICTV taxonomy reclassification is a known fragility — taxon IDs must be re-verified after database updates (confirmed example: Ralstonia phage p12J 247080 → Porrectionivirus p12J 2956327).

---

## 4. Key Scientific Findings

### 4.1 HERV-K: Distribution, DRG Enrichment, PD Hypothesis Test

Human endogenous retrovirus K (HERV-K / HML-2, taxon 45617) is the dominant signal in all virome runs and has been the most informative finding despite being a false positive in the exogenous virus context.

**Distribution across all cohorts:**

| Cohort | n (interpretable) | HERV-K reads range | HERV-K RPM range | Mean RPM |
|---|---|---|---|---|
| Skeletal muscle | 5 | 510–757 | 27.2–34.9 | 31.3 |
| Non-PD DRG, donor1 | 6 | 1,772–7,725 | 28.4–57.7 | 45.8 |
| Non-PD DRG, Saad (usable) | 4 | 1,759–5,272 | 61.9–115.7* | 72.7* |
| PD DRG, controls 023–028 | 6 | 634–985 | 31.3–37.9 | 34.6 |
| PD DRG, PD samples | 14 | 475–999 | 24.3–39.9 | 31.8 |

*Saad_4 RPM inflated by small library size; raw reads consistent with other samples.

**DRG enrichment:** 5.8-fold over muscle (39,848 reads in DRG vs. 629/sample in muscle; fullcohort_pluspf run). Confirmed independently across donor1 and Saad cohorts. The enrichment is consistent across all 6 spinal levels (L1–L5, T12). The biological interpretation is HERV-K LTR promoter activity in post-mitotic sensory neurons — neural-lineage chromatin accessibility and higher transcriptional complexity — not exogenous retroviral infection. Under PlusPF competitive classification, all HERV-K reads are reclaimed to the Homo sapiens reference genome.

**PD de-repression hypothesis test:** HERV-K de-repression in neuroinflammatory conditions is biologically proposed (NF-κB elevation in PD could drive LTR activation). This dataset does not support the hypothesis. Mean HERV-K RPM in PD patients (31.8 RPM) is comparable to the numeric controls 023–028 (34.6 RPM) and to the non-PD muscle baseline (31.3 RPM). The DRG enrichment pattern observed in the non-PD cohort is absent in the PD cohort — PD DRG RPM values (24–40 RPM) are closer to the muscle range than to the non-PD DRG range (28–116 RPM, median ~45 RPM). This difference may reflect tissue quality, library preparation differences, or genuine biological differences between the cohorts, but it does not show PD-specific HERV-K elevation.

**Manuscript value:** HERV-K DRG enrichment (5.8x over muscle; reproducible across two independent DRG donor cohorts at 6 spinal levels) constitutes a primary finding about HERV-K expression in human sensory ganglia at bulk RNA-seq resolution — a tissue not previously characterized for endogenous retroviral transcription at this level of detail.

### 4.2 Confirmed Viral Detections (Tier 1)

**Non-PD cohort:** Tier 1 = 0 across all 16 unique samples (14 biologically interpretable). This result was first observed in the pluspf_v3 pilot (n=3) and confirmed at scale in fullcohort_pluspf (n=16 unique). No exogenous virus was confirmed in any DRG or muscle sample in the non-PD cohort. This is a biologically coherent null result — known DRG-tropic herpesviruses (HSV-1, VZV) maintain latency with minimal transcription below the bulk RNA-seq detection floor (~10 RPM in the host-depleted fraction).

**PD cohort:** Tier 1 = 1 — HSV-1 (Simplexvirus humanalpha1, taxon 3050292) in sample PD19 only. 46 reads, 1.89 RPM. This is the first confirmed dual-database viral detection across all DRG virome runs. Details and context in Section 7.

### 4.3 Tier 2 Background: Consistent Signal, Interpretation

Three Tier 2 (viral-only exclusive) taxa appear consistently across all runs:

**HERV-K (taxon 45617):** Present in 100% of samples with human RNA. Endogenous retroviral sequence; DRG-enriched. Reclaimed to Homo sapiens by PlusPF in all samples. Not a biological viral signal.

**Human CMV (HHV-5) proxy (taxon 3050337):** Present in 19/20 PD samples (absent from PD18 only) and in virtually all non-PD samples. ~1–2 RPM. The taxon (Cytomegalovirus papiinebeta3) arises from the 2023 ICTV reclassification of the Cytomegalovirus genus; human reads previously classified as HHV-5 (taxon 10359) now distribute across reclassified primate betaherpesvirus nodes. Complete disappearance under PlusPF in all samples is definitive k-mer cross-mapping artifact. The display name "Human CMV (HHV-5) [proxy]" is applied by `assets/taxon_remap.tsv` to flag this classification at all output stages.

**Molluscum contagiosum virus (taxon 10279):** Present in 17/20 PD samples (0.39–1.24 RPM) and 8/14 interpretable non-PD samples. Sporadic pattern (not universal) and muscle-predominant in the non-PD cohort. Assessment: index hopping or low-level environmental contamination during library preparation. MCV is a skin poxvirus with no documented internal tissue tropism; biological signal excluded.

**Additional Tier 2 taxa in PD cohort:**

| Taxon | Samples | Classification |
|---|---|---|
| Abelson murine leukemia virus (11788) | 024, PD9 (2 samples) | Murine retrovirus artifact; k-mer cross-mapping |
| Harvey murine sarcoma virus (11807) | PD10 (1 sample) | Murine retrovirus artifact |

Murine retroviral taxa (Abelson MuLV, Harvey MuSV) are known k-mer artifacts in human tissue RNA-seq — retroelement sequences with homology to endogenous human sequences. Their sporadic, low-read-count appearance (11–27 reads) is consistent with stochastic classification noise.

### 4.4 Artifact Landscape: Lessons Learned

The artifact pipeline has been calibrated across three independent tissue types and two clinical cohorts. Key lessons:

1. **Ruminant orthobunyaviruses (Schmallenberg, Simbu-related)** are the highest-read-count artifacts in the minreads matrix: typically 200–1,000 RPM before exclusion. Their bovine origin creates strong k-mer cross-mapping in human tissue due to shared mammalian sequences. They are always excluded.

2. **Baculoviruses (Betabaculovirus chofumiferanae)** produce 50–160 RPM pre-exclusion across all cohorts. The lepidopteran insect origin produces k-mer overlap with neuronal gene transcripts — the DRG's unusually high expression of ion channels and neuropeptides creates tissue-specific susceptibility to this artifact.

3. **Hantaviruses (Orthohantavirus oxbowense)** appear at 2–11 RPM consistently across all samples and tissue types, confirming a systematic k-mer cross-mapping artifact rather than biological signal.

4. **Environmental metagenome viruses** (Gihfavirus, Kinglevirus) were originally identified as DRG-exclusive signals. After investigation, these are confirmed artifacts arising from DRG-specific transcripts (neuronal ion channels, neuropeptides, lncRNAs) generating k-mer matches. Any novel "DRG-specific" finding requires BLAST validation.

5. **ICTV taxonomy reclassification** is an ongoing fragility: taxon IDs change across ICTV releases, causing previously excluded taxa to re-emerge under new IDs. The confirmed example (Ralstonia phage p12J → Porrectionivirus p12J) highlights the need to re-audit `artifact_taxa.tsv` after each database update.

---

## 5. min_reads Sensitivity Analysis

The pipeline uses a minimum reads threshold (`params.min_reads = 5`) applied after Bracken to remove low-confidence taxa before the final filtering stage. The default threshold of 5 reads was evaluated by comparing the `viral_abundance_matrix.tsv` (final, post-threshold) against the `minreads_matrix.tsv` (post-threshold only, pre-artifact-exclusion) and `bracken_raw_matrix.tsv` (no threshold, all taxa).

### 5.1 Effect of min_reads=5 on taxon counts

From the PD cohort filter summary, the min_reads threshold alone removes a substantial fraction of taxa:

| Stage | Median taxa per sample | Reads retained |
|---|---|---|
| bracken_raw | 26 | 100% (all Bracken-assigned reads) |
| minreads (≥5 reads) | 10 | 100% (reads, not taxa, are retained) |
| final (post-artifact exclusion) | 3 | ~5–10% of bracken_raw reads |

The read attrition is almost entirely at the final (artifact exclusion) stage, not the min_reads stage, because the highest-read-count taxa are the artifacts (orthobunyaviruses, baculoviruses) which survive the 5-read threshold before exclusion.

### 5.2 min_reads=1 sensitivity test (PD cohort)

A sensitivity analysis was performed relaxing min_reads to 1 for the parkinson_2026 run. Result: **no new candidate taxa emerge**. All non-zero taxa in the bracken_raw output have read counts of ≥10 in every sample. This means the 5-read threshold is not suppressing any signals in this dataset — the noise floor is approximately 10 reads per taxon at the library sizes achieved by this protocol (~1.4–1.9 GB FASTQ per sample, ~12,000–44,000 post-host-removal reads).

The PD18 sample (HERV-K only, richness = 1) was examined specifically — it has the lowest final read count (516 reads) and might be expected to have sparse taxa near the 5-read floor. Even at min_reads=1, no additional taxa survive artifact exclusion in PD18.

### 5.3 Conclusion on threshold calibration

min_reads=5 is validated as appropriate for this dataset and protocol. The detection floor is ~10 reads (empirically observed minimum in the minreads matrix for any non-artifact taxon). At the current read depth, relaxing the threshold adds noise (more spurious low-read taxa that must be manually reviewed) without adding scientifically interpretable signal. This threshold should be revisited if library depths decrease substantially or if targeted enrichment protocols are introduced.

---

## 6. PD vs. Non-PD DRG Comparison

### 6.1 HERV-K Comparison

| Group | n | HERV-K RPM range | Mean RPM |
|---|---|---|---|
| Muscle (non-PD) | 5 | 27.2–34.9 | 31.3 |
| Non-PD DRG (donor1) | 6 | 28.4–57.7 | 45.8 |
| Non-PD DRG (Saad, usable) | 4 | 61.9–115.7 | 72.7 |
| PD DRG controls (023–028) | 6 | 31.3–37.9 | 34.6 |
| PD DRG patients (PD2–PD20) | 14 | 24.3–39.9 | 31.8 |

The non-PD DRG cohort showed substantially higher HERV-K RPM than the PD cohort. The cause is uncertain. Possible explanations: (1) tissue quality differences between cohorts (non-PD from donor1/Saad tissue banks vs. PD from Psomagen clinical processing); (2) differences in post-mortem interval or preservation; (3) spinal level differences (non-PD includes L5 which has the highest HERV-K per sample); or (4) a genuine biological difference. This comparison requires proper statistical analysis with clinical metadata and normalization verification before drawing conclusions.

The PD de-repression hypothesis — that neuroinflammation in PD elevates HERV-K via NF-κB-driven LTR activation — is not supported by this data. PD DRG RPM (mean 31.8) is lower than, not higher than, non-PD DRG RPM (mean ~55, combining donor1 and Saad cohorts). Even comparing PD patients to their within-cohort controls (023–028, mean 34.6 RPM), there is no PD-specific elevation.

### 6.2 Tier 2 Background Comparison

The same three Tier 2 taxa (HERV-K, CMV proxy, MCV) are present in both cohorts. MCV is more uniformly distributed in the PD cohort (17/20 samples) than in the non-PD cohort (8/14 interpretable samples). This may reflect batch differences in library preparation or flow cell lot. The additional murine retroviral taxa (Abelson MuLV, Harvey MuSV) in the PD cohort are sporadic and low-count.

### 6.3 Tier 1 Comparison

| Cohort | n unique | Tier 1 detections | Taxon | Reads |
|---|---|---|---|---|
| Non-PD DRG (fullcohort_pluspf) | 16 | 0 | — | — |
| PD DRG (parkinson_2026) | 20 | 1 | HSV-1 (PD19) | 46 |

The difference in Tier 1 outcomes (0 vs. 1) is the most significant cross-cohort finding. HSV-1 is absent from 16 non-PD samples including all 11 non-PD DRG samples at any read count level (not in bracken_raw). It is present in 1 of 20 PD samples (PD19 only, 46 reads). The specificity is:
- 0/6 PD-cohort numeric controls (023–028)
- 0/13 other PD patients
- 0/11 non-PD DRG samples
- 1/14 PD patients (PD19)

This pattern is consistent with PD-specific or patient-specific HSV-1 reactivation, but n=1 precludes any statistical inference. BLAST validation is the necessary next step.

### 6.4 Diversity Summary Comparison

| Group | Richness range | Shannon range | Total viral reads range |
|---|---|---|---|
| Non-PD DRG (14 interpretable) | 2–3 | 0.067–0.390 | 1,815–8,028 |
| PD DRG (20 samples) | 1–4 | 0.0–0.465 | 499–1,063 |

Non-PD DRG samples have substantially higher total viral reads than PD DRG samples. This difference is driven by HERV-K (the dominant taxon by read count) and is consistent with the HERV-K RPM comparison above — again pointing to cohort-level differences in library depth or tissue quality rather than biological viral signal differences.

---

## 7. PD19 HSV-1: Assessment and Next Steps

### 7.1 The Finding

Sample PD19 (PD patient, parkinson_2026 cohort) is the only sample in the entire virome dataset to produce a Tier 1 (dual-database confirmed) viral detection:

| Attribute | Value |
|---|---|
| Taxon | Simplexvirus humanalpha1 (HSV-1) |
| NCBI taxon ID | 3050292 |
| Reads (viral-only DB) | 46 |
| RPM (viral-only DB) | 1.89 |
| Reads (PlusPF DB) | ≥5 (sufficient to pass tier assignment) |
| Tier assignment | Tier 1 (shared) |
| Prevalence in PD cohort | 1/14 PD patients (PD19 only) |
| Prevalence in controls 023–028 | 0/6 |
| Prevalence in non-PD cohort | 0/16 unique samples |
| Bracken_raw present in non-PD | No (not detected at any threshold) |

### 7.2 Biological Context

HSV-1 (Herpes Simplex Virus type 1) establishes lifelong latency in sensory ganglia after primary infection. The trigeminal ganglion is the canonical reservoir, but DRG latency is documented, particularly in individuals with lower-body HSV-1 or following viremia. During latency, HSV-1 expresses primarily the LAT (Latency-Associated Transcript) lncRNA. During reactivation, immediate-early (IE) genes (ICP0, ICP4, ICP27) are transcribed first, followed by early (E) and late (L) genes. Bulk RNA-seq detection of 46 HSV-1 reads is consistent with low-level reactivation or aberrant LAT expression — not necessarily active productive infection.

**PD biological plausibility:** Three mechanisms have been proposed for HSV-1 involvement in PD pathology:
1. Direct neuroinvasion from sensory ganglia to CNS via retrograde axonal transport — HSV-1 can travel from DRG to spinal cord and brain stem
2. Alpha-synuclein interaction — HSV-1 infection promotes alpha-synuclein aggregation in neurons in vitro; the viral protein ICP34.5 interacts with USP24, a PD-associated ubiquitin pathway gene
3. Neuroinflammation — repeated HSV-1 reactivation drives chronic neuroinflammation via innate immune activation (STING, cGAS) in neurons and satellite cells

Epidemiological evidence is mixed but suggestive: anti-HSV-1 IgG titers are higher in some PD cohorts; antiviral treatment (acyclovir/valacyclovir) has been associated with reduced PD risk in one large Danish registry study (Douros et al., 2021). This is an active area of investigation.

### 7.3 Why It Matters

This is the first Tier 1 detection across more than 40 DRG RNA-seq samples spanning two tissue types (muscle, DRG), three independent donor cohorts, and two clinical groups (non-PD, PD). The fact that it appears exclusively in the PD cohort and specifically in a single PD patient is notable. It is the only biological hypothesis generated by this dataset that links a specific exogenous virus to PD DRG biology.

However, the caution flags are equally important:
- **n=1**: No statistical inference is possible from a single sample. This is a hypothesis, not a finding.
- **46 reads**: Low confidence. Pipeline detection floor is ~10 reads, so 46 reads is above floor but well below what would be considered robust. A single read-level mapping artifact could inflate this count.
- **No BLAST validation**: The Tier 1 classification is based on k-mer agreement between two databases. BLAST against the NCBI nt database is required to confirm that the 46 reads are genuinely HSV-1-derived.
- **Life cycle unknown**: Without gene-level mapping, it is impossible to determine whether any detected reads are from LAT (latency), IE (early reactivation), E, or L genes. This distinction is biologically critical — LAT detection has different implications than IE/E/L detection.
- **Single-cell contamination possibility**: If a single epithelial cell contaminated during DRG dissection carried HSV-1, bulk RNA-seq would detect it without meaningful biology.

### 7.4 Validation Plan

The BLAST verification pipeline (`blast_verify.nf`) built today provides the necessary validation framework:

**Step 1 — BLAST identity confirmation:**
```bash
nextflow run blast_verify.nf -profile slurm \
  -params-file assets/config_blast_pd19.yaml
```
Extract the 46 PD19 reads assigned to taxon 3050292 from the Kraken2 output, BLAST against NCBI nt, confirm ≥95% identity to HSV-1 reference genomes.

**Step 2 — Reference genome mapping:**
Map confirmed HSV-1 reads to the HSV-1 reference genome (GenBank JN555585 or GCF_000859085.1). Calculate per-gene read counts if coverage is sufficient. Even 46 reads distributed non-randomly across HSV-1 gene models would be informative.

**Step 3 — Life cycle phase classification:**
If reads map to annotated HSV-1 coordinates: classify as IE (ICP0, ICP4, ICP22, ICP27, ICP47), E (TK, DNA pol, UL9, UL29), L (gC, gB, VP16), or LAT (RL2 antisense region). LAT-only detection suggests latency; IE/E detection suggests reactivation.

**Step 4 — Negative control confirmation:**
Verify that the same 46 reads are absent from any non-PD19 sample at the BLAST stage (confirm the Tier 1 specificity is genuine, not an artifact of the tier assignment algorithm).

### 7.5 Decision Tree Post-Validation

| BLAST result | Interpretation | Next action |
|---|---|---|
| ≥95% identity to HSV-1, multiple reads confirmed | Genuine HSV-1 detection; validate further | Expand PD cohort; map to reference for life cycle phase |
| Reads map to HSV-1 LAT region only | Latency detection in DRG; biologically expected | Report as latency finding; note detection sensitivity limit |
| Reads map to IE/E genes | Low-level reactivation in DRG; novel finding | Priority for expanded cohort and clinical correlation |
| Reads blast to human genome or unrelated sequence | Kraken2 k-mer artifact | Close; add taxon to artifact_taxa.tsv if recurrent |
| Mixed results | Partial artifact; cannot distinguish | Requires deeper sequencing or targeted PCR validation |

---

## 8. Open Questions and Blockers

### 8.1 Critical Blockers (Must Resolve Before Any Comparative Analysis)

**Q1: Identity of samples 023–028 (PD cohort)**
These six samples were delivered as a separate numeric group from Psomagen. Their tissue type (DRG vs. other), spinal level, and disease classification (healthy control, other neurological disease, different disease stage) are unconfirmed. Any PD vs. control comparison depends entirely on establishing that 023–028 are truly matched healthy DRG controls. Without this confirmation, the parkinson_2026 data cannot support a case-control comparison.
- Action: Contact Psomagen / clinical collaborator to confirm sample metadata
- Blockers if unresolved: no PD-vs-control HERV-K analysis, no control group for PD19 HSV-1 context

**Q2: Missing PD IDs (PD1, PD7, PD8, PD11, PD12, PD13)**
Six PD IDs are absent from the delivery. These may represent QC failures, a second sequencing batch, or permanent exclusions. The gap in ID numbering (PD1 missing, then PD7–8 and PD11–13) suggests a systematic exclusion pattern rather than random dropout. Understanding the missing samples is important for assessing cohort selection bias.
- Action: Query Psomagen for delivery completeness and QC reports

**Q3: PD19 HSV-1 — BLAST validation required**
As described in Section 7.4, no biological interpretation of the HSV-1 finding should be communicated until BLAST confirmation is complete. The `blast_verify.nf` pipeline is ready to run; this requires compute time on Juno (interactive node + PD19 work directory access or FASTQ re-run).

### 8.2 Important Questions (Affect Analysis Depth)

**Q4: PD clinical metadata**
Age, sex, PD subtype (tremor-dominant vs. PIGD), Braak stage, disease duration, levodopa use, and medications are needed for any subgroup analysis or clinical correlation. This is standard in virome-disease association studies. Currently, all PD samples are treated as a homogeneous group.

**Q5: Donor1_L3 anomaly**
Donor1_L3 in the non-PD cohort shows elevated HERV-K (49.1 RPM) combined with high artifact signals — Gihfavirus, Kinglevirus, Betafusellovirus, Steinhofvirus, Colossusvirus, Chalconvirus all present. This pattern is more extreme than the Saad_1 contamination outlier. Whether this represents library preparation failure, tissue quality, or an actual biological signal from a contaminated extraction is unresolved. The sample was retained in the non-PD cohort analysis with a flag; for any publication, its status must be formally resolved.

**Q6: AIG1390 correct FASTQs**
The AIG1390 samples were confirmed as duplicates of donor1 by MD5 checksum (fullcohort_pluspf analysis). The correct AIG1390 FASTQs have not been obtained from the sequencing provider. If obtained, they would add 5 spinal-level samples from an independent DRG donor to the non-PD baseline, increasing statistical power and enabling between-donor cross-validation at the HERV-K level.

**Q7: Saad cohort tissue characterization**
The Saad samples (Saad_1 through Saad_5) are DRG tissue but their spinal levels, post-mortem interval, and clinical background are not documented in the analysis records. Saad_2 is a library failure; Saad_1 has extreme contamination. The three usable Saad samples (Saad_3, Saad_4, Saad_5) provide reproducible biological signal but lack provenance metadata required for publication.

---

## 9. Future Directions

### 9.1 Immediate (Next 2–4 Weeks)

**9.1.1 BLAST validation of PD19 HSV-1**
The highest priority action in the project. The `blast_verify.nf` pipeline is ready. Requires:
(a) Interactive compute node on Juno (`srun --account=tprice --partition=normal --cpus-per-task=4 --mem=16G --time=4:00:00 --pty bash`)
(b) Access to PD19 FASTQ files (already on Juno at `/groups/tprice/data/2026_ParkinsonsDRG/`)
(c) NCBI BLAST+ installation (available in the `blast.sif` container to be built)
(d) Run: `nextflow run blast_verify.nf -profile slurm -params-file assets/config_blast_pd19.yaml`

Expected output: per-read identity to HSV-1 reference, gene-level coverage summary, life cycle phase classification if reads are sufficient.

**9.1.2 Confirm identity of samples 023–028**
Email or call clinical collaborator and Psomagen to confirm: tissue type, spinal level, disease classification. This is a one-question blocker that should take days, not weeks.

**9.1.3 Request PD clinical metadata**
Prepare a metadata request for the PD clinical team: sample ID, age at death/surgery, sex, PD subtype, Braak stage, disease duration, key medications. This data can be linked to the parkinson_2026 results table by sample ID.

**9.1.4 Request correct AIG1390 FASTQs**
Contact sequencing provider with the MD5 evidence of duplication. Request the correct AIG1390 (S9–S14 accessions). When received, add to Juno and run fullcohort_pluspf with `-resume` to add the new samples without reprocessing existing ones.

**9.1.5 Add HERV-K to artifact_taxa.tsv**
HERV-K (taxon 45617) should be added to the artifact exclusion list for single-database runs as defense-in-depth. It is already correctly handled by the dual-DB tier system (Tier 2), but adding it to artifact_taxa.tsv ensures it is excluded from single-DB final outputs. This is a one-line edit to `assets/artifact_taxa.tsv`.

### 9.2 Near-Term (1–3 Months)

**9.2.1 Expand PD cohort**
A single HSV-1 detection in n=1 is a hypothesis. Statistical power requires expansion. Target: 40–60 PD DRG samples + 20–30 matched controls. Options: (a) request additional samples from clinical collaborators; (b) access published DRG RNA-seq datasets (GTEx DRG if available, or published pain/neuropathy cohorts); (c) SRA search for DRG RNA-seq data with clinical annotations. Priority: any cohort with PD diagnosis and DRG tissue.

**9.2.2 conf/test.config — CI/smoke test profile**
A minimal test profile with synthetic data (or subsampled real FASTQs) is needed for pipeline development. Currently, every code change requires a full Juno run for verification. A 2-sample test with pre-computed expected outputs would enable local validation before SLURM submission. This was in the roadmap since v1.0 and has not been implemented.

**9.2.3 Host removal QC metric**
Add per-sample percent unmapped reads (STAR unmapped fraction) to MultiQC output. This metric flags: (a) library quality degradation; (b) unexpected host removal efficiency; (c) samples with high non-human content that may indicate contamination. Currently this is not reported and must be manually extracted from STAR logs.

**9.2.4 MultiQC custom content injection**
The filter_summary TSV (per-sample taxon counts at bracken_raw, minreads, and final stages) contains QC-relevant data that should appear in the MultiQC report. Inject as a custom content module so that the HTML report shows the filtering funnel alongside FastQC, Trimmomatic, and STAR metrics.

**9.2.5 Targeted HSV-1 qPCR or ddPCR validation**
The gold standard for confirming viral nucleic acid in archival tissue is PCR. If DRG tissue or DNA extracts from PD19 are available, quantitative PCR for HSV-1 (LAT, ICP4, or gB targets) would provide orthogonal confirmation independent of sequencing. Coordinates of primer sets are available in the literature.

### 9.3 Medium-Term (3–6 Months)

**9.3.1 PathSeq validation module**
GATK PathSeq is an orthogonal viral detection tool using alignment-based methods (not k-mer) against viral reference genomes. Adding an optional PathSeq step (stub `run_pathseq` already in params) would provide independent validation of any Tier 1 candidate. PathSeq is particularly useful for low-read-count detections like PD19 HSV-1 — it uses Smith-Waterman alignment rather than k-mer matching, and would confirm or deny the HSV-1 signal independently.

**9.3.2 Reference augmentation for HSV strains**
The current Kraken2 viral-only database represents HSV-1 by a limited set of reference strains (primarily 17syn+, F-strain). Human populations carry diverse HSV-1 strains with varying genome structures. Adding additional HSV-1 strain diversity (clinical isolates, Schmid et al. pan-genome strains) to the database would improve sensitivity for divergent strains and reduce k-mer assignment ambiguity for the HSV-1 / HSV-2 distinction. Related: adding human CMV strain diversity (Toledo, TB40/E, Merlin) would fix the HHV-5 cross-mapping at the source rather than relying on the taxon_remap workaround.

**9.3.3 DESeq2-style differential abundance module**
A cohort-level statistical module accepting sample group metadata (PD vs. control, donor vs. cultured, tissue type) and running DESeq2-style differential abundance on viral reads. This requires: (a) clinical metadata integration; (b) a counts matrix in DESeq2-compatible format (already available as viral_abundance_matrix.tsv); (c) minimum sample size per group (n≥5 per group recommended). This module would transform the pipeline from a detection tool to a comparative epidemiology tool.

**9.3.4 Kraken2 confidence threshold optimization**
The current confidence threshold is 0.1 (10% of k-mers must agree with classification). For human clinical tissue metagenomics, higher stringency (0.3–0.5) may reduce spurious classifications at the cost of sensitivity. A systematic analysis across a range of thresholds (0.05, 0.1, 0.2, 0.3, 0.5) on the existing cohort data would inform optimal settings. This is particularly relevant for the HSV-1 finding — does the 46-read detection survive at higher confidence thresholds?

**9.3.5 SRA data submission and repository**
Version 1.4.0 includes SRA submission prep. Submitting the non-PD baseline data (FASTQ files for donor1 and Saad cohorts) to SRA under a BioProject accession would enable reproducibility verification by reviewers and community reuse. This is a prerequisite for manuscript submission at most journals. Requires IRB approval confirmation for data sharing.

### 9.4 Long-Term (6–18 Months)

**9.4.1 Assembly-based viral discovery**
De novo viral assembly on host-depleted reads (using SPAdes or MEGAHIT) would detect novel or highly divergent viruses below Kraken2's k-mer detection threshold. This approach is particularly relevant for discovering DRG-tropic viruses that are not in current databases — a possibility that cannot be excluded by the current Tier 1 = 0 result. Pipeline integration: add a MEGAHIT → Prodigal → DIAMOND → vConTACT2 branch for assembled contigs.

**9.4.2 Metadata integration module**
Accept a structured metadata TSV (sample ID, tissue type, spinal level, diagnosis, age, sex, Braak stage, etc.) and incorporate into all report visualizations. This would enable: grouped heatmaps by diagnosis; spinal level-stratified HERV-K plots; age/sex-adjusted analysis; automatic PD vs. control comparison visualization. The architecture supports this through the `--metadata` parameter (stub in params; not yet implemented).

**9.4.3 Longitudinal tracking**
The current pipeline handles cross-sectional cohorts. For PD specifically, longitudinal sampling (same patient at multiple timepoints: presymptomatic, diagnosis, advanced disease) would enable tracking of viral dynamics across disease progression. This would require: (a) longitudinal patient cohort (difficult to obtain for DRG); (b) sample ID linkage across timepoints; (c) time-series statistical modeling. Long-term collaboration with a clinical DRG bank offering longitudinal samples would be required.

**9.4.4 Multi-center collaboration and meta-analysis**
A single-site n=20 PD cohort is underpowered for definitive conclusions. A meta-analysis approach using harmonized pipeline output from multiple centers (standardized FASTQ → same pipeline version → combined analysis) would provide the statistical power needed. Target: 3–5 independent DRG cohorts totaling 100+ PD samples and 50+ matched controls. This would require publication of the pipeline as a community tool (GitHub release, Zenodo DOI, protocol paper) to enable adoption.

**9.4.5 Single-cell virome deconvolution**
Bulk RNA-seq averages signal across all cell types in the DRG (neurons, satellite glial cells, Schwann cells, immune cells, fibroblasts, endothelial cells). Viral signals may be cell-type-specific — HSV-1 latency is neuron-specific; neuroinflammatory HERV-K expression may be glia-specific. Integration with single-cell RNA-seq data (or generation of DRG scRNA-seq with viral detection modules) would resolve cell-type specificity and increase sensitivity by focusing the analysis on the relevant cell population.

**9.4.6 Herpesvirus recurrence and trigger analysis**
If expanded cohort data confirms PD-associated HSV-1 DRG presence, a clinical analysis of recurrence triggers would be warranted. Key variables: immunosuppression status, stress markers (cortisol), PD medication effects on innate immune function (levodopa modulates dopamine receptor signaling, which intersects with toll-like receptor activation), and co-infections. This is downstream of the biology and requires clinical collaboration beyond the pipeline scope.

---

## Appendix: Data Paths

| Resource | Path |
|---|---|
| Pipeline repo | `/mnt/c/users/mwild/firebase2/virome/` (local) |
| Pipeline (Juno) | `/groups/tprice/pipelines/containers/virome/` |
| Non-PD results (local) | `/mnt/c/users/mwild/firebase2/virome/results/fullcohort_pluspf/` |
| PD results (local) | `/mnt/c/users/mwild/firebase2/virome/results/parkinson_2026/` |
| PD FASTQs (local) | `C:\users\mwild\firebase2\bulk_rnaseq\2026_ParkinsonsDRG\AN00028264\` |
| PD FASTQs (Juno) | `/groups/tprice/data/2026_ParkinsonsDRG/` |
| PD run output (Juno) | `/scratch/juno/maw210003/virome_parkinson_2026/` |
| Run configs | `/mnt/c/users/mwild/firebase2/virome/assets/config_*.yaml` |
| Artifact list | `/mnt/c/users/mwild/firebase2/virome/assets/artifact_taxa.tsv` |
| Taxon remap | `/mnt/c/users/mwild/firebase2/virome/assets/taxon_remap.tsv` |
| Consensus matrix (PD) | `/mnt/c/users/mwild/firebase2/virome/results/parkinson_2026/results/db_comparison/consensus_matrix.tsv` |
| Viral abundance matrix (PD) | `/mnt/c/users/mwild/firebase2/virome/results/parkinson_2026/results/viral_abundance_matrix.tsv` |
| Paper 1 manuscript | `/mnt/c/users/mwild/firebase2/virome/research/paper1/manuscript/` |
| Conference abstract | `/mnt/c/users/mwild/firebase2/virome/research/paper1/abstract_500.md` |

---

*Report generated 2026-04-04. Pipeline: virome-pipeline v1.4.0. Analysis by Matthew Wilde (mwilde49), TJP group, UT Dallas.*
