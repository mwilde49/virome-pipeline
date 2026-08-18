# STTR Intelligence Digest — Ataraxia Bio / Price Lab Phase I Application

**Source:** `Re_ Viral STTR.zip` (Specific_Aims.pages, Research_Strategy.pages), received 2026-07-08.
**Method:** Full text extracted from the Pages/IWA archives (no OCR — direct protobuf parse of `TSWP.StorageArchive` text runs), then reviewed in parallel by five independent expert lenses (Virology, Bioinformatics, Neuroscience/Electrophysiology, Grant Strategy, Red Team) and synthesized into this briefing. Produced 2026-07-15.
**Status of the underlying grant draft:** in progress, not submission-ready — see below.

---

## What this application is

A Phase I STTR co-developed with **Ataraxia Bio** (small-business partner, proprietary capture + duplex-sequencing + ddPCR platform) and this lab (research-institution side, Dr. Theodore Price PI). Central hypothesis: a **subset** of chronic neuropathic pain is driven by silent/subclinical latent viral reactivation (HSV-1, VZV, EBV, CMV, HHV-6A/B, HHV-7, enterovirus) and/or HERV-K derepression in DRG sensory neurons, converging on a cGAS-STING/type-I-IFN/IL-6 innate-immune node. Aim 1 (Ataraxia-led): agnostic DNA-level detection via hybridization capture + duplex sequencing + ddPCR + long-read topology. Aim 2 (UTD-led): spatial/single-nucleus localization of the reservoir and correlation of a host reactivation signature with an excitability phenotype. Functional causal validation (iPSC-derived sensory neuron + MEA) is explicitly deferred to an unfunded Phase II. Target destination: NIH HEAL Initiative's Pain Therapeutics Development Program (PTDP) or a Phase IIB.

Full extracted text of both source documents is preserved in this repo's session scratch history; this digest summarizes rather than reproduces it verbatim.

---

## The direct tie to this pipeline — read this section first

The Research Strategy's Preliminary Data paragraph is a **literal, bracketed placeholder still in the submitted text**:

> *"[To be completed after re-analysis of existing Price-lab bulk RNA-seq with M. Wilde; placeholder framing below.]"*

It names two deliverables for this lab specifically:
1. An "agnostic" requery of the unmapped-read fraction for viral and lytic (reactivation) transcripts.
2. A **per-donor cGAS-STING / type-I-IFN / IL-6 / interferon-stimulated-gene (ISG) host reactivation score**, tested for co-variation with pain phenotype.

**What already exists that helps:**
- The mature dual-DB Kraken2 viral detection pipeline (v2.0.0) — but this is k-mer, curated-database, artifact-filtered methodology, i.e. structurally the exact method category the grant's own Innovation section critiques as non-agnostic. It cannot be presented as validation of Aim 1's DNA-based approach without reframing as motivating context, not supporting evidence.
- The **host gene expression quantification arm (v2.0.0)**, committed 2026-07-12 — four days *after* the grant materials arrived — which is architecturally the correct foundation for the reactivation score: dedup/filter → featureCounts + HTSeq → an RPM matrix on the same STAR-input-reads denominator as the viral matrices, i.e. already designed to be directly correlatable with viral RPM per sample.
- One genuinely strong, reusable, quantitative finding: the **HSV-1/HERV-K dose-response regression in the Iadorola TG cohort (R²=0.459, p=0.0039, n=16, 5 HSV-1 Tier-1-positive)** — mechanistically consistent with HSV-1 ICP0 transactivating HERV-K LTRs, and directly supports the grant's own retroelement-driver → RT-inhibitor modality logic.
- **VZV: zero reads across every cohort processed to date** (9 groups, ~118 samples) — a small, free, honest illustration of exactly the RNA-blindness-to-latency limitation the grant cites as its own rationale for capture+duplex sequencing.

