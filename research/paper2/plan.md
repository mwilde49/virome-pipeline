# Paper 2 — Primary Research Paper Plan

**Format:** Full research article
**Target journals:** Journal of Virology, PLOS Pathogens, Brain, Annals of Neurology
**Status:** Planning — requires new cohort data

## Scientific question
Do specific neurotropic viruses — particularly betaherpesviruses (CMV/HHV-5, HHV-6) — show detectable activity or latent signatures in human DRG, and does this differ between neuropathic pain patients and controls?

## What paper 1 provides for this paper
- Citable pipeline reference (cite paper 1 for all methods detail)
- Validated artifact exclusion framework
- Baseline virome profile for healthy DRG tissue
- Demonstrated k-mer noise floor as context for interpreting low-level signals

## Minimum study design requirements

| Requirement | Rationale |
|------------|-----------|
| ≥20 DRG donors | Statistical power for group comparisons |
| ≥2 clinical groups | Neuropathic pain vs. healthy, or acute vs. chronic |
| Tissue-paired samples | DRG + muscle from same surgical specimen |
| Multiple spinal levels per donor where possible | Intra-donor replication |
| Competitive Kraken2 database (PlusPF) | Reduces false positives vs viral-only DB |
| Alignment-based validation | minimap2 confirmation of any taxon with RPM > threshold |
| Targeted enrichment (optional) | VirCapSeq or similar for latent virus sensitivity |

## Current sample inventory toward paper 2

| Cohort | Samples | Status | Notes |
|--------|---------|--------|-------|
| donor1 DRG | 6 (L1–L5, T12) | Usable | Single donor; no clinical metadata |
| Saad DRG | 4 usable (Saad_3/4/5 + flagged Saad_1) | Usable | Independent donors; Saad_1 flagged QC outlier; hantavirus artifact confirmed (artifact list) |
| AIG1390 DRG | 0 usable | **Excluded — confirmed duplicate** | MD5 checksum = donor1; same FASTQs submitted under two donor IDs. Correct AIG1390 FASTQs not yet obtained. |
| Saad_2 | 0 | Excluded — library failure | HERV-K = 0; pipeline produces 0 final taxa correctly |
| Muscle (Sample_19–23) | 5 | Usable as non-neural controls | Independent donors; unpaired to DRG donors |
| Jayden REJOIN (473-1–473-17) | 17 | **Pending FASTQ transfer to Juno** | Not yet on cluster; will extend cohort to 32 interpretable samples on next run |

**Current effective cohort: 15 usable samples** (6 donor1 DRG + 4 Saad DRG + 5 muscle)
**After Jayden transfer: 32 samples** — approaches minimum for inter-individual analysis

**Gap for paper 2:** Need ≥20 DRG donors (Jayden adds 17 → gets us to ~27 DRG samples total
if all pass QC). Still need: clinical stratification metadata, tissue-paired design,
neuropathic pain vs. control classification.

## What full-cohort results change for paper 2

- **Paper 1 null result** now establishes the baseline that paper 2 builds on:
  no exogenous viral signal in "normal" DRG at bulk RNA-seq sensitivity
- **HERV-K tissue differential (5.8x DRG > muscle)** — now the most robust quantitative
  finding from paper 1; paper 2 should test whether HERV-K expression differs between
  neuropathic and control DRG (neuroinflammation drives LTR de-repression via NF-kB)
- **Detection floor established** (~10 RPM in host-depleted fraction) — paper 2 power
  calculation should use this as the minimum detectable signal
- **T. gondii** (1,330 reads surviving PlusPF in pluspf_v3) — still unvalidated;
  if BLAST confirms apicomplexan-specific k-mers, this is the only potentially biologically
  meaningful signal from paper 1 data and warrants paper 2 serology/PCR follow-up

## Pending items before paper 2 data collection
- [ ] Obtain correct AIG1390 FASTQs from sequencing provider (5 DRG levels)
- [ ] Transfer Jayden REJOIN FASTQs (473-1–473-17) to Juno; rerun with full 38-sample sheet
- [ ] BLAST T. gondii reads from pluspf_v3 (1,330 reads in Saad_1 + donor1_L4)
- [ ] Obtain Saad cohort clinical metadata (diagnosis, age, PMI, tissue handling)
- [ ] Define clinical groups in collaboration with clinical partner
- [ ] Plan tissue collection protocol for paired DRG + muscle from same donor
- [ ] Power calculation: using 10 RPM detection floor and expected viral prevalence

## Figures (placeholder — will be defined once data exists)
- Cohort overview (sample metadata, clinical groups)
- Differential abundance: neuropathy vs. control
- Spinal level stratification
- CMV/HHV-5 alignment-based validation (minimap2 depth plots)
- HERV-K tissue-paired comparison (DRG vs muscle, same donors)
