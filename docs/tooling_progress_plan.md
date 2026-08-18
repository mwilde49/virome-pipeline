# Host-Quant Tooling — Forward Progress Plan

**Written:** 2026-07-15, during a GTEx/Juno-unavailable local (WSL2) working session.
**Scope:** what was validated locally, exactly what's left to run the real host-quant
arm on Juno, what's blocked on GTEx/dbGaP access vs. what isn't, and a prioritized
task list. Companion doc: `docs/project_dossier_2026-07-15.md` (read that first if
you're resuming cold — it's the 5-minute orientation; this doc is the task list).

---

## 1. What was validated locally this session, and how confidently

No Juno access and no GTEx/dbGaP access were available this session (by design —
see the dossier). Everything below ran in this WSL2 environment against a toy
chr21-only reference and two small real-but-truncated FASTQ downloads. Disk
budget used: **~1.2 GB total** (well under the 30 GB ceiling; peaked around
6 GB mid-session with duplicated Nextflow work-dir staging of the 1.1 GB
Kraken2 DB across two samples, cleaned up after the run succeeded and its
outputs were confirmed published), living entirely under the scratch path
(nothing large was written into the git-tracked repo — see §5).

### 1a. Apptainer actually works in WSL2 for real, non-trivial workloads — HIGH confidence

