# RESTART_CLAUDE.md — Read This First

**Written 2026-08-27.** This file exists to let this project be picked up from
a completely fresh Claude session/account with zero prior context. Read it top
to bottom, then follow the pointers below in order. It is not a replacement
for `CLAUDE.md` (the technical/architecture authority) — it's the
project-management and history layer that sits above it.

## How to use this file

Claude Code's persistent memory feature (`~/.claude/projects/<hashed-cwd>/memory/`)
is scoped to the local machine and the exact working-directory path used to
launch the session — it is **not** tied to any Anthropic account login. It may
or may not carry over to a "new Claude account," depending entirely on whether
that account runs Claude Code from the same machine and the same literal path.

**Do not treat Claude memory as authoritative. This repo is now the source of
truth.** Concrete reason why: while producing this file (2026-08-27), it was
discovered that this project had **two separate memory namespaces** —
`~/.claude/projects/-mnt-c-Users-mwild-firebase2-virome/` (capital `U`, 5
files) and `~/.claude/projects/-mnt-c-users-mwild-firebase2-virome/` (lowercase
`u`, 18 files) — a WSL2 case-sensitivity artifact: the filesystem treats
`/mnt/c/Users/...` and `/mnt/c/users/...` as the same directory, but the memory
system hashes the literal path string, so a session launched with a
differently-cased `cd` gets a completely separate, non-overlapping memory
store. The session that did this consolidation had **never seen** the
richer, older, 18-file namespace until today, despite that namespace holding
the STTR grant history, the full HERV-K cross-cohort statistics, the
`AIG1390`/Parkinson provenance findings, and more. That's real, demonstrated
information loss between sessions — not a hypothetical risk. Everything of
lasting value from both namespaces has been migrated into this repo's `docs/`
as of today; new durable findings should go into git-tracked files going
forward, with memory used only as a same-session/near-term convenience.

## Project identity

A Nextflow DSL2 pipeline for systematic profiling of the human dorsal root
ganglion (DRG) virome from paired-end bulk RNA-seq, run on the Juno HPC
cluster (UT Dallas, TJP research group) via SLURM and Apptainer. Repo lives at
`/mnt/c/Users/mwild/firebase2/virome` locally (WSL2 on Windows) and is also
deployed on Juno as a git submodule of `github.com/mwilde49/hpc` at
`/groups/tprice/pipelines/containers/virome`.

**User**: mwilde49 / maw210003@utdallas.edu — PhD student in the TJP group at
UT Dallas, first author on the DRG virome work, strong in
Nextflow/HPC/Apptainer/Python. **PI**: Dr. Theodore Price, who directs
strategy decisions (journal targets, paper scope, grant framing) — this is
PI-directed research, not independent work; don't make strategy calls (journal
choice, what to disclose in a grant, publication scope) without checking
whether the PI has already decided them (see `project_single_paper_strategy.md`
pattern below).

## Read next, in this order

1. `CLAUDE.md` (repo root) — the technical/architecture authority: pipeline
   version, module list, deployment commands, known gotchas. Always defer to
   this file over this one for anything code/pipeline-mechanics related.
2. `docs/juno_hpc_operations_guide.md` — general Juno/SLURM/Nextflow/Apptainer
   operations knowledge, written to apply beyond just this pipeline.
3. `docs/hervk_findings_comprehensive_2026-08-27.md` — the full HERV-K/HSV-1/
   CMV-proxy statistical findings across every cohort, with every caveat
   (including the not-yet-confound-tested status of the headline numbers).
4. `docs/claude_access_and_capabilities.md` — exactly what Claude can and
   cannot do on Juno (and now a second machine, "Threadripper" — see below).
5. `docs/project_status_and_open_items_2026-08-27.md` — STTR grant status,
   tool-comparison decisions (MysteryMiner vs VPF-Class), the minimap2 and
   Telescope roadmap items, remaining cohort-provenance items, and the full
   record of what got migrated from the old memory namespace and where.
6. `docs/cohort_registry.md` — the full cohort list/status. Provenance
   caveats (AIG1390, Parkinson 023–028) were just fixed here today — see
   Critical Standing Directives below.
7. `HERVK/README.md` — a standalone, thesis-level HERV-K research sub-project
   living inside this repo (literature review, biology background, mechanisms,
   hypotheses, a critical synthesis document, and its own pre-existing
   `hervk_deck.pptx`). Treat this as the deeper scientific foundation behind
   the HERV-K claims used in the pipeline-facing docs.
8. `research/` — `virome_prospectus.md` (methodology/contamination framework),
   `cmv_taxonomy_investigation.md` (the CMV-proxy forensics), `paper1/`
   (methods-paper draft, still broadly relevant), `paper2/` (**stale** — see
   `research/PUBLICATION_MO.md`'s superseded-banner; the two-paper split it
   describes was abandoned by the PI in April 2026).

