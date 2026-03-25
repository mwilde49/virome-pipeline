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

| Cohort | Samples | Status | Issue |
|--------|---------|--------|-------|
| donor1 DRG | 6 (L1–L5, T12) | Usable | Single donor, no clinical metadata |
| Saad DRG | 4 usable | Usable | Different donors, hantavirus batch signal unvalidated |
| AIG1390 DRG | 0 usable | Excluded | Confirmed or suspected duplicate of donor1 — needs correct data |
| Muscle (Sample_19–23) | 5 | Usable as controls | Different donors, not paired to any DRG donor |

**Gap:** Need ~15 more DRG donors with clinical stratification and paired tissue.

## Pending items before paper 2 data collection
- [ ] Resolve AIG1390: MD5 checksum vs donor1; obtain correct data if duplicate confirmed
- [ ] BLAST Saad hantavirus reads: determine if batch contamination or real
- [ ] Obtain Saad cohort library prep metadata (batch, kit, date)
- [ ] Define clinical groups in collaboration with clinical partner
- [ ] Plan tissue collection protocol for paired DRG + muscle

## Figures (placeholder — will be defined once data exists)
- Cohort overview (sample metadata, clinical groups)
- Differential abundance: neuropathy vs. control
- Spinal level stratification
- CMV/HHV-5 alignment-based validation (minimap2 depth plots)
- HERV-K tissue-paired comparison (DRG vs muscle, same donors)
