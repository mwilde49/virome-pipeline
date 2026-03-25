# Paper 1 — Manuscript Outline
# Bioinformatics Application Note (~2500 words, 3 figures)

## Title
A Nextflow pipeline for systematic k-mer-based virome profiling of human neural
tissue from bulk RNA-seq, with a curated artifact exclusion framework

## Structured abstract (≤200 words)
- **Motivation:** No reproducible, publicly available pipeline exists for virome
  profiling specifically from human neural tissue bulk RNA-seq. k-mer classifiers
  applied to viral-only databases produce systematic false positives that require
  tissue-specific curation.
- **Results:** We present virome-pipeline, a Nextflow DSL2 pipeline integrating
  host depletion, Kraken2 viral classification, Bracken re-estimation, and a
  multi-stage filtering framework with a curated 24-entry artifact exclusion list.
  Applied to 15 human samples (DRG and skeletal muscle), the pipeline demonstrates
  systematic characterization of k-mer noise sources including reagent contaminants,
  cross-species reference database imbalances, and tissue-specific transcript
  cross-mapping. After filtering, 3–5 species were detected per sample, anchored
  by HERV-K as an internal positive control.
- **Availability:** github.com/mwilde49/virome-pipeline (DOI: 10.5281/zenodo.XXXXXXX)
- **Contact:** [email]

---

## 1. Introduction (~300 words)

**Paragraph 1 — Clinical motivation**
- Neurotropic viruses (HSV-1/2, VZV, CMV) establish latency in DRG
- Viral activity implicated in neuropathic pain, peripheral neuropathy
- Human DRG virome largely uncharacterized — no systematic profiling reported

**Paragraph 2 — Technical gap**
- Bulk RNA-seq increasingly available from human neural tissue (GTEx, disease cohorts)
- k-mer classifiers (Kraken2, Centrifuge) applicable but not optimized for this context
- Viral-only databases create closed-world assumption: all unclassified reads forced
  into viral bins → systematic false positive inflation
- No published pipeline addresses neural tissue-specific artifact patterns

**Paragraph 3 — Our contribution (1 short paragraph)**
- virome-pipeline: reproducible, HPC-ready, multi-stage filtering
- Curated artifact list derived from systematic per-read investigation
- Two worked examples of database-driven misassignment (CMV, hantavirus)
- Establishes baseline for larger cohort studies

---

## 2. Pipeline description (~600 words)

**2.1 Architecture** (reference Fig 1 — pipeline diagram)
- 7-step Nextflow DSL2 workflow: FASTQC → TRIMMOMATIC → STAR → KRAKEN2 → BRACKEN → KRAKEN2_FILTER → AGGREGATE
- Three parallel output streams: bracken_raw, minreads, final
- Each step containerized (Apptainer); SLURM-ready via profiles

**2.2 Multi-stage filtering**
- Stage 1 (bracken_raw): all viral species from Bracken, no threshold
- Stage 2 (minreads): ≥5 reads per taxon per sample
- Stage 3 (final): curated artifact exclusion list applied
- filter_summary.tsv: per-stage taxa/read counts for QC tracking (reference Fig 2 — funnel)

**2.3 Artifact exclusion framework**
- assets/artifact_taxa.tsv: 24 curated entries, versioned with pipeline
- Categories: reagent contaminants, ruminant bunyaviruses, insect baculoviruses,
  phages, environmental metagenome viruses, DRG k-mer cross-mapping, avian
  herpesviruses, giant amoeba viruses
- ICTV reclassification caveat: both old and new taxon IDs listed where applicable

**2.4 Taxon display name remapping**
- assets/taxon_remap.tsv: corrects misleading NCBI labels from cross-species
  k-mer assignments (e.g. baboon CMV reference → "Human CMV (HHV-5) [proxy]")

---

## 3. Results (~700 words)

**3.1 Application to 15-sample DRG/muscle cohort**
- 15 samples: 11 DRG (6 from one donor across spinal levels L1–L5/T12;
  5 from 5 additional donors), 5 skeletal muscle from 5 independent donors
