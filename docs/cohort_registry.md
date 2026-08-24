# Virome Pipeline — Cohort Registry

All biological sample collections processed through the virome pipeline, in chronological order.

| # | Cohort | Samples | n | Tissue | Key notes |
|---|---|---|---|---|---|
| 1 | **Muscle** | Sample_19–23 | 5 | Skeletal muscle | First cohort; Sample_19 was the initial single-sample test |
| 2 | **Donor1 DRG** | donor1_L1–L5, T12 | 6 | DRG | Single donor, 6 spinal levels |
| 3 | **AIG1390 DRG** | AIG1390_L1–L4, T12 | 5 | DRG | Second donor, 5 spinal levels |
| 4 | **Saad DRG** | Saad_1–5 | 5 | DRG | Saad_1: QC outlier (10× depth, extreme contamination); Saad_2: known library failure — both retained deliberately for pipeline assessment |
| 5 | **REJOIN Jayden** | 473-1–473-17 | 17 | DRG | 2025 cohort; completes the 38-sample full cohort used for paper 1 |
| 6 | **Parkinson 2026** | PD2–PD20, 023–028 | 20 | DRG | 14 PD patients + 6 controls; sequenced by Psomagen (AN00028264); PD1/7/8/11/12/13 absent from delivery; PD19 = first HSV-1 Tier 1 detection |
| 7 | **BLAST verify PD19** | PD19 | 1 | DRG | Offshoot (`blast_verify.nf`) to confirm HSV-1 identity and latency phase in PD19 |
| 8 | **Iadorola TG** | TG1–TG22 (non-contiguous) | 16 | Trigeminal ganglion | Public benchmark; LaPaglia et al. 2017 (SRP113004); post-mortem; HSV-1 detected in 5/16 samples — pipeline validation run |
| 9 | **OSM Juliet** | D1–D3 × O/V × rep1–3 | 18 | DRG | 2026; OSM-treated vs vehicle control; 3 donors × 2 conditions × 3 replicates |

| 10 | **DPN & RA Kulkarni** | JE81, WE52, PA71, J1M2, T0M2, 2AC1, 1AN1, 8EN1, RO52, S1D1, 2OE1, N4N2, ME61, LE41, L1V1, FL0A2, FL0B1, 1VYA1, 1VYB2, CA7A2, CA7B1, 4LIA1, 4LIB2, G1NA1, G1NB2 | 25 | DRG | 2023; 10 shared healthy controls, 5 DPN cases, 10 RA specimens (5 donors × A/B — confirm L/R vs replicate); 5 metadata donors without fastq files (M4X, L3O, J4N, M3L, T1F) |

**Cohorts 1–5** were consolidated into the 38-sample full cohort (`all_cohort_pluspf`) for paper 1 analysis.

**Total unique biological samples: 118** across skeletal muscle, DRG, and trigeminal ganglion.

## Planned — Prometheus/gataca → Titan → scratch batch (not yet launched, 2026-08-18)

Config/samplesheet pairs built for 151 of the 157 confirmed-paired-end samples
found in `docs/prometheus_fastq_inventory_2026-08-18.md` (6 more excluded after
staging began, see Watchmaker row below), staged via gataca → the linux relay
machine → `/titan/tprice/ingest/virome/<original_prometheus_folder_name>/`
(real transfer, ~1.4TB/314 files, corrected mid-flight from an initial
local-instead-of-remote-destination mistake — see chat log). One cohort = one
config, per established convention.

**Resolved 2026-08-18 (was an open risk, now a known fact with a fix applied):**
a real launch attempt against `config_watchmaker_titan.yaml` failed at
`main.nf`'s samplesheet-parsing `checkIfExists` step — a plain Nextflow-host
file check, before any Apptainer container was even involved — because Juno's
**compute nodes do not have `/titan` mounted**, only login nodes do. This is a
bigger issue than the originally-flagged container-bind-mount risk (would have
blocked all 11 cohorts, not just one). Fix: every samplesheet now points at
`/scratch/juno/$USER/gataca_fastq/<dataset>/` instead of `/titan/...` directly;
`scripts/stage_titan_to_scratch_2026-08-18.sh` copies each cohort from Titan to
that scratch location (run from a login node, e.g. via tmux — the transfer
itself is a login-node-only operation, same reasoning as why the pipeline run
itself cannot be).

