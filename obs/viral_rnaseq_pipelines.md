# Viral Detection in Bulk RNA-seq: Pipelines & Tools

## Overview

This document summarizes major bioinformatics pipelines and tools used
for detecting viruses in bulk RNA-seq data. It is structured for use in
Obsidian with links and organized sections.

------------------------------------------------------------------------

## 1. End-to-End Pipelines

### VIRTUS

-   GitHub: https://github.com/yyoshiaki/VIRTUS
-   Detects and quantifies viral transcripts
-   Splicing-aware alignment
-   Supports bulk and single-cell RNA-seq

### viGEN

-   Paper: https://pmc.ncbi.nlm.nih.gov/articles/PMC5996193/
-   Designed for tumor RNA-seq
-   Outputs viral abundance and variants

### VirPy

-   Paper: https://pubmed.ncbi.nlm.nih.gov/35316210/
-   Clinical RNA-seq pipeline
-   Integrates viral detection and host variant calling

### Pathonoia

-   Paper:
    https://bmcbioinformatics.biomedcentral.com/articles/10.1186/s12859-023-05144-z
-   Probabilistic pathogen detection
-   Focus on reducing false positives

------------------------------------------------------------------------

## 2. Metagenomic / Virome Pipelines

### VirusSeeker

-   Paper: https://pubmed.ncbi.nlm.nih.gov/28110145/
-   BLAST-based detection
-   Supports novel virus discovery

### AliMarko

-   Paper: https://www.mdpi.com/1999-4915/17/3/355
-   Hybrid approach (alignment + assembly + HMM)

### TAR-VIR

-   Paper:
    https://bmcbioinformatics.biomedcentral.com/articles/10.1186/s12859-019-2878-2
-   Viral strain reconstruction

------------------------------------------------------------------------

## 3. Modular Pipeline Components

### Host Depletion

-   STAR
-   HISAT2

### Taxonomic Classification

-   Kraken2
-   Centrifuge
-   Kaiju

### Alignment

-   Bowtie2
-   BWA
-   minimap2

### Assembly

-   MEGAHIT
-   metaSPAdes
-   Trinity

### Viral Identification

-   VirSorter / VirSorter2
-   geNomad
-   CheckV

------------------------------------------------------------------------

## 4. Standard Pipeline Workflow

1.  Preprocessing
    -   QC, trimming, rRNA removal
    -   Host alignment → retain unmapped reads
2.  Dual Detection
    -   Classification (Kraken2, Centrifuge)
    -   Assembly + BLAST/DIAMOND
3.  Validation
    -   Re-alignment to viral genomes
    -   Coverage assessment
4.  Quantification
    -   TPM / CPM normalization
5.  Filtering
    -   Remove contaminants and artifacts
    -   Address index hopping

------------------------------------------------------------------------

## 5. Key Challenges

-   Low viral abundance
-   False positives (index hopping, contamination)
-   Reference bias
-   Latent vs active infection signal

------------------------------------------------------------------------

## 6. Conceptual Approaches

  Approach               Strength               Weakness
  ---------------------- ---------------------- --------------------------
  k-mer classification   Fast                   False positives
  alignment-based        Accurate               Misses divergent viruses
  assembly-based         Novel discovery        Requires depth
  transcript-aware       Biological relevance   Reference limited

------------------------------------------------------------------------

## 7. Future Directions

-   Hybrid pipelines
-   Transcript-aware quantification
-   Statistical filtering
-   ML-based viral classification
-   Large-scale virome mining

------------------------------------------------------------------------

## Notes

This page is designed for integration into an Obsidian knowledge base.
