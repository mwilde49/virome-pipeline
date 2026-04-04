# Abstract — Paper 1 (Conference Poster, ~500 words structured)

**Title:** virome-pipeline: competitive dual-database classification with multi-stage QC eliminates false positives
and establishes a null baseline for the human dorsal root ganglion virome from bulk RNA-seq

---

## Background

Neurotropic viruses including varicella-zoster virus (VZV), herpes simplex virus (HSV-1/2),
and cytomegalovirus (HHV-5) establish latency in dorsal root ganglia (DRG) and are
implicated in chronic neuropathic pain and neuropathies. Bulk RNA-seq from human neural tissue is
increasingly available through post-mortem biobanks, yet no validated pipeline exists for
systematic virome profiling in this context. k-mer classifiers such as Kraken2, when applied
to viral-only reference databases, impose a closed-world assumption that, while enhancing 
detection sensitivity, incurs an expected cost to specificity: every unclassified read
is forced onto the nearest viral taxon, systematically inflating false positive rates. We
present virome-pipeline to characterize this bias, resolve it via competitive classification,
and establish a null baseline for future DRG virome studies.

## Methods

virome-pipeline (v1.3.0) is a Nextflow DSL2 pipeline implementing splice-aware host read
depletion against GRCh38 (STAR), k-mer taxonomic classification (Kraken2, confidence 0.1),
species-level re-estimation (Bracken, 150 bp), three-stage output filtering (bracken raw →
min-reads ≥5 → curated artifact exclusion), and an optional dual-database competitive
classification branch. The dual-database branch exploits the sensitivity–specificity trade-off: a maximally
sensitive viral-only database and the comprehensively specific PlusPF standard database
classify reads in parallel. Each detected taxon receives a confidence tier: Tier 1 (both databases — confirmed
viral candidate), Tier 2 (viral-only exclusive — false positive candidate), or Tier 3
(PlusPF-only — non-viral background). A 24-entry artifact exclusion list addresses tissue-specific k-mer cross-mapping confirmed
by per-read BLAST. All steps are
containerized (Apptainer) and SLURM-ready. The pipeline was applied to 15 post-mortem
samples: 5 skeletal muscle and 10 DRG from two independent donor cohorts spanning cervical,
thoracic, and lumbar spinal levels.

## Results

Dual-database competitive classification produced zero Tier 1 viral detections across all 15
samples and both tissue types — a 100% empirical false positive rate for viral-only Kraken2
classification in this context. Three Tier 2 taxa were identified and fully mechanistically
resolved:

**Human endogenous retrovirus K (HERV-K)** — 5.8-fold enriched in DRG over skeletal muscle
(p = 3.3 × 10⁻⁴, Mann-Whitney U, one-sided), reproduced across two independent cohorts at
six spinal levels. PlusPF reclassifies all reads to *Homo sapiens*, confirming endogenous
chromosomal origin consistent with neural-lineage LTR promoter activity in post-mitotic
sensory neurons.

**Human CMV (HHV-5) [proxy]** — 1,097 reads across 14 samples; zero reads under PlusPF in
all samples. ICTV 2023 taxonomic reclassification routes human k-mers via a baboon CMV
reference node; fully resolved by competitive classification.

**Molluscum contagiosum virus** — 189 sporadic reads, muscle-predominant (65% of total);
consistent with index-hopping contamination.

Multi-stage filtering reduced a cohort-wide median of 30 bracken_raw taxa to 3 at final
output. These results establish an empirical detection floor of approximately 10 reads per
million host-depleted reads for active viral transcription by bulk RNA-seq metagenomics.

## Conclusions

Viral-only k-mer classifiers produce excessively false positive signals in human neural
tissue bulk RNA-seq. Competitive dual-database classification is necessary before any viral
detection from this data type can be biologically interpreted. The null result establishes that no active viral transcription above the bulk RNA-seq
sensitivity floor is present in these donors — a validated baseline for clinical cohort
studies of the DRG virome. The tissue-specific HERV-K enrichment (5.8×, DRG > muscle) is
a novel observation warranting investigation as a viral co-factor in neuropathic pain.
virome-pipeline is open source (MIT; github.com/mwilde49/virome-pipeline), containerized,
and generalizable to other tissue types via a swappable artifact exclusion list.


