# Project Status and Open Items — 2026-08-27

This is a permanent, git-committed consolidation of project-management-level
state that used to live only in Claude's memory system: the STTR grant status
delta since the 2026-07-15 digest, tool-comparison/roadmap decisions, and
remaining open cohort-provenance items. HERV-K-specific statistical findings
live in the sibling doc `docs/hervk_findings_comprehensive_2026-08-27.md` —
don't duplicate that here, just cross-reference it. Start at
`RESTART_CLAUDE.md` (repo root) if you haven't already; that's the master
index this file hangs off of.

---

## 1. Why this document exists

On 2026-08-27, while assembling a full project restart doc, this session
discovered that a **second, older, richer Claude memory namespace existed for
this exact project under a differently-cased path** —
`-mnt-c-users-mwild-firebase2-virome` (lowercase `users`) — separate from the
active session's own `-mnt-c-Users-mwild-firebase2-virome` (capital `Users`).
WSL2's filesystem is case-insensitive, so both paths resolve to the identical
directory on disk, but Claude Code's memory system hashes the literal path
string, so `cd`ing into the project with a different case at some point in the
past created a second, disconnected memory store.

That older namespace held **18 memory files** covering an entire STTR grant
application, a standalone HERV-K thesis sub-project (`HERVK/`), repeatedly
flagged-but-never-applied cohort data-provenance issues, tool-comparison
decisions (MysteryMiner vs. VPF-Class), and a full minimap2 implementation
plan — none of which had ever surfaced to the sessions that had been running
under the capital-path namespace. This is a concrete, demonstrated instance of
the exact memory-loss risk that motivated writing all of this into
git-committed docs instead of continuing to rely on Claude's own persistent
memory. Git-tracked files in this repo are now the source of truth going
forward, not Claude memory of either namespace.

---

## 2. STTR grant application — status update

**Recap** (full detail: `docs/sttr_intelligence_digest.md`, 2026-07-15 — this
section is only the delta since then). Phase I STTR, co-developed with
**Ataraxia Bio** (small-business partner, proprietary capture +
duplex-sequencing + ddPCR platform) and this lab (Dr. Theodore Price, PI, UT
Dallas). Central hypothesis: a subset of chronic neuropathic pain is driven by
silent/subclinical latent viral reactivation (HSV-1, VZV, EBV, CMV, HHV-6A/B,
HHV-7, enterovirus) and/or HERV-K derepression in DRG sensory neurons,
converging on a cGAS-STING/type-I-IFN/IL-6 innate-immune node. This lab is
named directly in the Research Strategy's Preliminary Data section — a
literal bracketed placeholder — for two deliverables: (1) an agnostic
requery of the unmapped-read fraction for viral/lytic transcripts, and (2) a
per-donor cGAS-STING/IFN/IL-6/ISG host reactivation score tested against pain
phenotype.

**What has NOT changed since 2026-07-15 — still the top blocking item**: the
single most-repeated "start here" action across at least two prior
dossier-writing sessions — deploying the Juno host-quant reference files (GTF,
blacklist/exclude BED) and running the **first-ever real
`run_host_quant=true` production run** — still has not happened. Confirmed
directly this session: a repo-wide search for `*host_gene_expression*` under
`results/` returns nothing at all. The host-quant code itself was validated
end-to-end locally back on 2026-07-15 (WSL2, toy chr21 reference, real
subsampled Iadorola reads) with two real bugs found and fixed (a missing
`#!/usr/bin/env Rscript` shebang in `bin/featurecounts_host.R`; a missing
`assets/NO_FILE` sentinel), and both fixed containers (`host_quant.sif`,
`python.sif`) were already rebuilt locally and ready to `rsync` as-is as of
that date. This is purely an operational/Juno-access gap now, not a code gap
— it has been stalled for 6+ weeks past the point where it was code-ready.

