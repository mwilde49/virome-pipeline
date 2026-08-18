# PathSeq Feasibility + Verified Test Datasets — 2026-08-14

Produced by a 27-agent research workflow (2 on PathSeq, 6 fanning out across the web
for candidate datasets, 19 independent per-accession re-verification agents that each
fetched the actual SRA/ENA/GEO page + cited publication rather than trusting the
search result). 0 of 19 candidates were rejected outright, but several had real
factual errors in author names, citation metadata, or assay-type framing that the
verify pass caught and corrected — those corrections are folded into this doc, not
just the original claims.

---

## Part 1 — GATK PathSeq (`params.run_pathseq`)

### Bottom line

**Build it, narrowly.** As a Tier-1-only post-hoc offshoot (`pathseq_verify.nf`,
structurally a sibling to `blast_verify.nf`), **not** a fourth arm feeding the
Tier1/2/3 consensus, and **sequenced after the minimap2 arm**, not before. Use it as
a third-opinion validator for publication-critical novel calls (PD19-class findings),
not as routine per-cohort infrastructure.

### Why

- **The existing `nextflow.config` stub is already scoped correctly.** Confirmed
  directly (lines 76-80): `run_pathseq`, `pathseq_microbe_bwa_image`,
  `pathseq_microbe_fasta`, `pathseq_taxonomy` — no host k-mer/host-BWA params. GATK's
  own source (`PSFilterArgumentCollection`) marks host-subtraction inputs optional and
  PathSeq is explicitly designed to accept already-host-depleted input. That means
  point it at STAR-unmapped FASTQs (same input `blast_verify.nf` already uses) — do
  **not** re-run PathSeq's own host removal against an ~26 GB host bundle you don't
  need.
- **Mechanics:** `PathSeqFilterSpark` (host subtract, skip it here) →
  `PathSeqBwaSpark` (BWA-MEM align vs. curated microbe reference) →
  `PathSeqScoreSpark` (taxonomy-tree-aware likelihood scoring; a read with N equal
  hits splits 1/N across taxa; paired reads must be supported by **both** mates).
  Output `scores.txt` is a Bracken-analogous abundance table.
- **A herpesvirus-specific gotcha with no Kraken2-side analogue:** hg38's standard
  decoy set includes `chrEBV`. If PathSeq's host-subtraction were ever run against a
  decoy-inclusive reference, real EBV/HHV-4 reads get silently discarded as "host"
  unless `--ignore-alignment-contigs` is set. Worth knowing even though this pipeline
  plans to skip PathSeq's host step entirely.
