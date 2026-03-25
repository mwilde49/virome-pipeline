# Research Prospectus: Systematic Profiling of the Human Dorsal Root Ganglion Virome

**Version:** 1.0
**Date:** 2026-03-24
**Pipeline version:** 1.0.0
**Authors:** TJP Group, UT Dallas
**Status:** Internal research memo -- pre-publication planning document

---

## Table of Contents

1. [Scientific Background and Motivation](#1-scientific-background-and-motivation)
2. [Pipeline Design Assessment](#2-pipeline-design-assessment)
3. [Database and Reference Considerations](#3-database-and-reference-considerations)
4. [Known Artifacts and Contamination Sources](#4-known-artifacts-and-contamination-sources)
5. [Results Interpretation](#5-results-interpretation)
6. [Normalization and Statistical Considerations](#6-normalization-and-statistical-considerations)
7. [Validation Strategy](#7-validation-strategy)
8. [Future Pipeline Features and Roadmap](#8-future-pipeline-features-and-roadmap)
9. [Publication Strategy](#9-publication-strategy)

---

## 1. Scientific Background and Motivation

### 1.1 Biology of the Dorsal Root Ganglion

The dorsal root ganglion (DRG) is a cluster of neuronal cell bodies located in the intervertebral foramina along the spinal column. Each DRG houses the soma of primary sensory (afferent) neurons whose peripheral axons innervate skin, muscle, viscera, and joints, and whose central axons project into the spinal cord dorsal horn. The DRG serves as the obligate relay for essentially all somatosensory information entering the central nervous system, including touch, proprioception, temperature, itch, and pain.

#### 1.1.1 Cell type composition

Human DRGs contain a heterogeneous mixture of neuronal and non-neuronal cell types. Recent single-cell and single-nucleus RNA-seq studies have dramatically refined our understanding of this cellular landscape:

**Neuronal subtypes.** Harmonized cross-species atlases describe at least 12--18 transcriptionally distinct neuronal subtypes in mammalian DRG (Nguyen et al., 2021, *Nature Neuroscience*; Jung et al., 2023, *Science Advances*; Tavares-Ferreira et al., 2022, *Science Translational Medicine*). These include:

- **Nociceptors** (peptidergic and non-peptidergic): small-diameter neurons expressing TRPV1, SCN10A (Nav1.8), SCN11A (Nav1.9), NTRK1 (TrkA), CALCA (CGRP), and TAC1 (Substance P). These subdivide into at least 5--6 molecular subtypes, including pruriceptors (itch-sensing) and silent nociceptors.
- **Mechanoreceptors**: medium- to large-diameter neurons expressing NTRK2 (TrkB) and/or NTRK3 (TrkC), including A-beta low-threshold mechanoreceptors (LTMRs) that mediate touch and proprioception.
- **Proprioceptors**: large-diameter neurons expressing PVALB and NTRK3, innervating muscle spindles and Golgi tendon organs.
- **C-LTMRs**: unmyelinated mechanoreceptors expressing TAFA4/FAM19A4 and TH, mediating affective (pleasant) touch.

**Non-neuronal cells.** Single-nucleus transcriptomic profiles of glial cells in human DRG (Ji et al., 2023, *Anesthesiology and Perioperative Science*) and satellite glial cell heterogeneity mapping (Ahlgreen et al., 2026, *Advanced Science*) have revealed:

- **Satellite glial cells (SGCs):** Envelop each neuronal soma in a thin perisomatic sheath. At least 4--6 transcriptionally distinct SGC subtypes exist in human DRG, including: (1) canonical FABP7+/KIR4.1+/GS+/CX43+ perisomatic SGCs; (2) OCT6+ SGCs ensheathing initial axon segments; (3) SCN7A+ SGCs forming specialized sheaths around non-peptidergic neurons; and (4) interferon-response SGCs that respond to herpes simplex virus infection. This last subtype is directly relevant to virome biology.
- **Schwann cells:** Myelinating and non-myelinating subtypes that ensheath axons within the ganglion and along peripheral nerves.
- **Macrophages and other immune cells:** Resident macrophages, T cells, and mast cells populate the DRG and are critical for neuroinflammatory responses, including those triggered by viral reactivation.
- **Endothelial cells and fibroblasts:** Comprise the blood-nerve barrier and structural connective tissue of the ganglion.
- **Vascular pericytes:** Regulate blood flow within the DRG microvasculature.

The presence of interferon-response SGCs in the DRG underscores that the ganglion maintains constitutive immune surveillance against viral threats, consistent with its role as a reservoir for latent neurotropic viruses.

#### 1.1.2 Role in pain and neurological disease

The DRG is a central node in pain pathophysiology. Nociceptor sensitization in the DRG drives both inflammatory and neuropathic pain. Key mechanisms include:

- **Peripheral sensitization**: Upregulation of voltage-gated sodium channels (Nav1.7, Nav1.8, Nav1.9) in DRG neurons following tissue injury or inflammation.
- **Ectopic firing**: Spontaneous action potential generation in DRG neurons, a hallmark of neuropathic pain conditions.
- **Neuroimmune crosstalk**: Macrophage and SGC activation in the DRG releases pro-inflammatory cytokines (TNF-alpha, IL-1beta, IL-6) that sensitize adjacent neurons.
- **Transcriptional reprogramming**: Nerve injury induces large-scale transcriptomic changes in DRG neurons, including upregulation of ATF3 and other injury-responsive genes.

These mechanisms are clinically relevant in diabetic neuropathy, chemotherapy-induced peripheral neuropathy (CIPN), postherpetic neuralgia (PHN), HIV-associated neuropathy, and complex regional pain syndrome (CRPS).

### 1.2 Why Viruses Matter in the DRG

#### 1.2.1 Known viral tropisms for sensory ganglia

The DRG is a well-established latency reservoir for several neurotropic viruses. This tropism is not incidental; it reflects specific molecular interactions between viral entry machinery and sensory neuron surface receptors, combined with the immunoprivileged nature of the ganglionic microenvironment.

**Varicella-zoster virus (VZV, Human alphaherpesvirus 3).** VZV establishes lifelong latency in DRG neurons following primary infection (chickenpox). Latent VZV DNA resides as an episome in the nuclei of approximately 2--5% of sensory neurons per ganglion (Zerboni et al., 2005, *PNAS*; Nagel & Gilden, 2014, *Journal of NeuroVirology*). Reactivation decades later causes herpes zoster (shingles), characterized by dermatomal pain and vesicular rash. Critically, up to 20% of zoster patients develop postherpetic neuralgia (PHN), a debilitating chronic neuropathic pain state that can persist for years. The mechanism linking VZV reactivation to chronic pain involves virus-induced neuronal damage, inflammation, fibrosis, and cell loss in the DRG, with persistent alterations in sodium and calcium channel expression (Fleetwood-Walker et al., 1999). VZV reactivation also triggers polykaryon formation between neurons and satellite cells, amplifying viral spread and tissue damage (Zerboni et al., 2007, *Journal of Virology*).

**Herpes simplex virus type 1 and type 2 (HSV-1, HSV-2).** Both HSV serotypes establish latency in sensory ganglia, with a slight preference for trigeminal ganglia (HSV-1) versus lumbar/sacral DRG (HSV-2). During latency, the viral genome persists as a transcriptionally repressed episome, with the latency-associated transcript (LAT) being the only abundantly expressed viral RNA. LAT is a long non-coding RNA processed into regulatory microRNAs (miR-H2, miR-H6) that suppress productive infection and modulate host gene expression (Kramer et al., 2011). Notably, HSV-1 and HSV-2 display different tropisms for nociceptive neuron subtypes, with HSV-1 preferentially latent in A5+ neurons and HSV-2 in KH10+ neurons (Yang et al., 2000, *Journal of Virology*). This subtype specificity has implications for which neuronal populations might be functionally impaired during reactivation. An immortalized human DRG cell line has been established to study HSV-1 latency and reactivation *in vitro*, providing a model system for understanding virus-neuron interactions (Thellman et al., 2017, *Journal of Virology*).

**Human cytomegalovirus (HCMV, Human betaherpesvirus 5).** HCMV can infect peripheral neurons and has been detected in DRG tissue, though its tropism for sensory ganglia is less well-characterized than that of alphaherpesviruses. HCMV infection of DRG neurons *in vitro* can alter neuronal gene expression and may contribute to inflammatory signaling in the ganglionic microenvironment. The detection of a non-human CMV (Cytomegalovirus papiinebeta3, a baboon betaherpesvirus) in our DRG data raises questions about cross-reactive classification that are addressed in Section 4.

**Enteroviruses.** Poliovirus and other enteroviruses can infect sensory neurons, though their primary tropism is for motor neurons in the spinal cord. Non-polio enteroviruses (coxsackievirus, echovirus) have been implicated in some forms of post-infectious neuropathy, and their potential for DRG persistence is underexplored.

**HIV.** HIV does not directly infect DRG neurons but can infiltrate the ganglionic microenvironment via infected macrophages and T cells. HIV-associated sensory neuropathy (HIV-SN) is one of the most common neurological complications of HIV infection, affecting up to 50% of patients. The contribution of HIV viral proteins (gp120, Tat) to DRG neurotoxicity is well-documented, but the potential role of co-infecting viruses in the DRG of HIV+ patients remains uncharacterized.

#### 1.2.2 Endogenous retroviruses in the nervous system

Human endogenous retroviruses (HERVs) comprise approximately 8% of the human genome and are remnants of ancestral retroviral integrations. Most HERV loci are transcriptionally silenced, but certain families -- particularly HERV-K (HML-2) -- retain open reading frames and can be transcriptionally reactivated under specific conditions.

HERV-K has received considerable attention in neurological disease:

- **ALS**: HERV-K is transcriptionally activated in cortical and spinal motor neurons of a subpopulation of ALS patients. Transgenic mice expressing HERV-K Env protein in neurons develop a motor neuron disease phenotype resembling ALS, with neurite retraction and beading (Li et al., 2015, *Science Translational Medicine*). HERV-K Env protein in neuronal extracellular vesicles has been proposed as a biomarker of motor neuron disease (Arru et al., 2021).
- **Multiple sclerosis**: HERV-W Env protein (syncytin) is implicated in oligodendrocyte damage and demyelination. A monoclonal antibody targeting HERV-W Env (temelimab) has been tested in clinical trials.
- **Neurodevelopment**: HERV-K expression is dynamically regulated during human neural development, with expression in embryonic stem cells and neural progenitors that is normally silenced upon differentiation.

**Critically, HERV-K expression in the peripheral nervous system, and specifically in DRG neurons, has not been systematically characterized.** Our preliminary finding of HERV-K enrichment in DRG relative to muscle tissue (~46--58 RPM vs. 27--35 RPM, approximately 2-fold) represents, to our knowledge, the first quantification of HERV-K expression in human DRG from RNA-seq data. This finding is biologically plausible: DRG neurons are post-mitotic and long-lived, potentially allowing gradual epigenetic derepression of HERV loci; the DRG microenvironment contains inflammatory signals (e.g., from SGCs and resident macrophages) that can activate HERV-K transcription; and the partial immune privilege of sensory ganglia may permit HERV expression that would be suppressed in tissues with more vigorous immune surveillance.

The functional significance of HERV-K expression in DRG neurons is unknown, but several hypotheses merit investigation: (1) HERV-K transcription may be a passive indicator of epigenetic relaxation in post-mitotic neurons; (2) HERV-K Env protein, if translated, could contribute to neuronal stress or dysfunction analogous to its role in motor neurons; (3) HERV-K-derived regulatory sequences (LTRs) may modulate expression of nearby host genes relevant to sensory neuron function.

#### 1.2.3 Viral contributions to neuropathic pain

Beyond the well-characterized case of VZV-induced PHN, there is growing evidence that viral infections contribute to neuropathic pain through multiple mechanisms:

- **Direct neuronal damage**: Lytic viral replication in DRG neurons causes cell death and axonal degeneration, leading to deafferentation pain.
- **Neuroinflammation**: Viral infection activates resident macrophages and SGCs, releasing pro-inflammatory mediators that sensitize neighboring neurons.
- **Ion channel modulation**: VZV infection alters expression of Nav1.7, Nav1.8, Cav alpha-2-delta, and TRPV1 in DRG neurons, directly lowering firing thresholds.
- **Epigenetic reprogramming**: Latent viral genomes and their associated non-coding RNAs (e.g., HSV LAT, VZV VLT) can alter host chromatin state, potentially affecting expression of pain-relevant genes.
- **Immune-mediated damage**: Reactivation-triggered adaptive immune responses can damage DRG neurons through cytotoxic T cell activity and antibody-mediated complement activation.

The potential for "silent" or subclinical viral infections in the DRG to contribute to idiopathic neuropathic pain states is a largely untested hypothesis. Comprehensive virome profiling of DRG tissue from neuropathic pain patients versus pain-free controls could provide the first systematic test of this hypothesis.

### 1.3 Gap in the Field

Despite the DRG's well-established role as a viral reservoir and its centrality to pain biology, **no published study has performed unbiased, comprehensive virome profiling of human DRG tissue.** The existing literature on viruses in the DRG is limited to:

1. **Targeted studies of individual viruses**: PCR-based detection of VZV, HSV-1, HSV-2, and occasionally HCMV in human DRG autopsy or surgical specimens. These studies confirm the presence of known neurotropic viruses but cannot detect unexpected or novel viral agents.

2. **Human DRG transcriptomics focused on host genes**: Several high-quality bulk and single-cell RNA-seq datasets from human DRG exist (Ray et al., 2018, *Pain*; Tavares-Ferreira et al., 2022, *Science Translational Medicine*; deep RNA-seq by Bhatt et al., 2024, *Nature Neuroscience*; long-read sequencing by Wangzhou et al., 2023), but none have been systematically analyzed for viral content. The unmapped reads from these existing datasets represent an untapped resource.

3. **Virome studies in other neural tissues**: A small number of studies have profiled the virome of brain tissue (e.g., Readhead et al., 2018, *Neuron*, linking HHV-6A/7 to Alzheimer disease), but the peripheral nervous system virome remains essentially uncharacterized.

4. **Gut and skin virome studies**: The human virome has been profiled extensively in mucosal sites (gut, respiratory tract, skin) but not in solid organs of the nervous system.

This gap creates several opportunities:

- **Discovery of unexpected viral residents**: The DRG may harbor viruses beyond the known alphaherpesviruses. Our preliminary data already suggest this (see Section 5).
- **Quantification of HERV expression**: No prior study has quantified endogenous retrovirus expression in human DRG, despite its potential relevance to neuropathic pain and neurodegeneration.
- **Cross-tissue and cross-donor comparison**: Understanding how the DRG virome varies across spinal levels, between tissues, and between individuals with and without neuropathic pain.
- **Methodological foundation**: Establishing a reproducible computational pipeline for DRG virome profiling that can be applied to archival RNA-seq datasets.

### 1.4 Why Bulk RNA-seq Is a Reasonable Starting Point

Bulk RNA-seq is not the ultimate tool for virome profiling -- it lacks the sensitivity of targeted enrichment methods and the resolution of single-cell approaches. However, it is a pragmatic and scientifically defensible starting point for several reasons:

1. **Availability of existing data**: Large bulk RNA-seq datasets from human DRG already exist (e.g., Ray et al., 2018; North et al., 2019), and our group generates DRG RNA-seq data routinely. Virome analysis can be layered onto these datasets at minimal additional cost.

2. **Detection of actively transcribed viruses**: Bulk RNA-seq captures viral transcripts from actively replicating or transcriptionally active latent infections, which are the most biologically relevant for ongoing host-virus interactions.

3. **Adequate sensitivity for abundant species**: For viruses that constitute even a tiny fraction of the transcriptome (0.001--0.01%), standard sequencing depths of 20--150M read pairs provide hundreds to thousands of viral reads, sufficient for confident detection.

4. **Established computational infrastructure**: Mature tools exist for viral classification from RNA-seq data (Kraken2, Bracken, PathSeq), and the field has accumulated experience with artifact identification and filtering.

5. **Foundation for targeted follow-up**: Initial bulk RNA-seq profiling identifies candidate viruses that can then be investigated with more sensitive and specific methods (PCR, FISH, single-cell approaches).

The key limitation is sensitivity for low-abundance or DNA-only viruses (e.g., latent VZV genomes that are not actively transcribed), which would require dedicated virome enrichment protocols (VirCapSeq-VERT, CATCH) or metagenomic DNA sequencing.

---

## 2. Pipeline Design Assessment

### 2.1 Quality Control: FastQC

**Why this tool was chosen.** FastQC (Babraham Bioinformatics) is the de facto standard for raw read quality assessment in Illumina sequencing. It provides rapid, standardized metrics on base quality, adapter content, GC distribution, sequence duplication, and overrepresented sequences.

**Strengths.**
- Universal acceptance; reviewers and collaborators immediately understand FastQC output.
- No configuration required; automatically detects encoding and read format.
- Output integrates seamlessly into MultiQC for cross-sample comparison.
- Can flag library preparation problems (adapter contamination, GC bias, duplication) before they confound downstream analysis.

**Limitations.**
- FastQC is purely diagnostic; it does not modify reads. Quality issues must be addressed by downstream trimming.
- Some warnings are expected and benign for specific library types (e.g., per-base sequence content in the first 10--15 bases of RNA-seq libraries is always "failed" due to random hexamer priming bias).
- GC content warnings may be triggered by viral sequences in samples with high viral load, leading to a paradoxical "failure" flag in the samples of greatest interest.

**Key parameters.** None; FastQC is run with default settings. The `--noextract` flag is used to produce compressed zip output suitable for MultiQC.

**Alternatives.** `falco` is a C++ reimplementation of FastQC that is approximately 2.5x faster on large files. `fastp` can simultaneously perform QC and trimming, potentially replacing both FastQC and Trimmomatic (see Section 8). `NanoPlot` is used for long-read QC but is not relevant here.

**Known failure modes.** FastQC can misinterpret polyA-selected RNA-seq as having low sequence complexity. On rare occasions, FastQC fails silently on corrupted gzip files without producing an error. The pipeline should verify that expected output files exist.

### 2.2 Adapter Trimming: Trimmomatic PE

**Why this tool was chosen.** Trimmomatic (Bolger et al., 2014, *Bioinformatics*) is a widely-used Java-based trimmer that handles paired-end reads with orphan management. It was selected for its reliable adapter removal, configurable quality filtering, and extensive benchmarking history. The PE mode ensures that R1/R2 pairing is maintained through trimming, which is critical for paired-end Kraken2 classification.

**Strengths.**
- Sequence-matching adapter removal using ILLUMINACLIP with palindrome mode, which is effective for short adapter fragments and chimeric reads.
- Configurable multi-step quality filtering (leading, trailing, sliding window, minimum length) allows fine-tuned control.
- Well-characterized behavior across thousands of publications.
- MultiQC integration for trim statistics reporting.

**Limitations.**
- **Performance**: Trimmomatic is Java-based and substantially slower than fastp (2--5x). For large cohorts, this impacts wall-clock time significantly.
- **Maintenance**: Trimmomatic has not been actively maintained since approximately 2020. No new releases or bug fixes are expected.
- **Missing features**: No built-in deduplication, no UMI handling, no polyG tail trimming (relevant for NextSeq/NovaSeq two-color chemistry), no automatic adapter detection.
- **Edge case**: ILLUMINACLIP's palindrome mode can occasionally trim legitimate genomic sequence if the read-through adapter fragment is very short (<4 bp).

**Key parameters and rationale.**

| Parameter | Value | Rationale |
|-----------|-------|-----------|
| ILLUMINACLIP | NexteraPE-PE.fa:2:30:10:8:true | Nextera adapters; 2 seed mismatches; palindrome clip threshold 30; simple clip threshold 10; min adapter length 8; keep both reads (true) |
| LEADING | 3 | Remove leading bases below Q3 -- permissive, only trims obvious low-quality |
| TRAILING | 3 | Symmetric with LEADING |
| SLIDINGWINDOW | 4:15 | 4-base window, trim when average quality drops below Q15 -- standard for RNA-seq |
| MINLEN | 36 | Discard reads shorter than 36 bp after trimming -- shorter reads produce unreliable k-mer classification |
| HEADCROP | 0 | No fixed 5' clipping; can be set >0 for libraries with known 5' bias |

**Alternatives.**
- **fastp** (Chen et al., 2018, *Bioinformatics*; v1.0 released 2025): 2--5x faster, auto-detects adapters, handles polyG trimming for two-color chemistry, produces its own QC report (HTML+JSON), and is actively maintained. **We recommend transitioning to fastp in a future pipeline version** (see Section 8.5).
- **Cutadapt** (Martin, 2011): More flexible adapter specification but slower than both Trimmomatic and fastp.
- **BBDuk** (BBTools suite): Fast and versatile, with built-in k-mer-based adapter and contaminant removal.
- **AdapterRemoval** (Schubert et al., 2016): Strong adapter trimming, but less widely used.

A 2024 benchmarking study on RNA virus sequencing data (PMC11476207) found that Trimmomatic and BBDuk effectively removed adapters from all datasets tested, while fastp occasionally left short adapter fragments. However, fastp retained the highest-quality reads overall. For virome profiling, where read quality directly impacts k-mer classification accuracy, either Trimmomatic or fastp are appropriate choices.

**Known failure modes.**
- If the wrong adapter file is provided (e.g., TruSeq adapters for a Nextera library), adapter removal will fail silently and adapter-contaminated reads will pass through to downstream steps.
- Very aggressive SLIDINGWINDOW settings (e.g., 4:20) can cause excessive read shortening, reducing the effective read length available for Kraken2 classification. Q15 is a reasonable balance.
- Trimmomatic does not handle interleaved FASTQ or single-end reads gracefully in PE mode.

### 2.3 Host Removal: STAR Alignment to GRCh38

**Why this tool was chosen.** STAR (Dobin et al., 2013, *Bioinformatics*) is a splice-aware RNA-seq aligner widely used in transcriptomics. In this pipeline, STAR serves a subtraction role: reads that align to the human genome (GRCh38) are considered host-derived and removed; only unmapped reads are forwarded to viral classification. The existing STAR index was already available on the Juno cluster from host transcriptomic workflows, making this an efficient choice.

**Strengths.**
- Extremely fast (minutes for tens of millions of reads with sufficient RAM).
- Splice-aware alignment captures reads spanning exon junctions, which constitute a large fraction of RNA-seq data. A non-splice-aware aligner (BWA, Bowtie2) would fail to map many host reads spanning splice junctions, inflating the number of "unmapped" reads passed to Kraken2 and increasing false positive viral classifications.
- The `--outReadsUnmapped Fastx` option directly outputs unmapped reads in FASTQ format for downstream processing.
- STAR log files provide precise input read counts, which serve as the denominator for RPM normalization.

**Limitations.**
- **Memory requirements**: STAR index loading requires approximately 30--35 GB RAM for GRCh38. This is manageable on HPC but prohibitive for local testing.
- **GRCh38 coverage of repetitive elements**: The reference genome assembly contains consensus sequences for some repetitive elements and transposable elements, but the representation of HERV sequences in the reference is incomplete. Many HERV-K loci have been annotated and are present in GRCh38, but divergent copies may not map cleanly. This has direct implications for HERV-K detection: some HERV-K reads may map to the host genome (and be subtracted), while others from more divergent loci may fail to map and be classified as viral by Kraken2. The net effect is that HERV-K abundance estimates from this pipeline likely undercount true HERV-K expression. See Section 3.2 for further discussion.
- **No decoy sequences**: The current STAR index uses only the primary GRCh38 assembly. It does not include ALT contigs, decoy sequences, or HLA haplotypes. Reads from polymorphic regions that do not match the reference may spuriously enter the viral classification step.
- **Multimapping handling**: The `--outFilterMultimapNmax 1` setting reports only uniquely mapping reads. Reads that map to multiple genomic loci (common for repetitive elements and HERVs) are classified as unmapped and passed to Kraken2. This conservative setting maximizes host depletion specificity but reduces its sensitivity. Reads from high-copy-number HERV families will disproportionately "leak" through host removal because they multimap.

**Key parameters and rationale.**

| Parameter | Value | Rationale |
|-----------|-------|-----------|
| `--outFilterMultimapNmax` | 1 | Only report unique alignments; multimappers treated as unmapped. Conservative: ensures high-confidence host subtraction, at the cost of allowing repetitive element reads to pass through. |
| `--outSAMtype` | BAM SortedByCoordinate | Standard sorted BAM output for QC/review purposes |
| `--outReadsUnmapped` | Fastx | Emit unmapped reads as FASTQ for Kraken2 input |
| `--readFilesCommand` | zcat | Handle gzip-compressed input |

**Alternatives.**
- **Bowtie2** (Langmead & Salzberg, 2012): Commonly used for host subtraction in metagenomics. Faster index loading and lower memory, but not splice-aware. For RNA-seq host removal, Bowtie2 would miss a substantial fraction of host reads at exon junctions, inflating false positive viral calls. Not recommended as a sole host subtraction tool for RNA-seq.
- **HISAT2** (Kim et al., 2019): Splice-aware with a more memory-efficient index than STAR (~8 GB vs. ~30 GB). A viable alternative if memory is limiting.
- **BWA-MEM2**: Not splice-aware; inappropriate for RNA-seq host subtraction.
- **GATK PathSeq**: Uses a two-pass BWA-based subtraction with a kmer-based pre-filter, designed specifically for pathogen detection. More thorough host removal than a single STAR pass but considerably slower. Considered for a future validation module (see Section 7.2).
- **KneadData** (Huttenhower Lab): Combines Bowtie2 host subtraction with Trimmomatic. Not splice-aware.

**Known failure modes.**
- If the STAR index was built with a different genome build (e.g., hg19 instead of GRCh38), reads from regions with assembly differences may fail to map and contaminate viral calls.
- Reads from genomic regions absent from the reference (structural variants, novel insertions) will not be subtracted.
- Very short reads (<30 bp, after trimming) may fail to map to the host genome even if host-derived, because STAR's minimum seed length defaults may exceed the read length.
- STAR can produce unmapped reads for technical reasons unrelated to viral origin (e.g., reads spanning complex structural rearrangements, reads with excessive mismatches due to SNPs, or reads from contaminating DNA that spans introns).

### 2.4 Taxonomic Classification: Kraken2

**Why this tool was chosen.** Kraken2 (Wood, Derrick E., Jennifer Lu, and Ben Langmead, 2019, *Genome Biology*) is the most widely used k-mer-based taxonomic classifier for metagenomic sequencing data. It operates by breaking each read into k-mers (k=35 by default) and matching them against a pre-built database of reference genomes, using a lowest common ancestor (LCA) algorithm to assign each read to a taxon.

**Strengths.**
- Extremely fast: classifies millions of reads per minute using a memory-mapped hash table.
- Well-validated against other classifiers (Centrifuge, CLARK, MetaPhlAn) with competitive or superior sensitivity and specificity in benchmarks.
- Active maintenance and community support.
- Pre-built databases available from the Langmead Lab (see Section 3.1).
- The `--confidence` parameter provides a tunable threshold for classification stringency.

**Limitations.**
- **K-mer-based classification**: Kraken2 assigns reads based on exact k-mer matches, not full read alignment. This means:
  - Short regions of homology can drive misclassification if k-mers are shared between taxa.
  - Novel or divergent viruses with <80% nucleotide identity to database references may be missed entirely.
  - Chimeric reads (e.g., from library preparation artifacts) can produce k-mers matching multiple taxa, leading to LCA assignments at high taxonomic levels (e.g., family or order) rather than species.
- **Database dependence**: Classification is only as good as the reference database. Viruses not represented in the database cannot be detected. The Langmead viral database is comprehensive for known viral species but does not include metagenomically-assembled viral genomes (MAGs) from environmental samples. See Section 3.1.
- **No alignment**: Unlike BLAST or minimap2, Kraken2 does not produce alignments. There is no way to assess read coverage across a viral genome, identify which regions of a virus are detected, or calculate genome-wide depth. This limits the ability to distinguish true infections from spurious matches.
- **Paired-end handling**: Kraken2's `--paired` mode classifies each mate independently and then combines the results. If only one mate contains viral k-mers, the pair may still be classified, but confidence is lower.
- **Compositional bias**: In low-complexity or low-biomass samples, Kraken2 can produce false positive classifications at elevated rates because even random sequences may contain k-mers matching database entries.

**Key parameters and rationale.**

| Parameter | Value | Rationale |
|-----------|-------|-----------|
| `--confidence` | 0.1 | Requires 10% of k-mers in a read to support the assigned taxon. Default is 0.0 (no confidence threshold). A value of 0.1 provides a mild filter that removes the most spurious classifications while retaining sensitivity for genuine viral reads. Higher values (0.2--0.5) would reduce false positives but risk missing true viral reads, especially for reads with low query coverage against reference genomes. |
| `--paired` | (flag) | Enables paired-end classification |
| `--gzip-compressed` | (flag) | Input reads are gzip-compressed |

**Confidence threshold considerations.** The choice of confidence=0.1 is deliberately permissive. For DRG samples, where we expect low viral abundance relative to host RNA, sensitivity is prioritized over specificity. The pipeline's multi-stage filtering (Bracken re-estimation, min-reads threshold, artifact exclusion) provides additional specificity downstream. However, for future cohorts, it may be appropriate to test confidence thresholds of 0.1, 0.2, and 0.3 in parallel to assess the sensitivity-specificity tradeoff empirically (see Section 8).

**Alternatives.**
- **Centrifuge** (Kim et al., 2016): Uses a compressed FM-index rather than a hash table. Lower memory footprint but somewhat slower. Similar accuracy to Kraken2.
- **KrakenUniq** (Breitwieser et al., 2018): Extends Kraken with a unique k-mer counting step that can help distinguish true hits (many unique k-mers) from false positives (few unique k-mers mapping repeatedly to the same reference region). Worth considering as an additional filter.
- **MetaPhlAn** (Beghini et al., 2021): Marker-gene-based classifier. Very high specificity but poor sensitivity for viruses, which have fewer species-specific marker genes than bacteria. Not recommended for viral profiling.
- **DIAMOND/BLAST**: Alignment-based approaches that are far more sensitive for divergent viruses but orders of magnitude slower. Could be used as a secondary validation step for candidate hits.
- **Kaiju** (Menzel et al., 2016): Protein-level classifier using translated nucleotide sequences. More sensitive than nucleotide-based classifiers for divergent viruses but higher false positive rate.

**Known failure modes.**
- Shared k-mers between closely related viruses (e.g., within the Herpesviridae) can cause classification ambiguity, with reads assigned to the LCA (often genus or family level) rather than species.
- Extremely short reads (<50 bp after trimming) contain few k-mers and are prone to misclassification.
- Database contamination (e.g., host sequences inadvertently included in viral reference genomes) can cause systematic misclassification.
- Low-complexity sequences (e.g., polyA tails from RNA-seq) can match low-complexity regions in viral genomes, producing spurious hits. Kraken2's `--confidence` parameter partly mitigates this.

### 2.5 Abundance Re-estimation: Bracken

**Why this tool was chosen.** Bracken (Bayesian Reestimation of Abundance with KrakEN; Lu et al., 2017, *PeerJ Computer Science*) addresses a fundamental limitation of Kraken2's output: many reads are classified at genus or higher taxonomic levels (rather than species) because their k-mers are shared across multiple species within a genus. Bracken uses Bayesian redistribution to re-estimate species-level abundances based on the proportion of unique vs. shared k-mers in each reference genome.

**Strengths.**
- Produces species-level abundance estimates from Kraken2 reports, even when many reads are classified above species level.
- Uses pre-computed probability distributions (built with `bracken-build`) that account for the specific database and read length.
- Computationally trivial (seconds per sample).
- Produces both a modified Kraken2-format report and a species-level abundance table.

**Limitations.**
- **Read length dependency**: Bracken's probability distributions are computed for a specific read length. Using the wrong read length parameter produces inaccurate re-estimations. Our `bracken_read_length=150` is correct for 150 bp paired-end sequencing but would be inappropriate for shorter or longer reads.
- **Threshold behavior**: Bracken's `-t` (threshold) parameter excludes species with fewer than the specified number of reads *before* re-estimation. Our threshold of 10 means that species with <10 reads at the Kraken2 classification step will not receive any re-estimated reads. This is aggressive for rare viral species. A lower threshold (e.g., 1 or 5) would increase sensitivity for low-abundance viruses, at the cost of retaining more noise.
- **Redistribution artifacts**: In samples with very few classified reads (as in our virome application), the Bayesian redistribution can produce volatile estimates. If 50 reads are classified to genus Betaherpesvirus, Bracken must decide how to distribute them across HCMV, HHV-6A, HHV-6B, HHV-7, etc., based on database priors rather than sample-specific evidence.
- **Single taxonomic level**: Bracken operates at one level at a time (S, G, F, etc.). Our choice of level=S (species) is appropriate for virome profiling, as species-level resolution is needed for biological interpretation.

**Key parameters and rationale.**

| Parameter | Value | Rationale |
|-----------|-------|-----------|
| `-r` | 150 | Read length matches sequencing platform (150 bp PE) |
| `-l` | S | Species-level estimation |
| `-t` | 10 | Minimum reads for re-estimation; moderate threshold |

**Alternatives.** There are no widely-used alternatives to Bracken for Kraken2-based abundance re-estimation. One approach is to skip Bracken entirely and use raw Kraken2 species-level counts, accepting that many reads will be classified above species level. For virome profiling where species identification matters, Bracken is essentially required.

**Known failure modes.**
- If the Bracken database files (kmer_distrib files) were built with a different Kraken2 database version than the one used for classification, the re-estimation will be incorrect.
- In highly unbalanced communities (one dominant species), Bracken tends to further concentrate reads on the dominant species, potentially inflating already-abundant taxa.

### 2.6 Filtering Strategy: KRAKEN2_FILTER

**Why this tool was chosen.** The three-stage filtering strategy is implemented in a custom Python script (`bin/filter_kraken2_report.py`) designed specifically for this pipeline. No off-the-shelf tool provides the combination of rank-based filtering, read count thresholds, and curated exclusion lists needed for virome analysis.

**Design rationale.** The filtering proceeds through three progressive stages, each emitted as a separate output file for auditability:

**Stage 1: `bracken_raw`** -- All viral taxa at species or subspecies level (ranks S, S1, S2, G, G1, F), with taxon_id != 0, sorted by read count. This is the unfiltered baseline.

**Stage 2: `minreads`** -- Taxa with >= `min_reads_per_taxon` (default: 5) direct reads. This threshold removes the long tail of taxa with 1--4 reads, which are overwhelmingly noise in low-biomass virome applications. The threshold of 5 is conservative; in a sample with 20M unmapped reads, 5 reads to a taxon represents 0.25 RPM. At this level, the probability of a spurious match (due to random k-mer overlap or sequencing error) is non-negligible.

**Stage 3: `final`** -- After removal of taxa in the artifact exclusion list (`assets/artifact_taxa.tsv`). See Section 4 for detailed assessment of each excluded taxon.

**Strengths.**
- Full transparency: all three stages are emitted as separate TSV files, and a filter_summary.tsv records taxa counts and read counts at each stage. This allows downstream review of what was removed and why.
- The artifact exclusion list is versioned with the pipeline and documented with reasons for each exclusion.
- The filtering is sample-independent: the same criteria apply uniformly to all samples, preventing cherry-picking.

**Limitations.**
- **Fixed per-sample threshold**: The `min_reads` threshold does not account for sequencing depth. A sample with 100M unmapped reads and a sample with 5M unmapped reads both use the same absolute threshold of 5 reads. A depth-aware threshold (e.g., minimum RPM) would be more principled.
- **No statistical test**: The current filtering uses hard cutoffs rather than statistical testing. There is no formal assessment of whether a given number of reads to a taxon is significantly more than expected by chance. A null model based on database composition and sample complexity could be used to compute p-values for each detection.
- **Exclusion list is static**: The artifact exclusion list is manually curated. Taxa must be individually assessed and added. An automated approach (e.g., excluding taxa detected in negative controls, or applying prevalence-based filters across cohorts) would be more scalable.
- **No cross-sample normalization**: Filtering is performed independently per sample. Taxa that are consistently detected at low levels across many samples might be real (biological) or might be systematic contaminants. The current pipeline cannot distinguish these cases.

**Alternatives.**
- **Decontam** (Davis et al., 2018): An R package that uses the frequency or prevalence of taxa in negative controls to statistically identify contaminants. Requires negative control samples, which our current experimental design does not include.
- **KrakenUniq's unique k-mer filter**: Adds a unique k-mer count per taxon, enabling filtering based on k-mer diversity rather than just read count.
- **Statistical null model**: Simulate expected read counts per taxon under a null model (no true virus present) based on database composition and read count, then retain only taxa exceeding a significance threshold.

### 2.7 Aggregation and Normalization: RPM

**Why this approach was chosen.** The aggregation script (`bin/aggregate_virome.py`) combines per-sample filtered TSVs into a unified abundance matrix with both raw read counts and RPM (reads per million) normalized values. RPM normalization accounts for differences in sequencing depth between samples, enabling cross-sample comparison.

**Normalization denominator.** The RPM denominator is the STAR "Number of input reads" -- i.e., the number of reads entering the STAR alignment step after trimming. This represents the total usable library size. The formula is:

```
RPM = (viral_reads_to_taxon / STAR_input_reads) * 1,000,000
```

**Why STAR input reads rather than total raw reads or unmapped reads?** Using raw read count would conflate trimming efficiency with biological signal. Using unmapped reads (the Kraken2 input) would create a compositional artifact: samples with more viral reads would have a larger denominator, artificially compressing RPM values. The STAR input read count represents a consistent, pre-classification library size metric that is not influenced by the viral content of the sample.

**Strengths.**
- Simple, interpretable, and widely used in viromics literature.
- Enables cross-sample comparison of relative viral abundance.
- Independent of classification results (denominator is set before viral classification).

**Limitations.**
- **RPM does not account for viral genome length**: A 200-kb herpesvirus genome will generate more RNA-seq reads per virion than a 4-kb RNA phage genome. For cross-taxon comparisons, RPKM (reads per kilobase per million) would be more appropriate. However, RPKM requires knowing the effective transcript length for each viral taxon, which is non-trivial for viruses with complex transcription patterns.
- **RPM is a relative measure**: It does not estimate absolute viral load. Two samples with identical RPM for a given virus may have very different absolute viral titers if their total library sizes differ.
- **Compositionality**: RPM values are compositionally constrained (they sum to a fixed total per sample). This means that an increase in one taxon's RPM necessarily decreases another's, even if the second taxon's absolute abundance is unchanged. For differential abundance testing, this is a well-known problem (see Section 6).
- **Sensitivity to denominator accuracy**: If STAR log parsing fails or returns an incorrect value, all RPM calculations for that sample are wrong. The aggregation script should validate that parsed read counts are within a plausible range.

**Alternatives.** See Section 6 for a detailed discussion of normalization approaches.

### 2.8 Reporting

**Why this tool was chosen.** The reporting module (`bin/virome_report.py`) generates a self-contained HTML report with embedded PNG plots and summary tables. This was implemented as a custom script because no existing virome reporting tool provides the specific combination of multi-stage filtering visualization, diversity metrics, and abundance heatmaps needed for this pipeline.

**Report contents.**
- **Diversity table**: Per-sample richness (number of detected taxa) and Shannon diversity index, computed from the final filtered matrix.
- **Filtering funnel chart**: Grouped bar chart showing taxa count at each filtering stage (bracken_raw, minreads, final) per sample.
- **Read attrition chart**: Grouped bar chart showing read counts retained at each filtering stage per sample.
- **Abundance heatmap**: Top-N taxa by total reads, displayed as log10(reads+1) with a YlOrRd color scale.
- **Prevalence bar chart**: Horizontal bar chart showing the number of samples in which each taxon is detected.

**Strengths.**
- Self-contained HTML with base64-encoded images -- can be viewed offline, emailed, or archived.
- Provides immediate visual summary of pipeline output without requiring separate analysis.
- Filtering funnel and attrition charts are unique to this pipeline and provide critical transparency into the filtering process.

**Limitations.**
- Static HTML report; no interactive elements (e.g., hover tooltips, zooming).
- Shannon diversity is computed on raw read counts, not on RPM-normalized or rarefied counts. For samples with very different total viral read counts, diversity estimates may not be directly comparable.
- The heatmap uses a fixed color scale across all samples, which may not be optimal when samples span a wide dynamic range.

**Alternatives.**
- **Plotly/Dash**: Could provide interactive HTML reports with tooltips and zoom.
- **R Markdown / Quarto**: Would allow more sophisticated statistical reporting and integration with R-based diversity packages (vegan, phyloseq).

---

## 3. Database and Reference Considerations

### 3.1 The Langmead Lab Viral Kraken2 Database

The pipeline uses a pre-built viral Kraken2 database from the Langmead Lab at Johns Hopkins University, hosted on AWS (`https://benlangmead.github.io/aws-indexes/k2`). This database is one of several pre-built options maintained by the Kraken2 developers.

**Contents.** The viral database contains all viral genomes from NCBI RefSeq, including:
- Human viruses (herpesviruses, retroviruses, papillomaviruses, polyomaviruses, etc.)
- Animal viruses (veterinary pathogens, zoonotic viruses)
- Plant viruses
- Bacteriophages (which constitute the majority of known viral diversity)
- Environmental/metagenomic viral sequences present in RefSeq

**Size.** Approximately 1.1 GB for the hash table and taxonomy files. This is compact compared to the full Kraken2 Standard database (~75 GB for the full version, ~16 GB for Standard-8).

**How it was built.** The Langmead Lab uses `kraken2-build --download-library viral` to download all viral sequences from NCBI RefSeq, followed by `kraken2-build --build` to construct the database. Bracken kmer_distrib files for various read lengths (50, 75, 100, 150, 200, 250, 300) are pre-computed.

**Limitations.**

1. **RefSeq coverage**: The database is limited to sequences deposited in NCBI RefSeq. Viruses identified through metagenomics but not yet assigned RefSeq accessions are excluded. This is particularly relevant for RNA viruses, where thousands of novel species have been identified through meta-transcriptomic studies (Shi et al., 2016, *Nature*; Wolf et al., 2020, *Nature Microbiology*) but are not yet in RefSeq.

2. **Version drift**: The pre-built databases are periodically updated as RefSeq grows. Different versions of the database may produce different classification results for the same input data. Our pipeline uses a fixed snapshot of the database, but the specific version (date of download) should be recorded and reported in any publication.

3. **No size capping**: The full viral database does not use the `--max-db-size` cap that the "-8" and "-16" abbreviated databases use. This means all k-mers are retained, preserving sensitivity. However, it also means that low-complexity or shared k-mers between taxa are all present, potentially increasing classification ambiguity.

4. **Taxonomic currency**: ICTV taxonomy is updated annually, and RefSeq periodically renames or reclassifies taxa. Some taxa in the database may have obsolete names (e.g., older names for recently reclassified species like Shamonda virus vs. Orthobunyavirus simbuense).

5. **No human endogenous retrovirus annotation**: HERV-K and other endogenous retroviruses are present in the database as viral reference genomes (from their original characterization as exogenous viruses). However, they are also present in the human genome. This dual representation creates ambiguity: HERV-K reads may map to GRCh38 during host removal (and be subtracted) OR match the viral Kraken2 database (and be classified as viral). The result depends on the specific HERV-K locus, its divergence from the reference genome consensus, and STAR's multimapping settings.

6. **Bacteriophage overrepresentation**: Phages constitute the majority of viral diversity in RefSeq. In tissue virome applications, bacteriophage detections are almost always artifacts (from reagent contamination or misclassification) rather than genuine biological signal. The inclusion of phages in the database increases false positive rates.

### 3.2 GRCh38 as Host Reference

The STAR index uses the GRCh38 primary assembly (hg38) for host read subtraction.

**Coverage of repetitive elements.** GRCh38 contains annotated repeat elements including LINEs, SINEs, LTR retrotransposons, and DNA transposons, as catalogued by RepeatMasker. HERV-K (HML-2) loci are annotated in the reference, with approximately 90+ proviral insertions identified, of which ~10--12 retain full-length open reading frames for at least one gene (Subramanian et al., 2011). However:

- **Polymorphic HERVs**: Some HERV-K insertions are polymorphic in the human population (present in some individuals but absent from the reference). Reads from these insertions will not map to GRCh38 and will enter viral classification.
- **Divergent HERV copies**: Older, more divergent HERV-K copies may not map to the reference consensus with sufficient identity for STAR alignment, especially with `--outFilterMultimapNmax 1`.
- **Solo LTRs**: Many HERV-K loci have recombined to produce solo LTRs (just the LTR without internal coding regions). Reads from solo LTRs will map to the genome, but reads from internal regions of polymorphic or divergent proviruses may not.

**Impact on HERV-K detection.** The net effect is that our HERV-K RPM values represent a lower bound on true HERV-K expression. An unknown fraction of HERV-K reads is subtracted during host removal because they map to known HERV-K loci in GRCh38. The remaining HERV-K reads that reach Kraken2 likely originate from: (a) polymorphic insertions absent from the reference, (b) highly divergent copies that fail STAR alignment, or (c) reads with ambiguous multimapping that are discarded by `--outFilterMultimapNmax 1`.

To fully characterize HERV-K expression, a dedicated analysis using tools designed for repetitive element quantification (TEtranscripts, SalmonTE, ERVmap) would be more appropriate than the subtraction-classification approach used here. Our virome pipeline provides an estimate of "HERV-K activity detectable in the viral classification residual," which is a consistent and reproducible metric even if it underestimates true expression.

**Missing elements.** GRCh38 does not include:
- ALT contigs for structurally variable regions (not included in our STAR index)
- Decoy sequences (e.g., Epstein-Barr virus genome, commonly included as a decoy in variant-calling pipelines)
- HLA haplotype sequences beyond the primary assembly representation

The absence of EBV as a decoy is notable: if EBV-infected B cells are present in DRG tissue (e.g., from circulating blood), EBV reads would not be subtracted and would be correctly classified as viral by Kraken2. This is actually desirable for virome profiling.

### 3.3 Alternative Databases

| Database | Contents | Size | Advantages | Limitations |
|----------|----------|------|------------|-------------|
| Kraken2 Standard | Archaea, bacteria, viral, plasmid, human, UniVec_Core | ~75 GB (full) | Comprehensive; can classify non-viral contaminants | Large; most content irrelevant for virome |
| Kraken2 Standard-8 | Same as Standard, capped | ~8 GB | Manageable size | Reduced sensitivity due to size capping |
| Kraken2 PlusPF | Standard + protozoa + fungi | ~110 GB | Broad eukaryotic coverage | Very large; overkill for virome |
| NCBI nt | Full NCBI nucleotide | ~500 GB+ | Maximum sensitivity | Impractical for routine use; contains unvalidated sequences |
| IMG/VR v4 | Metagenomic viral genomes | ~700K genomes | Captures uncultured viral diversity | Not in standard Kraken2 format; would need custom build; environmental bias |
| VirSorter2 / VIBRANT | Viral identification from contigs | N/A | Designed for de novo viral discovery | Requires assembled contigs, not raw reads |
| Virosaurus | Curated vertebrate viral sequences | Small | High quality, low noise | Limited to known vertebrate viruses; small |

**Recommendation.** For the primary analysis, the Langmead viral database is appropriate: it is comprehensive for known viral species, produces manageable output, and is well-maintained. For validation, running against the full Kraken2 Standard database would help identify non-viral contaminants (bacterial, fungal) in the unmapped reads, providing context on the overall microbial content of DRG tissue. For maximum sensitivity to novel viruses, a custom database incorporating IMG/VR metagenomic viral genomes could be built (see Section 8).

### 3.4 Database Version Drift and Reproducibility

The version of the Kraken2 viral database used for analysis must be precisely documented. Recommended practices:

1. **Record the database download date** (or the version tag from the Langmead Lab index page).
2. **Archive the database** (hash the database files with SHA256 and store the checksums alongside results).
3. **Use a fixed database version** across all samples within a study. Do not update the database mid-analysis.
4. **Report the database version** in the Methods section of any publication, including the approximate number of species/genomes it contains.
5. **When comparing results across studies**, note that database differences can account for discrepancies in detected taxa, especially for recently classified or reclassified organisms.

### 3.5 Impact of Kraken2 Confidence Threshold

The `--confidence` parameter determines the fraction of k-mers in a read that must be classified to a given taxon (or its descendants) for that classification to be reported. At confidence=0.0 (default), a single matching k-mer suffices. At confidence=1.0, every k-mer in the read must match.

| Confidence | Expected effect | Appropriate use case |
|-----------|----------------|---------------------|
| 0.0 | Maximum sensitivity, many false positives | Discovery mode; follow up with extensive filtering |
| 0.05 | Slightly reduced noise | General metagenomics with downstream filtering |
| **0.1** (current) | **Moderate sensitivity, some noise reduction** | **Low-biomass virome with downstream multi-stage filtering** |
| 0.2 | Reduced sensitivity for divergent viruses | High-confidence detection; risk of missing real hits |
| 0.5 | Substantially reduced sensitivity | Confirmation of suspected viruses only |
| 1.0 | Only perfectly classified reads retained | Essentially useless for divergent viruses |

**For DRG virome profiling**, confidence=0.1 is a reasonable starting point. The pipeline's three-stage downstream filtering (Bracken threshold, min-reads, artifact exclusion) provides additional layers of specificity. However, **a systematic evaluation of confidence thresholds (0.0, 0.1, 0.2, 0.3) on the existing data** should be performed before the first publication, to demonstrate that the major findings (HERV-K enrichment, DRG-specific taxa) are robust to this parameter choice.

---

## 4. Known Artifacts and Contamination Sources

### 4.1 Systematic Assessment of the Current Exclusion List

The artifact exclusion list (`assets/artifact_taxa.tsv`) contains 9 taxa. Each is assessed below for the mechanism by which it enters the data and the strength of evidence for its artifactual nature.

#### 4.1.1 Ruminant orthobunyaviruses (3 taxa)

| Taxon | Taxon ID | Classification |
|-------|----------|---------------|
| Shamonda virus | 159150 | Orthobunyavirus, Peribunyaviridae |
| Orthobunyavirus simbuense | 3052441 | Same family; Shamonda virus reclassified name |
| Orthobunyavirus schmallenbergense | 3052437 | Schmallenberg virus; reassortant of Sathuperi/Shamonda |

**Mechanism of entry.** These three taxa are closely related members of the Simbu serogroup of orthobunyaviruses, which exclusively infect ruminants (cattle, sheep, goats) via Culicoides midges. They have zero plausible route of infection into human tissue. Their consistent detection across multiple unrelated human RNA-seq datasets (including our muscle tissue cohort and DRG samples) strongly suggests systematic contamination.

Schmallenberg virus was identified in 2011 as a novel ruminant pathogen in Europe. Phylogenetic analysis showed 97% identity to Shamonda virus for the S segment, and the full genome appears to be a reassortant of Sathuperi (M segment) and Shamonda (S and L segments) (Goller et al., 2012, *Emerging Infectious Diseases*). The consistent co-detection of these closely related taxa across samples supports a single contamination source rather than independent contamination events.

**Likely source.** The most probable source is bovine-derived reagents in the library preparation or sequencing workflow. Fetal bovine serum (FBS) is widely used in cell culture, and bovine-derived enzymes (e.g., BSA used as a blocking agent) are common in molecular biology kits. Bunyavirus RNA is relatively stable and could persist in lyophilized reagent preparations. Alternatively, these sequences may be present in the Illumina PhiX spike-in stock or in the sequencing flow cell manufacturing process if bovine materials are used.

Cantalupo et al. (2020, *Nature Communications*) documented consistent contamination of GTEx RNA-seq data with tissue-inappropriate viral sequences, strongly associated with sequencing date rather than biological origin. While they did not specifically identify bunyaviruses, the pattern matches.

**Confidence level: HIGH.** The evidence for artifactual origin is strong: (1) ruminant-specific viruses with no human host range; (2) consistent presence across tissues and donors; (3) no epidemiological plausibility; (4) co-occurrence of closely related taxa suggests a single contaminant source.

#### 4.1.2 Insect viruses / baculoviruses (3 taxa)

| Taxon | Taxon ID | Classification |
|-------|----------|---------------|
| Choristoneura fumiferana granulovirus | 56947 | Betabaculovirus; infects spruce budworm larvae |
| Bracoviriform facetosae | 2083300 | Polydnavirus; integrated in parasitoid wasp genome |
| Betabaculovirus chofumiferanae | 3051997 | ICTV-reclassified name for taxon 56947 (same virus) |

**Mechanism of entry.** Baculoviruses are obligate pathogens of insects (primarily Lepidoptera). They have no capacity to infect vertebrate cells. Their detection in human RNA-seq is almost certainly due to reagent contamination.

The spruce budworm granulovirus is widely used as a biopesticide and in research. Baculovirus expression vector systems (BEVS) are used to produce recombinant proteins in insect cells, including proteins used in vaccine production and molecular biology reagent manufacturing. If reagents are manufactured in facilities that also handle baculovirus-based expression systems, cross-contamination of nucleic acids is plausible.

Note that taxon IDs 56947 and 3051997 refer to the same biological entity under different taxonomic names (pre- and post-ICTV reclassification). Both are included in the exclusion list to catch either name that may appear in database versions.

Bracoviriform facetosae is an endogenous polydnavirus integrated into the genome of parasitoid wasps (Braconidae). Its detection likely reflects contamination with insect-derived nucleic acids in reagents, or possibly misclassification of repetitive element reads that share k-mers with polydnavirus sequences.

**Confidence level: HIGH.** Insect-specific viruses with no vertebrate host range. Detected consistently across samples. Baculovirus reagent contamination is a recognized phenomenon.

#### 4.1.3 Bacteriophages (2 taxa)

| Taxon | Taxon ID | Classification |
|-------|----------|---------------|
| Ralstonia phage p12J | 247080 | Phage of Ralstonia solanacearum (plant pathogen) |
| Salmonella phage SJ46 | 1815968 | Phage of Salmonella enterica |

**Mechanism of entry.** Bacteriophages are obligate parasites of bacteria and cannot infect human cells. Their detection in human tissue RNA-seq almost certainly reflects:
1. **Reagent contamination**: Molecular biology enzymes (polymerases, ligases, nucleases) are produced in bacterial expression systems. Residual phage DNA/RNA from the bacterial host or from contaminating prophages can be co-purified with the enzyme and carried through to library preparation (Salter et al., 2014, *BMC Biology*; Lusk, 2014, *PLOS Pathogens*).
2. **Misclassification**: Reads from bacterial contaminants (common in tissue extraction) may be partially classified to phage taxa if the phage genome contains integrated host sequences or if k-mers are shared between phage and bacterial genomes.

**Confidence level: HIGH.** Bacteriophages have no biological relevance to mammalian tissue virome. Their consistent low-level detection across diverse tissue types is a hallmark of reagent contamination.

#### 4.1.4 Miscellaneous

| Taxon | Taxon ID | Classification |
|-------|----------|---------------|
| BeAn 58058 virus | 67082 | Unclassified; originally isolated from a Brazilian rodent |

**Mechanism of entry.** BeAn 58058 virus is a poorly characterized virus originally isolated from *Oryzomys* rodents in Brazil (BeAn = Belem-Ananindeua, the isolation locality). Its genome sequence in RefSeq is fragmentary. The most likely explanation for its detection is **misclassification**: reads with partial k-mer matches to the BeAn 58058 reference at low confidence may represent host-derived sequences, repetitive elements, or reads from other organisms that share short homologous regions.

**Confidence level: MODERATE.** The mechanism is less certain than for the insect/ruminant viruses, but there is no epidemiological route for this rodent virus to infect human DRG tissue.

### 4.2 Literature on Illumina Reagent Contamination in Viromics

Several landmark publications have documented the scope and mechanisms of contamination in sequencing-based viromics:

1. **Cantalupo et al. (2020), "Consistent RNA sequencing contamination in GTEx and other data sets," *Nature Communications*.** Demonstrated that 26 of 48 GTEx tissues showed cross-sample contamination, with contamination strongly correlated with sequencing date. This established that lane-level cross-contamination on Illumina platforms is systematic and can produce reproducible but artifactual signals.

2. **Viera Braga et al. (2020), "Virus expression detection reveals RNA-sequencing contamination in TCGA," *BMC Genomics*.** Identified HeLa-derived HPV18 reads in non-cervical TCGA samples, traced to cross-contamination during library preparation or sequencing. Demonstrated that low-level viral contamination can be persistent and widespread in large consortium datasets.

3. **Naccache et al. (2014), "Contamination Issue in Viral Metagenomics," *Frontiers in Microbiology* (2021 review).** Comprehensive review of contamination sources in viral metagenomics, including: (a) laboratory environment; (b) nucleic acid extraction kits; (c) library preparation reagents; (d) sequencing platform; (e) computational/database artifacts.

4. **Salter et al. (2014), "Reagent and laboratory contamination can critically impact sequence-based microbiome analyses," *BMC Biology*.** Demonstrated that DNA extraction kits contain a consistent "kitome" of bacterial DNA. While focused on bacteria, the same principles apply to viral nucleic acids in reagents.

5. **Strong et al. (2014), "Microbial Contamination in Next Generation Sequencing," *PLOS Pathogens*.** Identified common viral contaminants in NGS data, including PhiX, lambda phage, and murine leukemia virus-related sequences from reverse transcriptase preparations.

**Key principles from the contamination literature:**

- Contamination is **not random**: specific taxa appear consistently across samples processed with the same reagent lots, on the same sequencing instruments, or at the same facilities.
- Contamination signal is **inversely proportional to true signal**: low-biomass samples (like human tissue virome) are disproportionately affected because the contaminant-to-signal ratio is high.
- **Negative controls are essential**: the only reliable way to distinguish contaminants from true biological signal in low-biomass samples is to process extraction blanks and library preparation blanks through the full pipeline.
- **Cross-run contamination**: viral reads from high-titer samples (e.g., cell culture virus stocks) can contaminate low-titer samples sequenced on the same flow cell.

### 4.3 Making the Exclusion Strategy More Robust

The current exclusion list is manually curated, static, and contains only 9 taxa. Several improvements are recommended:

1. **Negative controls.** Process extraction blanks (water through the full RNA extraction protocol) and library preparation blanks (water through library prep) for each sequencing batch. Run these through the full pipeline. Any taxon detected in negative controls at or above the levels seen in tissue samples should be flagged as a contaminant.

2. **Prevalence-based filtering.** Taxa detected at similar abundance across all samples regardless of tissue type, donor, or experimental condition are likely contaminants. Implement a prevalence-adjusted threshold: taxa present in >80% of samples at <2x variation in RPM should be flagged for manual review.

3. **Decontam integration.** The R package `decontam` (Davis et al., 2018, *Microbiome*) uses the relationship between taxon abundance and DNA concentration (frequency method) or prevalence in true samples vs. negative controls (prevalence method) to statistically identify contaminants. Integrating decontam would provide a principled statistical framework for contamination assessment.

4. **Cross-study comparison.** Compare detected taxa against published lists of common contaminants (e.g., the "contaminome" catalogue from Goig et al., 2022, *Scientific Reports*). Taxa appearing in published contaminant lists should be flagged.

5. **Biological plausibility filter.** Implement an automated host-range check: for each detected viral species, query whether the known host range includes humans or closely related primates. Taxa with exclusively non-mammalian hosts (insects, plants, bacteria) should be automatically flagged.

### 4.4 Assessment of Uncertain Taxa

The following taxa are detected in our data but are NOT in the current exclusion list. Each requires careful assessment.

#### 4.4.1 Gihfavirus pelohabitans

**Taxonomy.** Domain: Riboviria > Phylum: Lenarviricota > Class: Leviviricetes > Order: Timlovirales > Family: Steitzviridae > Genus: Gihfavirus > Species: Gihfavirus pelohabitans.

**Biology.** This is a single-stranded positive-sense RNA virus belonging to the Leviviricetes, a class of bacteria-infecting ssRNA phages (levivirus-like). The Steitzviridae family was recently established through massive expansion of known RNA phage diversity via metagenomic and metatranscriptomic studies (Callanan et al., 2020, *Research in Microbiology*; Koonin et al., 2022). Gihfavirus pelohabitans was identified from environmental metagenomes (the name derives from characteristics of its metagenomic origin). It is an RNA bacteriophage with a compact genome (~3--5 kb) that infects prokaryotes.

**Detection pattern.** DRG-specific: absent in all 5 muscle samples. Present in both DRG samples from donor1: T12=417 reads (13.6 RPM), L5=1,664 reads (10.1 RPM).

**Assessment.**

*Arguments for artifact:*
- As an RNA bacteriophage, it has no capacity to infect human cells. Any detection in human tissue should be viewed with skepticism.
- The Leviviricetes were massively expanded through metagenomics, and many species are known only from environmental sequences. Database contamination (viral reference genomes containing non-viral sequences) is a risk for recently catalogued metagenomic taxa.
- The relatively high read count (417--1,664 reads) is unusual for a contaminant but not unprecedented.

*Arguments for real (non-human) biological signal:*
- DRG tissue specificity is unexpected for a reagent contaminant. If this were a reagent artifact, we would expect it in both muscle and DRG samples processed with similar kits.
- The read counts are substantial and differ between spinal levels (L5 > T12), which would be unusual for batch-level contamination.
- DRG tissue contains resident bacteria (the DRG is not sterile), and these bacteria could harbor RNA phages. However, the bacterial content of DRG tissue has not been characterized.

*Arguments for misclassification:*
- **This is the most likely explanation.** The Gihfavirus pelohabitans reference genome in RefSeq may contain k-mers that match human transcripts -- particularly from repetitive elements or highly expressed non-coding RNAs. If the reference genome has regions of spurious homology to human sequences, reads that escape STAR host subtraction (due to multimapping or mismatches) could be misclassified to this taxon.
- The tissue-specificity could reflect tissue-specific gene expression: if the misclassified human transcripts are more abundant in DRG than muscle (e.g., neuron-specific non-coding RNAs), the artifact would be tissue-specific.

**Recommended action.** (1) BLAST the Gihfavirus pelohabitans reference genome against GRCh38 to check for spurious homology. (2) Extract the reads classified to this taxon from the Kraken2 output file and BLAST them individually against nt/nr. (3) If the reads map back to human sequences, this is a misclassification artifact and should be added to the exclusion list. (4) If the reads genuinely match the phage genome with high identity across its full length, consider whether DRG tissue bacteria could be the source.

**Provisional classification: LIKELY ARTIFACT (misclassification).** Priority for validation is HIGH given the substantial read counts.

#### 4.4.2 Kinglevirus lutadaptatum

**Taxonomy.** Based on NCBI Taxonomy (taxon ID 2845070), this is a recently classified virus. The genus Kinglevirus falls within the broader context of recently expanded viral taxonomy, likely within the realm of metagenomically-identified viruses.

**Detection pattern.** Primarily DRG-specific: L5=206 reads (1.2 RPM), T12=19 reads. Absent or below threshold in muscle samples.

**Assessment.** Very similar reasoning to Gihfavirus pelohabitans. This appears to be another metagenomically-described virus with limited characterization. The modest read counts (19--206) and DRG-enrichment pattern suggest potential misclassification of tissue-specific human transcripts.

**Recommended action.** Same BLAST-based validation as for Gihfavirus. If confirmed as misclassification, add to exclusion list.

**Provisional classification: LIKELY ARTIFACT (misclassification).** Priority for validation is MODERATE (lower read counts than Gihfavirus).

#### 4.4.3 Cytomegalovirus papiinebeta3

**Taxonomy.** Family: Orthoherpesviridae > Subfamily: Betaherpesvirinae > Genus: Cytomegalovirus. Species: Papiine betaherpesvirus 3 (baboon cytomegalovirus, BaCMV).

**Biology.** BaCMV is an endogenous betaherpesvirus of baboons (*Papio* spp.) that is closely related to but distinct from human CMV (HCMV). Phylogenetically, BaCMV is more closely related to rhesus CMV (RhCMV) than to HCMV. Primate CMVs co-speciated with their hosts over millions of years (Leendertz et al., 2009; Brito et al., 2020, *Microorganisms*). BaCMV shares significant sequence homology with HCMV -- particularly in conserved herpesvirus genes (DNA polymerase, glycoprotein B, major capsid protein) -- but diverges in species-specific genes.

**Detection pattern.** Enriched in DRG relative to muscle.

**Assessment.**

*The most likely explanation is cross-reactive classification.* Kraken2 classifies reads based on k-mer matches, and reads from human CMV (or even host sequences derived from ancient herpesvirus integrations) may share enough k-mers with the BaCMV reference to be classified to this taxon rather than to HCMV. This is especially likely if:
- The sample contains genuine HCMV reads (HCMV seroprevalence is ~50--80% in most adult populations), and some HCMV reads match BaCMV k-mers better than HCMV k-mers due to database composition effects.
- Conserved herpesvirus genes are the source of the classified reads, and the LCA algorithm places them at the BaCMV node rather than at the CMV genus level.

*Less likely but not impossible:* True baboon CMV infection through zoonotic exposure. This would be extraordinary and would require extraordinary evidence (e.g., detection of BaCMV-specific genes absent from HCMV).

**Recommended action.** (1) Extract reads classified to BaCMV and align them to both HCMV and BaCMV reference genomes. Determine whether they map better to one or the other. (2) Check whether HCMV itself is also detected in the same samples. (3) If reads map equally well to both, they likely represent conserved CMV sequences and should be reported as "CMV (species indeterminate)" rather than specifically as BaCMV.

**Provisional classification: LIKELY MISCLASSIFICATION of HCMV or conserved betaherpesvirus reads.** Not necessarily an artifact to exclude, but the species-level assignment should not be trusted.

#### 4.4.4 Orthohantavirus oxbowense

**Taxonomy.** Family: Hantaviridae > Genus: Orthohantavirus > Species: Orthohantavirus oxbowense (Oxbow virus).

**Biology.** Oxbow virus is a hantavirus isolated from the American shrew mole (*Neurotrichus gibbsii*) in Oregon, USA (Kang et al., 2009). It is a negative-sense single-stranded RNA virus with a tripartite genome (S, M, L segments). Phylogenetically, it clusters with soricomorph-borne (shrew/mole) hantaviruses rather than with the rodent-borne hantaviruses known to cause human disease (e.g., Sin Nombre virus, Hantaan virus). There is no documented human infection with Oxbow virus, and the shrew-mole-borne hantaviruses are generally considered to have limited or no zoonotic potential.

**Detection pattern.** Present at low levels in both tissue types: detected in both muscle and DRG samples at low read counts. Consistent presence across samples.

**Assessment.**

*Arguments for artifact:*
- No known human host range.
- Consistent low-level presence across tissues and donors is suggestive of reagent contamination.
- Hantavirus genome segments are negative-sense ssRNA, which should not be efficiently captured by standard polyA-selected or rRNA-depleted RNA-seq protocols unless active replication is occurring.

*Arguments against simple contamination:*
- Unlike the ruminant bunyaviruses (which are positive-sense or ambisense), negative-sense hantavirus RNA should be less likely to persist as a contaminant in reagents.
- The read counts are very low but consistent, which could indicate either a very low-level systematic contaminant or a borderline-detectable biological signal.

*Most likely explanation: misclassification.* Reads from an unknown source (possibly host-derived or from a common environmental microbe) share k-mers with the Oxbow virus reference genome. The relatively low diversity of soricomorph hantaviruses in the Kraken2 database may mean that unrelated reads with partial k-mer matches are preferentially assigned to this taxon.

**Recommended action.** (1) Extract reads classified to Oxbow virus and BLAST against nt/nr. (2) Check whether the reads map to multiple segments of the Oxbow genome or are concentrated in a single region (concentration in one region suggests spurious homology). (3) If validated as misclassification, add to exclusion list. (4) If reads genuinely map across the hantavirus genome, this would be a remarkable finding warranting targeted PCR validation.

**Provisional classification: PROBABLE ARTIFACT (misclassification or low-level contamination).** The consistent cross-tissue detection pattern and low read counts argue against biological relevance, but full validation is needed before exclusion.

### 4.5 Summary Table: Artifact Assessment

| Taxon | Status | Mechanism | Confidence | Action |
|-------|--------|-----------|------------|--------|
| Shamonda virus | Excluded | Reagent (bovine) | High | Retain in exclusion list |
| Orthobunyavirus simbuense | Excluded | Reagent (bovine) | High | Retain |
| Orthobunyavirus schmallenbergense | Excluded | Reagent (bovine) | High | Retain |
| Choristoneura fumiferana GV | Excluded | Reagent (insect baculovirus) | High | Retain |
| Betabaculovirus chofumiferanae | Excluded | Reagent (same as above, reclassified) | High | Retain |
| Bracoviriform facetosae | Excluded | Reagent (insect polydnavirus) | High | Retain |
| BeAn 58058 virus | Excluded | Misclassification (rodent virus) | Moderate | Retain; validate with BLAST |
| Ralstonia phage p12J | Excluded | Reagent (bacterial enzyme prep) | High | Retain |
| Salmonella phage SJ46 | Excluded | Reagent (bacterial enzyme prep) | High | Retain |
| Gihfavirus pelohabitans | **Under review** | Probable misclassification | Moderate | BLAST validation required |
| Kinglevirus lutadaptatum | **Under review** | Probable misclassification | Moderate | BLAST validation required |
| Cytomegalovirus papiinebeta3 | **Under review** | Cross-reactive CMV classification | Moderate | Alignment-based resolution |
| Orthohantavirus oxbowense | **Under review** | Probable misclassification | Moderate | BLAST validation required |

---

## 5. Results Interpretation

### 5.1 HERV-K Enrichment in DRG

**Observation.** HERV-K (Human endogenous retrovirus K, family HML-2) is detected at approximately 46--58 RPM in DRG tissue versus 27--35 RPM in muscle tissue, representing an approximately 1.5--2x enrichment.

**Biological interpretation.** This enrichment, if confirmed, has several potential explanations:

1. **Epigenetic derepression in post-mitotic neurons.** DRG neurons are terminally differentiated and post-mitotic. Over the lifespan of a neuron, progressive erosion of DNA methylation and heterochromatin compaction could gradually derepress HERV-K loci. This is consistent with observations that HERV-K expression increases with age in some tissues and that post-mitotic cells (including neurons) accumulate epigenetic drift over decades. In contrast, skeletal muscle fibers, while also long-lived, undergo more active epigenetic maintenance through satellite cell-mediated regeneration.

2. **Inflammatory microenvironment.** The DRG contains resident macrophages, mast cells, and SGCs that produce basal levels of inflammatory cytokines. TNF-alpha and NF-kappaB signaling can activate HERV-K LTR-driven transcription (Manghera et al., 2016). The constitutive low-level inflammation in DRG (which is higher than in muscle due to the ganglionic immune cell population) could drive higher HERV-K expression.

3. **Neuron-specific transcription factor activity.** HERV-K LTRs contain binding sites for transcription factors that are active in neurons, including SOX family members and potentially neuron-specific regulatory elements. If certain HERV-K insertions are near neuron-expressed genes, their LTRs may be co-activated by neuronal enhancer activity.

4. **Technical artifact (differential host removal).** As discussed in Section 3.2, the HERV-K signal in the virome pipeline represents reads that escape host removal. If DRG tissue has a different spectrum of HERV-K locus activity than muscle (with more expression from divergent or polymorphic loci that do not map to GRCh38), the apparent enrichment could partly reflect differential host subtraction efficiency rather than truly higher expression.

**Caveats.**
- The enrichment is modest (~2x) and based on only 7 samples (5 muscle + 2 DRG from 1 donor). It is not statistically significant with this sample size.
- RPM normalization does not account for differences in RNA composition between tissues (e.g., DRG has higher rRNA content).
- HERV-K is a family of ~90+ loci. The pipeline detects aggregate HERV-K expression across all loci without locus-level resolution. A dedicated HERV analysis tool would be needed to determine which specific loci are active.

**Significance if confirmed.** HERV-K enrichment in DRG would be a novel finding with potential implications for: (1) understanding the epigenetic landscape of sensory neurons; (2) evaluating whether HERV-K Env protein contributes to DRG neuron dysfunction (analogous to its role in motor neuron disease); (3) exploring whether HERV-K expression correlates with neuropathic pain status.

### 5.2 Gihfavirus pelohabitans and Kinglevirus lutadaptatum

As discussed in Section 4.4.1 and 4.4.2, these are provisionally classified as probable misclassification artifacts. The DRG-specific detection pattern is intriguing but more parsimoniously explained by tissue-specific human transcripts being misclassified due to spurious k-mer homology with metagenomic viral reference sequences.

**Before reporting these as DRG-specific viruses, the following validation is essential:**
1. BLAST-based read-level assessment (described in Section 4.4.1).
2. If reads are confirmed as truly viral, genome coverage analysis (are reads distributed across the viral genome, or concentrated in a single region?).
3. Orthogonal detection by RT-PCR with primers designed against the viral genome (away from any regions of human homology).

**The risk of false discovery is high.** Reporting novel, biologically implausible viruses in human neural tissue without rigorous validation would damage credibility and distract from the pipeline's genuine findings.

### 5.3 Cross-Tissue Comparison: Muscle vs. DRG Virome Profile

**Key observations from the existing data:**

| Metric | Muscle (n=5) | DRG (n=2, 1 donor) |
|--------|-------------|---------------------|
| Bracken_raw taxa | 22--34 | 31--33 |
| Final taxa | 4--9 | 8--9 |
| Bracken_raw reads | 4K--14K | 43K--98K |
| HERV-K RPM | 27--35 | 46--58 |
| DRG-specific taxa | -- | Gihfavirus, Kinglevirus (pending validation) |
| Shared taxa | Orthohantavirus oxbowense, Molluscum contagiosum (low) | |

**Interpretation.** The most striking difference is the dramatically higher total viral read count in DRG (43K--98K bracken_raw reads) compared to muscle (4K--14K). This approximately 5--10x difference persists even after accounting for library size differences (DRG donor1_L5 has 174M read pairs, but even T12 with ~20M reads has more viral reads than muscle samples at similar depth).

Possible explanations:
1. **Genuine biological enrichment**: The DRG harbors more viral RNA than muscle, consistent with its known role as a viral latency reservoir.
2. **Tissue-specific host removal efficiency**: If DRG tissue has a more diverse transcriptome (due to its cellular heterogeneity), more reads may fail host mapping and enter viral classification.
3. **Artifact inflation**: If certain misclassification artifacts (e.g., Gihfavirus) are DRG-specific, they inflate the apparent viral content.

Disentangling these explanations requires: (a) validation of individual taxa (Section 4.4), (b) analysis of host removal efficiency (percent mapped reads) across tissue types, and (c) expansion of the cohort.

### 5.4 Spinal Level-Specific Virome Variation (L5 vs. T12)

**Observation.** Within donor1, L5 (lumbar DRG) and T12 (thoracic DRG) show overlapping but not identical virome profiles:
- L5 has more total viral reads (14,335 final) than T12 (5,108 final), though L5 also has substantially more total reads (174M vs. ~20M read pairs).
- Gihfavirus is present in both at different RPM levels.
- Some taxa are present in one but not the other (e.g., Molluscum contagiosum in L5 but not T12).

**Interpretation.** Spinal level-specific differences in the DRG virome are biologically plausible because:
- Different DRG levels innervate different body regions and may be exposed to different viral infections (e.g., lumbar DRG innervate the lower extremities and are the site of HSV-2 latency, while thoracic DRG innervate the trunk).
- DRG at different spinal levels have subtly different neuronal subtype compositions.
- Vascular supply and immune cell infiltration may differ between spinal levels.

**However, with n=1 donor and only 2 spinal levels, no meaningful conclusions can be drawn about spinal level-specific virome variation.** The observed differences are confounded by: (a) dramatically different sequencing depths (174M vs. 20M); (b) stochastic variation in viral detection at low abundance; (c) potential library preparation batch effects.

### 5.5 Limitations of Single-Donor Data

The current DRG dataset (n=1 donor, 2 spinal levels) is insufficient for any generalizable claims about the human DRG virome. Specific limitations:

1. **No biological replicates**: All DRG observations come from a single individual. Any "DRG-specific" finding could be donor-specific rather than tissue-specific.
2. **No disease-control comparison**: Without neuropathic pain patients, there is no way to assess whether virome differences associate with pain status.
3. **Confounded variables**: The DRG and muscle samples may have been processed at different times, with different reagent lots, or on different sequencing runs. Batch effects cannot be separated from tissue effects.
4. **Donor demographics unknown**: The donor's age, sex, medical history, herpesvirus serostatus, and immunological status all influence the expected virome.

### 5.6 What a Larger Cohort Could Reveal

The TJP group reportedly has access to 17+ DRG samples. With an expanded cohort, the following analyses become feasible:

1. **Prevalence estimation**: Which viruses are consistently detected across DRG donors vs. sporadically detected? Consistent detection of HERV-K, for example, would support it as a genuine feature of the DRG transcriptome rather than an artifact.

2. **Differential abundance between pain groups**: With metadata on neuropathic pain status, DESeq2 or ANCOM-BC can test whether specific viruses are enriched in neuropathic pain vs. control DRG. This is the primary scientific question motivating this pipeline.

3. **Spinal level comparisons**: With multiple donors and multiple spinal levels per donor, mixed-effects models can assess whether virome profiles vary along the neuraxis while accounting for inter-donor variability.

4. **Donor-level covariates**: Age, sex, medication use, and herpesvirus serostatus can be incorporated as covariates in statistical models.

5. **Contamination assessment**: With >17 samples, prevalence-based contamination filtering becomes more powerful. Taxa present at invariant low levels across all donors are likely contaminants; taxa with donor-specific variation are more likely biological.

6. **Power calculations**: For differential abundance testing with n=10 per group and typical virome effect sizes, power is limited. Realistically, only viruses with large prevalence or abundance differences (>3x RPM difference) would be detectable. See Section 6.5.

---

## 6. Normalization and Statistical Considerations

### 6.1 RPM Normalization: Appropriateness and Limitations

RPM (reads per million) is a form of Total Sum Scaling (TSS) where read counts are divided by the total library size (in millions). In this pipeline, the denominator is STAR input reads (post-trimming, pre-classification), which is a reasonable library size metric.

**When RPM is appropriate:**
- Comparing the same taxon across samples (e.g., "HERV-K is 46 RPM in DRG vs. 32 RPM in muscle").
- Descriptive reporting of viral abundance.
- Visualization (heatmaps, bar charts).

**When RPM is inappropriate:**
- **Differential abundance testing.** RPM values are compositional: they sum to a fixed total, creating spurious negative correlations between taxa. If one taxon increases in absolute abundance, all other taxa decrease in RPM even if their absolute abundance is unchanged. This violates the independence assumption of most statistical tests.
- **Cross-taxon comparison.** RPM does not account for viral genome length. A 100-kb herpesvirus genome produces more RNA-seq fragments per virion than a 4-kb RNA virus genome.
- **Cross-study comparison.** Different pipelines use different denominators (raw reads, trimmed reads, mapped reads, unmapped reads), making RPM values non-comparable across studies.

### 6.2 Alternative Normalization Approaches

| Method | Description | Advantages | Limitations | Appropriate for virome? |
|--------|-------------|------------|-------------|------------------------|
| **RPM/TPM** | Reads (or transcripts) per million | Simple, intuitive | Compositional; no genome length correction | Descriptive only |
| **RPKM/FPKM** | RPM normalized by gene/genome length (kilobases) | Accounts for genome length | Requires effective transcript length; compositional | Better for cross-taxon comparison |
| **DESeq2 size factors** | Median-of-ratios normalization | Accounts for compositional effects; designed for count data | Assumes most taxa are not differentially abundant | Yes, for differential testing |
| **CSS (metagenomeSeq)** | Cumulative Sum Scaling | Reduces bias from preferentially sampled taxa | Complex; assumes taxon abundances are iid up to a quantile | Possibly |
| **ANCOM-BC** | Bias-corrected analysis of compositions | Incorporates sampling fraction; controls FDR well | Requires >20 samples per group for power | Yes, for differential testing with adequate n |
| **CLR (centered log-ratio)** | Log-ratio transformation | Removes compositionality | Requires non-zero counts (pseudocount needed); sensitive to many zeros | With appropriate zero-handling |
| **TMM (edgeR)** | Trimmed mean of M-values | Robust normalization for count data | Assumes most taxa unchanged between conditions | Possibly |

**Recommendation.** For the primary publication, report RPM for descriptive purposes and use DESeq2 or ANCOM-BC with appropriate normalization for any differential abundance claims. Given the expected small sample sizes (<20 per group), DESeq2 may be preferable to ANCOM-BC, which loses sensitivity below n=20 per group.

### 6.3 The Challenge of Very Low Read Counts

Many viral detections in DRG samples consist of 5--50 reads. At these levels:

1. **Poisson noise is dominant.** The coefficient of variation for a Poisson count of lambda=10 is 1/sqrt(10) = 31.6%. Technical noise alone could produce 2-fold apparent differences between samples.

2. **Detection is stochastic.** A virus present at a true abundance of 1 RPM in a sample with 20M reads has an expected count of 20 reads. Due to sampling variance, the observed count could easily be 5--35 reads. At 5 RPM in a sample with 20M reads (expected 100 reads), detection is much more reliable.

3. **The min_reads threshold creates a detection cliff.** With min_reads=5, a taxon with 4 reads in one sample is filtered out while the same taxon with 5 reads in another sample passes. This binary threshold creates a discontinuity that can distort prevalence estimates and diversity metrics.

**Mitigations:**
- Report confidence intervals or credible intervals alongside point estimates.
- For prevalence analysis, consider using the bracken_raw matrix (no threshold) rather than the final filtered matrix, with appropriate statistical modeling of the detection probability.
- Consider lowering the min_reads threshold to 3 and relying more heavily on cross-sample consistency and biological plausibility for filtering.

### 6.4 False Discovery Rate

**What proportion of detections at 5--10 reads are expected to be spurious?**

This depends on the complexity of the database and the complexity of the input. In a Kraken2 viral database with ~15,000 species, the probability of a random read (containing no true viral sequence) being classified to a specific taxon at confidence=0.1 is very low (<<0.01%). However, across 15,000 taxa and millions of input reads, the cumulative probability of at least some spurious classifications is near 1.

A rough estimate: In a sample with 1M unmapped reads and a false classification rate of 0.001% per read (conservative), we expect ~10 spuriously classified reads total, distributed across multiple taxa. Most taxa would receive 0 or 1 spurious reads. The probability of 5+ spurious reads to a single taxon is very low under these assumptions, but increases if:
- The false classification rate is higher (e.g., for reads from repetitive elements).
- Certain taxa in the database have regions of spurious homology to human sequences (creating "attractors" for misclassified reads).
- Low-complexity reads are present in the unmapped fraction.

**Bottom line:** At a threshold of 5 reads with confidence=0.1, most detections in a well-filtered pipeline are likely true positives. However, a non-trivial minority (estimated 10--30%) may be spurious, particularly for taxa with known database issues (see Section 4). **Orthogonal validation is essential for any taxon intended for publication as a novel DRG-associated virus.**

### 6.5 Sample Size Requirements

For differential abundance testing between two groups (e.g., neuropathic pain vs. control DRG), the required sample size depends on:
- Effect size (fold-change in abundance between groups)
- Prevalence of the virus (what fraction of samples it is detected in)
- Within-group variability (technical + biological)
- Desired statistical power and significance level

**Rough estimates for virome differential abundance (based on microbiome literature):**

| Scenario | Effect size | Prevalence | Required n per group (80% power, alpha=0.05) |
|----------|-------------|------------|----------------------------------------------|
| Large effect, common virus | >5x fold-change | >80% prevalence | 5--8 |
| Moderate effect, common virus | 2--3x fold-change | >80% prevalence | 15--25 |
| Small effect, common virus | 1.5x fold-change | >80% prevalence | 50+ |
| Any effect, rare virus | Any | <30% prevalence | 30--50+ |
| Presence/absence | -- | Fisher's test | 10--15 per group (for 50% vs. 0% prevalence) |

**For our DRG cohort (estimated 17+ samples):** If split into ~8--10 neuropathic pain and ~8--10 control, we have adequate power only for large effects (>3x fold-change) or presence/absence differences in moderately prevalent viruses. We should design the study with these power constraints in mind and be transparent about them in the publication.

---

## 7. Validation Strategy

### 7.1 Levels of Evidence for Viral Detection

Before reporting a virus as "present" in human DRG tissue, the following levels of evidence should be considered:

| Level | Evidence | Confidence |
|-------|----------|------------|
| 1 | K-mer classification (Kraken2) alone | Low -- requires further validation |
| 2 | K-mer classification + read-level BLAST confirmation | Moderate -- confirms reads are genuinely viral |
| 3 | Level 2 + genome coverage analysis (reads map across viral genome) | Good -- argues against spurious homology |
| 4 | Level 3 + orthogonal computational method (PathSeq) | Strong -- two independent classifiers agree |
| 5 | Level 4 + targeted PCR/RT-PCR from independent aliquot | Very strong -- wet-lab confirmation |
| 6 | Level 5 + in situ detection (FISH, RNAscope, immunohistochemistry) | Definitive -- localizes virus to specific cells |

**For publication, Level 3 evidence should be the minimum for any reported virus. Level 5 evidence should be pursued for the most important/novel findings (e.g., HERV-K enrichment, any truly novel DRG-associated virus).**

### 7.2 GATK PathSeq as Computational Validation

PathSeq (Walker et al., 2018, *Bioinformatics*) is a GATK-based pipeline for microbial detection in host-associated sequencing data. It uses a fundamentally different approach from Kraken2:

- **Host subtraction**: Two-pass BWA alignment + k-mer pre-filter (more aggressive than single-pass STAR).
- **Microbial classification**: BWA-MEM alignment against a comprehensive microbial reference database (not k-mer-based).
- **Output**: Per-read alignments with mapping quality, enabling assessment of alignment confidence, genome coverage, and depth.

**Value as orthogonal validation.** Because PathSeq uses alignment rather than k-mer matching, it provides independent evidence:
- Viruses detected by both Kraken2 and PathSeq are high-confidence hits (concordance).
- Viruses detected by Kraken2 but not PathSeq may be misclassification artifacts (the alignment does not support the k-mer-based call).
- Viruses detected by PathSeq but not Kraken2 may be divergent viruses missed by k-mer matching (PathSeq's alignment-based approach is more sensitive for divergent sequences).

**Implementation considerations.**
- PathSeq requires substantial computational resources (~30 GB RAM for the host reference, plus the microbial database).
- The pipeline already has a stub for PathSeq in the params (`run_pathseq`). A dedicated Nextflow module should be developed.
- PathSeq output (BAM files with microbial alignments) enables downstream genome coverage plots and per-read quality assessment.

### 7.3 Reference-Based Depth-of-Coverage Validation

For taxa passing Kraken2 and PathSeq filters, remapping the classified reads to the specific viral reference genome using minimap2 or BWA-MEM provides:

1. **Genome coverage**: What fraction of the viral genome is covered by reads? Genuine infections typically produce reads across multiple genomic regions, while spurious classifications often cluster in a single region of homology.

2. **Coverage uniformity**: Is coverage relatively uniform (expected for true infections with random fragmentation) or highly non-uniform (suggestive of PCR duplicates amplifying a single fragment or a localized region of cross-homology)?

3. **Read depth**: Maximum and average depth across the genome. Very high depth in a focal region with zero coverage elsewhere is suspicious.

4. **Variant calling**: For viruses with expected quasispecies diversity (e.g., HCMV, VZV), single-nucleotide variants can confirm active replication (quasispecies) vs. clonal contamination (all reads identical).

**This analysis can be automated as a post-classification module** (see Section 8, medium-term roadmap).

### 7.4 Wet-Lab Orthogonal Validation

For the highest-impact findings, wet-lab validation is essential:

**RT-PCR / qRT-PCR.** Design primers against viral sequences identified in the RNA-seq data. Use independent aliquots of DRG RNA (not the same extraction used for sequencing) to test for viral RNA by RT-PCR. Include negative controls (no-template, water extraction, muscle tissue).

**RNAscope / FISH.** For viruses confirmed by PCR, *in situ* hybridization on DRG tissue sections can localize viral RNA to specific cell types (neurons vs. SGCs vs. immune cells). This provides critical biological context that bulk RNA-seq cannot.

**Immunohistochemistry.** For viruses with available antibodies (e.g., anti-VZV, anti-HSV, anti-HCMV), protein-level detection complements RNA-level evidence.

**Viral metagenomics (VirCapSeq-VERT).** Targeted viral enrichment using the VirCapSeq-VERT probe panel (Briese et al., 2015, *mBio*) dramatically increases sensitivity for vertebrate viruses (~1000x enrichment). This could confirm low-abundance hits and detect latent DNA viruses not captured by standard RNA-seq.

### 7.5 Specific Validation Priorities

| Finding | Priority | Recommended validation |
|---------|----------|----------------------|
| HERV-K enrichment in DRG | **HIGH** | PathSeq + dedicated HERV tool (TEtranscripts) + qRT-PCR + expansion to full cohort |
| Gihfavirus pelohabitans (DRG-specific) | **HIGH** | Read-level BLAST (first step) -- if confirmed viral, RT-PCR + genome coverage |
| Kinglevirus lutadaptatum | **MODERATE** | Read-level BLAST |
| Cytomegalovirus papiinebeta3 | **MODERATE** | Alignment to HCMV vs. BaCMV reference; serostatus of donor |
| Orthohantavirus oxbowense | **LOW** | Read-level BLAST; likely add to exclusion list |
| Molluscum contagiosum (low reads) | **LOW** | RT-PCR if cohort expansion confirms prevalence |

---

## 8. Future Pipeline Features and Roadmap

### 8.1 Near-Term Enhancements

#### 8.1.1 Test configuration (`conf/test.config`)

A minimal test profile using synthetic or subsampled data is essential for:
- CI/CD pipeline validation after code changes.
- Verifying container integrity after rebuilds.
- Onboarding new team members.

The test profile should include: (a) a small synthetic FASTQ (10K reads) containing spiked viral sequences at known concentrations; (b) a minimal STAR index (one chromosome); (c) a minimal Kraken2 database (10--20 viral genomes).

#### 8.1.2 Kraken2 confidence tuning

Expose the confidence threshold as a prominent parameter and implement a "sweep" mode that runs classification at multiple confidence levels (e.g., 0.05, 0.1, 0.2, 0.3) in parallel. This allows empirical assessment of the sensitivity-specificity tradeoff for each dataset.

#### 8.1.3 Host removal QC metric

Emit the STAR mapping rate (% reads mapped to host genome) as a per-sample metric into MultiQC. Abnormally low mapping rates may indicate: (a) sample degradation; (b) contamination with non-human material; (c) technical problems with library preparation. Abnormally high mapping rates (>99.99%) may indicate that essentially no viral reads are present, reducing confidence in any downstream classifications.

#### 8.1.4 MultiQC custom content

Inject the filter_summary.tsv into MultiQC as custom content modules, displaying: (a) per-sample taxa counts at each filtering stage; (b) per-sample viral read counts; (c) filtering efficiency metrics. This consolidates all QC information into a single report.

### 8.2 Medium-Term Enhancements

#### 8.2.1 PathSeq validation module

Implement PathSeq as an optional Nextflow module that runs on the same unmapped reads used for Kraken2. Output a concordance table comparing PathSeq and Kraken2 detections. Requires: (a) building a PathSeq microbial reference; (b) a dedicated `pathseq.sif` container with GATK; (c) a comparison script.

#### 8.2.2 RPKM normalization

Implement reads per kilobase per million (RPKM) normalization as an additional column in the abundance matrix:

```
RPKM = (viral_reads_to_taxon / (STAR_input_reads / 1e6)) / (viral_genome_length_kb)
```

This requires a lookup table mapping each viral taxon_id to its genome length, which can be derived from the Kraken2 database or from NCBI RefSeq metadata.

#### 8.2.3 Reference augmentation (minimap2 remapping)

For each detected taxon, extract classified reads from the Kraken2 output file and remap them to the corresponding viral reference genome using minimap2. Produce per-taxon genome coverage plots. Flag taxa with <10% genome coverage as potential misclassifications.

#### 8.2.4 Cohort-level statistical module (DESeq2)

Implement a differential abundance testing module that accepts: (a) the final abundance matrix; (b) a metadata table with group assignments. Run DESeq2 with appropriate normalization and produce: (a) volcano plots; (b) results tables with adjusted p-values; (c) PCA plots of virome profiles. This module would enable the primary scientific analysis (neuropathic pain vs. control comparison).

### 8.3 Long-Term Enhancements

#### 8.3.1 Metadata integration

Accept a metadata TSV with columns: sample_id, tissue_type, spinal_level, donor_id, neuropathic_pain_status, age, sex, culture_status (fresh vs. cultured). Use metadata for: (a) stratified reporting; (b) covariate adjustment in statistical models; (c) batch effect assessment.

#### 8.3.2 De novo viral assembly

Host-depleted reads that are not classified by Kraken2 (i.e., reads that do not match any known virus in the database) may contain sequences from novel or highly divergent viruses. De novo assembly of these reads using SPAdes (metaSPAdes mode) or MEGAHIT could identify novel viral contigs that can then be characterized by: (a) protein-level homology search (DIAMOND against nr); (b) viral hallmark gene identification (VirSorter2, VIBRANT, geNomad); (c) phylogenetic placement.

This is particularly relevant given the rapid expansion of known viral diversity through metagenomics. The DRG may harbor viruses not yet represented in reference databases.

#### 8.3.3 Multi-database classification

Run Kraken2 against both the viral database and the full Standard database in parallel. The Standard database classification reveals: (a) bacterial content of unmapped reads (useful for assessing tissue sterility and contamination); (b) fungal or parasitic sequences; (c) viral classifications in the context of all microbial diversity (may improve specificity by revealing when "viral" reads match bacterial genomes better).

#### 8.3.4 Longitudinal tracking

For donors with DRG samples collected at multiple timepoints (e.g., pre- and post-treatment, or from longitudinal culture experiments), track changes in the virome over time. This requires appropriate statistical methods for repeated-measures data (e.g., generalized estimating equations, mixed-effects models).

### 8.4 The Case for Replacing Trimmomatic with fastp

fastp (Chen et al., 2018, *Bioinformatics*; v1.0, 2025, *iMeta*) is now the recommended replacement for Trimmomatic, based on:

| Feature | Trimmomatic | fastp |
|---------|-------------|-------|
| Speed | Baseline (Java) | 2--5x faster (C++) |
| Adapter detection | Requires adapter file | Auto-detect + manual |
| polyG trimming | Not supported | Built-in (critical for NovaSeq) |
| Deduplication | Not supported | Built-in (optional) |
| UMI handling | Not supported | Built-in |
| QC report | None (requires FastQC) | HTML + JSON report |
| Active maintenance | No (last update ~2020) | Yes (v1.0 released 2025) |
| Adapter removal quality | Excellent (sequence-matching) | Excellent (overlap + sequence-matching) |
| Output quality | Q30 bases: 93--97% | Q30 bases: 93--97% |

**Migration plan:**
1. Build a `fastp.sif` container.
2. Implement a `FASTP` module with equivalent parameters.
3. Run both Trimmomatic and fastp on a subset of samples and compare: (a) number of reads retained; (b) downstream Kraken2 classifications; (c) viral abundance estimates.
4. If results are concordant, switch to fastp for all future analyses.
5. Note: migrating mid-study would introduce a pipeline version change. All samples in a single publication should be processed with the same trimmer.

### 8.5 Single-Cell Virome Profiling

As a longer-term direction, single-cell RNA-seq (scRNA-seq) or single-nucleus RNA-seq (snRNA-seq) of DRG tissue could localize viral transcripts to specific cell types. This would address fundamental questions:

- Are HERV-K transcripts expressed in neurons, SGCs, or both?
- Which neuronal subtypes (nociceptors vs. mechanoreceptors) harbor detectable viral transcripts?
- Do SGCs show cell-type-specific viral expression patterns (e.g., interferon-response SGCs vs. other subtypes)?

**Technical challenges:**
- Viral reads are extremely sparse at the single-cell level. A virus at 50 RPM in bulk RNA-seq (50 reads per million total reads) would produce approximately 0.05 reads per cell in a typical 10x Chromium experiment (~5000 reads/cell). This is at or below the detection limit.
- Droplet-based scRNA-seq captures primarily polyadenylated transcripts. Many viral RNAs are not polyadenylated, requiring full-length transcript or total RNA-based single-cell methods (SMART-seq, sci-RNA-seq).
- Single-cell data from DRG is sparse due to the difficulty of dissociating adult human ganglia without damaging neurons. Single-nucleus approaches are more tractable but capture only nuclear RNA, missing cytoplasmic viral replication intermediates.

**Feasibility assessment.** Single-cell virome profiling of DRG is technically challenging but potentially transformative. A phased approach -- starting with bulk RNA-seq (current pipeline), then targeted enrichment (VirCapSeq-VERT), then spatial transcriptomics (Visium, MERFISH), and finally single-cell -- would progressively refine our understanding of the DRG virome at increasing resolution.

---

## 9. Publication Strategy

### 9.1 What Constitutes a Publishable Finding

Several publication-worthy findings could emerge from this pipeline, in order of increasing impact:

1. **Methods paper**: "A Nextflow pipeline for systematic virome profiling of human tissue RNA-seq data, with application to the dorsal root ganglion." This would describe the pipeline design, validation, artifact assessment, and proof-of-concept results. Publishable even with the current small cohort, as the primary contribution is methodological.

2. **DRG virome atlas**: "The transcriptionally active virome of the human dorsal root ganglion." Requires the full cohort (17+ DRG samples) with at least 2 tissue types for comparison. Would report: (a) the overall virome composition; (b) cross-tissue comparison with muscle; (c) HERV-K quantification; (d) identification and validation of DRG-associated viruses.

3. **Disease association study**: "Virome alterations in dorsal root ganglia from patients with neuropathic pain." Requires case-control design with adequate sample sizes (minimum n=8--10 per group, ideally n=15--20). Would require DESeq2/ANCOM-BC analysis, multiple testing correction, and orthogonal validation of differential taxa.

4. **Mechanistic follow-up**: "HERV-K expression in human sensory neurons: implications for DRG biology and neuropathic pain." Would require HERV-K-specific analyses (TEtranscripts, locus-level resolution), wet-lab validation (qRT-PCR, RNAscope), and ideally functional experiments (effect of HERV-K Env on DRG neuron function in culture).

**Realistic near-term goal**: Publication types 1 and 2 can proceed in parallel. The methods paper could be submitted first (within 6--12 months), followed by the DRG virome atlas once the full cohort is processed (12--18 months). The disease association study (type 3) depends on cohort composition and metadata availability.

### 9.2 Appropriate Journals

| Journal | Impact factor (approx.) | Focus | Fit |
|---------|------------------------|-------|-----|
| **Virology / Microbiology** | | | |
| *mBio* | 6.4 | Broad microbiology | Methods + atlas paper; strong fit for virome profiling |
| *Journal of Virology* | 5.1 | Virology | Atlas paper if strong viral biology angle |
| *Virus Evolution* | 5.5 | Viral evolution & genomics | Methods + atlas with HERV-K focus |
| *Microbiome* | 15.5 | Microbiome/virome | Atlas paper if differential abundance results are strong |
| **Neuroscience / Pain** | | | |
| *Pain* | 7.4 | Pain research | Disease association paper |
| *Brain* | 14.5 | Neurology | Disease association with strong mechanistic data |
| *Journal of Neuroscience* | 5.3 | Neuroscience | Mechanistic follow-up |
| **Genomics / Bioinformatics** | | | |
| *Genome Biology* | 12.3 | Genomics methods | Methods paper if pipeline is broadly applicable |
| *Bioinformatics* | 5.8 | Computational biology | Pipeline-focused methods paper |
| *GigaScience* | 7.7 | Large-scale data analysis | Methods + atlas with data sharing |
| **General / High-impact** | | | |
| *Nature Communications* | 16.6 | Broad science | Strong atlas + disease association paper |
| *Cell Reports* | 8.8 | Cell biology | Mechanistic follow-up with functional data |

**Recommended primary target**: *mBio* or *Microbiome* for the combined methods + atlas paper. These journals have a strong track record of publishing tissue virome studies and metagenomics pipeline papers.

### 9.3 Minimal Cohort Size

**For a methods paper**: The current data (5 muscle + 2 DRG samples) is sufficient, provided the paper focuses on pipeline design, validation, and artifact assessment. The biological results are presented as illustrative rather than definitive.

**For a DRG virome atlas**: Minimum n=10 DRG samples from >= 5 donors, with >= 5 non-neural tissue samples for comparison. The 17+ DRG samples available should suffice.

**For a disease association study**: Minimum n=8 per group (neuropathic pain vs. control), with matched demographics. Ideally n=15--20 per group for adequate statistical power for moderate effect sizes.

### 9.4 Essential Controls

The following controls are critical for a rigorous publication:

1. **Negative extraction controls**: Water processed through the full RNA extraction protocol. At least 1 per extraction batch.
2. **Library preparation blanks**: Water through library prep. At least 1 per library prep batch.
3. **Technical replicates**: At least 2--3 samples processed in duplicate (independent extractions from the same tissue) to assess technical reproducibility.
4. **Cross-tissue controls**: Non-neural tissue (muscle, skin, or blood) from the same donors to distinguish DRG-specific signal from systemic viral presence.
5. **Positive controls**: If available, DRG tissue from a known VZV+ or HSV+ patient (confirmed by clinical PCR) to validate the pipeline's ability to detect known viruses.

**Ideally, negative controls should have been included in the original sequencing runs.** If they were not, retrospective controls (processing water through the current pipeline) can partially substitute but cannot account for run-specific contamination.

### 9.5 Data Sharing and Reproducibility Standards

For publication, the following must be provided:

1. **Raw data**: Deposit raw FASTQ files in SRA/ENA/DDBJ under a BioProject accession. Include appropriate consent and de-identification.
2. **Pipeline code**: Archive the exact pipeline version used (tag the Git repository) on GitHub with a DOI (Zenodo). Include all configuration files, container definitions, and analysis scripts.
3. **Container images**: Deposit Apptainer/Docker images on a container registry (DockerHub, Quay.io, or GitHub Container Registry) or provide Singularity definition files.
4. **Database version**: Record and report the exact Kraken2 database version (download date, SHA256 hash of database files).
5. **Intermediate files**: Provide the abundance matrices (all three stages), filter summaries, and MultiQC reports as supplementary data.
6. **Reproducibility**: The pipeline should be runnable by an independent group using only the deposited code, containers, and database, producing identical results.
7. **FAIR principles**: Follow FAIR data principles (Findable, Accessible, Interoperable, Reusable). Use standard file formats (TSV/CSV for matrices, FASTQ for reads, BAM for alignments).

### 9.6 Ethical Considerations

- Human DRG tissue is typically obtained from organ donors or surgical patients. Appropriate IRB approval and informed consent must be documented.
- RNA-seq data from human tissue can potentially reveal germline genetic variants. BAM files should not be made public; deposit only unmapped FASTQ (post-host-removal) or use controlled-access repositories (dbGaP).
- If viral findings have potential clinical implications (e.g., detection of an unexpected pathogen), consult with the IRB about whether reporting obligations apply.

---

## Appendix A: Glossary

| Term | Definition |
|------|-----------|
| DRG | Dorsal root ganglion |
| SGC | Satellite glial cell |
| HERV | Human endogenous retrovirus |
| RPM | Reads per million |
| RPKM | Reads per kilobase per million |
| LCA | Lowest common ancestor (taxonomic classification algorithm) |
| PHN | Postherpetic neuralgia |
| VZV | Varicella-zoster virus |
| HSV | Herpes simplex virus |
| HCMV | Human cytomegalovirus |
| BaCMV | Baboon cytomegalovirus |
| FDR | False discovery rate |
| TSS | Total sum scaling |
| CLR | Centered log-ratio |

## Appendix B: Key References

*Note: Not all references listed below have been individually verified against primary sources. References marked with [*] are cited from memory and should be confirmed against the original publications before inclusion in a manuscript.*

### DRG Biology and Pain
- Tavares-Ferreira D, Shiers S, et al. (2022). Spatial transcriptomics of dorsal root ganglia identifies molecular signatures of human nociceptors. *Science Translational Medicine*. [*]
- Nguyen MQ, et al. (2021). Single-nucleus transcriptomic analysis of human dorsal root ganglion neurons. *eLife*. [*]
- Ray P, Torck A, Quigley L, et al. (2018). Comparative transcriptome profiling of the human and mouse dorsal root ganglia. *Pain*. PMID: 29561359
- Bhatt DK, et al. (2024). Deep RNA sequencing of human dorsal root ganglion neurons reveals somatosensory mechanisms. *Nature Neuroscience*.
- Jung M, et al. (2023). Harmonized cross-species cell atlases of trigeminal and dorsal root ganglia. *Science Advances*.
- Ji A, et al. (2023). Single-nucleus transcriptomic atlas of glial cells in human dorsal root ganglia. *Anesthesiology and Perioperative Science*.
- Ahlgreen et al. (2026). Mapping Satellite Glial Cell Heterogeneity Reveals Distinct Spatial Organization. *Advanced Science*.

### Viruses in DRG / Neural Tissue
- Zerboni L, et al. (2005). Varicella-zoster virus infection of human dorsal root ganglia in vivo. *PNAS*. PMID: 15784738
- Nagel MA, Gilden D (2014). Neurological complications of varicella zoster virus reactivation. *Current Opinion in Neurology*. [*]
- Thellman NM, et al. (2017). An immortalized human dorsal root ganglion cell line provides a novel context to study herpes simplex virus 1 latency and reactivation. *Journal of Virology*. PMID: 28404842
- Li W, et al. (2015). Human endogenous retrovirus-K contributes to motor neuron disease. *Science Translational Medicine*. PMID: 26424568
- Readhead B, et al. (2018). Multiscale analysis of independent Alzheimer's cohorts finds disruption of molecular, genetic, and clinical networks by human herpesvirus. *Neuron*. [*]

### Viromics Methods and Contamination
- Wood DE, Lu J, Langmead B (2019). Improved metagenomic analysis with Kraken 2. *Genome Biology*.
- Lu J, et al. (2017). Bracken: estimating species abundance in metagenomics data. *PeerJ Computer Science*.
- Walker MA, et al. (2018). GATK PathSeq: a customizable computational tool for the discovery and identification of microbial sequences. *Bioinformatics*. PMID: 29982281
- Cantalupo PG, et al. (2020). Consistent RNA sequencing contamination in GTEx and other data sets. *Nature Communications*. PMID: 32321923
- Viera Braga FA, et al. (2020). Virus expression detection reveals RNA-sequencing contamination in TCGA. *BMC Genomics*. PMID: 31992194
- Salter SJ, et al. (2014). Reagent and laboratory contamination can critically impact sequence-based microbiome analyses. *BMC Biology*. [*]
- Davis NM, et al. (2018). Simple statistical identification and removal of contaminant sequences in marker-gene and metagenomics data. *Microbiome*. [*]
- Goig GA, et al. (2022). The human "contaminome." *Scientific Reports*.

### Normalization and Statistics
- Weiss S, et al. (2017). Normalization and microbial differential abundance strategies depend upon data characteristics. *Microbiome*.
- Lin H, Peddada SD (2020). Analysis of compositions of microbiomes with bias correction. *Nature Communications*. [*]
- Nearing JT, et al. (2022). Microbiome differential abundance methods produce different results across 38 datasets. *Nature Communications*. [*]

### Tools
- Dobin A, et al. (2013). STAR: ultrafast universal RNA-seq aligner. *Bioinformatics*. [*]
- Bolger AM, Lohse M, Usadel B (2014). Trimmomatic: a flexible trimmer for Illumina sequence data. *Bioinformatics*. [*]
- Chen S, et al. (2018). fastp: an ultra-fast all-in-one FASTQ preprocessor. *Bioinformatics*. PMID: 30423086
- Chen S, et al. (2025). fastp 1.0: An ultra-fast all-round tool for FASTQ data quality control and preprocessing. *iMeta*.

---

*This document is a living research memo. It will be updated as new data are generated, validation experiments are completed, and the pipeline evolves. Last updated: 2026-03-24.*