**What is missing — net-new work, not adaptation:**
- No cGAS-STING/IFN/IL-6/ISG gene panel or scoring script exists anywhere in this repo — every hit found on search is prose in background docs, not code or a curated gene list.
- The host-quant arm **has never been run on real data**: no `host_gene_expression_matrix.tsv` exists anywhere in `results/`. The Juno reference files it needs (GTF, blacklist/exclude BED) have not been deployed — an operational blocker, independent of any coding, per this repo's own `CLAUDE.md` deployment notes.
- No cohort in hand has both confirmed neuropathic-pain phenotype **and** serostatus at adequate n. The closest match, DPN & RA Kulkarni (n=5 confirmed DPN vs. 10 shared healthy controls), has no serostatus data and is small.
- **Two caveats on the one strong number we do have:** per the `HERVK/synthesis/synthesis_v1.md` internal review, the HSV-1/HERV-K R² finding has **not yet survived a PMI/RIN/batch confound test**, and the gating locus-level Telescope RNA experiment identified in that same synthesis has not been run. Citing this externally today means exporting an internally-flagged, not-yet-defensible statistic — **verify this against the actual synthesis document before deciding how to use the number.** Separately, the LaPaglia/MAGIC comparison shows our Kraken2 output undercounts HSV-1 by **~90x** relative to alignment-based ground truth — any RPM figure pulled from current matrices is a demonstrable undercount unless caveated.

**Realistic scope (sequential, not parallelizable):**
1. Deploy Juno references, rsync `host_quant.sif`, run `run_host_quant=true` for the first time on the best available cohort. **Operational, blocking, start first.**
2. Curate the reactivation gene panel (subset `assets/gene_id_name_biotype.tsv` against a published Hallmark Interferon + cGAS-STING pathway list) and write a scoring script. ~1–2 days, gated on step 1.
3. Adapt `results/iadorola_tg/hsv1_hervk_analysis.py`'s regression pattern into a host-score-vs-viral-RPM correlation tool; run and report descriptively, not as a powered test given small n.
4. Draft the Preliminary Data section with front-loaded caveats, framed as feasibility/mechanistic rationale for Aim 1's DNA approach — **not** as validation of it.

The rate-limiting step is **not code** — it is whether a phenotype- and serostatus-labeled cohort exists at adequate n at all, which is a donor-metadata question outside this department's control and should be raised with the PI now.

---

## Cross-department synthesis

**Where all five independent reviews agree:**
- The hypothesis is properly scoped ("a subset of" pain) and the aims correctly sequenced — real scientific discipline, not a presupposed-target grant in disguise.
- The wet-lab technology choices are individually well-matched to the problems they solve.
- **The Preliminary Data placeholder is the single most urgent, universally-flagged defect** — all five reports independently named it as unacceptable to reach a reviewer as written.
- The "disciplined claim" framing around the failed Devanand 2025 valacyclovir trial is legitimate risk management *and* an unfalsifiable rhetorical pattern simultaneously (Virology and Red Team reach this from different directions).
- The HERV-K DNA-topology framework doesn't fit HERV-K's germline-integrated biology; this lab's own HERV-K thesis work already concluded RNA/Telescope quantification is the correct assay, not DNA topology.
- **Cohort data-provenance problems were flagged independently by four of five departments**: the AIG1390 duplicate-sample issue still listed as a legitimate second donor in `docs/cohort_registry.md`, and the Parkinson's 2026 "023–028 = control" label stated as fact in that same registry despite being explicitly unconfirmed in the original intake report. Near-unanimous convergence — **treat as a hard gate on using any of this lab's cohort data externally**, not just for this grant.

**Where they genuinely conflict — decisions only the PI can make:**

