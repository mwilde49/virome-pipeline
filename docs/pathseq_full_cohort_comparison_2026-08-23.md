# PathSeq full-cohort batch — results and Kraken2 comparison

**2026-08-23.** Companion to the "Results (2026-08-23)" note in
`docs/cohort_registry.md`'s PathSeq section — this doc is the actual
per-cohort/per-taxon findings; that one covers launch mechanics and the
`unknown_doloromics`/`4A-R` saga in more operational detail.

## Status: all 11 cohorts complete

| Cohort | n | PathSeq | Duration |
|---|---|---|---|
| thoracic_drg | 24 (23 w/ PathSeq) | ✅ | 1d 16h 53m |
| watchmaker | 24 | ✅ | 1h 22m |
| adult_infant_soma_axon | 10 | ✅ | 6h 51m |
| mgoexplant_saad | 6 | ✅ | 42m |
| tg_2018_emma_nih | 16 | ✅ | 1h 22m |
| osmexplant_juliet | 7 | ✅ | 12m 33s |
| osmcultured_juliet | 6 | ✅ | 35m 2s |
| dpn_ra_kulkarni | 25 | ✅ | 1h 53m 33s |
| osm_juliet | 18 | ✅ | 47m 2s |
| rejoin_jayden | 17 | ✅ | 18m 2s |
| **unknown_doloromics** | 8 → **7** | ✅ | 1m 2s (after excluding `4A-R`) |

`unknown_doloromics` took three attempts. First: 7/8 samples' `PATHSEQ_SCORE`
tasks completed (one, `2A-R`, alone took 12h26m); the 8th (`4A-R`) OOM-killed
after 11 minutes (SLURM `State=OUT_OF_MEMORY`, exit `0:125`), aborting the
whole run before `AGGREGATE_PATHSEQ` could run. Second: retried with a
one-off 340GB override (+70% over the standard 200GB) — OOM-killed again,
barely later (12m30s vs. 11min), the tell this wasn't a fixed memory
shortfall. Root cause, found by checking `4A-R`'s own Kraken2
classification directly: **99.3% of its classified reads (6.77M of 6.82M)
are three taxa already documented in `assets/artifact_taxa.tsv`** as
reagent/cross-mapping contaminants (`Orthobunyavirus schmallenbergense`,
`Orthobunyavirus simbuense`, `Betabaculovirus chofumiferanae`) — real biology
(HERV-K) is 3,513 reads underneath that noise. Kraken2's own pipeline already
excludes these three via `artifact_taxa.tsv` (why `4A-R`'s filtered Kraken2
results, in the tracking workbook, are fine); PathSeq has no equivalent
pre-filter and pays BWA-MEM's alignment cost for millions of
highly-repetitive contaminant reads — a multi-mapping memory blowup, not a
proportional-to-input-size requirement (hence why +70% memory barely moved
the failure point). `4A-R` is now excluded from the PathSeq samplesheet and
from all tracking (same treatment as `104T8R`/`Saad_2` elsewhere in this
project); the third attempt, on the remaining 7 samples, completed in 1m2s.
Full detail: `docs/cohort_registry.md`'s PathSeq results section.

## Cross-method comparison — Kraken2 (bracken_raw) vs. PathSeq

