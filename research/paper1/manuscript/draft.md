# Paper 1 — Manuscript Draft
# Bioinformatics Application Note

**Title:** A Nextflow pipeline for systematic k-mer-based virome profiling of human
neural tissue from bulk RNA-seq, with a curated artifact exclusion framework

**Status:** Bullet-point draft — prose to be written by author from these points.
Section 3.5 is a placeholder pending PlusPF comparison run.

---

## Structured Abstract

- **Motivation**
  - Human DRG is a known latency site for neurotropic viruses; broader viral landscape uncharacterized
  - No reproducible pipeline exists for virome profiling from human neural tissue bulk RNA-seq
  - k-mer classifiers applied to viral-only databases produce systematic tissue-specific false positives
    that require explicit curation before biological interpretation

- **Results**
  - We present virome-pipeline: Nextflow DSL2, HPC-ready (SLURM/Apptainer), multi-stage filtering
  - Integrates host depletion (STAR/GRCh38), Kraken2 viral classification, Bracken re-estimation,
    and a 24-entry curated artifact exclusion list
  - Applied to 15 human samples (DRG n=11, skeletal muscle n=5):
    - Median 30 taxa at baseline → 4 after full filtering
    - HERV-K detected in all samples as internal positive control
    - Two case studies demonstrating database-driven misassignment (CMV, hantavirus) and their remediation
  - Optional dual-database mode (viral-only + PlusPF) classifies taxa into three confidence tiers

- **Availability**
  - github.com/mwilde49/virome-pipeline (DOI: 10.5281/zenodo.XXXXXXX)

---

## 1. Introduction

**Paragraph 1 — Clinical motivation**
- Human DRG are the primary latency reservoir for alphaherpesviruses: HSV-1, HSV-2, VZV
- Betaherpesviruses (CMV/HHV-5) may also persist in sensory ganglia — supported by seroprevalence
  and occasional detection in post-mortem tissue, though not systematically characterized
- Viral reactivation in DRG is proposed as a contributor to neuropathic pain and peripheral neuropathy,
  particularly in immunocompromised populations and post-infection settings
- Despite clinical relevance, the full viral landscape of human DRG has never been systematically profiled —
  no published study reports a comprehensive, unbiased virome of sensory ganglia

**Paragraph 2 — Technical gap**
- Bulk RNA-seq from human neural tissue is increasingly available: GTEx, disease cohorts, surgical biobanks
- k-mer-based classifiers (Kraken2, Centrifuge) are fast, reference-agnostic, and applicable to existing datasets
  without additional sequencing
- Viral-only reference databases create a closed-world assumption: every unclassified read is forced into a viral
  bin, inflating false positive rates relative to a competitive classification strategy
- Human bulk RNA-seq is host-dominated: viral reads are a tiny fraction of total reads; signal-to-noise is
  fundamentally challenging
- Neural tissue contains tissue-specific transcripts (neuronal ion channels, neuropeptides, lncRNAs) whose k-mers
  can overlap with environmental metagenome-derived viral sequences — a class of artifact not documented for
  other tissue types
- No published pipeline addresses these neural tissue-specific artifact patterns, nor provides a systematic
  framework for their identification and exclusion

**Paragraph 3 — Our contribution**
- We present virome-pipeline: a reproducible, HPC-ready Nextflow DSL2 pipeline for virome profiling
  from bulk RNA-seq
- Key contributions beyond existing tools:
  - Multi-stage filtering with per-stage audit trails (not a black box)
  - A versioned, extensible artifact exclusion list derived from systematic per-read investigation
  - Two worked case studies documenting novel artifact categories (database reference imbalance, tissue-specific
    cross-mapping) with explicit remediation strategies
  - An optional dual-database mode that classifies taxa by detection confidence across databases
- Applied to 15 human samples spanning DRG and skeletal muscle, establishing the first systematic baseline for
  human DRG virome profiling and the noise characteristics of this approach

