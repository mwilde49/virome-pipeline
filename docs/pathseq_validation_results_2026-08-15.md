# Real-Data Pipeline Validation Results — 2026-08-15

Consolidated record of every real (non-synthetic) main-pipeline and `pathseq_verify.nf`
run against the new test datasets curated in
`docs/pathseq_and_test_datasets_2026-08-14.md`. Deep-dive taxonomy analysis for the
CMV/EBV cross-genus finding lives in `research/cmv_taxonomy_investigation.md` — this
doc is the top-level index so nothing sits in chat history only.

## Summary table

| Dataset | Samples | Main pipeline | PathSeq | Headline finding |
|---|---|---|---|---|
| `cmv_fibroblast` | 4 (`SRR5660016-19`) | ✅ 43/43, 1h1m | ✅ complete | Real human CMV (`3050295`) correctly dominant; PathSeq independently confirms under its own legacy taxid (`10359`) |
| `vzv_hsv1_tg` | 5 (`ERR2182863-67`, TG3-TG7) | ✅ 50/50, 4h28m | ✅ complete | Both HSV-1 (`3050292`/PathSeq `10298`) and VZV (`3050294`/PathSeq `10335`) confirmed Tier-1 **and** PathSeq-positive in **all 5** donors |
| `ebv_gm12878` | 2 (`SRR3192396-97`) | ✅ 25/25, 1h5m | ✅ complete | Real EBV (`3050299`/PathSeq `10376`) Tier-1, PathSeq-confirmed 98%+ share; Kraken2's ~3% cross-genus artifact (`3050339`) does **not** reproduce under PathSeq (<0.03%) |

## `cmv_fibroblast` — GSE99823/SRP108855 (Cheng et al., PNAS 2017)

MRC-5 fibroblasts, WT human CMV infection, 12/24/48/72 hpi time course. Config:
`assets/config_cmv_fibroblast.yaml`.

- Main pipeline: real, dominant, time-course-consistent CMV signal (`3050295`
  "Cytomegalovirus humanbeta5") — millions of reads, RPM climbing 12h→48h then
  dropping at 72h (lytic kinetics). The documented proxy taxon (`3050337`) does not
  appear in this sample at all.
- PathSeq: independently confirms under taxon `10359` ("Human betaherpesvirus 5" —
  same species, PathSeq's Dec-2017 taxonomy predates the ICTV rename that produced
  `3050295`). 99.9%+ normalized score in all 4 samples.
- Full writeup: `research/cmv_taxonomy_investigation.md`'s two 2026-08-15 update
  sections.

## `vzv_hsv1_tg` — PRJEB23238 (Depledge et al., Nat Commun 2018)

Real human trigeminal ganglia, 7 donors in the source paper, this run scoped to
TG3-TG7 (5 donors, single clean library prep each — TG1/TG2 have 4 preps each,
excluded here; see `docs/pathseq_and_test_datasets_2026-08-14.md`). Bait-capture
(VZV+HSV-1) enriched, not standard unbiased bulk — expect inflated apparent viral
fraction vs. unbiased datasets. Config: `assets/config_vzv_hsv1_tg.yaml`.

**Result** — `results/viral_abundance_matrix.tsv` / `results/db_comparison/consensus_matrix.tsv`:

| Donor | HSV-1 reads (RPM) | VZV reads (RPM) | Tier |
|---|---|---|---|
| TG3 (`ERR2182863`) | 8,267,423 (93,363) | 409,012 (4,619) | shared (both) |
| TG4 (`ERR2182864`) | 11,707,977 (141,751) | 877,025 (10,618) | shared (both) |
| TG5 (`ERR2182865`) | 17,540,230 (255,395) | 50,682 (738) | shared (both) |
| TG6 (`ERR2182866`) | 49,372,617 (497,941) | 471,534 (4,756) | shared (both) |
| TG7 (`ERR2182867`) | 10,575,993 (122,224) | 209,184 (2,417) | shared (both) |

Both HSV-1 (`3050292`) and VZV (`3050294`) land in the dual-DB `shared`/Tier-1 tier —
this pipeline's strongest confidence classification — in **every single donor**.
Directly, independently reproduces the source paper's core finding (VZV latency
transcript detected across the donor TG cohort) on a cohort this project had never
processed before (distinct from the Iadorola/LaPaglia TG cohort already used
elsewhere in this repo).

Notable biological detail: real donor-to-donor heterogeneity in the HSV-1:VZV ratio
(TG5 has the highest HSV-1 burden but the lowest VZV; TG4 has strong signal for
both) — consistent with individual latency-burden variation in real patient tissue,
not an artifact (both viruses stay Tier-1 regardless).