**The cGAS-STING/IFN/IL-6/ISG tooling does exist in the repo**, confirmed
directly this session: `assets/cgas_sting_ifn_panel.tsv` (188 genes) and
`bin/score_host_reactivation.py` / `bin/score_vs_viral_correlation.py` are all
present. As of the last available record (2026-07-15) these had only been
tested against mock/synthetic data with clearly-labeled meaningless numbers —
this session found no evidence either way of any real numbers having been
produced since then; don't assume real output exists without checking for a
genuine `host_gene_expression_matrix.tsv` first (there isn't one, per above).

**Cohort provenance fixes the grant reviewers flagged as a hard gate — now
resolved.** Four of five STTR department reviews (per the July digest)
independently flagged `docs/cohort_registry.md`'s AIG1390-as-legitimate-donor
and Parkinson-2026 023–028-as-confirmed-controls entries as a hard gate on
using any of this lab's cohort data externally. Both caveats were applied
directly to the registry table today, 2026-08-27 (commit `80c0cd7`), after
being flagged repeatedly since March/April 2026 and again in the July digest
without ever being applied to the table rows themselves.

**Open PI-level decisions — still unresolved, not this document's or Claude's
call to make**:
- Submission deadline (every other lead-time item depends on it)
- Who is the named sensory-neuron-latency co-I — Phase II's single biggest
  feasibility gap; no MEA/iPSC-latency capability exists anywhere in this
  lab's current codebase
- How much of the null/underpowered disease-specific track record (HSV-1+/-
  TG p=0.10–0.27; DPN/Healthy p=0.51–0.60; PD/"control" p=0.397, control label
  itself only just caveated, not resolved) gets disclosed in the Preliminary
  Data section
- Whether to cite the HSV-1/HERV-K correlation before its PMI/RIN/batch
  confound test is run — **still not run**, see
  `docs/hervk_findings_comprehensive_2026-08-27.md`
- Whether this lab pushes back on Aim 1's HERV-K DNA-topology design (a
  mismatch with HERV-K's germline-integrated biology, per this lab's own
  HERV-K thesis conclusions) or stays in a bioinformatics-support role
- The GTEx/dbGaP access question — see §3 below

**This session's own SfN Neuroscience 2026 abstract work is a separate,
smaller deliverable** — `docs/sfn_abstract_2026_draft.md` and the
`docs/presentations/` lab-update deck are a conference poster abstract, not
part of the STTR grant, and shouldn't be conflated with it. Worth noting
directly: the STTR digest's caveat about the not-yet-confound-tested HERV-K
number applies equally to the SfN abstract's material, which cites the same
underlying HSV-1/HERV-K relationship (appropriately hedged, and without
quoting the specific R²/p numbers) — that hedging was the right call, and
should stay in place until a confound test actually runs.

---

## 3. GTEx/dbGaP access

Still **not confirmed active**. Idea: use GTEx bulk RNA-seq (9,416 samples,
Shnayder et al. 2018, mBio) as a large external CMV validation set for this
pipeline's Kraken2-based detection. Controlled-access via dbGaP accession
**phs000424**. One concrete lead: Dr. Price co-authored Ray et al. 2019
(*Frontiers in Molecular Neuroscience*), which used approved GTEx dbGaP access
(phs000424.v7.p2) under **UT Dallas IRB protocol 15-237** (Pradipta Ray,
corresponding author) — but that DAR's Research Use Statement was scoped to a
different study (tibial nerve sex-dimorphic expression, not CMV/virome
validation) and dbGaP DARs require annual renewal, so a 7-year-old approval
for a different stated purpose would not automatically cover this new use.

**Claude should never attempt to resolve or access this directly.** The only
real next step is a human one — the user contacting Pradipta Ray or Dr. Price
directly to ask whether that dbGaP project is still active/renewable or needs
a fresh DAR/amendment.

---

## 4. Tool-comparison decisions (so they're not re-litigated)

**VPF-Class (github.com/biocom-uib/vpf-tools) is permanently discarded.** Its
viral protein family database has ~29 retrovirus VPFs vs. ~20,700 dsDNA phage
VPFs; human herpesviruses (HHV-5/CMV, HSV-1/2, VZV) and HERV-K are essentially
absent from its coverage; eukaryotic host prediction coverage is ~5%.
Non-functional for this project's human DRG herpesvirome context — best
suited for bacteriophage/environmental metagenomics instead. Do not revisit or
suggest it for this project.

