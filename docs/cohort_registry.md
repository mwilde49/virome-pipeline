# Virome Pipeline — Cohort Registry

All biological sample collections processed through the virome pipeline, in chronological order.

| # | Cohort | Samples | n | Tissue | Key notes |
|---|---|---|---|---|---|
| 1 | **Muscle** | Sample_19–23 | 5 | Skeletal muscle | First cohort; Sample_19 was the initial single-sample test |
| 2 | **Donor1 DRG** | donor1_L1–L5, T12 | 6 | DRG | Single donor, 6 spinal levels |
| 3 | **AIG1390 DRG** | AIG1390_L1–L4, T12 | 5 | DRG | Second donor, 5 spinal levels |
| 4 | **Saad DRG** | Saad_1–5 | 5 | DRG | Saad_1: QC outlier (10× depth, extreme contamination); Saad_2: known library failure — both retained deliberately for pipeline assessment |
| 5 | **REJOIN Jayden** | 473-1–473-17 | 17 | DRG | 2025 cohort; completes the 38-sample full cohort used for paper 1 |
| 6 | **Parkinson 2026** | PD2–PD20, 023–028 | 20 | DRG | 14 PD patients + 6 controls; sequenced by Psomagen (AN00028264); PD1/7/8/11/12/13 absent from delivery; PD19 = first HSV-1 Tier 1 detection |
| 7 | **BLAST verify PD19** | PD19 | 1 | DRG | Offshoot (`blast_verify.nf`) to confirm HSV-1 identity and latency phase in PD19 |
| 8 | **Iadorola TG** | TG1–TG22 (non-contiguous) | 16 | Trigeminal ganglion | Public benchmark; LaPaglia et al. 2017 (SRP113004); post-mortem; HSV-1 detected in 5/16 samples — pipeline validation run |
| 9 | **OSM Juliet** | D1–D3 × O/V × rep1–3 | 18 | DRG | 2026; OSM-treated vs vehicle control; 3 donors × 2 conditions × 3 replicates |

| 10 | **DPN & RA Kulkarni** | JE81, WE52, PA71, J1M2, T0M2, 2AC1, 1AN1, 8EN1, RO52, S1D1, 2OE1, N4N2, ME61, LE41, L1V1, FL0A2, FL0B1, 1VYA1, 1VYB2, CA7A2, CA7B1, 4LIA1, 4LIB2, G1NA1, G1NB2 | 25 | DRG | 2023; 10 shared healthy controls, 5 DPN cases, 10 RA specimens (5 donors × A/B — confirm L/R vs replicate); 5 metadata donors without fastq files (M4X, L3O, J4N, M3L, T1F) |

**Cohorts 1–5** were consolidated into the 38-sample full cohort (`all_cohort_pluspf`) for paper 1 analysis.

**Total unique biological samples: 118** across skeletal muscle, DRG, and trigeminal ganglion.
