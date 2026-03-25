# Paper 1 — Methods Paper Plan

**Format:** Bioinformatics Application Note (Oxford)
**Target:** ~2500 words, 3 figures, structured abstract ≤200 words
**Status:** Pre-submission — blocking items in progress

## Working title
Computational Profiling of the Human Dorsal Root Ganglion Virome from Bulk RNA-Seq Reveals a Sparse Exogenous Viral Landscape with Low-Level Cytomegalovirus-Associated Signal

## Core argument
k-mer-based virome profiling of human neural tissue from bulk RNA-seq is feasible but requires rigorous multi-stage artifact curation. The nature of the noise is systematic, characterizable, and largely tissue/reagent-specific — and we document it.

## Figures (final set for submission)

| # | File | Caption summary |
|---|------|----------------|
| 1 | fig6_pipeline_diagram.png | Pipeline architecture — 7-step flow with 3-stage filtering |
| 2 | fig2_filtering_funnel.png | Taxa retained per filtering stage across 15 samples |
| 3 | fig3_virome_heatmap.png | Final filtered abundance heatmap (15 samples) |

Fig 4 (HERV-K) moves to supplementary or is dropped — it supports the internal positive control narrative but is not central to the methods argument.

## Blocking items

| Item | Status | Notes |
|------|--------|-------|
| taxon_remap.tsv implemented | ✓ Done (v1.2.0) | CMV now shows as "Human CMV (HHV-5) [proxy]" |
| Hantavirus BLAST | Pending | Drop from paper if unresolved — not needed for methods story |
| Zenodo DOI | Pending | Required before submission |
| SRA accession | Pending | Required before submission; ~1–2 week processing |
| AIG1390 excluded from paper | ✓ Done | 15 usable samples documented |
| PlusPF comparison | Optional | Strengthens paper; not blocking |

## Submission checklist
- [ ] Zenodo DOI assigned to pipeline repo
- [ ] SRA BioProject + accession numbers obtained
- [ ] Manuscript draft complete (see manuscript/ subfolder when started)
- [ ] All figures at 300 dpi, correct font sizes for print
- [ ] Supplementary: artifact_taxa.tsv formatted as table
- [ ] Supplementary: cmv_taxonomy_investigation as supplementary note
- [ ] Author list and affiliations confirmed
- [ ] Cover letter drafted

## Key references to include
- Kraken2: Wood et al. 2019, Genome Biology
- Bracken: Lu et al. 2017, PeerJ Computer Science
- STAR: Dobin et al. 2013, Bioinformatics
- Trimmomatic: Bolger et al. 2014, Bioinformatics
- Langmead viral database: k2_viral_20240904
- HERV-K neural expression: relevant prior literature TBD
- Virome profiling methodology: Rampelli et al., VirSorter, VIBRANT — context papers TBD
