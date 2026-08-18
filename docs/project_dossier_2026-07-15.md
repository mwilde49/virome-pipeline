# Project Dossier — 2026-07-15

**Purpose:** read this top-to-bottom in under 5 minutes when you sit back down.
It synthesizes and points to the underlying docs — it does not repeat them in
full. Written at the end of a session that had **no Juno access and no GTEx/
dbGaP access** (by design — see §2) and worked entirely locally in WSL2.

---

## The single most important thing to do first

**Deploy the host-quant reference files + the two already-rebuilt `.sif`
containers to Juno, and launch the first-ever `run_host_quant=true`
production run** (DPN & RA Kulkarni cohort). This was already the #1 blocking
item per the STTR intelligence digest before this session started; this
session's work removes the main reason to hesitate — a full, real
Nextflow orchestration of the v2.0.0 host-quant code (STAR → dedup/filter →
featureCounts+HTSeq → aggregate) now completes successfully end-to-end on
real data, **after finding and fixing two real bugs** that would otherwise
have surfaced on Juno's first production run (a missing shebang in
`bin/featurecounts_host.R`, and a sentinel placeholder file,
`assets/NO_FILE`, that had never actually existed in the repo — see §5). Both
fixes are already applied and both affected containers (`host_quant.sif`,
`python.sif`) already rebuilt locally, ready to `rsync` as-is. The
gene-panel/scoring tooling downstream is built and tested and ready to
consume the real matrix the moment it exists. See
`docs/tooling_progress_plan.md` §2 for the exact commands.

Everything else below is context, not a blocker to that first action.

---

## 1. STTR application status

Full detail: `docs/sttr_intelligence_digest.md` (produced 2026-07-15, same
day as this session, from `Re_ Viral STTR.zip` — five independent expert
reviews synthesized). Headlines:

- Phase I STTR, Ataraxia Bio + Price Lab. Hypothesis: a *subset* of chronic
  neuropathic pain driven by latent viral reactivation (HSV-1, VZV, EBV, CMV,
  HHV-6A/B, HHV-7, enterovirus) and/or HERV-K derepression in DRG sensory
  neurons, converging on cGAS-STING/type-I-IFN/IL-6.
- **The Preliminary Data section is a literal bracketed placeholder** in the
  submitted draft, naming this lab for two deliverables: (1) an agnostic
  requery of unmapped reads for viral/lytic transcripts, (2) a per-donor
  cGAS-STING/IFN/IL-6/ISG host reactivation score correlated against viral
  RPM. **This session built the tooling for (2) — see §5.** It did not (and
  could not, without Juno) produce the real numbers.
- Five independent department reviews (Virology, Bioinformatics,
  Neuroscience, Grant Strategy, Red Team) converge on: the hypothesis is
  properly scoped and the aims are well-sequenced, but the draft is not
  submission-ready — no budget, no power calculation, both go/no-go gates
  are effectively unfalsifiable as written, and this lab's own cohort
  history has *never once* reached significance on a comparable
  disease-vs-viral/HERV-K contrast (HSV-1+/- TG n=5v11 p=0.10-0.27;
  DPN/Healthy n=5v10 p=0.51-0.60; PD/"control" n=14v6 p=0.397, control label
  itself unconfirmed — see §6).