Both CLAUDE.md files (repo root and this repo's own) previously stated flatly
that "Apptainer/Singularity cannot run inside WSL2." That was true historically
and is no longer true on this machine (apptainer 1.4.5, WSL2 kernel
6.6.87.2-microsoft-standard-WSL2). This was re-confirmed this session with much
heavier workloads than the earlier smoke test (`samtools --version`,
`python3 --version`):

- **STAR 2.7.11b** (`containers/star.sif`): built a real STAR genome index
  (chr21, ~46.7 Mb, `genomeSAindexNbases 11`) in ~12 seconds, then ran splice-aware
  paired-end alignment of 467,600 real read pairs (subsampled from Iadorola TG1,
  SRR5850223) in ~5.5 minutes at ~5.16M reads/hour, multi-threaded (8 threads),
  using `--outSAMtype BAM SortedByCoordinate` and `--outReadsUnmapped Fastx`
  identically to `modules/star_host_removal.nf`. Repeated successfully for a
  second sample (TG2, SRR5850224).
- **sambamba/bedtools/samtools/Rsubread/htseq** (`containers/host_quant.sif`):
  ran `sambamba markdup -r`, `samtools index`, `bedtools intersect -v -abam`
  (against the *real* ENCODE blacklist + the *real* psoma `filter.bed`, see §1b),
  `featureCounts` (Rsubread, R), and `htseq-count` — all via `apptainer exec`,
  all exit 0, all producing correctly-shaped, non-empty output.
- **A full `nextflow run main.nf -profile standard --run_host_quant true`**
  orchestration (Nextflow 26.04.6, self-installed via `get.nextflow.io`) —
  see §1c; this succeeded completely and found two real bugs (also §1c).
- **`apptainer build --fakeroot`** (not just `apptainer exec`) was also
  confirmed working in WSL2: rebuilt both `containers/python.sif` and
  `containers/host_quant.sif` locally from their `.def` files (pip/mamba
  installs, `%test` block execution, SIF packaging all completed normally) —
  see §1c for why these rebuilds were necessary, not just a demonstration.

Both CLAUDE.md files have been updated (see §5) to reflect this — historical
claim preserved with a note on why it changed, not silently deleted.

**One real gotcha found in the process, unrelated to Apptainer itself:**
Nextflow >= ~25.x eagerly validates every `includeConfig` path across *all*
`profiles {}` blocks at config-parse time, not just the one selected on the
command line. `nextflow.config`'s `test` profile points at `conf/test.config`,
which — per this repo's own roadmap — had never been written. Result: even
`-profile standard` failed outright with `Invalid include source:
conf/test.config` before any pipeline logic ran. Fixed by adding a minimal
stub `conf/test.config` (real fix, not a workaround — see the file's own header
comment for detail). Juno's pinned Nextflow build may be old enough not to
have this eager-validation behavior, so this may not have bitten anyone there
yet — but it will on the next Nextflow upgrade, anywhere, so it's fixed now
rather than left latent. **Action: none required, already fixed and committed
to working tree (uncommitted, awaiting your review like everything else this
session).**

A second small, real, latent bug found along the way: `params.save_unmapped_reads`
and `params.save_kraken2_output` are read by `modules/star_host_removal.nf` /
`modules/kraken2_classify.nf` (`enabled: params.save_unmapped_reads ?: false`
pattern) but were never added to the `params {}` block in `nextflow.config`,
so every run prints `WARN: Access to undefined parameter` for both. Harmless
(the `?:` guard means it still behaves as `false` when unset) but worth a
one-line fix next time you're in `nextflow.config` — not fixed this session
since it's cosmetic and outside the host-quant scope.

### 1b. The `filter.bed` question — RESOLVED, was a false alarm

The task brief for this session stated `psoma`'s local `filter.bed` was 0
bytes / empty. **Verified this is incorrect** — the file is 12 bytes with no
trailing newline: `chrM\t0\t16569` (confirmed via `xxd`/`cat -A`). 16,569 bp is
exactly the length of the human mitochondrial genome in GRCh38 — this is a
deliberate, legitimate single-region exclude BED covering the **entire
mitochondrial chromosome**, used together with the real ENCODE blacklist
(`blacklist.bed`, sourced from ENCFF356LFX per
`psoma/.../readmes/blacklist_source.txt`) to strip mt-RNA and ENCODE
blacklist-region reads from host gene counting. Confirmed this is the same
pattern `psoma`'s own `dedup_and_filtering.sh` / `psomagen_bulk_rna_seq_pipeline.nf`
use in production (`bedtools intersect -v -abam ... -b exclude_bed blist_bed`
— identical command shape to `modules/dedup_filter_host.nf`), and that
`psoma`'s own container test harness (`container/test_nextflow_pipeline.sh`)
uses the same "single dummy interval" pattern for a placeholder exclude BED,
confirming a one-region exclude BED is an expected, supported shape, not a
malformed input.

**This session copied the real `filter.bed` + `blacklist.bed` from `psoma` and
ran them through `bedtools intersect` via `host_quant.sif` for real (see §1a)
— zero errors.** The only actual defect was the missing trailing newline,
which was patched locally in the scratch copy (`printf '\n' >>`) before use;
worth doing the same when these files are deployed to Juno, out of caution
(some strict BED parsers choke on a missing final newline; bedtools 2.31.1
did not, but no reason to rely on that).

**Action:** when deploying to Juno per the existing CLAUDE.md rsync
instructions, add the trailing newline to `filter.bed` before or during the
`rsync` step, e.g.:
```bash
awk '1' psoma/HISAT2_pipeline_files/HISAT2_pipeline_files/filter.bed > /tmp/filter.bed  # awk adds trailing \n
rsync -avP /tmp/filter.bed maw210003@juno.hpcre.utdallas.edu:/groups/tprice/pipelines/references/exclude.bed
rsync -avP psoma/HISAT2_pipeline_files/HISAT2_pipeline_files/blacklist.bed \
    maw210003@juno.hpcre.utdallas.edu:/groups/tprice/pipelines/references/blacklist.bed
```

### 1c. The v2.0.0 host-quant code path — proven end-to-end on real data, MEDIUM-HIGH confidence

Ran the actual sequence `DEDUP_FILTER_HOST → FEATURECOUNTS + HTSEQ_COUNT →
AGGREGATE_HOST_COUNTS` by hand (each step's exact command copied from the
`.nf` module files) against the real STAR-aligned, real-dedup/filtered chr21
BAM from §1a:

- `sambamba markdup -r`: 6,402 read pairs in, 992 duplicates removed.
- `bedtools intersect` against real blacklist+exclude BEDs: 0 errors (§1b).
- `featureCounts` (Rsubread, `bin/featurecounts_host.R` unmodified): 1,134
  meta-features (chr21 genes), 49.4% of alignments successfully assigned.
- `htseq-count`: ran cleanly, standard `__no_feature`/`__ambiguous` summary
  rows present as expected.
- `bin/aggregate_host_counts.py` (unmodified, run via `python.sif`): produced
  a real, non-empty **`host_gene_expression_matrix.tsv`** — first one that has
  ever existed anywhere for this pipeline — 1,134 genes × 1 sample, plus
  `host_gene_expression_matrix_qc_summary.tsv` showing featureCounts/HTSeq
  concordance of **Pearson r = 0.90 (log1p), Spearman rho = 0.84** on real
  data (i.e. the QC check the script was built to compute is itself confirmed
  to work and to produce a sane, non-degenerate number). Top nonzero genes
  were biologically sane for chr21 in ganglion-derived tissue (APP, SOD1,
  S100B, COL6A1/2, PFKL) — not zero-inflated noise.

Repeated the STAR + dedup/filter half for a second sample (TG2, SRR5850224)
to exercise the multi-sample collection path.

**What this proves:** the actual v2.0.0 code — never run on real data before
this session, per the task brief — executes correctly end-to-end on real
STAR-aligned reads, with no code changes needed. Zero bugs found in
`modules/dedup_filter_host.nf`, `modules/featurecounts.nf`,
`modules/htseq_count.nf`, `modules/aggregate_host_counts.nf`,
`bin/featurecounts_host.R`, or `bin/aggregate_host_counts.py`.

**What this does NOT prove:** real gene-level biology (chr21-only reference
means only 1,134 of ~79k GENCODE genes could ever be counted; most of the
cGAS-STING/IFN/IL-6 panel genes are not on chr21 — see §1d), production-scale
performance/memory behavior (the real GTF is ~1.8 GB vs. the 21 MB chr21
subset used here; `FEATURECOUNTS` is provisioned 32 GB on Juno for exactly
this reason), or the *Nextflow-orchestrated* version of this exact chain
(that's §1c-continued, below) beyond what actually completed.

**Nextflow orchestration (`main.nf -profile standard --run_host_quant true`) —
completed successfully, and this is where the real value was.** Launched a
real two-sample (TG1+TG2 smoketest) end-to-end run through the *entire*
pipeline (FASTQC → TRIMMOMATIC → STAR_HOST_REMOVAL → KRAKEN2_CLASSIFY →
BRACKEN → KRAKEN2_FILTER → AGGREGATE, **plus** the host-quant branch) against
the toy chr21 index/GTF/BEDs and the real local 1.1 GB Kraken2 viral DB, using
a local resource-override config (Juno's `conf/base.config` requests up to
64–128 GB per task, sized for Juno compute nodes; this box has 44 GB total, so
without an override Nextflow's local executor refuses to schedule those tasks
at all).

**This orchestration run found two real bugs that the by-hand `apptainer exec`
testing above had accidentally masked — exactly the failure mode a
Nextflow-level smoke test is for, and exactly why the task brief asked for
one in addition to manual container calls. Both are now fixed:**

1. **`bin/featurecounts_host.R` had no shebang line** (`library(Rsubread)`
   was line 1). `modules/featurecounts.nf` invokes it as a bare command
   (`featurecounts_host.R . ${gtf} true ${task.cpus} featurecounts_raw.csv`),
   relying on the execute bit + shebang for the OS to know to run it with
   `Rscript`. Without a shebang, the shell fell back to interpreting the file
   as `/bin/sh`, which choked immediately on `library(Rsubread)`:
   `syntax error near unexpected token 'Rsubread'`. My earlier by-hand test
   (§1c above) had invoked it as `Rscript bin/featurecounts_host.R ...` —
   i.e. I supplied the interpreter myself, which is exactly why that test
   passed while the real pipeline wiring would have failed on Juno on its
   very first production run. **Fixed**: added `#!/usr/bin/env Rscript` as
   line 1. Rebuilt `containers/host_quant.sif` locally, verified the fix
   directly (bare `featurecounts_host.R . <gtf> true 4 out.csv` now runs
   correctly), then reran the full Nextflow pipeline with `-resume`, which
   picked up the fix and let `FEATURECOUNTS` (and everything downstream,
   including `AGGREGATE_HOST_COUNTS`) complete successfully.
2. **`assets/NO_FILE` — the sentinel placeholder file used throughout
   `workflows/virome.nf` for every optional `path` input
   (`artifact_list`/`taxon_remap`/`gene_info`/`comparison_plot`/
   `host_expression_matrix`, checked downstream via `.name != 'NO_FILE'`) —
   had never actually existed in the repo (`git log --all -- assets/NO_FILE`
   returns nothing).** This broke `VIROME:REPORT` outright
   (`cp: cannot stat '.../assets/NO_FILE': No such file or directory` —
   Nextflow's own file-staging step, before the script even runs) the moment
   `kraken2_db2` is unset, because `ch_comparison_plot` falls back to this
   placeholder. **Why this was never caught before**: every real cohort
   config in `assets/config_*.yaml` happens to always set `kraken2_db2`
   (checked all seven — six set it, only the two non-`main.nf` configs
   don't), so the single-DB code path through `REPORT` — and, by the same
   mechanism, disabling `artifact_list`/`taxon_remap`/`gene_info` — appears
   to have never been exercised in this pipeline's history until this local
   smoke test hit it. **Fixed**: created `assets/NO_FILE` as a real, empty,
   0-byte file (matching the pattern's intent — it is only ever inspected by
   `.name`, never read). This is a repo-wide fix, not specific to
   host-quant or to this smoke test.

After both fixes, reran with `-resume` a third time. **Result: full pipeline
success** — `[SUCCESS] completed=1 failed=0 cached=21` (the single
newly-completed task was `REPORT`; everything else replayed from the
`-resume` cache since only `assets/NO_FILE` changed between run 2 and run 3,
and that file isn't a task input hash dependency for the already-succeeded
tasks). Every expected output file is present and non-empty in
`$SCRATCH/host_quant_smoke_test/nf_run/out/` (path under this session's
scratch — see the final report for the literal path): both viral matrices
(`results/viral_abundance_matrix.tsv`, `bracken_raw_matrix.tsv`,
`minreads_matrix.tsv`), **both host-quant outputs**
(`results/host_gene_expression_matrix.tsv` — 1,134 genes × 2 samples,
featureCounts/HTSeq concordance Pearson r = 0.89 and 0.91 for the two
samples respectively — and `results/host_gene_expression_matrix_qc_summary.tsv`),
the full HTML report (`results/virome_report/summary.html` with all four
plots), and the MultiQC report. As a bonus sanity check, the (real, not toy)
Kraken2 viral branch also picked up a real HERV-K signal in this tiny
truncated Iadorola subsample (25 and 23 reads, ~52–58 RPM in the two
samples) — consistent with this pipeline's well-established cross-cohort
HERV-K ubiquity finding, and a good sign the viral branch wiring is
unaffected by anything touched this session.

**Net effect: the host-quant branch is now proven through real end-to-end
Nextflow orchestration, not just by-hand container calls, with two real bugs
found and fixed along the way** (§ above) that would otherwise have surfaced
on the very first real Juno production run.

### 1d. Gene panel + scoring script — built and tested, HIGH confidence in mechanics, N/A confidence in any numbers

- **`assets/cgas_sting_ifn_panel.tsv`**: 188 unique genes, sourced from
  verbatim downloaded MSigDB Hallmark gene sets
  (`HALLMARK_INTERFERON_ALPHA_RESPONSE`, 97 genes; `HALLMARK_IL6_JAK_STAT3_SIGNALING`,
  87 genes; both v2023.2.Hs, fetched directly from gsea-msigdb.org this
  session) plus a small hand-curated set of cGAS-STING pathway machinery genes
  (CGAS, STING1, TBK1, IKBKE, IRF3, IFNB1) and a few canonical ISGs/receptors
  confirmed absent from the Hallmark sets (MX2, OAS2, OAS3, IFIT1, RIGI, IL6R).
  All 188 symbols resolved cleanly (0 unmatched) against GENCODE v48
  (`assets/gene_id_name_biotype.tsv`). Full sourcing/rationale is documented
  in the file's own header comment block — read that before citing this list
  externally, especially the caveat that the IL6/JAK/STAT3 Hallmark set is a
  general gp130/JAK/STAT3 signaling set, not IL-6-specific.
- **`bin/score_host_reactivation.py`**: computes `mean(log1p(RPM))` across
  panel genes per sample (+ cohort z-score, + per-category subscores). Ran
  successfully against both the real chr21 smoke-test matrix (§1c — only
  5/189 panel genes present, as expected for a single-chromosome toy
  reference) and a 25-sample **mock** matrix (§ below).
- **`bin/score_vs_viral_correlation.py`**: generalized version of the
  regression pattern in `results/iadorola_tg/hsv1_hervk_analysis.py` — takes
  any host score file + any viral taxon_id, joins on sample, reports Pearson/
  Spearman + a labeled scatter/regression plot.
- **Mock end-to-end test**: built a synthetic `host_gene_expression_matrix.tsv`
  (189 panel genes × the 25 real DPN & RA Kulkarni sample IDs, log-normal
  random values, **seed=42**, zero injected biological signal) and ran the
  full chain: mock matrix → `score_host_reactivation.py` → 25 real z-scored
  values → `score_vs_viral_correlation.py` against the *real*
  `results/dpn_ra_kulkarni/results/viral_abundance_matrix.tsv` HERV-K row →
  R=-0.325, R²=0.106, p=0.113 (Pearson), rho=-0.310, p=0.132 (Spearman).
  **These numbers are from synthetic random data and are biologically
  meaningless — they exist only to prove the join/correlation/plotting code
  works.** The correlation script's `--label` flag stamps this warning
  directly onto the output plot and stdout so it can't accidentally be reused
  silently. Non-significance is itself a sanity check: random data should not
  correlate, and it didn't.
  Artifacts live under this session's scratch path (`mock_test/`), not the
  git-tracked repo — see the final report for the exact path if you want to
  re-inspect them; they were deliberately not copied into the repo.

**Net effect:** the moment a real `host_gene_expression_matrix.tsv` exists
(from an actual Juno `run_host_quant=true` run), both scoring and correlation
scripts are ready to run against it with no further code changes needed —
just swap `--matrix` from the mock file to the real one.

---

## 2. Exact next steps to run the real host-quant arm on Juno

This is unchanged in substance from the existing CLAUDE.md deployment notes
("Host gene expression quantification (optional)" section) — this session
did not change that plan, only validated that the underlying code is sound
so the deployment isn't gated on undiscovered bugs. Restated here as a
concrete checklist, informed by what this session found:

1. **Deploy references to Juno** (per existing CLAUDE.md rsync commands):
   ```bash
   rsync -avP psoma/HISAT2_pipeline_files/HISAT2_pipeline_files/gencode.v48.primary_assembly.annotation.gtf \
       maw210003@juno.hpcre.utdallas.edu:/groups/tprice/pipelines/references/
   # NOTE: add the missing trailing newline to filter.bed before/during rsync -- see §1b.
   awk '1' psoma/HISAT2_pipeline_files/HISAT2_pipeline_files/filter.bed > /tmp/filter.bed
   rsync -avP /tmp/filter.bed maw210003@juno.hpcre.utdallas.edu:/groups/tprice/pipelines/references/filter.bed
   rsync -avP psoma/HISAT2_pipeline_files/HISAT2_pipeline_files/blacklist.bed \
       maw210003@juno.hpcre.utdallas.edu:/groups/tprice/pipelines/references/blacklist.bed
   ```
2. **Rsync `host_quant.sif`** — already rebuilt locally THIS session (not
   just previously built) to pick up the `featurecounts_host.R` shebang fix
   (§1c) — this fix is *required*, not optional, or `FEATURECOUNTS` will fail
   on Juno exactly as it did here before the fix. `.sif` files are portable
   binaries; no need to rebuild again on/for Juno, just rsync the copy
   already sitting in this local checkout:
   ```bash
   rsync -avP containers/host_quant.sif maw210003@juno.hpcre.utdallas.edu:/groups/tprice/pipelines/containers/virome/
   ```
3. **Rsync `python.sif`** — also already rebuilt locally this session to
   bake in the two new scripts (`bin/score_host_reactivation.py`,
   `bin/score_vs_viral_correlation.py`; added to `containers/python.def`'s
   `%files` block and confirmed present at `/opt/virome/bin/` and on `PATH`
   in the rebuilt image):
   ```bash
   rsync -avP containers/python.sif maw210003@juno.hpcre.utdallas.edu:/groups/tprice/pipelines/containers/virome/
   ```
   (They can also be run directly with
   `apptainer exec python.sif python3 bin/score_*.py ...` without relying on
   `PATH`, since `python.sif` already has pandas/numpy/scipy/click either way
   — confirmed this session.)
4. **Launch the first-ever production `run_host_quant=true` run.** Recommended
   cohort: **DPN & RA Kulkarni** (`assets/config_dpn_ra_kulkarni.yaml`) — 25
   samples, the most phenotype-relevant cohort in hand per prior HERV-K
   analysis (`project_hervk_findings.md`), and the cohort this session's mock
   test already used for its sample-ID list, so the mock-test correlation
   script can be re-run against the real matrix with zero changes once it
   exists. Add to that config:
   ```yaml
   run_host_quant: true
   gtf:            /groups/tprice/pipelines/references/gencode.v48.primary_assembly.annotation.gtf
   blacklist_bed:  /groups/tprice/pipelines/references/blacklist.bed
   exclude_bed:    /groups/tprice/pipelines/references/filter.bed
   ```
5. **Once `host_gene_expression_matrix.tsv` exists for real:**
   ```bash
   python3 bin/score_host_reactivation.py \
       --matrix results/dpn_ra_kulkarni/results/host_gene_expression_matrix.tsv \
       --panel assets/cgas_sting_ifn_panel.tsv \
       --output results/dpn_ra_kulkarni/results/host_reactivation_score

   python3 bin/score_vs_viral_correlation.py \
       --score results/dpn_ra_kulkarni/results/host_reactivation_score.tsv \
       --viral-matrix results/dpn_ra_kulkarni/results/viral_abundance_matrix.tsv \
       --taxon-id 45617 \
       --output results/dpn_ra_kulkarni/results/host_score_vs_hervk
   ```
   Re-run `--taxon-id` per taxon of interest (HERV-K=45617,
   CMV-proxy=3050337, etc. — see `assets/artifact_taxa.tsv` /
   `assets/taxon_remap.tsv` for the full taxon_id vocabulary already in use).
   **Check `host_gene_expression_matrix_qc_summary.tsv` first** — if
   featureCounts/HTSeq concordance is poor for any sample, flag it before
   trusting that sample's score.

---

## 3. What's blocked on GTEx/dbGaP access vs. what isn't

**Blocked (only the user/PI can resolve — do not attempt):**
- The large-scale external CMV validation itself (GTEx 9,416-sample cohort,
  ~101 raw CMV-positive / ~61 after excluding MIEP/vector-contamination
  artifacts per Shnayder et al. 2018 mBio) — requires an active dbGaP DAR for
  phs000424 with a Research Use Statement that actually covers this use case.
  See the dossier for the Ray/Price IRB 15-237 precedent and why it may not
  currently apply.
- Anything that requires downloading real GTEx FASTQs/BAMs or accessing
  dbGaP-controlled phenotype data.

**NOT blocked — nearly everything else in this plan:**
- Steps 1–5 above (Juno deployment, first production `run_host_quant` run,
  gene panel, scoring/correlation scripts) — all use this lab's own already-
  consented cohort data, already resolved this session or ready to run the
  moment Juno is reachable.
- Cohort provenance fixes (§4 below).
- Drafting the STTR Preliminary Data section itself, once step 4/5 produce
  real numbers.

**Bottom line, echoing the STTR digest's own assessment:** the rate-limiting
step for the STTR deliverable is not code, and — separately — the rate-
limiting step for the GTEx validation idea is not code either. Both are
now genuinely unblocked on the *tooling* side; what's left is Juno access
(routine, not this session) and a PI-level decision on the dbGaP DAR
question (see dossier).

---

## 4. Prioritized task list going forward

| # | Task | Blocked on | Effort | Priority |
|---|---|---|---|---|
| 1 | Deploy GTF/blacklist/exclude BED + the two already-rebuilt `.sif` files (`host_quant.sif`, `python.sif`) to Juno (§2 steps 1-3) | Juno access | ~30 min | **Highest — do first** |
| 2 | Launch first-ever `run_host_quant=true` production run (DPN & RA Kulkarni) | #1 | ~1-4 hrs compute (unattended) | High |
| 3 | Run `score_host_reactivation.py` + `score_vs_viral_correlation.py` against the real matrix, for each Tier 1 viral taxon | #2 | ~30 min | High |
| ~~4~~ | ~~Add scoring scripts to `containers/python.def` `%files`, rebuild+rsync `python.sif`~~ | — | — | **Done this session** — see §1c/§2 |
| 5 | Fix `AIG1390` duplicate-donor entry and PD "023-028=control" unconfirmed-label caveat in `docs/cohort_registry.md` | none | ~30 min | **High — flagged by 4/5 STTR reviewers as a hard gate on using cohort data externally; not done this session, out of this session's scope but should not wait** |
| 6 | Add `params.save_unmapped_reads` / `params.save_kraken2_output` defaults to `nextflow.config`'s `params {}` block (removes harmless but noisy WARN) | none | ~5 min | Low |
| 7 | Draft the STTR Preliminary Data section using the real (non-mock) score + correlation output | #3 | ~1-2 days, PI-gated on disclosure-level decisions per `docs/sttr_intelligence_digest.md` | High, but gated on a PI decision, not on this lab's tooling |
| 8 | Pursue the GTEx/dbGaP DAR question with Ray/Price | PI/user only | — | Separate track, does not block 1-7 |
| 9 | (Optional, not scoped this session) Build out the real `conf/test.config` CI/synthetic-data profile — a stub now exists (this session) so config-parsing no longer breaks, but no synthetic samplesheet/reference is wired up yet | none | ~1 day | Low — nice-to-have, this session's toy chr21 reference (kept in scratch, see final report) is a ready-made starting point if you want to build this out |
| 10 | Write the Nieuwenhuis-vs-Shnayder/MIEP contamination-mechanism distinction into `research/virome_prospectus.md`'s CMV proxy-taxon section (§3 of the dossier — discovered not actually written despite being described as done) | none | ~15 min | Low-medium, citation-defensibility item |

---

## 5. What this doc deliberately does not cover

- The HERV-K/HSV-1 R²=0.459 confound-test status, the STTR draft's own
  weaknesses, and the GTEx/dbGaP precedent details — all covered in
  `docs/project_dossier_2026-07-15.md`, not duplicated here.
- Anything requiring GTEx/dbGaP/Juno credentials — explicitly out of scope
  for this session per its own instructions.
