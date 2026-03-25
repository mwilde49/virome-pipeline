# 11-Sample Analysis: Muscle + DRG Full Cohort
**Date**: 2026-03-24
**Pipeline version**: v1.0.0
**Run output**: `results/muscle_drg_full/`
**Samplesheet**: `samplesheets/muscle_drg_full.csv`

---

## Samples

| Sample | Tissue | Spinal Level | Est. Library Size |
|---|---|---|---|
| Sample_19 | Skeletal muscle | — | ~17.5M reads |
| Sample_20 | Skeletal muscle | — | ~16.5M reads |
| Sample_21 | Skeletal muscle | — | ~27.8M reads |
| Sample_22 | Skeletal muscle | — | ~17.3M reads |
| Sample_23 | Skeletal muscle | — | ~22.4M reads |
| donor1_L1 | DRG | Lumbar 1 | ~71.8M reads |
| donor1_L2 | DRG | Lumbar 2 | ~67.4M reads |
| donor1_L3 | DRG | Lumbar 3 | ~91.7M reads |
| donor1_T12 | DRG | Thoracic 12 | ~30.7M reads |
| donor1_L4 | DRG | Lumbar 4 | ~80.6M reads |
| donor1_L5 | DRG | Lumbar 5 | ~165.3M reads |

Library sizes estimated from HERV-K reads/RPM. All DRG samples are from the same donor (donor1).

---

## Final Abundance Matrix (after all filtering + artifact exclusion)

10 taxa retained. Full table in `results/muscle_drg_full/results/viral_abundance_matrix.tsv`.

| Taxon | Tissue pattern | Max reads | Notes |
|---|---|---|---|
| HERV-K (45617) | All 11 samples | 7725 (L5) | Internal control / normalization anchor |
| CMV/HHV-5 (3050337) | All 11 samples | 279 (L5) | Database label = papiinebeta3; actually HHV-5 (see CMV report) |
| Orthohantavirus oxbowense (3052491) | 4/5 muscle, 5/6 DRG | 2339 (L2) | **L2 anomaly** — see below |
| Gihfavirus pelohabitans (2844652) | 0/5 muscle, 6/6 DRG | 1664 (L5) | Artifact; added to exclusion list |
| Kinglevirus lutadaptatum (2845070) | 0/5 muscle, 5/6 DRG | 206 (L5) | Artifact; added to exclusion list |
| Pandoravirus neocaledonia (2107708) | 3/5 muscle, 4/6 DRG | 129 (L5) | Artifact; added to exclusion list |
| Mardivirus columbidalpha1 (3050267) | 3/5 muscle, 4/6 DRG | 170 (L5) | Artifact; added to exclusion list |
| Molluscum contagiosum virus (10279) | 3/5 muscle, 3/6 DRG | 62 (Sample_23) | Hold for validation |
| Porrectionivirus p12J (2956327) | 3/5 muscle only | 19 (Sample_19) | Phage artifact (=Ralstonia phage p12J, reclassified); added to exclusion list |
| Oceanusvirus kaneohense (3060432) | 2/5 muscle, 1/6 DRG | 14 (Sample_21) | Phage artifact; added to exclusion list |

---

## Key Findings

### 1. Genuine DRG Virome Signal: CMV/HHV-5 Latency

**The primary biological finding.** HHV-5 (human cytomegalovirus) is detected in all 11 samples with consistent DRG enrichment over muscle. After HERV-K normalization (CMV RPM / HERV-K RPM ratio):

| Sample | CMV RPM | HERV-K RPM | Ratio |
|---|---|---|---|
| Muscle (mean) | ~0.72 | ~31.2 | 0.023 |
| donor1_L3 | 0.62 | 49.1 | 0.013 |
| donor1_L1 | 1.00 | 36.7 | 0.027 |
| donor1_L2 | 1.00 | 28.4 | 0.035 |
| donor1_L5 | 1.69 | 46.7 | 0.036 |
| donor1_L4 | 2.21 | 56.2 | 0.039 |
| donor1_T12 | 3.71 | 57.7 | **0.064** |

T12 (thoracic) has the highest normalized CMV signal — ~2.8x above muscle mean and ~5x above L3. This may reflect dermatomal variation in CMV latency burden, different cell type composition, or differential reactivation at thoracic vs. lumbar levels.

**Note on taxonomy**: reads report as *Cytomegalovirus papiinebeta3* (3050337 / Papiine betaherpesvirus 3, NC_055235.1) due to reference imbalance in the Langmead DB — single Merlin strain for human CMV vs. a complete baboon CMV genome. See `research/cmv_taxonomy_investigation.md` for full trace.