- Open PI-level decisions (not this department's call): submission deadline,
  who is the sensory-neuron-latency co-I (biggest feasibility gap in the
  whole application), how much of the null/underpowered track record gets
  disclosed, whether to commit the HSV-1/HERV-K R²=0.459 number before it
  survives confound testing (§4).

---

## 2. GTEx/dbGaP CMV validation — access status (do not attempt yourself)

**Idea:** use GTEx bulk RNA-seq (9,416 samples total per Shnayder et al. 2018
mBio, ~101 raw CMV-read-positive, ~61 after excluding reads restricted to the
CMV Major Immediate-Early Promoter/MIEP region — a signature of
reagent/plasmid-vector CMV-promoter contamination rather than genuine latent
infection, per that paper's own filtering) as a large external CMV validation
set for this pipeline's Kraken2-based detection.

**Status: not confirmed active.** Requires a dbGaP Data Access Request for
accession **phs000424**. There is a 2019 precedent — Price lab co-author
Pradipta Ray had approved GTEx dbGaP access under **UT Dallas IRB protocol
15-237** for an unrelated study — but that DAR's Research Use Statement does
not cover this use case and may have lapsed. **Only the user can resolve this
by contacting Ray/Price directly.** This session did not and should not
attempt any GTEx/dbGaP access.

**Known blocker on continuing the investigation:** further email-based
digging into the Ray/Price precedent needs Gmail access re-authenticated
first — not done this session (out of scope; requires the user).

**What is NOT blocked by this:** essentially the entire host-quant tooling
plan in `docs/tooling_progress_plan.md` — it runs entirely on this lab's own
already-consented cohort data.

---

## 3. A citation-accuracy finding worth knowing about

This session's task brief described `research/virome_prospectus.md` as
already containing a fix distinguishing **two different contamination
mechanisms** — Nieuwenhuis et al. 2020 (cross-sample library-prep carryover
of highly-expressed host marker genes) vs. Shnayder et al. 2018 (reagent/
vector-derived CMV MIEP-promoter contamination, the same paper behind the
GTEx CMV numbers in §2) — "both now correctly cited."

**Checked this directly. That is only half true.** The file's uncommitted
diff (`git diff research/virome_prospectus.md`) does contain a real, good fix
made earlier today: a citation previously misattributed to "Cantalupo et al.
2020" (for PMID 32321923, the GTEx cross-sample-contamination paper) has been
corrected to its actual first author, **Nieuwenhuis et al.** — fixed in both
the artifact-assessment prose (§4.1.1) and the bibliography. That part is
done and correct.

**There is no Shnayder citation and no mention of "MIEP" anywhere in this
file or the rest of the repo.** The Nieuwenhuis-vs-Shnayder *distinction* —
two different contamination mechanisms, both relevant to this lab's own CMV
proxy-taxon finding (3050337, "Human CMV (HHV-5) [proxy]" in
`assets/taxon_remap.tsv`) — has not actually been written into
`virome_prospectus.md`. If you want that distinction documented (it's a
genuinely useful one: it separates "our ruminant-orthobunyavirus artifacts
are the same class of GTEx batch-carryover effect Nieuwenhuis documented"
from "our own CMV detection could in principle be a MIEP-vector artifact the
same way ~40% of GTEx's raw CMV-positive calls turned out to be, per
Shnayder" — a citable, specific hedge for the CMV proxy-taxon finding), that
still needs to be written. Small task, ~15 minutes, not done this session
(discovered too late in the session to fit, and outside this session's
assigned scope).

---

## 4. HERV-K findings and the open confound-test caveat

Full detail: `HERVK/synthesis/synthesis_v1.md` (critical synthesis, 2026-05-11)
and Claude memory `project_hervk_findings.md`. Headlines:

- HERV-K elevated across 9 cohort groups, Kruskal-Wallis p=1.9e-6 —
  cross-cohort consistency is real, but **driven by tissue-culture status,
  not disease status**, per Red Team's read of the same numbers.
- **The one number everyone wants to cite — HSV-1/HERV-K R²=0.459, p=0.0039,
  n=16 (Iadorola TG cohort) — has NOT survived a PMI/RIN/batch confound
  test.** `results/iadorola_tg/hsv1_hervk_analysis.py` produces this exact
  regression; nothing about the number changed this session.
- **Gating analysis, not yet run:** Telescope locus-level HERV-K
  quantification (distinguishes "genuine disease-associated derepression"
  from "one constitutively-active locus, e.g. 1q22, dominating the aggregate
  Kraken2 signal"). Until this runs, per the synthesis doc, "every
  higher-order analysis is at risk."
- Every disease-specific contrast run to date (HSV-1+/- TG, DPN/Healthy,
  PD/"control") is non-significant (§1).
- **This session did not touch HERV-K analysis code or numbers.** Flagging
  here only because the STTR digest and the dossier's own §1 both reference
  this number, and a reader landing on this dossier should know its status
  without having to go find `synthesis_v1.md` first.

---

## 5. This session's work — host-quant tooling

Full detail: `docs/tooling_progress_plan.md`. Short version:

- **Confirmed Apptainer works in WSL2 for real workloads**, not just trivial
  ones — built a STAR genome index and ran splice-aware paired-end alignment
  of real subsampled Iadorola-cohort reads, then ran the full v2.0.0
  dedup→filter→featureCounts→HTSeq→aggregate chain via `host_quant.sif` and
  `python.sif`, all through `apptainer exec`. **Updated both CLAUDE.md files**
  (repo root `/mnt/c/users/mwild/firebase2/CLAUDE.md` and this repo's
  `CLAUDE.md`) to reflect this — old claim preserved with a note on why it
  changed, not deleted (see each file's WSL2 Notes section).
- **First-ever real `host_gene_expression_matrix.tsv`** now exists — and,
  after two rounds of debugging, **a full real Nextflow orchestration run of
  the entire pipeline (viral branch + host-quant branch together) completed
  successfully end-to-end** (`[SUCCESS] completed=1 failed=0 cached=21`) via
  `nextflow run main.nf -profile standard --run_host_quant true` against a
  toy chr21 reference. This found and fixed **two real bugs in the
  never-before-run v2.0.0 code** that by-hand container testing alone had
  masked: (1) `bin/featurecounts_host.R` was missing a `#!/usr/bin/env Rscript`
  shebang, so it would have failed the moment Nextflow invoked it for real
  (fixed, `host_quant.sif` rebuilt and reconfirmed locally); (2)
  `assets/NO_FILE` — the sentinel placeholder file this pipeline's own code
  relies on throughout `workflows/virome.nf` for every optional input — had
  literally never existed in the repo, and would break the final `REPORT`
  step (and the artifact/remap/gene-info disable paths) the instant
  `kraken2_db2` is left unset, which every real cohort config to date
  happens to always set (fixed: created a real empty file, git-tracked now).
  **Both fixes are real code/asset changes in the working tree, not just
  documentation** — see the file list in the final report. Both
  `host_quant.sif` and `python.sif` have already been rebuilt locally with
  these fixes baked in and are ready to `rsync` to Juno as-is.
- **`assets/cgas_sting_ifn_panel.tsv`** (new, 188 genes) and
  **`bin/score_host_reactivation.py`** / **`bin/score_vs_viral_correlation.py`**
  (new scripts) — the two things the STTR digest flagged as "net-new work,
  not adaptation, nothing exists yet." Built, documented with citable
  sourcing, and tested against both the real (if minimal) chr21 matrix and a
  25-sample **mock** matrix using real DPN & RA Kulkarni sample IDs +
  synthetic RPM values. **Any correlation numbers currently associated with
  this mock test are meaningless and are labeled as such in the script output
  itself** (`--label` flag stamps a warning onto the plot).
- Found and fixed one small latent Nextflow config bug (`conf/test.config`
  stub — see `docs/tooling_progress_plan.md` §1a) and documented, but did not
  fix, a second one (`save_unmapped_reads`/`save_kraken2_output` missing
  `params{}` defaults).
- Did **not** touch: HERV-K analysis, cohort registry provenance issues,
  GTEx/dbGaP, Juno, the STTR draft text itself, or the Shnayder/MIEP citation
  gap noted in §3.

---

## 6. Cohort provenance issues — still open, not addressed this session

Per Claude memory and the STTR digest (flagged independently by 4/5 expert
reviews as "a hard gate on using any of this lab's cohort data externally"):

- **`docs/cohort_registry.md` still lists AIG1390 as a legitimate second DRG
  donor** (row 3, "AIG1390 DRG"). Per `project_hervk_findings.md`, AIG1390 is
  a confirmed duplicate of donor1, should be excluded from the "Early DRG"
  grouping (n=16→11), and the registry has not been corrected.
- **Parkinson 2026 cohort "023-028 = control"** is stated as fact in the
  registry (row 6) but was explicitly unconfirmed in the original intake
  report per `project_parkinson_2026_provenance.md`.

Neither was in this session's scope. Both are cheap fixes (~30 min per
`docs/tooling_progress_plan.md` §4) and should happen before either cohort's
numbers are used in any external-facing document, including the STTR draft.

---

## 7. Source documents, for when you need the full version

| Topic | Doc |
|---|---|
| STTR grant intelligence | `docs/sttr_intelligence_digest.md` |
| Host-quant tooling — full detail, task list | `docs/tooling_progress_plan.md` |
| HERV-K critical synthesis | `HERVK/synthesis/synthesis_v1.md` |
| Cohort registry (provenance issues open, §6) | `docs/cohort_registry.md` |
| Contamination/artifact methodology | `research/virome_prospectus.md` |
| Pipeline architecture, deployment commands | `CLAUDE.md` (this repo) |
| WSL2/Apptainer capability (updated this session) | `CLAUDE.md` (this repo + parent `/mnt/c/users/mwild/firebase2/CLAUDE.md`) |