---

## 2. Pipeline Description

**2.1 Architecture** (Fig 1)
- Seven-step Nextflow DSL2 workflow, each step in its own Apptainer container
- Steps in order:
  1. FASTQC — raw read quality assessment
  2. TRIMMOMATIC — adapter trimming, quality trimming (leading/trailing Q3, sliding window 4:15, min length 36 bp)
  3. STAR_HOST_REMOVAL — alignment to GRCh38; unmapped reads retained for viral classification
  4. KRAKEN2_CLASSIFY — k-mer classification against Langmead viral DB (k2_viral_20240904, confidence = 0.1)
  5. BRACKEN — species-level abundance re-estimation from Kraken2 report (read length 150 bp)
  6. KRAKEN2_FILTER — multi-stage filtering (described in 2.2)
  7. AGGREGATE — merge per-sample outputs into cohort-level abundance matrices; normalize to RPM using
     STAR-reported input read counts
- SLURM-ready via `--profile slurm`; container paths parameterized via `params.container_dir`
- Reports: per-run HTML execution report, timeline, and DAG automatically generated
- MultiQC collects FASTQC, Trimmomatic, STAR, and Bracken logs for a unified QC summary

**2.2 Multi-stage filtering** (Fig 2)
- Three stages preserved as separate outputs — no overwriting, full audit trail
  - *bracken_raw*: complete Bracken output; all viral species regardless of count
  - *minreads*: ≥5 reads per taxon per sample (parameterized via `params.min_reads_per_taxon`)
  - *final*: artifact exclusion list applied on top of minreads
- Per-sample `filter_summary.tsv` records: taxa count and total reads retained at each stage
- Per-sample `artifacts_removed.tsv` records: which specific taxa were excluded and at what counts
- Three cohort-level matrices produced: `bracken_raw_matrix.tsv`, `minreads_matrix.tsv`,
  `viral_abundance_matrix.tsv` (primary output)
- Comparison of bracken_raw to final reveals per-sample filtering yield — useful for QC and batch effects

**2.3 Artifact exclusion framework**
- `assets/artifact_taxa.tsv`: NCBI taxon ID list, versioned with the pipeline, extensible
- 24 curated entries as of v1.3.0, organized into categories:
  - *Reagent/environmental contaminants*: phages and environmental metagenome viruses absent from vertebrate host
    range (e.g., Gihfavirus, Kinglevirus — detected exclusively in DRG due to neuronal k-mer overlap)
  - *Reference database artifacts*: taxa present in the viral DB lacking genuine human host range
    (ruminant orthobunyaviruses, insect baculoviruses, avian herpesviruses, giant amoeba viruses)
  - *Cross-tissue k-mer artifacts*: viruses consistently detected at low, uniform levels across all
    sample types and cohorts — signal inconsistent with tissue tropism (Oxbow virus, described in 3.4)
- ICTV reclassification caveat: ICTV periodically reassigns taxon IDs; both old and new IDs listed
  where reclassification is confirmed. Exclusion lists should be audited after database version changes.
- Set `params.artifact_list = null` to disable; designed for reuse with a tissue-appropriate exclusion list

**2.4 Taxon display name remapping**
- Some taxa receive correct LCA assignments by taxon ID but carry NCBI labels that are misleading in a
  human tissue context (cross-species reference dominance in the database)
- `assets/taxon_remap.tsv`: maps taxon_id → corrected display_name; taxon_id preserved in all outputs
  for traceability
- Applied after artifact exclusion to all three output stages
- Current entry: taxon 3050337 (*Cytomegalovirus papiinebeta3*, baboon CMV reference) → `Human CMV (HHV-5) [proxy]`
  — the `[proxy]` flag explicitly signals inferred rather than confirmed assignment
- Set `params.taxon_remap = null` to disable