Both methods classify the same STAR-unmapped read pool per sample, so a
direct read-count comparison is meaningful: Kraken2 is k-mer classification,
PathSeq is BWA alignment against a taxonomy-wide microbe reference —
genuinely independent methods. PathSeq's reference is RefSeq 81 (2017), so
two taxa carry older taxon IDs there: HSV-1 is `10298` (vs. Kraken2's
`3050292`, same virus pre-/post- ICTV rename) and Rhadinovirus
saimiriinegamma2 is `10381` (vs. Kraken2's `3050350`). The two cross-species
Simplexvirus candidates (atelinealpha1, paninealpha3) have no identifiable
equivalent in PathSeq's 2017 taxonomy at all.

**Aggregate agreement, all 159 comparable samples across all 11 cohorts
(`4A-R` excluded, see above):**

| Taxon | Agreement | Both+ | Both− | Kraken2-only | PathSeq-only |
|---|---|---|---|---|---|
| **HERV-K** | **98.7%** | 145 | 12 | 0 | 2 |
| HSV-1 | 98.7% | 10 | 147 | 0 | 2 |
| AAV | 98.1% | 1 | 155 | 0 | 3 |
| Rhadinovirus saimiriinegamma2 | 86.2% | 1 | 136 | 0 | 22 |
| Molluscum contagiosum | 85.5% | 4 | 132 | 10 | 13 |

### HERV-K — the headline result: as close to perfect as this gets
Zero Kraken2-only misses across all 159 samples — PathSeq never fails to
confirm a Kraken2 HERV-K call. Read counts track proportionally (PathSeq
consistently ~45-70% of Kraken2's count per sample) rather than being
identical, exactly the signature of two independently-calibrated methods
agreeing on a real signal. This is the strongest possible third-opinion
corroboration for the primary DRG HERV-K finding.

### HSV-1 — clean, plus new leads confirmed
Every previously-known Kraken2 HSV-1 positive is confirmed by PathSeq,
**including a brand-new one**: `unknown_doloromics 2A-R` (279 Kraken2 reads,
flagged earlier this batch as a new candidate) is now PathSeq-confirmed
almost exactly — 276 reads. Also `rejoin_jayden 473-3` (74 PathSeq reads vs.
48 Kraken2 — a real, corroborated hit). One PathSeq-only trace hit worth a
BLAST check rather than dismissing: `thoracic_drg 106T3L` (10 reads).

### AAV — sparse but clean where it matters
Only one real, both-positive hit (`thoracic_drg 109T3`, 17 Kraken2 / 23
PathSeq reads). Three new PathSeq-only trace hits in `dpn_ra_kulkarni`
(2-5 reads each) — low-confidence, not corroborated by Kraken2.

### Rhadinovirus saimiriinegamma2 — PathSeq shows a diffuse background signal
Only one genuine both-positive agreement (`rejoin_jayden 473-10`, 14 Kraken2
/ 10 PathSeq reads — the pre-existing known hit). The other 22 PathSeq-only
hits are overwhelmingly low-count (5-10 reads) and appear in 16 of
`rejoin_jayden`'s 17 samples — a near-universal, low-level signal Kraken2
never sees at all. That pattern (diffuse, low-magnitude, present almost
everywhere in one cohort) reads more like PathSeq-side background/cross-
mapping noise for this specific taxon than 16 independent genuine
detections. Treat PathSeq positives for this taxon with real skepticism
outside the one Kraken2-corroborated sample.

### Molluscum contagiosum — the weakest-supported taxon in the whole panel
Worth being direct: this is not a clean corroboration in either direction.
10 Kraken2-only misses (including `osmcultured_juliet`'s striking 6/6
within-cohort penetrance from the last check-in — PathSeq confirms only 1 of
those 6, at just 2 reads) plus 13 PathSeq-only trace hits Kraken2 never saw.
Neither direction is reliable here. This taxon needs BLAST verification
before any confidence statement beyond "detected by at least one method
somewhere" — the `osmcultured_juliet` "universal" signal flagged as
noteworthy before this batch ran has not held up under a second method.

## Not yet cross-checkable
The two cross-species Simplexvirus candidates (atelinealpha1, paninealpha3 —
no PathSeq/RefSeq-81 equivalent found) remain outside this comparison. Every
cohort's PathSeq run is otherwise complete.

## Source data
- Kraken2: `results/bracken_raw_2026-08-19_batch/<cohort>/results/bracken_raw_matrix.tsv`
- PathSeq: pulled via the read-only Juno key from
  `/scratch/juno/maw210003/virome_pathseq_<cohort>/pathseq_verification/pathseq_abundance_matrix.tsv`
- Full per-sample detail: `docs/neurotrophic_virus_tracking.xlsx` (`Summary`,
  `By Sample`, `PathSeq` sheets)