**MysteryMiner (github.com/Senorelegans/MysteryMiner, Marko Melnick, UT
Dallas — same institution, worth checking for a lab connection) is a live
integration target**, not adopted wholesale, with two concrete near-term
roadmap items pulled from it:
1. A **Bowtie2 second-pass host removal** module after STAR
   (`modules/bowtie2_host_removal.nf`, gated behind
   `params.run_bowtie2_host_removal = false`) — catches divergent human
   transcripts STAR's own filtering misses, directly reducing false viral
   classifications at the source. Requires a Bowtie2 index of GRCh38 (can
   reuse the existing STAR genome).
2. A **prevalence filter at the matrix-aggregation level**
   (`params.min_samples_per_taxon = 1` default, applied in the AGGREGATE
   step) — a simplified version of MysteryMiner's cross-sample reproducibility
   concept, a one-line filter in `bin/aggregate_bracken.py`.

A longer-term item pulled from the same comparison: an optional
**SPAdes-assembly + BLASTN "dark biome" branch**, modeled on the existing
dual-DB parallel-arm pattern (`if (params.run_assembly)`), for detecting
viruses absent from any k-mer database entirely — converts the pipeline from
"known virus profiler" to "known + novel virus profiler." This fits well as
Discussion-section future work under the current single-paper strategy (see
`RESTART_CLAUDE.md` for that pivot).

---

## 5. minimap2 competitive-alignment arm (planned, not started)

`CLAUDE.md`'s own roadmap section documents this at summary level; this is
the pointer to the fuller plan. **Motivation**: a direct comparison against
LaPaglia et al. 2017 (the MAGIC pipeline, same Iadorola TG samples this repo
also uses) shows this pipeline's Kraken2 k-mer classifier recovers **~90x
fewer HSV-1 reads relative to HERV-K** than an alignment-based approach on
identical input. Binary detection calls are equivalent between the two
methods, but quantification of viral burden within a positive sample is a
demonstrable, quantified undercount, not a hypothetical concern.

A full implementation plan exists (not yet built): NCBI vertebrate-infecting
viral RefSeq as the reference panel, `containers/minimap2.def`,
`modules/minimap2_viral_align.nf`, `bin/aggregate_minimap2.py`,
`params.run_minimap2` (default off) producing an RPKM-normalized
`minimap2_matrix.tsv` alongside the existing Kraken2 matrices. Effort
estimate ~4–6 days.

**Flag explicitly for any external-facing use of current data**: any RPM
figure pulled from the current Kraken2-only matrices — including anything
cited in the STTR grant or a manuscript — needs this ~90x HSV-1 undercount
caveat attached. It is a real, measured limitation of the current
methodology, not a theoretical one.

---

## 6. Telescope / HERV-K locus-level quantification

Pointer only — full detail lives in
`docs/hervk_findings_comprehensive_2026-08-27.md` §11 and
`HERVK/experimental_roadmap.md` Phase 1 Experiment 1. One line: an agreed
two-leg architecture (decided 2026-08-18, user-approved, not implemented) —
Leg 1 stays exactly as today's taxon-level Kraken2/PathSeq detection on every
sample; Leg 2 is an opt-in, post-hoc Telescope offshoot (sibling to
`blast_verify.nf`/`pathseq_verify.nf`) for locus-level HML-2 resolution on
samples where the aggregate signal itself warrants it. Blocked on a concrete
technical gap: `modules/star_host_removal.nf` runs
`--outFilterMultimapNmax 1` (uniquely-mapped reads only), which discards
exactly the multi-mapping reads Telescope needs — Leg 2 needs its own wide
STAR re-alignment, not a reuse of Leg 1's host-removal BAM.

---

## 7. Remaining cohort-provenance / data-hygiene items still open

Distinct from the AIG1390/Parkinson fixes already applied today (§2 above):