1. **Grant Strategy's optimism vs. Red Team's structural skepticism.** Grant Strategy: the gaps are "almost entirely administrative/structural... fixable without touching the hypothesis or the aims." Red Team: the go/no-go gates are **unfalsifiable by design** — the Innovation section states outright that a mixed *or null* result "strengthens the program," meaning no funded experimental outcome can actually show the hypothesis wrong. Adding numeric thresholds (Grant Strategy's fix) would address much of Red Team's complaint *if implemented rigorously* — but the two frame the same missing thresholds as a completeness gap versus a science-honesty problem.
2. **Does our own data help or hurt the Preliminary Data section?** Virology and Bioinformatics both treat the HSV-1/HERV-K R² finding as our strongest asset. Red Team warns that our real numbers — HERV-K globally significant across cohorts but driven by tissue-culture status, not disease, and *every single* disease-specific contrast run to date (HSV-1+/− TG, DPN/Healthy, PD/"control") non-significant — would, inserted honestly, undercut rather than support the pain-association narrative unless carefully reframed. Full disclosure is non-negotiable; how much protective reframing survives a sophisticated reviewer is a risk-tolerance call.
3. **Do we push back on Aim 1's HERV-K design, or just flag it?** Virology: add an RNA/epigenetic arm for HERV-K or explicitly justify DNA topology in text. Bioinformatics: this is a design question for the grant/Ataraxia side; our role is limited to flagging the internal concern.
4. **Neuroscience's finding is not an "administrative" fix.** The unresolved placeholder **"[in-house vs. named sensory-neuron-latency co-I to confirm]"** is the single biggest feasibility gap in the whole application — closing it means either recruiting a named external collaborator/subcontract or building genuinely new wet-lab capability (biosafety review, iPSC protocol validation, equipment access) this lab does not currently have. Materially longer lead time than the other "add a paragraph" fixes; Grant Strategy's "administrative, not scientific" framing does not fully account for this one item.

---

## Scientific risk assessment

**Strongest parts of the case:**
- Hypothesis scoping and aim sequencing hold up on their own terms.
- The ciHHV-6 copy-per-cell control and the RNAscope/DNAscope cytoplasmic-LAT-loss anticipation signal genuine domain fluency, not boilerplate.
- Bjornevik 2022 (EBV/MS) is accurately and conservatively characterized by both Virology and Red Team — though Red Team notes it supports only generic plausibility ("chronic viral infection can precede delayed neurological disease"), not the DRG-specific mechanism under test.
- The VZV zero-read finding is small but real and honestly usable as illustrative, not proof.

**Weakest parts (high-confidence — independently corroborated across reviews):**
- **The four "independent lines of evidence" are borrowed from four different diseases and tissues** (PHN = symptomatic, clinically overt reactivation, not silent latency; spaceflight shedding = no pain phenotype in astronauts; EBV/MS = B-lymphocyte/CNS autoimmunity, different cell type and mechanism; AD amyloid = no proposed DRG proteinopathy at all), bridged only by the word "virus."
- **Contamination-resistance is oversold.** Duplex sequencing answers base-calling/PCR error, not index-hopping, kitome reagent background, or reference-homology ambiguity — the actual failure modes that discredited the prior HHV-6/AD-brain and HSV-1/plaque literature. This lab's own `assets/artifact_taxa.tsv` independently documents all three failure modes in our own capture-adjacent pipeline (a hantavirus index-hop spike, an 866,614-read single-sample outlier from barcode bleed, HERV/LINE-vs-exogenous-retrovirus k-mer cross-mapping) — the last of which sits directly in the blast radius of the grant's proposed HERV-W/K tiling-capture arm.
- **Both go/no-go gates are effectively unfalsifiable as written.** Aim 1's gate is a technical QC check that passes regardless of the pain hypothesis's truth (VZV presence in aged seropositive ganglia is near-universal); Aim 2's gate has no pre-specified effect size, correction, or failure condition.
- **No power calculation exists anywhere**, and the best available empirical proxy — this lab's own organ-donor cohort history — has **never once reached significance** on a disease-status-vs-viral/HERV-K contrast at comparable or simpler questions (HSV-1+/− TG n=5v11, p=0.10–0.27; DPN/Healthy n=5v10, p=0.51–0.60; PD/"control" n=14v6, p=0.397, control label unconfirmed).
- **"Drivers" in the Aims title is not earned by Phase I.** Causal validation is entirely deferred to unfunded Phase II, and even a fully successful Phase II establishes causation only in an engineered iPSC dish, not prevalence in the clinically heterogeneous human chronic-pain population.
- **Reverse causation is structurally unaddressable**: cross-sectional postmortem tissue cannot distinguish reactivation-causes-hyperexcitability from hyperexcitability/neuroinflammation-causes-reactivation.
- **Uncontrolled confounds this lab's own cohort work has already flagged as material in this exact tissue**: PMI (our top-identified confound, absent from the stated covariate list entirely), donor age, and diabetes/metabolic status (directly relevant to the DPN-type donor category the design targets).
- Three citations need a formal accuracy check before submission: Itzhaki (contested field presented as settled), Devanand 2025 ("associated with faster decline" — verify significance and whether primary or subgroup finding), Eyting/Geldsetzer 2025 (verify authorship/journal/design characterization).

---

## Programmatic / strategic assessment

- **STTR mechanism fit is structurally plausible but unverified.** Aim 1 (Ataraxia's proprietary platform) and Aim 2 (UTD's spatial/MEA infrastructure) map onto a genuine technical division consistent with the ~40% SBC / ~30% RI work-allocation test — but no budget table exists to check the claim against, and Aim 2's custom probe design (informed by Aim 1 candidates) blurs the otherwise clean split. Dr. Price as academic-side science lead without needing to sit at the small business is correctly consistent with STTR rules (would disqualify an SBIR).
- **HEAL/PTDP alignment is aspirational, not anchored.** The actual funding vehicle for *this* Phase I application — HEAL-specific FOA vs. general STTR omnibus — is never named, which changes review criteria, page limits, and whether the PTDP-graduation language is real or filler.
- **Every element a study section uses to score feasibility is absent**: budget, cost breakout by partner, timeline, named personnel/percent effort beyond Dr. Price, an IP/data-rights allocation agreement between Ataraxia and UTD (a specific, commonly-checked STTR compliance item), statistical power/sample-size justification for either aim, human-subjects/IRB/consent/donor-accrual plan, NIH Genomic Data Sharing plan, and commercialization/company-capability content.

---

## Scope of work moving forward (this lab's actions only)

**Must-do before submission (blocking):**

1. **Deploy Juno reference files** (GTF, blacklist_bed, exclude_bed), rsync `host_quant.sif`, and **launch the first-ever production run of `run_host_quant=true`** on the DPN & RA Kulkarni cohort. Operational, not coding — start immediately.
2. **Provenance re-audit**: fix the AIG1390 duplicate entry in `docs/cohort_registry.md`; resolve or explicitly caveat the PD 023–028 "control" label before any cohort-derived number is used externally. Four of five departments hit this independently.
3. **Curate the cGAS-STING/type-I-IFN/IL-6/ISG gene panel and write the scoring script** against the new matrix once it exists (~1–2 days once step 1 completes).
4. **Adapt `hsv1_hervk_analysis.py`** into a general host-score-vs-viral-RPM correlation script; run against the best-available cohort; report as descriptive/exploratory, not a powered test.
5. **Draft the Preliminary Data section** with explicit, front-loaded caveats — RNA-blindness to latency (cite our own VZV zero-read finding), k-mer/curated-list methodology, ~90x HSV-1 undercount vs. alignment-based ground truth, small/unverified phenotype n, and our own non-significant disease-specific track record. Requires a PI decision on disclosure level.
6. **Add PMI, donor age, and diabetes/metabolic status** to the grant's stated covariate list — sequence after item 2 so the numbers are real.
7. **Resolve the sensory-neuron-latency co-I placeholder.** Longest lead-time item in the entire application; flag to the PI now regardless of progress elsewhere.
8. **Push for quantitative go/no-go thresholds** on both aims, informed by the hard fact that this lab's own cohorts (n=5–20 per arm) have never reached significance on comparable questions.
9. **Confirm ownership** of the purely administrative gaps (budget table, IP/data-rights paragraph, named FOA) — not this department's job, but someone needs to own it before submission.

**Can happen in parallel (non-blocking):**
- Explicit contamination-control language for the sequencing arm (dual indexing, extraction/NTC, run-separation controls), informed by our own `artifact_taxa.tsv` precedent.
- Expected-seroprevalence table and power statement for the seroconcordance design.
- Specify how the "excitability signature" is measured in postmortem tissue; flag Aim 2's selection-bias risk (prioritizing only Aim-1-positive donors for spatial work).
- Citation accuracy check (Itzhaki, Devanand 2025, Eyting/Geldsetzer 2025).
- Enterovirus inclusion rationale / SARS-CoV-2 post-viral neuropathy completeness gap.
- **minimap2 remediation arm — explicitly deprioritized** for this grant. Valuable (would close the 90x undercount) but not on the critical path for the named placeholder deliverable.
- HERV-K RNA/epigenetic companion-arm design — worth flagging internally now; can be resolved post-submission if the PI doesn't choose to block on it.

---

## Open questions for the PI

- **Submission deadline** — every sequencing decision above depends on it, and several items (co-I placeholder, cohort provenance fixes, the first-ever `run_host_quant` production run) have real, non-compressible lead time.
- **Who is the sensory-neuron-latency co-I?** Named external collaborator/subcontract with a letter of support, or does this lab commit to building in-house iPSC/MEA/HSV-1-quiescence capability as new scope?
- **How much of our own null/underpowered disease-specific track record gets disclosed** in the Preliminary Data section, and how is it framed so it reads as honest motivation rather than an own-goal against the grant's Innovation argument?
- **Do we commit the HSV-1/HERV-K R²=0.459 correlation as citable preliminary data now**, before the internally-flagged PMI/RIN/batch confound test and the gating Telescope locus-level analysis are run?
- **Does this lab push back on redesigning the HERV-K arm of Aim 1**, or stay strictly in a bioinformatics-support role and document the concern only internally?
- **Who owns the purely administrative/programmatic gaps** — budget table, IP/data-rights agreement, named FOA, statistical power calculation, IRB/consent/donor-accrual plan?
- **Does the "mixed result strengthens the program" / "ownable asset regardless of outcome" language stay, get softened, or get split** into a clearly separated commercialization/IP argument versus a scientific-hypothesis argument?
- **What is the actual target FOA** — HEAL-specific solicitation or general STTR omnibus?

---

## Appendix: department report headlines

For full narratives and complete observation/action lists, see the workflow run journal (`wf_53c00176-855`) referenced in this repo's Claude session history, 2026-07-15.

| Department | Headline assessment |
|---|---|
| **Virology & Molecular Biology** | Scientifically credible, appropriately hedged hypothesis with well-matched wet-lab technology; fundable as written but weakened by the placeholder preliminary-data section, a DNA-topology/HERV-K biology mismatch, uncontrolled confounds this lab's own cohort work has already shown matter (PMI, age, diabetes), and at least three citations needing a formal accuracy check. |
| **Bioinformatics & Computational Pipeline** | The pipeline provides real, reusable infrastructure and one genuinely strong correlational finding, but cannot honestly discharge the Preliminary Data placeholder as written — the grant's own Innovation section pre-critiques exactly the RNA/k-mer method this pipeline is built on, and the named host-reactivation-score deliverable requires a first-ever production run of an untested arm, a gene panel that doesn't exist, and phenotype/serostatus metadata this lab does not currently hold at adequate n. |
| **Neuroscience & Electrophysiology / iPSC Modeling** | Aim 2's spatial/localization plan is technically sound and rests on capability this lab plausibly already has; the Phase II functional-validation plan is the weakest link in the whole application — it borrows a rodent-neuron latency protocol wholesale, and the single most consequential technical role in the program is marked by an unresolved co-I placeholder. |
| **Grant Strategy, STTR Mechanism & Program Fit** | The science and narrative strategy are strong and STTR-appropriate, but this draft is not submission-ready: it is missing every element a study section uses to score feasibility (budget, timeline, named effort, IP terms, statistical power), and both go/no-go milestones are qualitative narrative rather than falsifiable decision rules. |
| **Red Team / Scientific Skeptic** | Polished and methodologically literate, but not falsifiable at either go/no-go gate; its "four independent lines of evidence" are borrowed from four different diseases in four different tissues; its "agnostic, contamination-resistant" claim overreaches what duplex sequencing alone can rule out; and no power calculation is shown for cohort sizes this exact collaboration has never seen reach significance on a comparable question. |