- Filtering funnel (Fig 2): median 30 taxa at bracken_raw → 12 at minreads → 4 at final
- Final virome heatmap (Fig 3): 3–5 species per sample

**3.2 HERV-K as internal positive control**
- Detected across all 15 samples; higher in DRG than muscle
- Demonstrates pipeline sensitivity to genuine viral-derived sequences
- Consistent with known HERV-K transcriptional activity in neural tissue

**3.3 Case study 1 — CMV reference database imbalance**
- Reads assigned to Cytomegalovirus papiinebeta3 (3050337) / Papiine
  betaherpesvirus 3 (2169863) — baboon CMV reference
- Trace: 0 direct reads at genus/family/species level; all direct reads at S1
  child 2169863 (NC_055235.1, baboon CMV genome)
- Root cause: Langmead viral DB contains single HHV-5 reference (Merlin strain);
  human CMV strain diversity → reads match baboon CMV k-mers via LCA
- Remediation: taxon_remap.tsv relabels to "Human CMV (HHV-5) [proxy]"
- General lesson: zero direct reads at species level = child taxon assignment;
  requires grep -A N on report file

**3.4 Case study 2 — Oxbow virus (hantavirus) cross-mapping**
- Orthohantavirus oxbowense (3052491) / Oxbow virus (660954) detected in
  ALL 15 samples at 22–197 reads including skeletal muscle
- Two anomalous spikes: Saad_1 (3287 reads), donor1_L2 (2339 reads)
- Universal cross-tissue signal rules out genuine infection
- Same per-read methodology: direct assignments at S1 child 660954
- Spikes consistent with index hopping from a high-signal library
- Both taxon IDs added to artifact list

**3.5 Recommendation: competitive classification**
- Viral-only database inflates false positive rate by forcing host/environmental
  reads into viral bins
- [PlusPF comparison results — X% reduction in bracken_raw taxa; INSERT after run]
- Recommend PlusPF standard database as default for new studies

---

## 4. Discussion (~400 words)

**Paragraph 1 — What the pipeline contributes**
- First reproducible pipeline targeting human neural tissue virome from bulk RNA-seq
- Artifact curation framework generalizable to other tissue types with substitution
  of appropriate exclusion lists

**Paragraph 2 — Fundamental limitations of k-mer approach from bulk RNA-seq**
- Sensitivity ceiling: low-abundance latent viruses may fall below noise floor
- Specificity limitation: viral-only DB forces misclassification; competitive DB
  partially mitigates but doesn't eliminate
- Bulk RNA-seq not designed for virome: host reads dominate; enrichment strategies
  needed for comprehensive characterization

**Paragraph 3 — Future directions (brief)**
- Alignment-based validation (minimap2/PathSeq) as confirmation layer
- Targeted enrichment (VirCapSeq) for latent virus detection
- Larger cohorts with clinical stratification (cite paper 2 in preparation)

---

## Figures

| Figure | File | Caption |
|--------|------|---------|
| Fig 1 | fig6_pipeline_diagram.png | virome-pipeline architecture. Seven-step Nextflow DSL2 workflow... |
| Fig 2 | fig2_filtering_funnel.png | Multi-stage filtering funnel across 15 samples... |
| Fig 3 | fig3_virome_heatmap.png | Final filtered viral abundance heatmap... |

## Supplementary
- Table S1: Full artifact_taxa.tsv (24 entries) formatted as table
- Note S1: CMV taxonomy investigation (condensed from cmv_taxonomy_investigation.md)
- Note S2: Oxbow virus cross-mapping investigation
- Table S2: PlusPF vs viral-only comparison table (INSERT after run)

---

## Word budget
| Section | Target |
|---------|--------|
| Abstract | 200 |
| Introduction | 300 |
| Pipeline description | 600 |
| Results | 700 |
| Discussion | 400 |
| Figure legends | 300 |
| **Total** | **~2500** |
