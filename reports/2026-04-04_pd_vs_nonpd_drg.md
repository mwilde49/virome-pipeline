# PD vs. Non-PD DRG Virome Comparison
**Date:** 2026-04-04  
**PD cohort:** AN00028264 (Psomagen), 2026 Parkinson's DRG cohort (n=20)  
**Non-PD cohort:** Paper 1 baseline, all_cohort run (n=21 DRG: donor1, AIG1390, Saad, REJOIN cohorts)

---

## Important caveat: identity of samples 023–028 unknown

The 6 numeric samples (023–028) in the PD cohort have not been confirmed as healthy DRG controls. Until their tissue type, disease status, and spinal level are confirmed, they are treated as an **unclassified group** in all comparisons below. Any PD vs. "control" interpretation must be considered provisional.

---

## Cohort summary

| Group | n | HERV-K (mean RPM) | HSV-1 detected | CMV proxy prevalence |
|---|---|---|---|---|
| PD DRG (PD2–PD20) | 14 | 31.8 | **1/14 (PD19)** | 14/14 |
| Unclassified 023–028 | 6 | 34.5 | 0/6 | 5/6 |
| Non-PD DRG (paper 1) | 21 | ~42 (median) | 0/21 | 19/21 |
| Muscle (paper 1) | 5 | ~30 | 0/5 | 4/5 |

---

## 1. HSV-1 (Tier 1 detection)

**This is the most significant finding from the cross-cohort comparison.**

| Cohort | HSV-1 (Simplexvirus humanalpha1) |
|---|---|
| PD DRG (n=14) | **1/14 — PD19, 46 reads, 1.89 RPM, Tier 1** |
| Unclassified controls (n=6) | 0/6 |
| Non-PD DRG (n=21) | **0/21 — not detected in bracken_raw at any level** |
| Muscle (n=5) | 0/5 |

HSV-1 is completely absent from all 26 non-PD samples across all run configurations. Its appearance as a Tier 1 detection (confirmed in both viral-only AND PlusPF databases) exclusively in a PD DRG sample is the first such detection in this pipeline's history.

**Biological context:**
- HSV-1 establishes latency predominantly in the trigeminal ganglion (TG), but documented DRG latency exists, primarily in lumbar-level DRG neurons
- In latency, the virus maintains episomal DNA in sensory neurons; only the LAT (latency-associated transcript) is robustly expressed
- BLAST verification (pending) will determine: (a) whether the 46 reads are genuinely HSV-1, and (b) whether the read distribution across IE/E/L/LAT genes is consistent with latency or active replication
- PD-virus connection: several lines of evidence link herpesvirus infection to α-synuclein pathology; HSV-1 triggers α-synuclein oligomerization in cell culture models; Braak staging of Lewy body pathology follows a retrograde neural circuit that includes DRG