Background: only other Tier `viral_only` flag is `45617` (HERV-K, expected/known
signal, see `[[project_hervk_findings]]` memory, not a detection concern). Everything
else is single-digit-to-low-hundreds (adenovirus, avian sarcoma virus — negligible,
likely reagent/lab contamination).

**PathSeq result** — `pathseq_verification/pathseq_abundance_matrix.tsv`
(`assets/config_pathseq_vzv_hsv1_tg.yaml`, first real run using
`params.consensus_matrix` instead of manually-specified `target_taxa`):

| Donor | HSV-1 share (PathSeq `10298`) | VZV share (PathSeq `10335`) |
|---|---|---|
| TG3 (`ERR2182863`) | 96.55% | 3.42% |
| TG4 (`ERR2182864`) | 95.05% | 4.93% |
| TG5 (`ERR2182865`) | 99.60% | 0.36% |
| TG6 (`ERR2182866`) | 99.17% | 0.82% |
| TG7 (`ERR2182867`) | 98.71% | 1.27% |

Both viruses independently confirmed by PathSeq's alignment-based (BWA-MEM), Dec-2017-
vintage reference in **every donor** — full three-way concordance with the dual-DB
Kraken2 Tier-1 call (viral-only DB + PlusPF DB + PathSeq, all agree). HSV-2 (`10310`)
and Bovine alphaherpesvirus 1 (`10320`) are correctly ~0% in every sample (max 19
reads, 0.0004% share) — clean specificity, no cross-reactivity from the two most
plausible confounders. Genus-level Simplexvirus/Varicellovirus totals match the
species-level HSV-1/VZV numbers almost exactly, meaning essentially no reads land
anywhere else in either genus.

**Quantitative comparison vs. Kraken2** (HSV-1:VZV share within each donor):

| Donor | Kraken2 HSV1% / VZV% | PathSeq HSV1% / VZV% | Δ VZV (PathSeq − Kraken2) |
|---|---|---|---|
| TG3 | 95.28% / 4.72% | 96.58% / 3.42% | −1.30 pt |
| TG4 | 93.03% / 6.97% | 95.07% / 4.93% | −2.04 pt |
| TG5 | 99.71% / 0.29% | 99.64% / 0.36% | +0.07 pt |
| TG6 | 99.05% / 0.95% | 99.18% / 0.82% | −0.13 pt |
| TG7 | 98.06% / 1.94% | 98.73% / 1.27% | −0.67 pt |

Rank order by VZV share is **identical** between methods (TG4 > TG3 > TG7 > TG6 > TG5)
— PathSeq reads a slightly lower VZV share in 4/5 donors but the qualitative call is
unaffected either way. Raw magnitude, by contrast, is *not* directly comparable:
PathSeq's raw HSV-1 read counts run at only ~13–18% of Kraken2's across all 5 donors
(fairly consistent ratio) despite both nominally starting from the same STAR-unmapped
pool — most likely PathSeq's own internal quality/complexity filtering (still active
even with host-subtraction skipped) discarding more of the bait-capture-enriched
library than Kraken2's k-mer classifier does. Plausible, not confirmed — would need
PathSeq's own filter-stage log counts to verify. Use proportional agreement (share,
rank order, Tier calls) for cross-validation, not raw counts.

## `ebv_gm12878` — ENCODE ENCSR000AEC (GEO GSE78550, SRP013565)

GM12878 (constitutively EBV-transformed lymphoblastoid line, Type III latency, HapMap
project), 2 replicates, polyA+ RNA-seq PE101. Found via live web verification
mid-session (not part of the original 14-dataset sweep) specifically because both
EBV candidates from that original sweep turned out single-end — see chat log
2026-08-15 for how this was verified against ENA directly. Config:
`assets/config_ebv_gm12878.yaml`.

**Result** — `results/bracken_raw_matrix.tsv`:

| taxon_id | taxon_name | SRR3192396 reads (RPM) | SRR3192397 reads (RPM) |
|---|---|---|---|
| **3050299** | **Lymphocryptovirus humangamma4** (true human EBV) | 250,052 (2,480) | 184,950 (2,074) |
| 3050339 | Lymphocryptovirus papiinegamma1 (baboon relative) | 6,948 (69) | 2,861 (32) |
| 3050337 | Human CMV (HHV-5) [proxy] | 71 (0.70) | 90 (1.01) |

