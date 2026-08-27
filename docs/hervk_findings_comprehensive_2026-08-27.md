# HERV-K Findings — Comprehensive Consolidation (2026-08-27)

**Purpose of this document.** Every HERV-K-related statistical finding this
project has produced, in one place, git-committed, with caveats attached to
every number. Written because Claude's own persistent memory turned out to be
fragmented across two different memory namespaces (a path-casing artifact —
`-mnt-c-Users-mwild-firebase2-virome` vs. `-mnt-c-users-mwild-firebase2-virome`)
that don't share content with each other, discovered 2026-08-27 while
assembling `RESTART_CLAUDE.md`. That's a real loss-of-continuity risk this repo
doesn't have — read this file, not scattered memory notes, for HERV-K status
going forward. Master index: `RESTART_CLAUDE.md`. Siblings:
`docs/claude_access_and_capabilities.md`, `docs/project_status_and_open_items_2026-08-27.md`.

---

## 1. What HERV-K is, in this project's context

Taxon `45617` in both Kraken2's and PathSeq's taxonomies (a rare case where the
two agree on ID — see `docs/pathseq_validation_results_2026-08-15.md`, most
taxa don't). It is an **aggregate k-mer/alignment-level signal for the HML-2
subfamily of human endogenous retrovirus K** — not locus-specific. GRCh38
carries roughly 90 full-length HML-2 proviruses plus ~1,000 solo LTRs at
85–95% sequence identity to each other, so most HML-2-originating reads are
genuine multi-mappers; Kraken2/PathSeq's taxon-45617 count cannot distinguish
"broad derepression across dozens of loci" from "one hyperactive locus
dominating the whole aggregate signal" (see §11).

HERV-K is detected in roughly 90–100% of samples in nearly every cohort this
project has run — it is simultaneously (a) a research target in its own right
(the HSV-1/CMV-proxy correlation work below) and (b) a de facto internal
QC/positive-control signal, since a sample with an unusually low HERV-K value
is itself a flag worth checking (see the `Saad_2`/`104T8R`-class library
failure cross-checks in §10).

---

## 2. Cross-cohort HERV-K level comparisons

**Progression of the cross-cohort comparison as more cohorts were added:**

| Stage | Groups | Test | Result |
|---|---|---|---|
| Original | 5 cohorts | Kruskal-Wallis | H=31.71, p=0.000002 |
| +DPN/RA Kulkarni | 7 groups | Kruskal-Wallis | H=40.03, p=4.5e-7 |
| Split Iadorola TG by HSV-1 status, DPN/control by real condition | 9 groups | Kruskal-Wallis | H=41.81, p=1.5e-6 |
| **After AIG1390 fix** (§3) | 9 groups | Kruskal-Wallis | **H=41.21, p=1.9e-6** (current) |

**Per-cohort summary statistics (HERV-K RPM), original 5-group comparison:**

| Cohort | n | Mean | Median | SD | Notes |
|---|---|---|---|---|---|
| Muscle | 5 | 31.3 | 31.6 | 3.1 | Cohort 1 |
| Early DRG | 16 (→11, see §3) | 49.6 (→51.4) | 49.4 (→49.8) | 24.0 (→28.1) | Cohorts 2–4; SD driven by Saad_4 outlier (115.7 RPM) |
| PD DRG | 20 | 32.7 | 32.8 | 5.3 | Parkinson 2026 cohort — "control" label for 6/20 unconfirmed, see `docs/cohort_registry.md` row 6 |
| Iadorola TG | 16 | 34.3 | 33.6 | 9.4 | Post-mortem TG, public benchmark |
| OSM Juliet DRG | 18 | 48.2 | 45.2 | 8.1 | Cultured DRG cells |
| RA Kulkarni | 10 | 36.1 | 35.5 | 2.8 | Added at 7-group stage |
| DPN/control (mixed) | 15 | 34.7 | 33.8 | 5.5 | Added at 7-group stage; later split into real Healthy(n=10)/DPN(n=5) |

**Significant pairwise comparisons (Bonferroni-corrected):**

| Comparison | p_adj | Sig |
|---|---|---|
| PD DRG vs OSM Juliet | <0.0001 | *** |
| Muscle vs OSM Juliet | 0.0006 | *** |
| Iadorola TG vs OSM Juliet | 0.001 | ** |
| Early DRG vs PD DRG | 0.024 | * (treat cautiously — Saad_4 outlier-driven, see above) |

**Non-significant, biologically informative:** PD DRG vs Iadorola TG (p_adj=1.0),
Muscle vs PD DRG (p_adj=1.0), Muscle vs Iadorola TG (p_adj=1.0) — tissue type
(DRG vs. TG) does not detectably affect HERV-K in post-mortem tissue; the
consistent post-mortem baseline is ~31–34 RPM across three otherwise-unrelated
cohorts.

**Interpretation: cell culture elevates HERV-K, not disease state.** OSM
Juliet (cultured) is significantly higher than every post-mortem group, and
this is not treatment-specific (OSM-treated n=9 vs. vehicle n=9, p=0.791) — it
reflects the in vitro environment itself (stress, passaging), consistent with
known HERV-K activation by generic cellular-stress signals.

**Every disease-specific contrast run in this project to date is
non-significant — state this plainly, it is itself a real finding, not an
absence of one:**
- PD (n=14) vs. "control" (n=6, label unconfirmed): p=0.397
- OSM-treated (n=9) vs. vehicle (n=9): p=0.791
- DPN (n=5) vs. Healthy (n=10, incl. Healthy_D): Mann-Whitney p=0.51, Welch p=0.60
- Iadorola TG HSV-1+ (n=5) vs. HSV-1− (n=11), as a **binary group split**: p_adj=1 (ns) — the HSV-1 relationship only shows up as a **continuous regression** (§4), not a clean positive/negative split, at current sample sizes.

This lab's own cohort history has never once reached significance on a
disease-status-vs-viral/HERV-K contrast — a fact independently flagged by 4/5
departments in the 2026-07-15 STTR grant review (`docs/sttr_intelligence_digest.md`)
as something that must be disclosed, not omitted, in any external-facing use
of this data.

**Rule of thumb for QC**: a new cohort with HERV-K substantially above ~50 RPM
should be checked for in-vitro/culture processing before being treated as a
biological signal; below ~20 RPM may indicate low viral-read recovery/mapping
issues.

---

## 3. The AIG1390 duplicate correction

`AIG1390_L1/L2/L3/L4/T12` are **confirmed byte-for-byte MD5 duplicates of
`donor1_L1/L2/L3/L4/T12`'s FASTQs** (documented back in
`reports/2026-04-04_project_state.md`, Q6 — "The correct AIG1390 FASTQs have
not been obtained from the sequencing provider"). `donor1_L5` has no AIG1390
counterpart, hence 5 matching pairs, not 6. Surfaced originally while
recoloring the "Early DRG" scatter plot by acquisition batch and noticing 5
near-identical value pairs; HERV-K RPM values matched to 4 decimal places,
consistent with literal file duplication, not biological coincidence.

**This was already correctly excluded in the actual paper1 manuscript**
(`research/paper1/manuscript/draft.md`/`outline.md`, "15 usable samples," no
AIG1390) since ~2026-03/04. It was **not** reflected in `docs/cohort_registry.md`
(row 3, written 2026-05-04) for nearly four months, despite being flagged
independently at least three times (2026-03/04 discovery, 2026-07-15 STTR
review, this doc's own note) — **finally fixed 2026-08-27, this session**: row
3 now carries the caveat directly.

**Corrected group**: Early DRG, **n=11** (donor1's 6 + Saad's 5), mean=51.4,
median=49.8, SD=28.1 — higher than the old contaminated n=16 mean (49.6)
because the AIG1390 duplicates were moderate-valued and diluted the mean
toward donor1's non-extreme levels; removing them lets Saad_4's 115.7 RPM
outlier pull the true n=11 mean up further. Updated 9-group KW:
**H=41.21, p=1.9e-6** (previously H=41.81, p=1.5e-6 with the contaminated n=16).

**How to apply**: any future analysis pulling "Early DRG" or the "38-sample
full cohort" (`all_cohort_pluspf`) from raw pipeline outputs must manually
re-exclude `AIG1390_*` — the raw output files themselves do not have this
exclusion applied, only the manuscript-facing analyses and (as of today)
`docs/cohort_registry.md`'s prose do.

---

## 4. HSV-1 ↔ HERV-K relationship — the headline finding and its status

### 4.1 Iadorola TG cohort (public benchmark, LaPaglia et al. 2017 / SRP113004)

- **Linear regression (HERV-K RPM ~ HSV-1 RPM)**: slope=1.377, intercept=31.78,
  Pearson r=0.678, **R²=0.459, p=0.0039, n=16** (5 HSV-1 Tier-1-positive: TG3,
  TG4, TG8, TG10, TG12). Script: `results/iadorola_tg/hsv1_hervk_analysis.py`;
  report: `results/iadorola_tg/hsv1_hervk_analysis.pdf`.
- **Binary group comparison (HSV-1 positive n=5 vs. negative n=11) is NOT
  significant**: Welch's t=1.73, p=0.1044; Mann-Whitney p=0.2674. Only the
  continuous regression is significant — the relationship shows up as a
  dose-response trend, not a clean positive/negative split, driven by the two
  highest-HSV-1 samples (TG12 at 14.7 RPM, TG3 at 12.5 RPM) also having the
  highest HERV-K values (58.4 and 41.6 RPM respectively).
- Mechanistic hypothesis (not confirmed in DRG/TG specifically): HSV-1 ICP0
  transactivates HERV-K LTRs. LAT abundance during latency may reflect ICP0
  expression episodes or independently modulate HERV-K via chromatin
  remodeling. Novel relative to LaPaglia et al. 2017, which reported both
  HSV-1 and HERV-K but did not analyze their relationship.

### 4.2 ⚠ CRITICAL, unresolved caveat — read this before citing R²=0.459 anywhere external

**This number has NOT survived a PMI/RIN/batch confound test**, per the last
check against `HERVK/synthesis/synthesis_v1.md` (the HERV-K thesis project's
own critical-advisor review). This is the single most-repeated caveat across
every STTR-grant-adjacent review of this finding (5 independent department
reviews in the 2026-07-15 digest all flag it; see
`docs/sttr_intelligence_digest.md` §4/§Cross-department synthesis). **Treat
R²=0.459 as not-yet-externally-citable as validated** until that confound test
is actually run. It is this project's strongest, most-cited number and its
weakest-verified one simultaneously — do not let the former obscure the
latter.

### 4.3 2026-08-19 batch replication — `thoracic_drg` cohort (this lab's own data)

- **R²=0.241, p=0.0148, n=24** — an independent second cohort, own data (not a
  public benchmark), same positive direction as Iadorola TG.
- **The same confound-test gap applies here too, and has not itself been
  closed** — this replication is new since the confound-test caveat was first
  raised against the original Iadorola number, and has not itself been tested
  for PMI/RIN/batch effects. Do not treat this replication as having cleared
  the bar the original finding didn't clear — it hasn't been checked against
  that bar at all yet.

### 4.4 Family-broadening result — argues for HSV-1 specificity, not generic herpesvirus effect

Broadening the predictor from HSV-1 species-level to the full herpesvirus-family
signal present in a cohort (adding cross-species Simplexvirus
atelinealpha1/paninealpha3 candidates and Rhadinovirus saimiriinegamma2)
**weakens** the relationship, does not strengthen it:
- `thoracic_drg`: R² 0.241 → 0.217
- `rejoin_jayden`: R² 0.067 → 0.056 (already n.s. before broadening)

This argues the effect is specific to HSV-1 (or specifically Simplexvirus
humanalpha1), consistent with a virus-specific protein interaction (e.g. an
ICP0-type mechanism) rather than a generic "any herpesvirus present" effect.

### 4.5 Power limitation — state plainly

Only 2 of the 2026-08-19 batch's 11 cohorts had enough HSV-1-positive samples
to test a regression at all (`thoracic_drg`, `tg_2018_emma_nih`); every other
cohort had 0–1 positive samples, untestable. This is a real, current
statistical-power ceiling on this line of work, not a methodological choice.

---

## 5. CMV-proxy ↔ HERV-K relationship

Taxon `3050337` ("Human CMV (HHV-5) [proxy]" per `assets/taxon_remap.tsv`) is
present in **every one of 160 samples across all 11 cohorts** — unlike HSV-1,
testable everywhere.

**Per-cohort HERV-K ~ CMV-proxy regression, all 11 cohorts:**

| Cohort | n | R² | p |
|---|---|---|---|
| watchmaker | 24 | 0.488 | 0.0001 |
| thoracic_drg | 24 | 0.376 | 0.0014 |
| osm_juliet | 18 | 0.301 | 0.0184 |
| adult_infant_soma_axon | 10 | 0.660 | 0.0043 |
| unknown_doloromics | 7 | 0.972 | <0.0001 (small n, caveat) |
| mgoexplant_saad | 6 | 0.665 | 0.0480 |
| osmexplant_juliet | 7 | 0.516 | 0.0689 (borderline) |
| dpn_ra_kulkarni | 25 | 0.019 | 0.506 (n.s.) |
| rejoin_jayden | 17 | 0.005 | 0.782 (n.s.) |
| osmcultured_juliet | 6 | 0.144 | 0.458 (n.s.) |
| tg_2018_emma_nih | 16 | 0.062 | 0.351 (n.s.) |

**11/11 cohorts have a positive slope — no exceptions.** Under a true null,
~half would be expected positive/half negative across 11 independent cohorts;
11-for-11 in the same direction is itself informative regardless of
individual-cohort significance.

**Pooled**: R²=0.382, p<0.000001 raw (not z-scored); within-cohort z-scored
r=0.483, **R²=0.233, p=9.8e-11**; Spearman ρ=0.735, p<0.000001.

**Confound tests already run and passed** (within-cohort z-scored to remove
between-cohort baseline differences first):
- NOT explained by total *other* viral RPM background: r=−0.207 (weak,
  actually negative — rules out "more background noise generally = higher
  HERV-K")
- NOT explained by generic per-sample depth/quality: CMV-proxy vs. total other
  viral RPM, r=−0.038, p=0.635 (n.s. — if CMV-proxy were just tracking
  per-sample depth/quality it should correlate with everything else too, and
  it doesn't)
- Partial correlation of HERV-K~CMV-proxy controlling for total other viral
  RPM: r=0.486, R²=0.236, p=7.2e-11 — essentially unchanged from raw. The
  relationship is not explained by a shared depth/noise confound.

### 5.1 ⚠ Identity caveat — do not present this as legitimate human CMV

Taxon `3050337` is a **Kraken2 LCA artifact**: reads assign to a baboon CMV
reference (`Cytomegalovirus papiinebeta3`, via child taxon `2169863`) because
the Kraken2 viral DB has no direct HHV-5/human-CMV node at that position — per
`assets/taxon_remap.tsv`'s own documentation, "genuine identity not yet
confirmed... awaiting alignment-based validation." Separately, and more
decisively: **PathSeq's real, validated CMV-positive run** (`cmv_fibroblast`
cohort, `research/cmv_taxonomy_investigation.md`'s 2026-08-15 update) found
genuine human CMV lands on a **completely different taxon** — PathSeq's own
2017-vintage taxonomy calls it `10359`/`3050295` ("Cytomegalovirus
humanbeta5"/"Human betaherpesvirus 5"), and taxon `3050337` **does not appear
at all** in that run's output; its 2017 reference predates the `3050337` ICTV
ID entirely.

The user is on record as **"very confident it is not legitimate human CMV"**
(stated directly, 2026-08-27 synopsis) and has **directed this not be
incorporated as a legitimate finding in external-facing documents** — the SfN
abstract draft and the pptx deck built this same session both deliberately
exclude CMV-proxy entirely, in either direction (not asserted positive, not
asserted negative).

**Two live, undistinguished hypotheses** for what the CMV-proxy/HERV-K
correlation actually reflects, neither confirmed:
(a) CMV's own IE1 protein has documented transactivation activity in other
contexts (not confirmed against HERV-K LTRs specifically) — a real,
CMV-proxy-specific mechanism, distinct from HSV-1 ICP0's;
(b) a remaining, not-yet-caught classification artifact, despite the two most
obvious confounds (depth/quality, generic viral background) being directly
ruled out above.

### 5.2 Contrast with §4.4's family-broadening result

CMV is a *different* herpesvirus (not Simplexvirus/Rhadinovirus) and its
relationship to HERV-K is, if anything, the single strongest and most
consistent one found in this project — the opposite of what happened when
HSV-1 was broadened to its own close relatives (§4.4). This asymmetry is
itself interesting but unexplained.

---

## 6. The BeAn-58058-virus (taxon 67082) finding

`BeAn 58058 virus` (taxid `67082`, already in `assets/artifact_taxa.tsv` as
"misclass: unclassified rodent virus, likely host reads misassigned at low
confidence," prevalence 148/160 — nearly as universal as HERV-K's own 145/160)
correlates with HERV-K at **r=0.489, R²=0.239, p=5.4e-11** (within-cohort z) —
nearly identical in strength to the CMV-proxy result. Ran the identical
confound-check as CMV-proxy: uncorrelated with generic other-viral background
(r=0.007, p=0.93 — not a depth/noise confound), partial correlation controlling
for that background essentially unchanged (r=0.510).

**Important caveat, not an independent third finding**: BeAn-58058 and
CMV-proxy are themselves strongly correlated with each other (**r=0.586,
p=3.75e-16**) — they are likely capturing overlapping aspects of the same
underlying phenomenon (both near-universal, low-confidence misclassification
bins), not two separate corroborating lines of evidence. **Treat as one
candidate signal with two names, not two.**

---

## 7. The watchmaker cross-mapping artifact and its fix

`watchmaker` initially looked like a *negative* HERV-K/"other-virus" tradeoff
(aggregated across all non-HERV-K taxa in that cohort's filtered matrix:
R²=0.40, p=0.0009, negative slope). Root-caused directly: every individual
murine/animal-retrovirus-family taxon in that cohort (Mus musculus mobilized
endogenous polytropic provirus, Murine leukemia virus, Mouse mammary tumor
virus, etc. — sharing Gag/Pol homology with HERV-K) is itself strongly,
individually anti-correlated with HERV-K (R² 0.27–0.52 each) — classic
k-mer/LCA classification competition, not biology.

**Fix required taxon-ID-based exclusion, not name-substring matching** — the
biggest contributor, "Mus musculus mobilized endogenous polytropic provirus"
(taxid `590745`), does not contain the literal substring "retrovirus," so a
naive name-pattern filter misses it. Excluding this taxon family properly (by
ID) **flips the sign**: R²=0.40→0.36, slope −0.027→+0.38, now consistent with
every other cohort's positive direction.

**Full taxon-ID list involved**: `590745`, `11786`, `11819`, `353765`,
`99182`, `11757`, `11809`, `11878`, `39746`, `11970`, `11884`.

**⚠ Real, actionable, currently-live pipeline gap — not yet applied**: these
specific taxa are **not** in `assets/artifact_taxa.tsv` (only a smaller,
related subset — `11788`/`11780`/`11807` — is already there). The full family
is currently contaminating the "final filtered" `viral_abundance_matrix.tsv`
output every downstream analysis (including this project's own) otherwise
treats as clean, concentrated overwhelmingly in `watchmaker` specifically.
**Offered to the user multiple times across this project's history; not yet
approved/applied as of 2026-08-27** — ask before doing it, since it changes
the curated exclusion list used for all cohorts.

**Independently reconfirmed at full-dataset scale** via the 2026-08-19 batch's
own murine-retrovirus recurrence in `dpn_ra_kulkarni` and `unknown_doloromics`
Tier-1 lists (specifically `590745` again) — **3 unrelated cohorts now**
carrying this same artifact family, strengthening the case that it's a
recurring database/k-mer cross-mapping phenomenon (same class as the
already-curated hantavirus/orthobunyavirus entries), not isolated
watchmaker-specific reagent contamination as first suspected.

---

## 8. Full taxon-taxon correlation heatmap findings (2026-08-23/24/27)

Four heatmap variants exist, all in `results/figures/`, all Spearman
correlation on within-cohort z-scored RPM, hierarchically clustered:

| Heatmap | Taxa | File | CMV-proxy included? |
|---|---|---|---|
| Full pan-taxa | 28 (≥10/160 samples) | `taxon_correlation_heatmap_2026-08-23.png` | Yes |
| Mammal-only subset | 13 | `mammal_taxon_correlation_heatmap_2026-08-23.png` | Yes |
| Human + Excel-tracked | 8 | `human_excel_taxon_correlation_heatmap_2026-08-24.png` | Yes |
| **Excel-tracked only (clean)** | 7 | *(built 2026-08-27, this session, for the pptx deck — see `docs/presentations/`)* | **No — deliberately excluded** |

**Three-cluster structure**, confirmed consistently across the pan-taxa and
mammal-only variants:
1. **HERV-K / BeAn-58058 / CMV-proxy block** (r=0.50–0.64) — the "near-universal,
   low-confidence" cluster described in §5/§6.
2. **Ruminant/rodent zoonotic contamination block** — `Orthohantavirus
   oxbowense`, `Orthobunyavirus schmallenbergense`/`simbuense`,
   `Betabaculovirus chofumiferanae` (r=0.5–0.88 mutually) — four taxa from
   three unrelated viral families, each already independently documented in
   `artifact_taxa.tsv` as its own separate contamination phenomenon, but too
   tightly mutually correlated to be coincidence. Points to **one shared
   upstream contamination event/batch**, not four independent problems.
   Similarly, `Andhravirus andhra` (plant Tospovirus, TG5 index-hopping
   outlier) correlates with `Escherichia virus DE3` (phage) at r=0.498 —
   consistent with the same index-hopping/batch explanation extending further.
3. **Feline/murine/simian sarcoma-virus retroviral-artifact family** (weaker,
   r=0.2–0.35) — the §7 watchmaker artifact family, diluted (not absent) at
   pooled scale since most cohorts don't carry that contamination.

**Molluscum contagiosum's reliability takes a further hit**: correlates
significantly with several taxonomically unrelated categories — positively
with `Pandoravirus neocaledonia` (r=0.442; plausibly real, both are giant-DNA-
virus/NCLDV-adjacent, a genuine shared-lineage explanation) but also with two
unrelated phages (`Colossusvirus PW` r=0.416, `Oceanusvirus kaneohense`
r=0.368) and negatively with `Orthohantavirus oxbowense` and Snyder-Theilen
feline sarcoma virus. Correlating promiscuously across several unrelated
categories rather than cleanly with one explicable partner is consistent with
Molluscum's own detection being partly driven by generic per-sample
background/complexity in a subset of noisier samples — **this project's least
reliable target taxon**, a standing caution, not a new finding here.

**The clean 7-taxon Excel-only heatmap** (built 2026-08-27, no CMV-proxy) has
its own leaf order and stats — see the pptx deck build notes
(`docs/presentations/drg_virome_preliminary_results_2026-08-25.pptx`) for the
exact figure; within that restricted 7-taxon set, HERV-K's own pairwise
correlation with any single tracked taxon is weak/non-significant when pooled
across all 11 cohorts (HERV-K↔HSV-1 pooled: r=0.135, p=0.088, not significant
at BH-FDR) — this is expected and does not contradict §4's per-cohort finding,
since §4's significant regressions are **per-cohort**, not the global pool,
and this heatmap deliberately omits CMV-proxy, which was the dominant
predictor in the combination sweep (§9).

---

## 9. The multi-taxon combination result (2026-08-24, re-verified 2026-08-27)

Tested every combination of a 5-taxon panel (HSV-1, Simplexvirus
atelinealpha1, Rhadinovirus saimiriinegamma2, AAV, Molluscum contagiosum —
Simplexvirus paninealpha3 dropped as the weakest-contributing taxon per an
earlier iteration) as a joint within-cohort-z-scored predictor of HERV-K, 31
non-empty combinations, Pearson r/R²/p per combination, BH-FDR (monotone) and
Bonferroni q-values.

**Strongest combination**: **HSV-1 + AAV + Molluscum contagiosum**, r=0.243,
**R²=0.059, p=0.00198**, survives BH-FDR (**q≈0.0498**, i.e. just under 0.05 —
borderline, not a comfortable margin). 4 of 31 combinations survive BH-q<0.05
overall (top 4 all contain HSV-1 + at least one of AAV/Molluscum).

**Re-verified directly from source matrices 2026-08-27** (this session, not
just pulled from the earlier PDF) — the exact monotone-BH-q computation
matches `results/figures/hervk_taxa_combination_table_2026-08-24.pdf` to 4
decimal places. Source data: `results/bracken_raw_2026-08-19_batch/<cohort>/results/bracken_raw_matrix.tsv`,
all 11 cohorts, `unknown_doloromics` sample `4A-R` excluded throughout.

**Interpretation caution, not yet independently confirmed**: HSV-1, AAV, and
Molluscum are not neighbors on the correlation heatmap's clustering (§8) — an
argument this combination isn't simply "HSV-1 under three names" via
cross-mapping, but this has not been tested any more rigorously than that
visual/clustering argument.

**⚠ CMV-proxy was also tested in this combination sweep, and the result was
deliberately NOT published** — flagging here so a future session doesn't
rediscover it from scratch and accidentally re-surface it without this
context. Adding CMV-proxy as a 6th taxon: it is the single strongest
individual predictor of HERV-K (**r=0.483, R²=0.233, p=9.78e-11** — consistent
with §5's number), and it **dominates every combination it's added to** — all
32 CMV-proxy-containing combinations outperform all 31 non-CMV combinations,
and adding CMV-proxy to any existing combination only ever dilutes (never
improves) that combination's correlation with HERV-K. This computed result
exists (scratchpad only, not committed to any figure) but was suppressed per
the user's explicit "do not incorporate cmv" direction, consistent with §5.1's
identity caveat — do not re-surface it in an external-facing artifact without
re-raising that context with the user first.

---

## 10. The 2026-08-19 batch's independent screen findings

Sample-by-sample, zero-threshold (`bracken_raw_matrix.tsv`, no `min_reads`, no
artifact exclusion) screen, 154–160 samples across 11 cohorts (`4A-R` excluded
from `unknown_doloromics` post-hoc, see PathSeq OOM root-cause work in
`docs/cohort_registry.md`).

- **HERV-K**: 90–91% overall positivity (140/154 in the 10-cohort snapshot,
  consistent with the pattern in §2). Still Tier 2/3 (single-DB) status in
  every cohort checked — never reached Tier 1 (dual-DB consensus) status in
  any cohort. Plausible mechanism, not just an observed pattern: PlusPF (DB2)
  includes a human genome reference DB1 (viral-only) doesn't, so the same
  STAR-unmapped reads DB1 calls `unclassified` get correctly reclaimed as
  human by DB2 instead — leaving little room for a low-abundance viral call in
  the same read pool. A structural property of the dual-DB design as applied
  to a low-abundance signal like HERV-K, not a DB1 classification error. Spot
  check: a `dpn_ra_kulkarni` sample's DB2-branch raw output was 99.86%
  classified `Homo sapiens`.
- **HSV-1 genus positivity concentrates in TG tissue**: `tg_2018_emma_nih`
  hit 5/16 (31%) — the **exact same rate** as the independent Iadorola TG
  cohort (also 5/16=31%, §4.1). Two independent TG cohorts landing on an
  identical positivity rate is a real consistency check, matching expected
  biology (TG is the classic anatomical site for HSV-1 latency).
- **VZV/CMV(genus)/EBV/HHV-6/7/8(direct): zero positives across all samples,
  even at zero threshold** — not a filtering artifact; these taxa don't
  appear even as zero-count rows in most cohorts, meaning Kraken2/Bracken
  never classified a single read to them.
- **Broader neurotropic/systemic virus panel, separately checked, zero
  threshold, same cohorts: completely clean, no hits at all.** HIV, all
  coronaviruses (incl. SARS-CoV-2), hepatitis A–E, poliovirus/enterovirus,
  rabies/lyssavirus, West Nile virus, JC polyomavirus, measles/mumps, Zika —
  worth recording as a real negative with the same weight as the VZV/EBV
  absence, not "not checked."
- **Cross-species Simplexvirus atelinealpha1/paninealpha3 and Rhadinovirus
  saimiriinegamma2 candidates are not yet resolved as artifact vs. real
  signal.** Structurally identical situation to the CMV-proxy cross-mapping
  case (§5.1) — the same investigation methodology
  (`methodology_taxonomy_investigation.md`'s protocol: confirm Kraken2 vs.
  Bracken origin, check library/seqid2taxid/nodes.dmp, rule out reagent/MIEP-
  style contamination first) would apply but has not been run for these taxa.
  One suggestive data point: Thoracic DRG's `80T2R` and `unknown_doloromics`'s
  `2A-R` both show co-occurring human HSV-1 signal *and* `Simplexvirus
  atelinealpha1` signal in the same sample — seen twice now, consistent with
  (but not proof of) divergent-read k-mer splitting of a real HSV-1 signal,
  rather than two independent findings.
- **Full "vir"-substring inventory** across all cohorts surfaced ~130 distinct
  taxa, mostly expected viral-metagenomics background. Two items worth
  keeping separate from the rest: (1) the murine-retrovirus finding (§7) is
  not 1–2 isolated taxa but **15+ distinct animal retrovirus/sarcoma-virus
  names together** (murine, feline, avian, monkey leukemia/sarcoma viruses,
  plus genus-level `Alpha`/`Beta`/`Gammaretrovirus` hits) — one underlying
  cross-mapping phenomenon via Kraken2 LCA across the whole Retroviridae tree,
  not 15 separate contamination events; (2) Molluscum contagiosum (`10279`)
  is a real, common human-infecting poxvirus, not an artifact candidate like
  the rest of the list — see §8's reliability caveat, but its presence itself
  is not disputed.

**Consistency/QC cross-checks that held up**: `mgoexplant_saad`'s `Saad-2`
shows zero HERV-K even at raw threshold, independently confirming the
pre-existing "Saad_2 known library failure" flag via a completely different
pipeline run. `101T5L`'s 146-read HSV-1 count matched exactly between this
aggregated matrix and its own raw per-sample Kraken2 report pulled
separately — a good end-to-end data-integrity signal.

---

## 11. Telescope locus-level quantification — the gating experiment, not yet run

**Why it matters.** GRCh38 carries ~90 full-length HML-2 proviruses plus
~1,000 solo LTRs at 85–95% sequence identity between full-length copies — most
HML-2-originating reads are genuine multi-mappers, not an alignment artifact.
Only a handful of loci (K108, K109, K113, K102/K115) are known to produce
protein; the LTR5Hs subtype (intact NF-κB sites) is the plausible
HSV-1-responsive set. Kraken2/PathSeq's taxon-45617 aggregate cannot
distinguish "broad derepression across dozens of loci" from "one or two
hyperactive loci driving the whole signal" — materially different biology
either way, and **every current HERV-K finding in this project (the §2
Kruskal-Wallis result, the §4/§5/§9 regressions) is currently blind to that
distinction.** `HERVK/experimental_roadmap.md` calls this the Phase 1 gating
experiment: WGCNA, the PMI/age/RIN confound regression (§4.2's missing test),
ISG correlation, and any ComBat-style cross-cohort meta-analysis all take its
output as input.

**Concrete technical blocker already identified (2026-08-18)**:
`modules/star_host_removal.nf` runs `--outFilterMultimapNmax 1`
(uniquely-mapped reads only) — precisely the anti-pattern
`HERVK/background/hervk_biology.md` §7.1 names as the standard failure mode
for HERV quantification. The host-mapped BAM this pipeline produces today is
**not usable for Telescope as-is**; a locus-level Leg 2 needs its own STAR
re-alignment with `--outFilterMultimapNmax 100 --outSAMmultNmax 100`, not a
reuse of Leg 1's alignment.

**Agreed architecture (2026-08-18, user-approved, not implemented)** —
two-leg design:
- **Leg 1 (unchanged, runs on everything)**: the existing Kraken2/PathSeq
  taxon-45617-level pipeline exactly as it works today. No change to
  `main.nf`/`workflows/virome.nf`.
- **Leg 2 (new, opt-in, post-hoc)**: a Telescope-based offshoot, structurally
  a sibling to `blast_verify.nf`/`pathseq_verify.nf` — not a routine
  per-cohort arm. Triggered selectively on samples/cohorts where the
  aggregate signal is itself interesting enough to warrant locus-level
  resolution — e.g. the HSV-1-positive Iadorola/`thoracic_drg` donors feeding
  §4's regressions, or any cohort with an anomalous aggregate HERV-K reading
  (e.g. Iadorola's anomalous 61–82% PathSeq HERV-K dominance found
  2026-08-17, vs. sub-2% in every other cohort — see
  `docs/pathseq_validation_results_2026-08-15.md`).

**Not yet started**: no `telescope_verify.nf`, no container, no reference
bundle pulled — this is an agreed plan, not an implementation. Full technical
spec: `HERVK/experimental_roadmap.md` Phase 1 Experiment 1.

---

## 12. Bottom line — how to use this document

**Solid, well-supported findings** (multiple confound tests passed, or a real
negative confirmed at zero threshold across many samples):
- The null track record on every disease-specific contrast run to date (§2) —
  itself a real, disclosure-worthy finding.
- VZV/EBV/CMV(genus)/HHV-6/7/8(direct) complete absence, plus a broad
  unrelated-virus panel, across 154–160 samples at zero threshold (§10).
- HSV-1-species-specificity vs. family-broadening contrast (§4.4) — a
  specific, not generic, herpesvirus effect.
- CMV-proxy/BeAn-58058's correlation with HERV-K surviving two independent
  confound tests against sequencing depth/generic viral background (§5, §6) —
  though what the correlation *means biologically* remains genuinely
  undetermined (§5.1).
- The watchmaker cross-mapping artifact, root-caused and demonstrated fixable
  by taxon-ID exclusion (§7) — mechanistically understood, just not yet
  applied to the curated exclusion list.

**Promising but not yet independently validated:**
- The HSV-1↔HERV-K dose-response relationship (§4) — real in two independent
  cohorts now, but **neither instance has passed a PMI/RIN/batch confound
  test**, the single most consequential open item in this whole document.
- The HSV-1+AAV+Molluscum combination result (§9) — passes BH-FDR only
  narrowly (q≈0.05), and the "not the same signal three ways" argument rests
  on heatmap clustering, not a dedicated statistical test.

**Actively misleading if taken at face value:**
- CMV-proxy (taxon `3050337`) presented as literal human CMV — it isn't (§5.1);
  keep it out of external-facing artifacts per the user's explicit direction
  until/unless independently BLAST/alignment-confirmed.

**Highest-value next computational step**: Telescope locus-level
quantification (§11) — described by this project's own thesis-synthesis
document as gating essentially every higher-order HERV-K analysis that would
follow it.

**Cheapest unfinished fix, data-hygiene not research**: add the 11 murine/
animal-retrovirus taxa (§7) to `assets/artifact_taxa.tsv` — mechanistically
understood, reconfirmed in 3 independent cohorts, offered to the user
multiple times, just needs a go-ahead.