## Current status snapshot (2026-08-27)

- **Pipeline version 2.2.0** (per `CLAUDE.md`) — pipeline-native run
  provenance output, config/samplesheet pairs staged for 11 real cohorts (151
  samples originally staged; the batch that actually ran ended up covering
  161 samples across those 11 cohorts once launched).
- **SfN Neuroscience 2026 poster abstract** — drafted and committed at
  `docs/sfn_abstract_2026_draft.md`. **The regular submission window already
  closed (June 11, 2026). The only remaining path is the late-breaking
  window: September 8–15, 2026** — genuinely time-sensitive, about two weeks
  out from this file's write date. Open items before it can actually be
  submitted: a real donor age-range (currently a placeholder), a theme/topic
  pick from SfN's live dropdown, funding/COI disclosure text.
- **Lab-update slide deck** — `docs/presentations/drg_virome_preliminary_results_2026-08-25.pptx`,
  11 plain slides (no icons/decoration, matches "no Claude-conventions"
  styling the user explicitly asked for), walks through the pipeline and
  findings for a lab audience. **Deliberately excludes CMV/CMV-proxy
  entirely** — see Critical Standing Directives.
- **Publication strategy**: single paper (not the two-paper split
  `research/PUBLICATION_MO.md` originally described), per an April 2026
  PI-directed pivot. Target journal **mSystems** (ASM) first, **Viruses**
  (MDPI) as fallback. Full research article (~5,000–6,000 words), HERV-K
  elevated to a primary result, pipeline content lives in Methods. If the
  Claude memory file `project_single_paper_strategy.md` still exists in
  whatever session picks this up, it has the same content as this paragraph
  plus a few more framing details — this file's version is now the
  authoritative one either way.

## Critical standing directives — do not violate without the user re-raising it