**Statistical note:** n=1/14 in PD vs. 0/26 in non-PD is not statistically significant (Fisher's exact test p ≈ 0.35 at these sample sizes). Expanded cohort needed.

---

## 2. HERV-K across cohorts

### RPM by group

| Group | n | Mean RPM | Median RPM | Min | Max |
|---|---|---|---|---|---|
| PD DRG | 14 | 31.8 | 29.1 | 24.3 | 39.9 |
| Unclassified 023–028 | 6 | 34.5 | 34.4 | 31.3 | 37.9 |
| Non-PD DRG (excl. outliers) | 19 | ~42 | ~37 | 28.4 | 63.4 |
| Non-PD DRG (all 21) | 21 | ~43 | ~37 | 0 | 116 |
| Muscle | 5 | ~29 | ~29 | 27.2 | 33.4 |

**Notable outliers in non-PD cohort:**
- donor1_L3: **0 reads** — library failure (also shows massive artifact contamination: Gihfavirus, Kinglevirus, Betafusellovirus, Steinhofvirus, Chalconvirus); exclude from HERV-K analysis
- AIG1390_L1: **115.7 RPM** — unusually high; not artifact-contaminated; may reflect genuine HERV-K upregulation in this spinal segment (L1 vs. L2-L5; different neuronal populations)

**Hypothesis test: Does PD elevate HERV-K in DRG?**

The hypothesis was: PD-associated neuroinflammation (NF-κB activation) drives HERV-K LTR de-repression in DRG neurons, producing elevated HERV-K RPM in PD vs. control DRG.

**Finding: NOT SUPPORTED at current sample sizes.**

PD DRG (mean 31.8 RPM) is actually lower than non-PD DRG (mean ~42 RPM excluding outliers), and the unclassified 023–028 group (34.5 RPM) also exceeds the PD group. The ranges overlap entirely (24–40 RPM for PD vs. 28–64 RPM for non-PD excluding outliers).

**Confounds that prevent firm conclusions:**
1. The 023–028 group identity is unknown — if they are the same tissue type as PD samples, a proper comparison is impossible until identity is confirmed
2. Non-PD samples are from heterogeneous cohorts (donor1 = post-mortem; AIG1390 = surgical; Saad = chronic pain donors; REJOIN = chronic low back pain) with different medical histories that could independently affect HERV-K expression
3. n=14 PD vs. n=19 non-PD has insufficient power to detect a <2-fold difference; the HERV-K 5.8× DRG/muscle enrichment from paper 1 reflected a tissue-level effect, not a disease-level effect
4. HERV-K RPM is affected by total library complexity and host removal efficiency; differences in RNA quality between post-mortem and surgical samples could confound the comparison

---

## 3. CMV proxy (HHV-5 cross-mapper)

| Group | Prevalence | Mean RPM | Range |
|---|---|---|---|
| PD DRG (n=14) | 13/14 (93%) | 1.22 | 0–2.03 |
| Unclassified 023–028 | 5/6 (83%) | 1.33 | 0.84–1.88 |
| Non-PD DRG (n=21) | 19/21 (90%) | 1.04 | 0–3.71 |

CMV proxy (taxon 3050337 = Cytomegalovirus papiinebeta3, remapped to "Human CMV (HHV-5) [proxy]") is uniformly present across all cohorts with no PD-specific pattern. It is classified as Tier 2 (viral-only only) in all samples — it has not achieved Tier 1 (shared) status in any run.

This is consistent with k-mer cross-mapping from human CMV (HHV-5) reads to the closest species in the viral database (Papiine betaherpesvirus 3) rather than genuine Cytomegalovirus papiinebeta3 infection. True HHV-5 detection would require k-mer overlap with a human CMV sequence in the viral-only database (currently absent from the Langmead viral DB at the version used here).

---

## 4. Molluscum contagiosum virus (MCV)

| Group | Prevalence | Mean RPM |
|---|---|---|
| PD DRG (n=14) | 11/14 (79%) | 0.73 |
| Unclassified 023–028 | 5/6 (83%) | 0.86 |
| Non-PD DRG (n=21) | 5/21 (24%) | 0.12 |

**Notable finding:** MCV prevalence is markedly higher in the PD cohort (79%) than in the non-PD DRG cohort (24%). However, MCV is classified as Tier 2 (viral-only only) in all runs — it does not pass the dual-DB concordance threshold. MCV in this context is likely a k-mer cross-mapping artifact from poxvirus sequences, not genuine infection; MCV infects skin epithelium and does not infect neurons.

The difference in prevalence between cohorts may reflect a technical difference between the two sequencing runs (different library prep batches, reagent lots, or Psomagen vs. other providers) rather than biological signal. This should not be interpreted as PD-associated MCV.

---

## 5. Viral diversity metrics: PD vs. non-PD

| Metric | PD DRG (n=14) | Non-PD DRG (n=21) |
|---|---|---|
| Mean viral richness (final matrix) | 3.1 | 2.3 |
| Mean Shannon diversity | 0.28 | 0.19 |
| Total viral reads (mean, final) | 798 | ~320 |

PD DRG samples show slightly higher apparent richness and Shannon diversity in the final matrix, but this is largely driven by the additional non-artifact Tier 2 taxa present in the Parkinson run (e.g., MCV appearing in more samples, PD19 HSV-1). Once the systematically different MCV prevalence is accounted for, viral diversity is comparable.

---

## 6. What is absent from PD DRG (relative to non-PD)

The non-PD DRG cohort had higher artifact burdens from two specific samples (donor1_L3 and Saad_2, both suspected failed libraries). Excluding those, there are no taxa uniquely present in non-PD that are absent from PD.

Notably absent from both cohorts (confirmed in neither):
- Enteroviruses (EV-A71, EV-D68, poliovirus) — not detected in any sample
- JC virus / BK virus — not detected
- EBV (HHV-4) — not detected
- VZV (HHV-3) — not detected
- HHV-6/7 — not detected
- HTLV-1/2 — not detected

---

## 7. Conclusions and next steps

### What we can say with confidence:
1. **HSV-1 is detected in 1 PD sample (PD19) and 0 non-PD DRG samples** — pending BLAST confirmation
2. **HERV-K shows no PD-specific elevation** at current sample sizes
3. **The background virome (CMV proxy, HERV-K)** is consistent between cohorts, suggesting no major technical batch effects in the core signals
4. **MCV prevalence differs** between runs but is Tier 2 (likely technical artifact)

### What we cannot say yet:
1. Whether PD19 HSV-1 is a genuine infection or a false positive (BLAST validation required)
2. Whether PD has a different virome than controls (no confirmed control group in the PD cohort)
3. Whether HERV-K is truly not elevated in PD (insufficient power; confounded non-PD cohort)

### Required next steps (in priority order):
1. **Confirm identity of 023–028**: contact Psomagen/PI — are these healthy DRG controls?
2. **BLAST-validate PD19 HSV-1**: run `blast_verify.nf` with `config_blast_pd19.yaml`
3. **Obtain PD clinical metadata**: age, sex, Braak stage, disease duration
4. **Expand both cohorts** before drawing statistical conclusions