Real EBV signal, Tier-1/shared consensus, both replicates — expected for GM12878's
steady-state Type III latency (proportionally smaller than the lytic-infection CMV
sample or the bait-enriched TG cohort, as expected for a routine/unenriched screen).

**This result directly extends the CMV taxonomy investigation** — full analysis in
`research/cmv_taxonomy_investigation.md`'s final update section:
1. The same primate-reference-imbalance cross-mapping pattern recurs in a second
   herpesvirus genus (Lymphocryptovirus, not just Cytomegalovirus) — `3050339`
   picks up ~3% of the combined genus signal and also lands in Tier-1/shared.
2. The *original* CMV proxy taxon (`3050337`) shows up here too, as background noise
   in a sample with nothing to do with CMV — independent, unprompted corroboration
   that it's a low-titer artifact, not a fundamental detection failure.

**PathSeq result** — `pathseq_verification/pathseq_abundance_matrix.tsv`
(`assets/config_pathseq_ebv_gm12878.yaml`, `params.consensus_matrix` from this
cohort's real dual-DB output):

| taxon | PathSeq id | SRR3192396 | SRR3192397 |
|---|---|---|---|
| Lymphocryptovirus (genus) | `10375` | 155,831 reads / 98.72% | 118,531 reads / 98.27% |
| **Human gammaherpesvirus 4 (EBV)** | **`10376`** | **155,830 reads / 98.70%** | **118,531 reads / 98.25%** |
| Macacine gammaherpesvirus 4 (baboon/macaque relative) | `45455` | 104 reads / 0.023% | 1 read / 0% |

EBV dominant and PathSeq-confirmed in both replicates — genus and species totals are
essentially identical, so almost nothing in the genus is landing anywhere but EBV
itself. Critically, this is the direct PathSeq analog of Kraken2's `3050339` cross-
genus artifact above, and **it does not reproduce**: 0.02% and 0% vs. Kraken2's ~3%.
Unlike the CMV proxy taxon (where PathSeq's `10359` genuinely was present as real
background), PathSeq's independently-built, alignment-based reference sees essentially
none of this specific cross-mapping signal. Read narrowly: this particular ~3%
cross-genus call looks more consistent with a Kraken2 k-mer/reference-imbalance
artifact than a real low-level co-infection — worth folding into the taxonomy
investigation writeup as a case where the two methods diverge, not just corroborate.

**Quantitative comparison vs. Kraken2** (EBV vs. the cross-genus relative, within-genus share):

| Sample | Kraken2 EBV% / relative% | PathSeq EBV% / relative% | Fold-reduction in cross-mapping |
|---|---|---|---|
| SRR3192396 | 97.30% / 2.70% | 99.977% / 0.0229% | ~118× |
| SRR3192397 | 98.48% / 1.52% | 99.978% / 0.0218% | ~70× |

*(Correction 2026-08-16: an earlier version of this table misread the `45455`
Macacine gammaherpesvirus 4 row's column boundaries and reported sample 2's PathSeq
relative-share as "0%" — the actual score_normalized value is 0.0218%, verified
against genus pct = species pct + relative pct, which checks out exactly. The
corrected ~70–120× range is tighter and more consistent than the erroneous
40×–1,800× spread, and supports the same conclusion more cleanly.)*

The fold-reduction is consistent across both replicates (~70–120×) — this is the
number that tips the interpretation toward "artifact, not biology" for this specific
cross-mapping call. Extra
corroboration: Kraken2's trace CMV-proxy reads in these EBV samples (71 / 90 reads,
<1 RPM) have **zero** PathSeq counterpart under `10359` in either sample — both
methods agree that trace is at or below noise floor. Raw-magnitude caveat: PathSeq
retains ~62–64% of Kraken2's raw EBV read counts here, a much higher retention ratio
than the `vzv_hsv1_tg` cohort's ~13–18% (see that section) — likely reflecting less
low-complexity/adapter material surviving into the STAR-unmapped pool from this
standard poly-A library vs. the TG cohort's bait-capture enrichment protocol.

## Figure: Kraken2 × PathSeq concordance heatmap (2026-08-16)