- **Do not present the CMV/CMV-proxy taxon (`3050337`, display name "Human
  CMV (HHV-5) [proxy]") as a legitimate positive finding in any
  external-facing document** (abstract, poster, grant text) — the user is "very
  confident it is not legitimate human CMV." This is reinforced by real
  evidence, not just caution: PathSeq's own independent validation run
  (`cmv_fibroblast` cohort, real genuine CMV infection) landed cleanly on a
  completely different taxon (`10359`/`3050295`, "Human betaherpesvirus 5" /
  "Cytomegalovirus humanbeta5") and never touched `3050337` at all — see
  `docs/hervk_findings_comprehensive_2026-08-27.md` for the full forensics
  and the still-open question of what `3050337`'s near-universal, oddly-behaved
  signal actually is. The SfN abstract and the pptx deck both deliberately
  omit it entirely (not asserted positive, not asserted negative).
- **The headline HSV-1↔HERV-K correlation numbers have NOT survived a
  PMI/RIN/batch confound test**: R²=0.459 (Iadorola TG cohort, p=0.0039, n=16)
  and R²=0.241 (thoracic_drg cohort, from the 2026-08-19 batch, p=0.0148,
  n=24). The Telescope locus-level gating experiment that `HERVK/synthesis/synthesis_v1.md`
  calls a prerequisite for trusting any higher-order HERV-K claim has **not
  been run**. Both numbers appear, appropriately hedged, in the already-produced
  SfN abstract and pptx deck — fine for a preliminary poster — but neither
  should be cited as fully validated in a grant application or manuscript
  without this caveat front-loaded, per explicit STTR red-team review
  feedback (`docs/sttr_intelligence_digest.md`).
- **`docs/cohort_registry.md`'s AIG1390-duplicate and Parkinson-023–028-
  unconfirmed-control caveats were just fixed today (2026-08-27, commit
  `80c0cd7`)** after being flagged three separate times since March/April 2026
  without ever being applied to the actual table rows. If a future edit to
  that file drops these caveats again, treat it as a real regression, not a
  style choice — it was independently flagged by 4 of 5 STTR grant reviewers
  as "a hard gate on using any of this lab's cohort data externally."
- **Response-formatting convention**: don't wrap a copy-paste command block
  meant for the user to run elsewhere (e.g. on Juno) inside a Bash tool call —
  write it directly in the response as a markdown fenced code block instead.
  The terminal UI renders tool calls as collapsed, non-copyable widgets;
  plain response text renders as copyable markdown. This bit repeatedly in
  long Juno-command-relay sessions before being fixed.
- **Claude has no working direct SSH/shell access to Juno** beyond the three
  narrow restricted keys documented in `docs/claude_access_and_capabilities.md`
  (read-only, jailed to specific directories). Never present a Juno/SLURM
  state check or command as something Claude ran "for real" unless it went
  through one of those specific restricted channels — broad actions (`sbatch`,
  general `squeue`/`sacct`, git operations on Juno's deployed checkout, `rsync`
  pushes) must be relayed through the user running them and pasting output
  back.

## Uncommitted working-tree state

**Update 2026-09-02**: `docs/presentations/` (the pptx deck) has since been
committed. `docs/neurotrophic_virus_tracking.xlsx` was investigated cell-by-cell
(HEAD vs. working tree, `openpyxl`, `data_only=True`, all 5 sheets) and is
**still uncommitted — still needs the user's decision, not resolved**:
- Genuine improvement: `Summary`/`PathSeq`/`By Cohort`/`Agreement` all gained
  real cached formula values (percentages) that read as `None` in the HEAD
  version — HEAD was apparently committed before the file was ever opened in
  Excel, so its formulas had no cached results. `Summary` also gained a new
  TOTAL row (160 samples, 35 total detections) not present in HEAD.
  `By Sample` is byte-identical in content (only sheet with zero diff).
- **Concerning, looks like real content loss, not just a resave**: the sheet
  title cells shrank or vanished — `Summary`'s A1 went from
  "Neurotrophic Virus Screen — Summary (total unique detections, by method)"
  to just "Neurotrophic Virus Screen"; `PathSeq` and `By Cohort`'s A1 titles
  went to blank entirely. Worse: **the `Agreement` sheet's entire 8-row Notes
  section is gone** (methodology notes on PathSeq's RefSeq-81 taxon IDs, the
  4A-R exclusion, and the "BLAST-verify Rhadinovirus/Molluscum before trusting
  either method alone" caveat — all deleted, not just reformatted).
  A plain Excel open→recalculate→save cycle does not rewrite cell text like
  this on its own, so this doesn't look like an inert resave.
- Net: this diff is a **mix of a real improvement (cached formulas, new
  total) and what looks like real, accidental content deletion** (titles,
  the entire Agreement Notes section). **Do not commit or discard without
  the user looking at it directly** (Excel/LibreOffice) — if the notes
  section is confirmed gone for good, it should be re-added (the deleted
  text is preserved verbatim above and in this session's investigation) before
  committing, not silently dropped.
- Everything else found uncommitted at the start of this consolidation task
  (`.gitignore` SSH-key-protection entries, `scripts/pull_bracken_raw_batch.sh`)
  has already been committed (commit `40d39bb`).

## HERV-K / viral findings summary

HERV-K (an endogenous retrovirus) is detectable in nearly every DRG/TG sample
across 11 cohorts (145–154/160ish depending on exact batch, no zero-count
libraries) and correlates significantly and positively with HSV-1 detection
in every cohort with enough HSV-1-positive samples to test (2 of 11: Iadorola
TG and thoracic_drg), replicating a previously TG-only finding into DRG for
the first time. A combined HSV-1 + AAV + Molluscum-contagiosum signal is the
strongest joint predictor of HERV-K among all taxon combinations tested, and
survives BH-FDR correction. EBV, VZV, and direct-CMV are genuine zero-read
negatives across all 160+ samples at zero threshold — not a filtering
artifact. The CMV-proxy taxon (`3050337`) is a separate, unresolved,
near-universal signal, deliberately not treated as real CMV (see directives
above). None of this is causally established — all findings are correlational,
bulk RNA-seq, with the confound-testing and locus-level caveats noted above.
Full detail, every number, every caveat, every cohort:
`docs/hervk_findings_comprehensive_2026-08-27.md`.

## STTR grant summary

An NIH STTR Phase I application is in progress, co-developed with **Ataraxia
Bio** (small-business partner, capture + duplex-sequencing + ddPCR platform)
and this lab (Dr. Theodore Price, PI). Central hypothesis: a subset of
chronic neuropathic pain is driven by latent viral reactivation (HSV-1, VZV,
EBV, CMV, HHV-6A/B, HHV-7, enterovirus) and/or HERV-K derepression in DRG
sensory neurons, converging on a cGAS-STING/type-I-IFN/IL-6 innate-immune
node. This lab is named directly in the grant's Preliminary Data section,
which is a literal bracketed placeholder asking for (1) an unmapped-read
viral/lytic-transcript requery and (2) a per-donor host-reactivation score
correlated against viral RPM. A five-department expert review (2026-07-15)
found the underlying draft scientifically sound in scope but **not
submission-ready** — no budget, no power calculation, both go/no-go gates
effectively unfalsifiable as written, and this lab's own cohort history has
never once reached significance on a comparable disease-vs-viral/HERV-K
contrast. Full original digest: `docs/sttr_intelligence_digest.md`. What's
changed since (or hasn't) as of 2026-08-27: `docs/project_status_and_open_items_2026-08-27.md`.

## Infrastructure summary

**Juno access**: Claude has three narrow, purpose-built SSH keys to Juno
(read-only rsync pull jailed to `/scratch/juno/maw210003`; a status-only
keyword dispatcher; a broader read-only inspect dispatcher) — no general
shell/SSH access. Full detail, exact scopes, and the gotchas that came with
setting them up: `docs/claude_access_and_capabilities.md`.

**Threadripper keys — discovered but unexplained.** While writing this file,
two more SSH keypairs were found already present in `~/.ssh/`:
`id_ed25519_threadripper_inspect` and `id_ed25519_threadripper_pullonly`
(created 2026-08-27, same day, mirroring the Juno `inspect`/`pullonly` naming
pattern exactly), plus matching `.gitignore` protection entries already
staged (now committed). **Nobody in this session's own history set these up,
and no repo doc or memory file explains what machine "Threadripper" is or
what it's for.** It's presumably a second compute machine the user has access
to (an AMD Threadripper workstation is a plausible guess given the name, but
that's a guess, not a confirmed fact) — **ask the user directly what this
machine is and what it's for** before assuming anything about it or trying to
use it.

**WSL2/Apptainer**: confirmed (2026-07-15) to work for real, non-trivial
pipeline workloads locally (STAR alignment, full Nextflow DSL2 orchestration)
— see `CLAUDE.md`'s WSL2 Notes section for exact verification detail. Useful
for local smoke-testing new modules before touching Juno; production-scale
runs still belong on Juno.

## Immediate next actions, priority-ordered

1. **SfN late-breaking submission prep** — real donor age-range for the
   `docs/sfn_abstract_2026_draft.md` placeholder, theme/topic pick, funding/COI
   text. **Deadline: September 8–15, 2026.**
2. **Ask the user what the "Threadripper" keys/machine are** — genuinely
   unexplained, discovered only while writing this file.
3. **Resolve the `docs/neurotrophic_virus_tracking.xlsx` uncommitted-diff
   question** — ask before committing or discarding.
4. **STTR grant open PI decisions** (none resolvable by Claude alone):
   submission deadline, who is the named sensory-neuron-latency co-I (the
   single biggest feasibility gap in the whole application), how much of the
   lab's own null/underpowered disease-specific track record gets disclosed,
   whether to cite the not-yet-confound-tested HERV-K correlation as citable
   preliminary data.
5. **The host-quant arm has still never been run on real Juno data** —
   reconfirmed today: no `host_gene_expression_matrix.tsv` exists anywhere
   under `results/`. This has been the #1 "start here" item across multiple
   past sessions' dossiers (at least since 2026-07-15) and has stalled every
   time on Juno reference-file deployment, not on code — the code itself has
   been validated locally and is ready. Worth asking the user directly why
   this keeps stalling before just re-attempting the same deployment steps.
6. **Telescope locus-level HERV-K quantification** — planned
   (`docs/project_status_and_open_items_2026-08-27.md` has the two-leg design)
   but not started. Gating experiment for trusting any higher-order HERV-K
   claim per the HERVK/ thesis synthesis.
7. **`assets/artifact_taxa.tsv` murine-retrovirus-family additions** —
   recommended (11 taxon IDs identified via the `watchmaker` cross-mapping
   investigation) but not yet applied; needs explicit user approval since it
   changes the curated exclusion list used for every cohort. Detail in
   `docs/hervk_findings_comprehensive_2026-08-27.md`.

## Directory map

| Path | What's there |
|---|---|
| `CLAUDE.md` | Technical/architecture authority — pipeline version, modules, deployment commands, gotchas |
| `docs/` | Findings write-ups, operations guides, cohort registry, this consolidation's new docs |
| `HERVK/` | Standalone HERV-K thesis sub-project — literature, biology/neurological background, mechanisms, hypotheses, a critical synthesis doc, and its own `hervk_deck.pptx` |
| `research/` | `virome_prospectus.md` (methodology/contamination framework), `cmv_taxonomy_investigation.md`, `paper1/` (methods-paper draft, still relevant), `paper2/` (stale — see superseded banner), `PUBLICATION_MO.md` (superseded two-paper strategy doc, banner added) |
| `assets/` | Per-cohort configs/samplesheets, curated taxon lists (`artifact_taxa.tsv`, `taxon_remap.tsv`), reference metadata |
| `modules/`, `workflows/`, `main.nf`, `blast_verify.nf`, `pathseq_verify.nf` | Pipeline code — see `CLAUDE.md` for the full architecture |
| `results/` | Per-cohort pipeline outputs, figures |
| `scripts/` | Operational helpers (container builds, Juno pulls, container/reference downloads) |