**2.5 Dual-database mode (optional)**
- Viral-only databases maximize detection sensitivity but inflate false positive rate
- Optional second Kraken2 + Bracken + filter branch runs in parallel from the same host-depleted reads
- Any Kraken2-compatible database can be used as DB2; recommended: Langmead PlusPF standard DB
  (k2_pluspf; includes bacteria, archaea, fungi, human, protozoa in addition to viral)
- Three confidence tiers assigned per taxon:
  - Tier 1 (Shared): detected in both databases — high-confidence signal, use for biology
  - Tier 2 (Viral-only only): detected only in viral-only DB — false positive candidates; inspect before interpreting
  - Tier 3 (PlusPF only): detected only in PlusPF DB — warrants investigation
- Outputs: `consensus_matrix.tsv` (Tier 1), `false_positive_candidates.tsv` (Tier 2), `db_comparison.tsv` (full)
- Activated by setting `params.kraken2_db2` to a database path; single-DB behavior unchanged when null

---

## 3. Results

**3.1 Application to the 15-sample DRG/muscle cohort**
- 15 human samples: paired-end bulk RNA-seq, NovaSeq 6000, 2×150 bp, 17–92 million reads per sample
- Sample composition:
  - DRG: 11 samples — 6 from a single donor (spinal levels L1, L2, L3, L4, L5, T12) and 5 from
    5 additional independent donors (Saad cohort)
  - Skeletal muscle: 5 samples from 5 independent donors (non-neural tissue control)
  - Note: muscle and DRG donors are not matched — tissue-paired comparisons are not possible
- Two samples excluded from final analysis: AIG1390 (confirmed duplicate of donor1) and Saad_2
  (failed library; phiX174 spike-in detected, not a biological sample)
- Host removal (STAR/GRCh38) retained [X]% of reads as unmapped — consistent with expectation for
  poly-A selected neural RNA-seq [INSERT values from results]
- Filtering funnel (Fig 2): median N taxa at bracken_raw → N at minreads → N at final
  [INSERT values from filter_summary outputs]
- Primary output matrix (Fig 3): 3–5 viral species detected per sample after full filtering
- RPM normalization enables cross-sample comparison despite read depth variation (17–92M reads)

**3.2 HERV-K as internal positive control**
- Human endogenous retrovirus K (HERV-K/HML-2) detected in all 15 samples at the final filtering stage
- Provides an internal positive control: a known human retrovirus-derived sequence expected to be
  transcriptionally active in neural tissue
- DRG samples show modestly elevated HERV-K signal relative to skeletal muscle (median ~50 vs ~31 RPM)
- Pattern consistent with published HERV-K transcriptional activity in neural tissue, including elevated
  expression in nervous system-derived cell types
- Confirms pipeline sensitivity is sufficient to detect low-abundance viral-derived reads in host-dominated libraries
- HERV-K reads assign via the Kraken2 LCA mechanism: HERV-K sequences present in the viral database at
  multiple taxonomic levels; detection is mechanistically expected

**3.3 Case study 1 — CMV reference database imbalance**
- *Observation*: reads consistently assigned to *Cytomegalovirus papiinebeta3* (NCBI taxon 3050337)
  across all samples including skeletal muscle; the baboon CMV reference genome (NC_055235.1)
- *Investigation*: Kraken2 report shows 0 direct reads at the species level (3050337); all direct
  reads at S1 child taxon 2169863 (*Papiine betaherpesvirus 3*) — classic LCA rollup signature
- *Root cause*: The Langmead viral database contains a single human CMV reference (Merlin strain,
  NC_006273.2); human CMV strain diversity is large, and reads from human samples that match no
  strain-level k-mer well are assigned to the baboon CMV reference through LCA, which sits adjacent
  in the betaherpesvirus phylogeny
- *Interpretation*: signal is most parsimoniously explained as HHV-5 (human CMV) presence inferred
  through cross-species k-mer matching, not genuine baboon CMV infection