`docs/figures/kraken_pathseq_concordance_heatmap.png` / `.pdf`, generated by
`scripts/make_concordance_heatmap.py` (re-run any time the underlying numbers
change — it's a plain Python/matplotlib script, no Juno access needed).

Distinct from the earlier interactive per-sample artifact: this is a static,
publication-style figure with a deliberately different normalization. For each
run, **both** the PathSeq and Kraken2 columns are expressed as a percent of
that run's own **Kraken2** total raw read count (summed across all taxa shown
for that run) — i.e. PathSeq's raw counts are rescaled against Kraken2's
denominator, not its own. This is what makes the two columns a real sensitivity
comparison rather than each method flattering itself against its own totals:
PathSeq recovers ~30% of Kraken2's raw CMV reads, ~15% of its HSV-1 reads,
~62% of its EBV reads, and a much smaller share of VZV (~0.24% vs Kraken2's
~2.03%, both against the same TG-cohort denominator) — all while still
correctly calling every primary taxon dominant within its own method. The
cross-species artifact rows are included for direct visual sensitivity/
specificity comparison per the same shared denominator, most notably the
baboon/macaque EBV cross-map: PathSeq's share (0.0138%) is ~160x smaller than
Kraken2's (2.204%) under this normalization — consistent with, and a cleaner
restatement of, the ~70–120x figure computed earlier in this doc under a
different (within-genus) normalization.

## Figure: high-resolution taxonomic-hierarchy variant (2026-08-16)

`docs/figures/highres_kraken_pathseq_concordance_heatmap.png` / `.pdf`,
generated by `scripts/make_concordance_heatmap_highres.py`. Second version of
the concordance figure above, restructured on explicit request: rows grouped
by **taxonomic lineage** rather than finding-type — each main virus (CMV,
HSV-1, VZV, EBV, HERV-K) is a bold anchor row with every related sub-taxon
(cross-species artifact, within-genus background, specificity-control
relative) indented directly beneath it. Same normalization as the primary
figure. Two additions beyond the primary figure's row set:

- **HSV-2 and Bovine alphaherpesvirus 1** (specificity-control relatives of
  HSV-1/VZV, `10310`/`10320`) — real PathSeq raw-read values now included
  (both ~1e-5–1e-6% of the TG cohort's Kraken2 total, i.e. essentially at
  noise floor, as expected for a clean specificity control), Kraken2 side
  marked "no data" since exact per-taxon counts for these two were never
  pulled (only a qualitative "everything else is single-digit-to-low-hundreds"
  note exists for TG background).
- **HERV-K** — **real numbers now confirmed in all 3 cohorts** (2026-08-16),
  pulled directly via `grep -w 45617 results/bracken_raw_matrix.tsv` (Kraken2)
  and `grep -i 'herv\|endogenous retrovirus' pathseq_abundance_matrix.tsv`
  (PathSeq) against each cohort's real output:

  | Cohort | Kraken2 raw reads (per sample) | PathSeq raw reads (per sample) |
  |---|---|---|
  | CMV Fibroblast (4) | 270, 102, 53, 17 | 256, 58, 34, 8 |
  | TG Ganglia (5) | 1977, 1232, 1163, 1286, 1221 | 162, 114, 592, 356, 178 |
  | EBV Lymphoblastoid (2) | 2549, 2513 | 976, 1158 |

  Present in every cohort at low but real levels — expected for ubiquitous
  low-level HERV-K expression, not tied to any one viral infection (consistent
  with the broader HERV-K project's finding of near-universal detection
  across 9 unrelated cohort groups, see `[[project_hervk_findings]]` memory).

  **Correction to the methodological question raised above**: PathSeq *does*
  model HERV-K — contrary to the hypothesis floated when this row was still
  pending. Notably it uses the **same taxon ID as Kraken2** (`45617`), the
  only taxon in this whole investigation where that's true (every herpesvirus
  needed different IDs per tool due to taxonomy vintage). A clean internal
  consistency check fell out of this too: PathSeq's parent (`206037`, "Human
  endogenous retroviruses"), species (`45617`), and subtype (`166122`, "K113")
  nodes report numerically identical read counts in every single sample
  across all 3 cohorts — meaning essentially all PathSeq HERV-K signal
  resolves unambiguously to the K113 subtype specifically.

  Since HERV-K now has real, complete data, it was folded into each cohort's
  `TOTAL_K2` denominator in the high-resolution figure (see below) per that
  figure's own stated methodology — this shifted the other rows' percentages
  by a negligible amount for CMV/TG (<0.01% relative) but a real ~1.1%
  relative reduction for EBV, whose much smaller total makes HERV-K's
  contribution proportionally more significant there.

## Cross-validation: every cohort checked against every other cohort's expected taxa (2026-08-16)

Every "n/a" cell in the primary-signal block of both heatmaps was, until now, an
*assumption* that a virus wasn't worth checking outside its own cohort — not a
verified negative control. Closed that gap: each of CMV/HSV-1/VZV/EBV was
grepped (both taxon-ID vintages, both tools) against the two cohorts it
*wasn't* the target of, using the same unfiltered `bracken_raw_matrix.tsv` /
`pathseq_abundance_matrix.tsv` outputs as everywhere else in this doc.

