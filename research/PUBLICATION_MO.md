# Publication Modus Operandi — DRG Virome

## Two-Paper Strategy

A methods paper followed by a primary research paper is a well-established and appropriate strategy here. The pipeline itself is the novel contribution right now; the biology requires more samples. Publishing the methods paper first:

- Establishes a citable, peer-reviewed reference for the pipeline before the larger study begins
- Forces resolution of known technical gaps (database, taxon relabeling, validation) before they become problems in the primary paper
- The primary paper then cites the methods paper for pipeline details, keeping its Methods section concise
- Both papers share the same first-author position and build a coherent research narrative

---

## Paper 1 — Methods / Pipeline Paper

### Framing
*A computational pipeline for systematic k-mer-based viral profiling of human neural tissue from bulk RNA-seq, with a curated artifact exclusion framework.*

The contribution is the pipeline design, the multi-stage filtering approach, the curated artifact taxonomy, the characterization of k-mer noise floor behavior in host-dominated libraries, and a feasibility demonstration on human DRG and muscle tissue.

### Target journals
- **Bioinformatics** (Oxford) — standard venue for pipeline papers; 4-page application note format fits well
- **GigaScience** — open data/methods emphasis; requires data deposition, fits the pipeline + data release angle
- **BMC Bioinformatics** — accessible, open access, broad methods scope
- **Briefings in Bioinformatics** — higher impact for methods, more narrative room

### What the current data can already support
- Pipeline architecture and design rationale (Figure 6 — done)
- Filtering funnel behavior across 15 samples (Figure 2 — done)
- Artifact taxonomy: categories, detection patterns, k-mer cross-mapping evidence (artifact_taxa.tsv — done)
- HERV-K as internal positive control showing the pipeline detects real viral-derived signal
- Characterization of k-mer noise floor (orthobunyaviruses, insect baculoviruses present in every sample)
- CMV taxonomy investigation as a worked example of database-driven misassignment (cmv_taxonomy_investigation.md — done)

### Blocking items — must resolve before submission

| Item | Work required | Est. effort |
|------|--------------|-------------|
| Viral-only database limitation | Rerun a subset of samples with PlusPF to demonstrate false positive reduction; frame as recommendation | 1–2 days (rerun + compare) |
| CMV taxon relabeling | Implement `assets/taxon_remap.tsv` + relabeling step; all figures must show "Human CMV (HHV-5)" not baboon | 1 day |
| Hantavirus characterization | BLAST classified reads → NCBI nt; determines whether it goes in as "batch contamination" or "cross-mapping artifact" | 1–2 days |
| Code release | Pipeline must be publicly available (GitHub) with a DOI (Zenodo) at time of submission | 1 day |
| Data deposition | Raw FASTQs to SRA or GEO; processed matrices to Zenodo or Figshare | 1–3 days (SRA submission) |
| AIG1390 resolution | Either confirm as duplicate and remove from paper entirely, or obtain correct data | Depends on source |

### Nice-to-have (strengthens paper, not blocking)
- `conf/test.config` with synthetic data for reproducibility demonstration
- Comparison table: viral-only vs. PlusPF false positive rates across the 15 samples
- Runtime and resource benchmarks on Juno (SLURM job stats)

### Figures (current status)
| Figure | Status | Notes |
|--------|--------|-------|
| Fig 1 — Library sizes | Done | May become supplementary |
| Fig 2 — Filtering funnel | Done | Core figure for methods paper |
| Fig 3 — Virome heatmap | Done | Demonstrates feasibility |
| Fig 4 — HERV-K | Done | Internal positive control |
| Fig 5 — Hantavirus | Done | Requires BLAST validation first |
| Fig 6 — Pipeline diagram | Done | Core figure for methods paper |

---

## Paper 2 — Primary Research Paper

### Framing
*The human DRG virome in neuropathic pain: systematic profiling across donors, spinal levels, and tissue types reveals [finding TBD].*

The scientific question is whether specific viral species — particularly neurotropic herpesviruses — are detectably active or latent in DRG in the context of neuropathic pain or peripheral neuropathy.

### Target journals (higher bar)
- **Journal of Virology** (ASM)
- **PLOS Pathogens**
- **Brain** — if neuropathic pain framing is central
- **Annals of Neurology** — if clinical cohort is strong

### What the current data cannot support
- Any tissue-paired comparison (muscle and DRG are from different donors)
- Any neuropathy vs. control comparison (no clinical stratification)
- Statistical testing of inter-group differences (n too small, no paired design)
- Confirmation of any specific exogenous viral finding (no orthogonal validation)

### Minimum requirements for primary paper

| Requirement | Current status | Path forward |
|------------|---------------|--------------|
| Tissue-paired design | Not met — muscle and DRG from different donors | Obtain DRG + muscle from same donors, OR pivot to DRG-only study |
| Sample size (DRG) | 11 (6 from 1 donor) | Target ≥20 donors across ≥2 clinical groups |
| Clinical groups | None | Neuropathic pain vs. healthy; or acute vs. chronic |
| Orthogonal validation | None | minimap2 alignment for CMV; PCR for any confirmed hit |
| Database | Viral-only | Switch to PlusPF or add competitive human background |
| AIG1390 | Unresolved duplicate | Obtain correct data |
| Saad cohort hantavirus | Unvalidated batch signal | BLAST + batch metadata |

### Recommended study design
- **n ≥ 20 DRG donors**, balanced across ≥2 clinical groups
- **Paired muscle** from the same surgical specimen where feasible
- **Multiple spinal levels** per donor where tissue availability permits (intra-donor replication)
- **Targeted enrichment** (VirCapSeq or similar) alongside bulk RNA-seq to improve sensitivity for latent virus detection
- **Competitive Kraken2 database** (PlusPF) as standard; viral-only as supplementary comparison
- **Alignment-based confirmation** (minimap2) for any taxon with RPM > threshold before inclusion in results

---

## Shared prerequisites (both papers need these)

1. **AIG1390 resolved** — confirmed duplicate removed from all analyses, or correct data obtained
2. **`taxon_remap.tsv` implemented** — no baboon CMV labels in any figure or table
3. **Hantavirus BLAST** — result determines how it's handled in both papers
4. **Data deposited** — SRA accession required for peer review at most journals
5. **Pipeline on GitHub with version tag and Zenodo DOI**

---

## Current research output status

| File | Status | Target |
|------|--------|--------|
| `research/abstract_draft.md` | Draft (methods paper framing) | Revise after hantavirus BLAST |
| `research/figures/fig1–fig6` | Generated | Review layout for journal format |
| `research/cmv_taxonomy_investigation.md` | Complete | Supplementary or methods section |
| `research/muscle_drg_full_analysis.md` | Complete | Internal reference |
| `assets/artifact_taxa.tsv` | 22 entries, current | Add `taxon_remap.tsv` alongside |
| `assets/taxon_remap.tsv` | Not yet created | Blocking for both papers |

---

## Immediate next actions (priority order)

1. Obtain correct AIG1390 FASTQ files or confirm and formally document exclusion
2. BLAST hantavirus classified reads (pull from Juno nf_work, run against NCBI nt)
3. Implement `taxon_remap.tsv` + relabeling step in pipeline
4. Rerun 2–3 samples with PlusPF database; generate false positive comparison table
5. SRA submission for the 15 usable samples
6. GitHub release tag + Zenodo DOI for pipeline v1.0.0