| Cohort | Config | Samplesheet | n | Notes |
|---|---|---|---|---|
| Watchmaker | `config_watchmaker_titan.yaml` | `samplesheet_watchmaker_titan.csv` | 24 | 30 found on Prometheus; MB1-6 (6 samples) confirmed 2026-08-18 as empty 23-byte gzip stubs on both Titan and the gataca source itself — excluded, not a transfer bug. See config comment |
| DPN & RA Kulkarni (re-run) | `config_dpn_ra_kulkarni_titan.yaml` | `samplesheet_dpn_ra_kulkarni_titan.csv` | 25 | **Already run** (cohort #10) — uniform re-stage, separate outdir |
| Thoracic DRG | `config_thoracic_drg_titan.yaml` | `samplesheet_thoracic_drg_titan.csv` | 24 | New. `104T8R` is a confirmed library failure (92 total STAR input reads, all-`unclassified` Kraken2 report — see CLAUDE.md's Bracken gotcha); `106T3R` has a separate, unexplained 74.52% multi-mapping ("too many loci") rate but otherwise classified normally |
| OSM Juliet (re-run) | `config_osm_juliet_titan.yaml` | `samplesheet_osm_juliet_titan.csv` | 18 | **Already run** (cohort #9) — path discrepancy vs. original config unresolved, see config comment |
| REJOIN Jayden (likely re-run) | `config_rejoin_jayden_titan.yaml` | `samplesheet_rejoin_jayden_titan.csv` | 17 | Matches cohort #5 almost exactly — confirm before treating as new |
| Adult/Infant Soma/Axon | `config_adult_infant_soma_axon_titan.yaml` | `samplesheet_adult_infant_soma_axon_titan.csv` | 10 | New. Sample-ID overlap risk with OSM cultured, see below |
| Unknown doloromics | `config_unknown_doloromics_titan.yaml` | `samplesheet_unknown_doloromics_titan.csv` | 8 | New. Folder literally named "unknown" — provenance TBD |
| MGO explant Saad (trial1) | `config_mgoexplant_saad_titan.yaml` | `samplesheet_mgoexplant_saad_titan.csv` | 6 | New. Saad-6 not in the registered Saad DRG n=5 — status unconfirmed |
| OSM explant Juliet | `config_osmexplant_juliet_titan.yaml` | `samplesheet_osmexplant_juliet_titan.csv` | 7 | New |
| OSM cultured Juliet | `config_osmcultured_juliet_titan.yaml` | `samplesheet_osmcultured_juliet_titan.csv` | 6 | New. 366-10 excluded (R1-only orphan); shares "366" numbering with Adult/Infant Soma/Axon |
| Lumar DRG (AIG1390) | `config_lumar_drg_titan.yaml` | `samplesheet_lumar_drg_titan.csv` | 6 | **Recommend excluding from the actual run** — 5/6 files are confirmed MD5-duplicates of Donor1 DRG (cohorts #2/#3); built for completeness only |
| TG 2018 Emma NIH | `config_tg_2018_emma_nih_titan.yaml` | `samplesheet_tg_2018_emma_nih_titan.csv` | 16 | New, different gataca subtree (`Trigeminal_ganglia/bulk_rnaseq/2018_Emma_NIH/`, SRA `_1`/`_2` naming, SRR5850220-235). All 16 present and complete on gataca — no stub/incomplete-file issues found this time |

**167 total** (157 DRG found on Prometheus, minus the 6 confirmed-empty Watchmaker MB samples, plus 16 new TG samples). Known open issue independent of this batch: the **AIG1390 DRG** row
above (cohort #3, n=5) still doesn't carry the duplicate-of-Donor1 caveat that's
already documented in project memory and correctly excluded from the actual
paper1 manuscript — worth fixing in this table separately from this batch.

### PathSeq offshoot — full-cohort validation (planned, 2026-08-19)

Scope decision: unlike every prior PathSeq run (`cmv_fibroblast`, `vzv_hsv1_tg`,
`ebv_gm12878`, `iadorola_tg` — all targeted at specific Tier 1 candidates), this
batch runs PathSeq on **every sample in all 11 launched cohorts** (161 samples —
the 167 above minus `lumar_drg`'s 6, which stays excluded from both the main
batch and this PathSeq batch) as a full third-opinion validation baseline, not a
targeted follow-up. A deliberate, much larger compute commitment than PathSeq's
routine use — see CLAUDE.md's "PathSeq verification offshoot" section for the
per-task cost (200 GB / 32 cpu / up to 48h, `conf/base.config`) driving that
choice, and this repo's own roadmap noting PathSeq was originally scoped as
*not* routine per-cohort infrastructure.

Prerequisite applied to all 11 `config_<cohort>_titan.yaml` files: added
`save_unmapped_reads: true` so `${outdir}/star_unmapped/` actually gets
populated (previously unset on every one of them — the flat files these were
generated from never turned it on). For a cohort whose main run already
completed before this was added, one more `-resume` pass against its real
session ID is needed first — `STAR_HOST_REMOVAL` cache-hits instantly for every
sample, this only adds the publish copy.

11 new `config_pathseq_<cohort>.yaml` + `samplesheet_pathseq_<cohort>.csv` pairs
built (mechanically derived from each cohort's existing main samplesheet — same
sample IDs, paths rewritten to `${outdir}/star_unmapped/{sample}_unmapped_R{1,2}.fastq.gz`),
plus `scripts/run_pathseq_config.sbatch` (sibling to `run_virome_config.sbatch`,
for `pathseq_verify.nf`). Each PathSeq config's `consensus_matrix` points at its
own cohort's `db_comparison/consensus_matrix.tsv` — this only curates which
taxa `AGGREGATE_PATHSEQ` highlights in `pathseq_concordance.tsv` (every sample's
full unmapped pool is scored taxonomy-wide regardless), and is harmless if that
file doesn't exist yet when a cohort's PathSeq run is chained to launch
immediately after its main run.

Not yet launched — chain each cohort's PathSeq job with
`--dependency=afterany:<that cohort's main-pipeline job ID>` once the main
11-cohort batch clears the queue.

#### Results (2026-08-23) — batch complete, 10/11 succeeded

Launched as a serialized `afterany` dependency chain (one cohort's PathSeq run
at a time, given the per-task cost noted above). Two configs
(`watchmaker`, `adult_infant_soma_axon`) hit a `consensus_matrix` path bug on
first attempt (missing `results/` segment, fixed in `3d4fe29`) and were
resubmitted individually ahead of the main chain; the main chain itself
(`thoracic_drg` → `mgoexplant_saad` → `tg_2018_emma_nih` →
`unknown_doloromics` → `osmexplant_juliet` → `osmcultured_juliet` →
`dpn_ra_kulkarni` → `osm_juliet` → `rejoin_jayden`) also had four members hit
that same pre-fix bug on their first attempt (all failed in ~3s each on
2026-08-19); all were resubmitted as part of the chain and completed.

**10 of 11 cohorts succeeded** (all except `unknown_doloromics`). Durations
ranged from 12m (`osmexplant_juliet`) to 1d 17h (`thoracic_drg`), tracking each
cohort's `star_unmapped/` data volume far more than its sample count —
`unknown_doloromics` itself had by far the largest per-sample unmapped pool in
the batch (30 GB / 8 samples ≈ 3.75 GB/sample, 2-8x every other remaining
cohort), which is almost certainly why it's the one that failed.

**`unknown_doloromics` failed** after 12h44m: 7 of 8 samples' `PATHSEQ_SCORE`
tasks completed fine (one, `2A-R`, took 12h26m alone — a real outlier even
within this already-slow cohort); the 8th (`4A-R`) terminated with exit 247
after only 11 minutes, no application-level stack trace in the captured
`.command.err` (just the GATK/Spark startup banner, then nothing) — consistent
with an external kill (OOM or similar) rather than a GATK-internal error, though
not confirmed via `sacct`'s own state field. Several of the 7 successful
samples in this same cohort already peaked at 170-185 GB RSS against the
200 GB/32cpu allocation in `conf/base.config`, so a memory-pressure kill on the
8th is the leading explanation. `AGGREGATE_PATHSEQ` never ran (Nextflow's
default `errorStrategy` aborted the whole run on the one task failure), so
there is no `pathseq_abundance_matrix.tsv`/`pathseq_concordance.tsv` for this
cohort despite 7/8 samples' individual `.pathseq_scores.tsv` files existing on
disk. Not yet re-run; a straightforward retry (same config, unaffected samples
will cache-hit via `-resume`) is the first thing to try, ahead of specific
resource-limit tuning.

**Update (2026-08-23): retried, OOM'd again, root-caused, `4A-R` excluded.**
A same-session `-resume` with a one-off 340GB override
(`assets/config_pathseq_highmem_override.config`, +70% over the standard
200GB) still OOM-killed `4A-R` — barely later than the first attempt (12m30s
vs. 11min), the tell that this wasn't a fixed "needs more RAM" shortfall.
Checked `4A-R`'s own Kraken2 (bracken_raw) classification directly: **6.77M of
6.82M total classified reads (99.3%) are three taxa already documented in
`assets/artifact_taxa.tsv`** as reagent/cross-mapping contaminants
(`Orthobunyavirus schmallenbergense` 3,960,024 reads, `Orthobunyavirus
simbuense` 1,765,902 reads, `Betabaculovirus chofumiferanae` 1,046,551 reads)
— real biology (HERV-K) is 3,513 reads underneath that noise. That's also why
this one sample's unmapped pool was 9.3GB against 16MB-4GB for its
cohort-mates. Kraken2's own pipeline already excludes these three via
`artifact_taxa.tsv` (which is why `4A-R`'s Kraken2/filtered results, already
in the tracking workbook, are fine as-is) — PathSeq has no equivalent
pre-filter and pays the BWA-MEM alignment cost for millions of
highly-repetitive contaminant reads before it can reach the real signal, a
multi-mapping memory blowup rather than a proportional-to-input-size
requirement (hence why +70% memory barely moved the failure point).

`4A-R` is now removed from
`assets/samplesheets/samplesheet_pathseq_unknown_doloromics.csv` (PathSeq-arm
exclusion only, same treatment as `104T8R`/`Saad_2` elsewhere in this
project — its Kraken2/filtered results are untouched), and the cohort is
also dropped from `4A-R`'s entry in `docs/neurotrophic_virus_tracking.xlsx`
entirely (not just the PathSeq columns).

**Re-run on the remaining 7 samples succeeded** (same session, 1m2s — all 7
cache-hit straight to `AGGREGATE_PATHSEQ`, exit 0). **All 11 cohorts are now
complete.** Notable result: `2A-R`'s HSV-1 hit (279 Kraken2 reads, flagged
earlier as a new candidate for this cohort) is now PathSeq-confirmed almost
exactly — 276 reads, independently corroborating a genuinely new finding.

Full cross-method (Kraken2 vs. PathSeq) results and per-cohort/per-taxon
comparison: `docs/pathseq_full_cohort_comparison_2026-08-23.md`. Same data is
also in `docs/neurotrophic_virus_tracking.xlsx` (`Summary`/`By Sample`/`PathSeq`
sheets).