- **`assets/artifact_taxa.tsv` murine/animal-retrovirus-family additions** —
  11 specific taxon IDs identified and cross-confirmed contaminating the
  "final filtered" output in 3 separate cohorts now (Watchmaker,
  `dpn_ra_kulkarni`, `unknown_doloromics`). Recommended multiple times across
  sessions, not yet applied — needs explicit user approval since it changes
  the curated exclusion list every cohort's filtered matrix depends on. Full
  detail and the exact taxon ID list: `docs/hervk_findings_comprehensive_2026-08-27.md`.
- **Cross-species Simplexvirus atelinealpha1/paninealpha3 and Rhadinovirus
  saimiriinegamma2 candidates** — still not resolved as genuine divergent
  signal vs. database cross-mapping artifact. The reusable investigation
  protocol for exactly this kind of question (trace Kraken2 report → check DB
  library coverage → walk the `nodes.dmp` taxonomy tree → distinguish
  LCA/k-mer cross-mapping from reagent/vector contamination) has, as of this
  check, **only ever lived in Claude memory** (`methodology_taxonomy_investigation.md`,
  in the older lowercase-path namespace referenced in §1) — it was never
  written into a permanent `docs/` file, and a search of `docs/` for a
  taxonomy-investigation doc turned up nothing. This is a reusable protocol,
  not a one-off finding, and is a good candidate for a real `docs/` writeup
  next time this kind of investigation comes up — not done as part of this
  pass, flagging so it isn't lost a second time.
- Several near-zero/failed-library samples across cohorts (`Saad_1`/`Saad_2`
  historical; `104T8R`/`116TR5` Thoracic DRG zero-classified-reads cases) are
  already adequately documented in `CLAUDE.md`'s "Known issues / gotchas"
  section — cross-referenced here, not repeated.
- The Kulkarni RA cohort's 5 donor A/B specimen pairs (FL0, 1VY, CA7, 4LI,
  G1N) — still unconfirmed whether A/B denotes left/right DRG or independent
  replicate preparations.

---

## 8. Literature review status

`research/literature_review/tool_comparison.md` (386 lines) exists, covering:
1. A tool-comparison table (this pipeline vs. MysteryMiner, VirCapSeq-VERT, CZ
   ID, GATK PathSeq, Centrifuge) on the key axis of closed-world-assumption
   handling — only this pipeline's dual-DB approach and PathSeq's
   full-reference alignment explicitly address it.
2. Neural virome state of the art (Readhead et al. 2018 HHV-6/AD in *Neuron*,
   with the Allnutt et al. 2020 reanalysis; DeRisi lab clinical metagenomics,
   Wilson et al. 2019 *NEJM*) — no published DRG virome profiling exists
   elsewhere; this pipeline is first.
3. The false-positive-problem literature (Nasko et al. 2018 *mSystems*
   formalizing the closed-world assumption; Breitwieser et al. 2019 k-mer
   misassignment; database contamination; index hopping, Asplund et al. 2019;
   ERVs as confounders; ICTV reclassification artifact escape).
4. HERV-K in neural tissue (Li et al. 2015 ALS/TDP-43 in *Science*;
   NF-κB→HERV-K LTR activation; constitutive NF-κB in DRG neurons, Li et al.
   2006 *Brain Research*; MS literature, Kremer et al. 2019).
5. Clinical DRG virology (VZV latency/VLT transcript, Depledge et al. 2018;
   HSV-1/2 latency; CMV polyradiculopathy; HHV-6/ciHHV-6 false-positive
   concern; HIV-DSP; SARS-CoV-2/long-COVID small fiber neuropathy — Oaklander
   et al. 2022, and Shiers et al. 2020's ACE2-in-DRG paper, a TJP group paper;
   the DPN viral-trigger hypothesis).
6. A positioning statement: this is the first dual-DB competitive
   classification pipeline for neural tissue viromics, establishing a null DRG
   baseline — and a null exogenous-virus result is itself scientifically
   valid (it constrains exogenous viral prevalence below bulk RNA-seq's
   detection threshold), not a failed experiment.