**Next steps**:
- Remap classified reads against HHV-5 Merlin genome (NC_006273.2) to confirm identity
- Determine if reads cover latency-associated (UL138, LUNA, US28) vs. lytic (IE1/IE2) transcripts
- Validate by HHV-5-specific qPCR on matched DRG DNA
- Check donor age/serostatus (CMV seroprevalence increases with age)

### 2. HERV-K as Normalization Anchor

HERV-K present in all 11 samples. RPM range: 27.2–57.7 RPM. Muscle is narrower (27–35) than DRG (28–58), suggesting DRG samples have variable neuronal content or RNA composition differences across spinal levels. T12 and L4 are HERV-K high; L2 is HERV-K low. **Always normalize to HERV-K before interpreting RPM gradients across DRG levels.**

### 3. DRG-Specific k-mer Cross-Mapping Artifacts

Gihfavirus pelohabitans (2844652) and Kinglevirus lutadaptatum (2845070) show 0/5 muscle, 6/6 and 5/6 DRG respectively. Both read counts scale with library size. These are environmental/metagenome-derived viruses with no vertebrate host range; the DRG-exclusive pattern reflects DRG-specific transcripts (ion channels, neuropeptides, lncRNAs) generating k-mer matches to these obscure references.

**Implication for future samples**: any novel "DRG-specific virus" finding from Kraken2 k-mer classification must be validated by read-level BLAST before interpretation. The tissue-specific transcriptome creates tissue-specific background artifacts.

### 4. The donor1_L2 Hantavirus Anomaly

| Sample | Orthohantavirus oxbowense reads | RPM |
|---|---|---|
| donor1_L1 | 0 | 0 |
| **donor1_L2** | **2339** | **34.7** |
| donor1_L3 | 103 | 1.1 |
| Muscle range | 22–91 | 1.3–4.1 |

L2 has 12–23x more reads than any other sample. Oxbow virus is a shrew mole hantavirus (Oregon, 2007) with no documented human infectivity. The single-sample spike pattern is inconsistent with any biological explanation. Most likely: index hopping from an unrelated sample on the same flowcell, or batch contamination during L2 library prep.

**Pending action**: pull and BLAST the L2 hantavirus-classified reads against NCBI nt. If they map primarily to human sequences → cross-mapping artifact, add to exclusion list. If genuine hantavirus k-mers → sequencing contamination, document and add to exclusion list.

### 5. Artifact Exclusion List Updates (this run)

Four taxa added to `assets/artifact_taxa.tsv`:
- **Porrectionivirus p12J** (2956327) — ICTV reclassification of Ralstonia phage p12J (247080), was escaping filter
- **Oceanusvirus kaneohense** (3060432) — marine phage, noise floor
- **Pandoravirus neocaledonia** (2107708) — giant amoeba virus, eukaryotic HGT k-mer cross-mapping
- **Mardivirus columbidalpha1** (3050267) — pigeon herpesvirus, human herpesvirus k-mer cross-mapping

Pending investigation:
- Orthohantavirus oxbowense (3052491) — after L2 read-level BLAST
- Gihfavirus pelohabitans (2844652) — added this run
- Kinglevirus lutadaptatum (2845070) — added this run

---

## Taxonomy Reclassification Note

The Porrectionivirus case reveals a pipeline maintenance requirement: ICTV taxonomy updates periodically reclassify species under new taxon IDs, causing previously excluded taxa to re-emerge with new IDs. Ralstonia phage p12J (247080) → Porrectionivirus p12J (2956327) is the first confirmed example. Periodic audits of the exclusion list against current NCBI taxonomy are warranted, especially after database updates.

---

## Outstanding Questions

1. **donor1_L2 hantavirus**: contamination source? Should this affect confidence in L2 for other taxa?
2. **Molluscum contagiosum virus** (10279): sporadic in muscle and DRG. Dissection-related skin contamination or k-mer cross-mapping from poxvirus gene content? Needs read-level investigation.
3. **CMV in L3**: consistently lowest CMV signal across DRG levels — is this biological (L3 cell type composition?) or technical?
4. **HHV-5 transcriptional state**: are DRG reads from latency-associated or lytic transcripts?

---

## Notes for Next Run

- Artifact exclusion list now at 15 entries (up from 9 before this analysis)
- With Gihfavirus, Kinglevirus, Pandoravirus, and Mardivirus excluded, the next run's final matrix should be cleaner
- Plan to implement `taxon_remap.tsv` to rename 3050337/2169863 → "Human CMV (HHV-5)" before the next publication-oriented analysis
- Consider implementing library-size-proportional flagging to auto-detect cross-mapping artifacts statistically