- *Remediation*:
  - `taxon_remap.tsv` relabels 3050337 to `Human CMV (HHV-5) [proxy]` in all pipeline outputs
  - The `[proxy]` flag signals that direct alignment-based confirmation is needed before making
    biological claims about CMV detection
  - Long-term fix: augment database with multiple HHV-5 strain genomes (Toledo, TB40/E, AD169) to
    capture strain-level k-mer diversity and redirect assignments to the correct reference
- *Generalizable lesson*: zero direct reads at a species node with non-zero clade reads always
  indicates assignment to a child taxon. Always inspect the Kraken2 report file (not just the Bracken
  output) when investigating unexpected detections

**3.4 Case study 2 — Oxbow virus hantavirus cross-mapping**
- *Observation*: Orthohantavirus oxbowense (NCBI taxon 3052491 / Oxbow virus child taxon 660954)
  detected in all 15 samples, including all 5 skeletal muscle samples, at 22–197 reads
- Two anomalous high-signal samples: Saad_1 (3287 reads) and donor1_L2 (2339 reads)
- *Investigation*: per-read Kraken2 analysis confirms all direct reads assign to taxon 660954
  (Oxbow virus, a North American vole hantavirus), not to the human-infecting hantaviruses
  (Sin Nombre, Hantaan)
- *Key diagnostic*: universal cross-tissue, cross-cohort signal is inconsistent with any plausible
  genuine infection hypothesis. A hantavirus that genuinely infected DRG would not produce identical
  read counts in skeletal muscle from different donors
- *Probable mechanism*: neuronal k-mer overlap — DRG-enriched transcripts (neuronal ion channels,
  neuropeptides) share short k-mer sequences with Oxbow virus genomic regions by chance, producing
  systematic false classifications
- *Anomalous spikes*: the two high-signal samples (Saad_1 and donor1_L2) are likely index hopping
  artifacts from adjacent wells containing high-hantavirus-signal samples in the sequencing run —
  a known Illumina NovaSeq artifact at <1% of read abundance
- *Remediation*: both taxon IDs (3052491 and 660954) added to artifact exclusion list (v1.2.1)
- *Generalizable lesson*: universal cross-tissue detection at low, uniform levels is the clearest
  diagnostic for k-mer cross-mapping artifacts. Any novel virus detected at similar levels in all
  samples, regardless of tissue type or donor, should be treated as artifact until proven otherwise

**3.5 Recommendation: competitive classification with a standard database**
- [PLACEHOLDER — insert after PlusPF comparison run]
- Key points to cover:
  - Viral-only database forces false classifications because unclassified reads have no competitive
    destination — every read is assigned somewhere within the viral tree
  - PlusPF competitive classification allows reads to assign to bacteria, fungi, human, etc.,
    reducing the pool of reads available for viral misassignment
  - Expected result: Tier 2 taxa (viral-only only) represent the FP-enriched fraction;
    Tier 1 (shared) represent high-confidence signal
  - Quantify: X% reduction in bracken_raw taxa count; Y% of final viral-only taxa confirmed by PlusPF
  - Recommendation: for new studies, use PlusPF or standard DB as the primary database;
    retain viral-only for sensitivity comparison

---

## 4. Discussion

**Paragraph 1 — What the pipeline contributes**
- virome-pipeline is the first publicly available, reproducible pipeline targeting human neural tissue
  virome profiling from bulk RNA-seq
- The artifact curation framework — systematic per-read investigation, explicit documentation of root
  causes, versioned exclusion list — is the primary methodological contribution
- The framework is tissue-agnostic in design; substituting a tissue-appropriate artifact exclusion list
  adapts the pipeline to other tissue types or disease contexts
- Publishing the exclusion list and its derivation is itself a contribution: researchers using
  Kraken2 on similar data will encounter the same artifacts

**Paragraph 2 — Fundamental limitations of the k-mer approach from bulk RNA-seq**
- Sensitivity ceiling: latent viral genomes not being actively transcribed will not be detected in
  poly-A selected RNA-seq; this approach detects viral transcription, not viral presence