**Result: clean except for one real, two-method-corroborated finding.**

| Off-target check | Kraken2 | PathSeq |
|---|---|---|
| VZV, EBV in CMV cohort | 0 reads (both) | 0 reads (both) |
| CMV, EBV in TG cohort | 0 reads (both) | 0 reads (both) |
| CMV, HSV-1, VZV in EBV cohort | 0 reads (all 3) | 0 reads (all 3) |
| **HSV-1 in CMV cohort** | **0, 12, 18, 22 reads (12h→72h)** | **0, 2, 10, 9 reads (12h→72h)** |

HSV-1 (`3050292` Kraken2 / `10298` PathSeq) shows a real, low-level, roughly
increasing signal specifically in the `cmv_fibroblast` time-course — near-zero
at 12h, then rising alongside CMV's own lytic replication kinetics through
24h/48h/72h. Both tools independently show the same shape from the same
underlying reads. At its peak this is ~0.0004% of the cohort's total
Kraken2-positive signal (Kraken2) / ~0.00016% (PathSeq) — trace, not remotely
close to threatening the CMV call — but real and worth a line of
interpretation rather than silent dismissal: **MRC-5** (the fibroblast line
used here, GSE99823/SRP108855) is one of the most widely used human diploid
fibroblast lines in virology specifically *because* it's broadly permissive
for herpesvirus propagation — literature reports HSV isolation rates of
~78–89% in MRC-5 monolayers used for exactly that purpose (see search below)
— so a low-level HSV-1 co-contamination in a CMV-focused lab culture is
biologically plausible on general cell-line-susceptibility grounds, not just
a database artifact. No source specifically documenting HSV-1 contamination
*in this exact dataset* was found — this is general permissiveness evidence,
not dataset-specific confirmation. Worth noting: `hsv1_fibroblast_lytic`
(`PRJNA851702`, still blocked on its FASTQ download — see chat log
2026-08-16) is a *separate, unrelated* study that also independently chose
MRC-5 cells, purely because it's a common line for this kind of work, not
because the two datasets share any lineage. Distinguishing "real trace
co-infection/contamination in this specific cell stock" from "a subtle
cross-mapping artifact between two different herpesvirus genera" would need
read-level BLAST/alignment verification (same standard this project already
applies to any novel finding) before drawing a firm conclusion — flagged
here, not yet resolved.

