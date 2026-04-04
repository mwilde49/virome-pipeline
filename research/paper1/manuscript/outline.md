# Paper 1 — Manuscript Outline
# Bioinformatics Application Note (~2500 words, 3 figures)

## Title
A Nextflow pipeline for systematic virome profiling of human neural tissue from bulk RNA-seq:
dual-database competitive classification eliminates false positives and establishes a null
baseline for human DRG

## Structured abstract (≤200 words)
- **Motivation:** No reproducible pipeline exists for virome profiling of human neural tissue
  from bulk RNA-seq with rigorous false positive control. Viral-only k-mer classifiers produce
  systematic false positives by forcing host-derived reads into viral bins — the closed-world
  assumption problem.
- **Results:** We present virome-pipeline, a Nextflow DSL2 pipeline with dual-database
  competitive classification (viral-only vs. PlusPF), three-tier confidence scoring, and a
  curated 24-entry artifact exclusion list. Applied to 15 human samples (DRG and skeletal
  muscle), the pipeline shows zero Tier 1 (confirmed) viral detections across all samples.
  The 100% false positive rate of viral-only classification is driven by HERV-K endogenous
  transcription (5.8x DRG-enriched), CMV k-mer cross-mapping artifact, and sporadic
  contamination — all fully resolved by competitive classification against PlusPF.
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
- 15 samples: 10 DRG (6 from donor1 spanning levels L1–L5/T12; 4 from the Saad cohort),
  5 skeletal muscle from independent donors
- Sample exclusions: AIG1390 (5 samples, confirmed donor1 duplicate by MD5); Saad_2 (library
  failure, 0 final taxa, HERV-K = 0)
- Filtering funnel (Fig 2): median 30 taxa bracken_raw → 12 minreads → 3 final across cohort
- Final virome heatmap (Fig 3): richness 2–3 per sample; all signals Tier 2 (see 3.5)

**3.2 HERV-K — paradigmatic endogenous false positive with tissue-level expression differential**
- Detected across all 15 samples; 5.8x enriched in DRG over skeletal muscle
  (DRG mean 3,670 reads/sample vs. muscle mean 629 reads/sample)
- Enrichment reproduced across two independent DRG donor cohorts (donor1 and Saad) at
  all 6 spinal levels — biologically consistent with neural-lineage LTR transcriptional
  activity in post-mitotic sensory neurons
- Under PlusPF: all reads reclassified to Homo sapiens — confirmed endogenous origin
- Framing: not "virus detected"; HERV-K is the primary illustration of the closed-world
  assumption driving false positives. The tissue differential is real but endogenous.

**3.3 Case study 1 — CMV reference database imbalance and k-mer cross-mapping**
- Reads assigned to Cytomegalovirus papiinebeta3 (3050337) via LCA from baboon CMV child
  node (2169863, NC_055235.1) — ICTV 2023 reclassification split HHV-5 into primate species
- 1,097 reads across 14 interpretable samples; ~10x DRG-enriched over muscle (mirrors HERV-K)
- Under PlusPF: zero reads at this taxon in all samples — complete competitive resolution
- Mechanism: human transcripts sharing 35-mers with CMV reference; compounded by ICTV
  reclassification mapping HHV-5 k-mers onto primate betaherpesvirus nodes
- Remediation: taxon_remap.tsv relabels to "Human CMV (HHV-5) [proxy]" to flag during
  single-DB operation; dual-DB confirms no genuine signal survives
- Language note: do not claim "CMV detected" anywhere — zero survival under PlusPF is
  incompatible with any level of genuine CMV transcription

**3.4 Case study 2 — Oxbow virus (hantavirus) cross-mapping**
- Orthohantavirus oxbowense (3052491) / Oxbow virus (660954) detected in ALL samples at
  22–197 reads including skeletal muscle — universal cross-tissue signal rules out genuine infection
- Anomalous spikes: Saad_1 (3,287 reads), donor1_L2 (2,339 reads) — consistent with
  index hopping from a high-signal library on a patterned flow cell
- Both taxon IDs added to artifact_taxa.tsv; confirmed k-mer cross-mapping artifact

**3.5 Dual-database competitive classification — results (FULLY POPULATED)**
- Dual-DB run (viral-only DB1 vs. PlusPF DB2) across 15 samples (+ 6 AIG1390 duplicates;
  full cohort of 21 processed samples, 16 unique)
- **Tier 1 (shared): zero taxa across all 15 samples and both tissue types**
- **Tier 2 (viral-only exclusive): 3 taxa — HERV-K (39,848 reads), CMV proxy (1,097 reads),
  MCV (189 reads)**
- **Tier 3 (PlusPF-only): 10–826 taxa per sample** (contamination landscape, QC utility)
- Empirical false positive rate of viral-only database: 100% per-taxon, 100% per-read
- HERV-K: PlusPF reclassifies all reads to Homo sapiens → endogenous retroviral transcription
- CMV proxy: PlusPF reclassifies all reads → k-mer cross-mapping fully resolved
- MCV (189 reads, sporadic): absent from deepest library (Saad_1 with 430K bracken_raw reads)
  — sporadic distribution inconsistent with systematic k-mer artifact; consistent with index
  hopping or low-level environmental contamination
- PlusPF-only contamination stratified by tissue type (muscle < DRG) and library quality
  (Saad_2 failure: 826 taxa; normal DRG: 25–179); provides baseline for post-mortem tissue
  metagenomics
- Key conclusion: dual-DB competitive classification is required for this tissue/protocol;
  single-DB viral-only produces exclusively false positives

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