- Bulk RNA-seq is not designed for virome profiling: viral reads represent a fraction of a percent of
  total reads; any k-mer at the noise floor is difficult to distinguish from systematic misclassification
- Reference database completeness is a hard ceiling: viruses not in the database cannot be detected;
  novel and divergent viruses are invisible to this approach
- k-mer classifiers assign based on sequence similarity without read-level alignment evidence;
  all detections at low abundance require orthogonal validation before biological interpretation
- These limitations are not unique to this pipeline — they are intrinsic to k-mer classification from
  host-dominated bulk RNA-seq, and should be explicitly acknowledged in any study using this approach

**Paragraph 3 — Future directions**
- Alignment-based validation (minimap2 to viral reference genomes, GATK PathSeq) as a confirmation
  layer for high-confidence candidates — especially any candidate proposed as a novel finding
- Targeted viral enrichment strategies (VirCapSeq-VERT, CRISPR-based depletion of host rRNA/mRNA)
  would substantially improve sensitivity for low-abundance latent viruses
- Larger cohorts with tissue-paired sampling, matched donors, and clinical stratification (neuropathic
  pain vs. control) are needed to distinguish genuine virome signals from donor-to-donor variation —
  the cross-sectional, multi-donor design of this study precludes such comparisons
- A primary research study employing this pipeline in a statistically powered, clinically stratified
  cohort is in preparation (cite paper 2)

---

## Figure Legends (draft bullets)

**Fig 1 — Pipeline diagram**
- virome-pipeline workflow
- Seven numbered steps from raw FASTQs to abundance matrices and HTML report
- Show three parallel output streams from KRAKEN2_FILTER
- Optional dual-DB branch indicated with dashed lines and [optional] label
- Color-coded by step category: QC (blue), alignment (green), classification (orange), reporting (grey)

**Fig 2 — Filtering funnel**
- Grouped bar chart: taxa retained per filtering stage per sample, across all 15 samples
- X-axis: samples grouped by tissue type (muscle | DRG donor1 | DRG Saad)
- Y-axis: taxa count
- Three bars per sample: bracken_raw (light), minreads (medium), final (dark)
- Demonstrates consistent filtering yield and reveals per-sample outliers (if any)

**Fig 3 — Virome heatmap**
- Final filtered viral abundance heatmap, top 30 taxa, all 15 samples
- Color: log10(reads + 1), YlOrRd scale
- X-axis: samples (grouped: muscle | DRG donor1 | DRG Saad)
- Y-axis: taxon name (using remap display names where applicable)
- HERV-K row visible across all samples; CMV row labeled as "Human CMV (HHV-5) [proxy]"

---

## Supplementary (content bullets)

**Table S1 — Artifact exclusion list**
- Full 24-entry `artifact_taxa.tsv` formatted as a table
- Columns: taxon_id, taxon_name, category, rationale summary, version added
- Note ICTV reclassification pairs where applicable (e.g., Ralstonia phage p12J 247080 / 2956327)

**Note S1 — CMV taxonomy investigation**
- Condensed from cmv_taxonomy_investigation.md
- Show Kraken2 report excerpt: species node with 0 direct reads, S1 child with all direct reads
- Explain LCA mechanism producing the pattern
- Show taxon phylogeny: Human CMV → Cytomegalovirus → baboon CMV reference DB position

**Note S2 — Oxbow virus cross-mapping investigation**
- Show per-sample read counts at taxon 660954 across all 15 samples (table)
- Highlight uniform low-level signal across tissue types as diagnostic
- Note two high-signal samples and index hopping hypothesis
- Explain neuronal k-mer overlap hypothesis

**Table S2 — PlusPF vs viral-only comparison** [PLACEHOLDER — insert after run]
- Per-taxon tier classification table for the 3-sample subset
- Columns: taxon_name, taxon_id, viral_only_reads, pluspf_reads, tier