- **Compute is the real cost.** Broad's own WDL: filter step 32 GB/8cpu, **align step
  140 GB/8cpu**, score step 8 GB/2cpu. A 2024 Biostars report of PathSeq run on
  35bp bulk-RNA unmapped reads (this pipeline's exact data shape) needed 200 GB heap
  and was still very slow.
- **Reference footprint:** skip the ~26 GB host bundle. Microbe bundle (Path A, fast
  start) = 94.6 GB + 6.7 MB taxonomy — but it's RefSeq release 81 from **April 2017**
  (confirmed HSV-1 taxid 10298 is present; anything characterized since 2017 is not).
  Rebuilding fresh (Path B) is 150–300+ GB and a real GATK community-forum case
  reported ~14 days to index a 250 GB reference with `BwaMemIndexImageCreator`.
- **Maintenance:** ships in every current GATK4 release (4.6.2.0), but no substantive
  PathSeq-specific feature work since June 2020; the standalone companion repo
  (`gatk-workflows/gatk4-pathseq`) is formally archived. The Broad's own later team
  (Nomburg/Bullman 2020, *Blood Advances*) built a **replacement tool ("virID")**
  rather than extend PathSeq, citing "10-100x more unassigned reads than
  microbe-assigned" as the reason.
- **No viral-specific benchmark exists in the literature.** The one rigorous
  PathSeq-vs-Kraken2 head-to-head found (*Bioinformatics Advances* 2023,
  PMC9976984) is bacteria-only by the authors' own explicit statement — PathSeq beat
  Kraken2 on sensitivity (0.739 vs 0.543) but was dramatically slower. Cannot be cited
  as evidence for or against viral performance. **No published use of PathSeq on
  DRG/TG/ganglion or any neural tissue was found at all** — this would be genuinely
  unexplored territory for that specific application.
- **Effort estimate:** ~5.5–8.5 days (container, FASTQ→uBAM conversion module —
  new, PathSeq needs BAM not FASTQ —, score module, aggregation script, Juno
  reference pull, validation against PD19). +2–5 days if you go Path B instead of
  the stale Path A reference.

Full source-cited technical report and integration memo (GitHub source citations,
WDL resource tables, live GCS bucket file sizes, GitHub issue links for real-world
failure modes) are in the workflow journal if deeper detail is ever needed —
ask and I'll pull it back out.

---

## Part 2 — Verified virus-positive bulk RNA-seq test datasets

All entries below **independently re-verified**: accession fetched live (not taken
from search snippets), library strategy/layout/access-level confirmed from
SRA/ENA/GEO metadata directly, and virus positivity checked against the cited
publication's own text. Corrections found during verification are noted inline.

⚠ **Pipeline compatibility note:** the current samplesheet format
(`sample,fastq_r1,fastq_r2`) is paired-end only. Several strong candidates below are
**single-end** — flagged in the Layout column — and won't plug in without either
picking a paired-end alternative or adding single-end support.

### Herpesviruses (priority)

| Virus | Accession | Tissue/model | Layout | Notes |
|---|---|---|---|---|
| **HSV-1** | `PRJNA384203` (LaPaglia/Iadarola, *Cephalalgia* 2018) | Human TG, 16 donors | PE, 2×125bp | **Already staged in this repo** — `assets/config_iadorola_tg.yaml`, `Iadorola/download_iadorola.sh` etc. all exist locally. This is the pipeline's existing minimap2-roadmap validation cohort, not a new set. 80.3% of viral reads = HSV-1 (LAT locus only, i.e. latent), reads correlate with donor serology (rs=0.833, p<0.001). Confirm with yourself whether a fresh pull is actually wanted before re-downloading. |
| **HSV-1** | `PRJNA851702` | MRC5 fibroblasts, lytic (WT KOS, 10 PFU/cell) | PE, 150bp | Clean high-titer positive control. **Correction:** original candidate's guessed companion publication (JVI/Rice lab) is wrong — verify agent traced the real likely companion to Ziegelbauer & Conrad, *EMBO J* 2025 (circRNA biogenesis study), design-matched but not accession-confirmed. Use WT-KOS runs only, skip the ΔICP4/ΔICP27/ΔICP22/ΔUL30 mutant arms for a clean positive signal. |
| **HSV-1** | `GSE236646` / `PRJNA991956` (*J NeuroVirol* 2024) | iPSC-derived neural precursor cells | PE | 53 samples, 2 MOIs × 3 timepoints ± antivirals — good for a sensitivity/dose-response test. Reporter-confirmed + direct viral-transcript mapping in the source paper. |
| **VZV + HSV-1** | `PRJEB23238` (Depledge/Verjans/Cohrs/Breuer, *Nat Commun* 2018) | **Human TG, 7 donors** (bait-capture panel also targets HSV-1) | PE | Independently surfaced twice, once each by the VZV/HSV-2 search and the Iadorola-lineage search — consistent facts both times. Real ganglion tissue, independent research group from the Iadarola cohort. ⚠ Virus-enriched (bait-capture), not standard bulk — inflates apparent viral read fraction, treat as a confirmed-positive reference rather than an RPM-comparable methodological analog. |
| **VZV** | `GSE141932` | SH-SY5Y neuroblastoma, 24h/48h post-infection | PE | Cleaner infected-vs-mock design, real timepoints/replicates, if primary-latent-ganglion isn't required. |
| **HSV-2** | `GSE229390` (Yale, *J Clin Invest* 2023) | Primary CD4+ T cells, MOI=10 | PE | Strongest (only solid) open HSV-2 bulk RNA-seq candidate found — most other HSV-2 hits were mislabeled (actually HSV-1), data-on-request-only, or PAR-CLIP not RNA-seq. Not genital/ganglionic tissue but genuine productive infection with confirmed "extensive expression of the HSV-2 proteome." |
| **HCMV/HHV-5** ⭐ | `GSE99823` (Goodrum lab, *PNAS* 2017), runs `SRR5660016–19` | MRC-5 fibroblasts, WT, 12/24/48/72 hpi | PE, 101bp | **Directly relevant to this pipeline's known CMV taxonomy bug** — ENA's own `scientific_name` field for these runs is literally "Human betaherpesvirus 5," i.e. genuine human CMV, not the *Cytomegalovirus papiinebeta3* proxy taxon Kraken2 currently substitutes. Ideal ground truth to check whether Kraken2/PathSeq correctly assign to taxid 10359. Strain TB40/E is plausible from lab lineage but not confirmed in fetched text (PNAS full text was CAPTCHA-gated). |
| **EBV/HHV-4** | `GSE125974` (*J Virol* 2019) | Primary B lymphocytes, transformation time course (d0–28) | **SE** | Quantified type-III latency gene induction (EBNA2/3A-C, LMP2B) in source paper. |
| **EBV/HHV-4** | `GSE96689` | GM12878 + MutuI, lytic reactivation ± acyclovir | **SE**, very deep (160–280M reads/sample) | Confirmed late-lytic-gene shift on acyclovir treatment. |

### Other neurotropic viruses

| Virus | Accession | Tissue/model | Layout | Notes |
|---|---|---|---|---|
| **JC polyomavirus** | `PRJEB64568` (*J Infect Dis* 2024) | **Human PML brain tissue** (autopsy/biopsy), 8 confirmed cases | **SE** | Real clinical brain tissue with IHC-confirmed JCPyV in the identical specimen. |
| **EV-A71 (AFM-associated)** | `GSE123550` (*Viruses* 2020) | Gerbil brainstem, in vivo | PE | No human AFM/EV-D68 bulk RNA-seq dataset with a real public accession could be found despite extensive search — animal model is the best available. |
| **Zika virus** | `GSE123816` (*Cell Stem Cell* 2021) | iPSC brain organoids | **SE** | MOCK vs ZIKV, ± IFN treatment, 36 samples. |
| **West Nile virus** | `GSE233216` (*J Neuroinflammation* 2023) | Mouse whole brain, in vivo, NY99 strain | PE | 36 samples, 3/7/10 dpi. Alternative: `GSE256333`/`PRJNA1079206`, same model. |

### Curated benchmark panels (mixed-titer, PCR-confirmed ground truth)

| Panel | Accession | What it is | Notes |
|---|---|---|---|
| **Miller/UCSF CSF mNGS** | `PRJNA516289` (*Genome Res* 2019) | The field's most widely-cited pathogen-mNGS ground-truth benchmark (SURPI+ validation). PCR-confirmed TP/FN for HSV-1, CMV (with defined 14 copies/mL LOD), EBV×2, HHV-6, plus documented sub-LOD VZV/HSV-2 false negatives | 230 samples, CSF not tissue, **dual DNA+RNA arms per sample** — select the RNA library specifically. |
| **Fan et al. China CDC CSF/serum** | `PRJNA963158` (*Microb Genom* 2023) | 226 samples, PCR+Sanger-confirmed HSV-1 (100% identity to the same NC_001806.2 reference this pipeline already uses for PD19) + several other viruses | ⚠ **Correction:** original candidate's notes oversold this as "purely RNA-seq" comparable to standard bulk RNA-seq. Verified: it's MDA-amplified total-nucleic-acid mNGS, methodologically closer to the Miller/UCSF panel than to this pipeline's own poly-A/rRNA-depleted bulk RNA-seq. |
| FDA-ARGOS | `PRJNA231221` | Reference-grade isolate genomes for ID-NGS validation | Checked and **ruled out** — confirmed no classical human herpesviruses present, and it's WGS of cultured isolates, not RNA-seq. Listed only so it isn't re-discovered and re-investigated later. |

### Lower-confidence / supplementary

- `CRA001750` — 4 new human TG donors (only 2/4 LAT-positive) + tree shrew/mouse HSV-1
  TG, Beijing GSA repository (not SRA/ENA/GEO — different access regime, double-check
  terms). Weaker evidence, listed for completeness only.

---

## Suggested starting picks

If testing incrementally rather than pulling everything:

1. **`GSE99823` (CMV, 4 runs, paired)** — smallest pull, directly interrogates the
   known CMV proxy-taxon bug.
2. **`PRJEB23238` (VZV+HSV-1, real TG tissue, paired)** — independent ganglion
   validation set, different group from the already-staged Iadarola cohort.
3. **`PRJNA851702` (HSV-1 WT-KOS fibroblasts, paired)** — clean high-titer sanity
   check for end-to-end detection.
4. **`GSE229390` (HSV-2, paired)** — only solid open HSV-2 option, broadens
   herpesvirus coverage.

All four are paired-end and plug directly into the existing samplesheet format with
no pipeline changes.