**Web search** (2026-08-16): no source found documenting HSV-1 contamination
specifically in GSE99823/SRP108855 or in this exact MRC-5 stock. General
literature confirms MRC-5 is a standard, broadly-permissive line for HSV
propagation/isolation (e.g. one study reports 77.8% HSV isolation rate in
MRC-5 vs. 88.9% in Vero cells for the same specimens) — supports biological
plausibility, does not confirm this specific finding.
Sources: [Detection and serotyping of herpes simplex virus in MRC-5 cells](https://ncbi.nlm.nih.gov/pmc/articles/PMC271574), [MRC-5 Cell Line: Human Fetal Lung Fibroblasts in Viral Research](https://www.cytion.com/us/Knowledge-Hub/Cell-Line-Insights/MRC-5-Cell-Line-Human-Fetal-Lung-Fibroblasts-in-Viral-Research/).

Both heatmaps (`docs/figures/kraken_pathseq_concordance_heatmap.{png,pdf}` and
the `highres_` variant) now show this full cross-validated matrix — every
previously-assumed "n/a" cell in the CMV/HSV-1/VZV/EBV block is now either a
confirmed `0%` or, in this one case, a real measured trace value.

## Complete cross-validation fill-in (2026-08-16, continued)

Extended the cross-validation above to *every* taxon in both heatmaps, not
just the primary four — every cross-species artifact and within-genus
background taxon (`cmv_proxy`, `ebv_cross`, `cerco_cmv`, `chimp_cmv`, and the
high-res figure's `hsv2`/`bovine`) checked against all 3 cohorts, both tools.
Two real findings came out of it, plus one taxonomy-naming lesson re-applied
correctly this time:

- **Bovine alphaherpesvirus 1 has a real positive**: 15 Kraken2 reads in TG3
  only, zero in every other sample/cohort (`taxon 3050243`, Kraken2's current
  name `Varicellovirus bovinealpha1` — *not* PathSeq's legacy `Bovine
  alphaherpesvirus 1`/`10320`, same vintage-mismatch pattern as everything
  else in this project). Single-donor, single-tool-dominant, trace-level —
  reads as an incidental low-level background detection, not a systematic
  signal, but real and now on the record.
- **`Cercopithecine betaherpesvirus 5` (PathSeq `50292`) and `Panine
  betaherpesvirus 2` (PathSeq `188763`) do have their own distinct PathSeq
  entries** — the earlier "not broken out by species in PathSeq's own output"
  assumption was wrong; it just required a name-based search (`cercopithecine`/
  `panine`) rather than assuming absence. Real, small, non-zero values in the
  CMV cohort for both.
- **Naming-convention lesson, applied correctly this time**: initial HSV-2/
  Bovine Kraken2 searches used PathSeq's legacy naming style (`Human
  alphaherpesvirus 2`) and came back empty — inconclusive, not confirmed. Kraken2's
  actual current-vintage names (`Simplexvirus`/`Varicellovirus` + host +
  alpha-N, same pattern already established for HSV-1 as `Simplexvirus
  humanalpha1`) were needed to get a trustworthy answer. HSV-2 remains a
  confirmed true-negative everywhere once searched correctly.

**Two cells remain non-numeric by design, not by gap**: `cmv_proxy`'s PathSeq
column in the CMV and TG cohorts (marked `n/a†`) — PathSeq has no taxon
distinct from `10359` representing Kraken2's specific proxy-species artifact,
so the question doesn't have a separate PathSeq answer; the Human CMV row's
own value (real signal in CMV, confirmed 0% in TG) already covers it.

Both `docs/figures/kraken_pathseq_concordance_heatmap.{png,pdf}` and the
`highres_` variant are now fully real, checked data across every cell except
those two.

## Figure: full high-resolution variant with Iadorola TG (2026-08-17)

`docs/figures/full_highres_kraken_pathseq_concordance_heatmap.png` / `.pdf`,
generated by `scripts/make_concordance_heatmap_full_highres.py`. Adds a 4th
real-world cohort — Iadorola et al. human TG (`SRP113004`), scoped to a
5-donor "batch1" subset (TG13, TG3, TG2, TG12, TG4) run ahead of the full
16-donor cohort specifically to get real positive/negative controls sooner.

**Per explicit request, this cohort is two columns, not one** — split by real
Kraken2 dual-DB Tier-1 HSV-1 status, not lumped together:

| Column | Donors | Kraken2 HSV-1 reads | PathSeq HSV-1 reads |
|---|---|---|---|
| Iadorola HSV+ | TG3, TG12, TG4 | 392, 467, 11 (Σ870) | 219, 293, 9 (Σ521) |
| Iadorola HSV− | TG13, TG2 | 0, 0 (Σ0) | 0, 0 (Σ0) |

Full concordance between tools on every donor — both call the same 3 positive
and 2 negative. HSV-1 was the *only* Tier-1/shared taxon in this batch (no
VZV/EBV/CMV cross-mapping, unlike `vzv_hsv1_tg`'s background profile — a
different research group's real cohort, different real biology). HERV-K is
also cross-validated for both new columns (real Kraken2 + PathSeq data) and
is **unusually dominant here** — 61–82% of each column's total signal, vs.
sub-2% in every other cohort in this project. Every other row is `n/a` for
these two columns (not yet cross-validated as off-target in this cohort),
not assumed zero.

**A real column-order bug was caught and fixed before this figure was
built** — worth recording since it nearly produced a false "major
discordance" finding. Three real output files from this one batch use three
different sample column orderings:
- `consensus_matrix.tsv` and `bracken_raw_matrix.tsv`: `TG13, TG2, TG3, TG12, TG4`
  (Nextflow/Bracken's own aggregation order — not alphabetical, not
  samplesheet order)
- `pathseq_abundance_matrix.tsv`: `TG12, TG13, TG2, TG3, TG4` (alphabetical —
  `bin/aggregate_pathseq.py` does `sort_values('sample_id')` +
  `groupby(...)`, and as strings `"TG12" < "TG13" < "TG2"` — the first cohort
  in this whole project where alphabetical order didn't coincide with
  numeric/samplesheet order)

Reading the PathSeq HSV-1 row against the wrong (consensus-matrix) order
initially looked like TG13 was HSV-1-positive-per-PathSeq but negative-per-
Kraken2, and TG3 the reverse — a dramatic discordance that would have been
wrong to report. Caught by demanding an explicit `head -1` on both files
before trusting either, rather than continuing to infer order from
convention. Every number above is header-verified, not assumed.

**Update 2026-08-17: cross-validation gap closed.** Every remaining taxon
(cmv, vzv, ebv, ebv_cross, cerco_cmv, chimp_cmv, bovine, hsv2) checked
against both tools for this batch. All confirmed true-negative except one
real, non-zero finding: **the CMV-proxy artifact (`3050337`) recurs here
too** — 18, 18, 14, 16, 0 reads across TG13/TG2/TG3/TG12/TG4 — a **4th
independent cohort** now showing this same low-titer artifact, after the
original DRG/muscle samples, `cmv_fibroblast`'s absence-as-control, and
`ebv_gm12878`'s trace background. Grouped: HSV+ column (TG3+TG12+TG4) =
0.605% of that column's total; HSV− column (TG13+TG2) = 1.665%. One
false-positive worth remembering for future greps: PathSeq's `10376` hit was
`Cellvibrio` (a bacterial background taxon), not real EBV — its own
read-count *value* happened to contain those digits, same class of
coincidental-substring match already seen once before in `cmv_fibroblast`'s
PathSeq output. Every cell in the figure is now real data except the 4
conceptually-not-applicable `n/a†` cells (PathSeq has no taxon distinct from
`10359` for the CMV-proxy question, in every cohort where that applies).

Also fixed in this pass: the column-header text (cohort names and the
PathSeq/Kraken2 sub-labels) was rendering partly outside the white header
region — it used matplotlib's automatic top-tick mechanism, which anchors to
the axes' physical bounding box rather than a data coordinate. Replaced with
manually-positioned text at a fixed data coordinate (same technique already
used for the cohort-name headers), which reliably keeps both label rows
inside the header band regardless of figure width.

## Figure: per-sample variant (2026-08-17)

Built `scripts/make_concordance_heatmap_full_highres_perpatient.py` →
`docs/figures/full_highres_kraken_pathseq_concordance_heatmap_perpatient.png/.pdf`.
Same 5 cohorts/11-taxon row structure as the full-highres figure, but every
Kraken2/PathSeq column-pair is split into one pair **per sample** (32 data
columns total) instead of summed per cohort — thin dividers between samples,
thick dividers between cohorts, 3-tier header (cohort → sample → method). No
new data gathering: every cell is a re-slice of the same per-donor values
already carried in `K2_RAW`/`PS_RAW`. Normalization changed accordingly: %
is now per-SAMPLE (taxon reads ÷ that sample's own Kraken2 total), not
per-cohort, so per-patient composition differences are visible instead of
pooled away. `RUN_LABEL["tg"]` renamed "TG Ganglia" → "TG VZV/HSV1 Ganglia"
(not propagated to the other two heatmap scripts unless asked). Depledge
cohort's TG3–TG7 column order (undocumented in the parent script) confirmed
via direct ENA filereport lookup (ERR2182863=TG3 ... ERR2182867=TG7) cross-
checked against this cohort's own VZV max/min pattern in the data — both
agree independently.

## Kraken2 vs PathSeq tool-level performance assessment (2026-08-17)

With the per-sample figure giving 162 real, individually-verified
(taxon × cohort × sample) data points (excludes only the 4 structurally
not-applicable `n/a†` cells), computed a direct head-to-head comparison
between the two classification arms — script:
`importlib`-loaded `make_concordance_heatmap_full_highres_perpatient.py`'s
`K2_RAW`/`PS_RAW` dicts directly (zero transcription risk), analysis not
saved as a standalone script (ad hoc, reproducible from the numbers below).

**Sensitivity (does it find the virus that's supposed to be there):**
Both tools **100.0% (19/19)** across every (cohort, taxon) ground-truth
positive instance across all real samples — CMV in all 4 fibroblast
timepoints, HSV-1 + VZV in all 5 Depledge donors, EBV in both GM12878
replicates, HSV-1 in all 3 Iadorola HSV-1+ donors. Neither tool ever missed
an expected virus in any sample in this project to date.

**Specificity (correctly reports zero for background/off-target/other-
cohort's-virus taxa, n=143 expected-negative rows):** Kraken2 78.3%
(112/143), PathSeq 75.5% (108/143) — close, PathSeq marginally noisier.
Both numbers are driven almost entirely by trace-level background (HERV-K,
cross-species CMV/lymphocryptovirus reference matches), not spurious
Tier-1-strength false positives — see the discordance list below for what
actually differs between the two "specificity misses."

**Binary detection agreement:** 152/162 = **93.8%** (both call it
present, or both call it absent). The 10 discordant cells:
- **3 K2-only** (K2>0, PS=0): Bovine alphaherpesvirus-1 in TG3 (15 reads,
  already-documented single-donor trace); CMV-proxy artifact (`3050337`) in
  both `ebv_gm12878` replicates (71, 90 reads) — PathSeq scored a clean zero
  on the same artifact Kraken2 picked up, consistent with PathSeq's k-mer-
  independent alignment approach being less susceptible to this specific
  divergent-reference cross-map, not a PathSeq miss of real biology.
- **7 PS-only** (PS>0, K2=0): 6 are HSV-2 in the Depledge TG cohort (0.5–27
  read-equivalents, TG3–TG7 — PathSeq's alignment scoring can assign
  fractional/sub-integer read-equivalents that Kraken2's stricter k-mer LCA
  floors to a clean zero), plus Bovine alphaherpesvirus-1 in TG5 (3.0) and
  Cercopithecine CMV in `cmv_fibroblast` 72h (0.40). All 7 are trace-level
  homology bleed to same-genus relatives, not evidence of a missed true
  positive either tool should be trusted over the other on.

**Magnitude bias — the single biggest, most consistent difference between
the two tools:** where both detect (n=47), PathSeq's raw count runs
systematically **lower** than Kraken2's — median ratio PS/K2 = **0.383**
(PathSeq ≈ 38% of Kraken2's count), and the effect is *stronger*, not
weaker, on the true-positive rows specifically: median **0.181** (range
0.107–0.818) across all 19 true-positive (cohort,taxon,sample) triples —
i.e. PathSeq typically reports roughly a fifth to a sixth of Kraken2's raw
read count for the actual target virus, every single cohort, every sample,
no exceptions in direction. Background/off-target rows show the same
median-low pattern (0.486) but with far more scatter (range 0.0006–2.819)
and one real exception in the other direction (Chimp/Pan CMV background at
`cmv_fibroblast` 72h, ratio 2.82, PS>K2) — worth remembering as the one
background taxon where PathSeq was more sensitive, not less, than Kraken2.
93.6% of all both-detect pairs have PS/K2 < 1.

**Correlation (despite the magnitude offset):** Pearson r = **0.966** on
log1p-transformed values across all 162 points; Spearman ρ = **0.917**
(p = 1.1e-65). The two tools agree very strongly on rank/relative
abundance even though PathSeq's absolute counts run systematically lower —
consistent with a fixed multiplicative bias (alignment stringency /
score-normalization methodology) rather than the tools disagreeing on the
underlying biology.

**Bottom line:** on this project's 162-point real dataset, Kraken2 and
PathSeq are not two independent opinions that happen to usually agree —
they are extremely well correlated (ρ=0.92) with a strong, consistent
Kraken2>PathSeq magnitude bias (~3–5×, most pronounced exactly on the true
positives) and near-identical sensitivity/specificity profiles. The two
tools' value as a validation pair comes almost entirely from the 100%
sensitivity concordance (neither ever misses the expected virus) and from
the small, low-magnitude discordance set flagging exactly the kind of
trace/artifact signal that shouldn't be over-interpreted either way — not
from independent detection power, since when they disagree it is always at
the sub-1%-of-signal trace level, never on a Tier-1-strength call.

## Open items

- All three cohorts (`cmv_fibroblast`, `vzv_hsv1_tg`, `ebv_gm12878`) now have both
  main-pipeline and PathSeq results — three-way validation complete for HSV-1, VZV,
  EBV, CMV. Next: fold the EBV cross-genus non-reproduction finding into
  `research/cmv_taxonomy_investigation.md` as its own explicit subsection (currently
  only logged here).
- `hsv1_fibroblast_lytic` config ready (`assets/config_hsv1_fibroblast_lytic.yaml`,
  WT-KOS + Uninfected mock pair) but not yet launched.
- `hsv1_npc_timecourse`, `hsv2_cd4t`, `csf_miller_ucsf` still need a subsetting
  decision before a config can be built (53 / 27 / 230 samples respectively).
- `wnv_mouse_brain`, `ev71_gerbil_brainstem` deliberately skipped for now — non-human
  host tissue, this pipeline's `STAR_HOST_REMOVAL` is GRCh38-only (see chat log
  2026-08-15 for the full tradeoff discussion).
- `ebv_btransform`, `ebv_lytic_reactivation`, `jcv_pml_brain`, `zika_organoid` blocked
  on single-end samplesheet support not existing yet.
- `csf_fan_chinacdc` — last remaining dataset from the original 14, download status
  not recently rechecked.
