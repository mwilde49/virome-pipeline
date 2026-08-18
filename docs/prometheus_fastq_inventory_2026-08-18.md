# Prometheus DRG Bulk RNA-seq FASTQ Inventory (2026-08-18)

Source: `fastqs.txt` (repo root, UTF-16LE, CRLF — Windows `dir`-style recursive
listing scraped via PowerShell from the mounted Prometheus `z:\data\` share,
per the user). Root scanned: `z:\data\homo_sapiens\Dorsal_root_ganglia\bulk_rnaseq\`.
Parsed with an ad hoc script (not committed — trivial to regenerate from
`fastqs.txt` if needed): 547 raw lines → 94 directories → 453 file paths.

**Purpose:** the user has been tasked with pushing all of these samples
through this pipeline's virus-detection arm. This is the ingest triage pass —
what's real, what's duplicated, what's already been run, and what's blocked
before any of it reaches a samplesheet.

## Headline numbers

- **14 distinct dataset/study folders**, 453 raw file paths, **371 real files**
  after removing 5 `Undetermined_S0_*` bcl2fastq catch-all files (not real
  samples) and 56 duplicate copies (see below).
- **214 unique real samples.**
- **157 (73%) are complete R1+R2 pairs** — ready to go straight into a
  samplesheet once paths are rsynced off Prometheus.
- **57 (27%) currently show only an R1 file** in this listing, across 5
  dataset folders/sub-batches — blocked until R2 is either located elsewhere
  on Prometheus or confirmed genuinely single-end (this pipeline has no
  single-end samplesheet support yet — same blocker already tracked for
  `ebv_btransform`/`ebv_lytic_reactivation`/`jcv_pml_brain`/`zika_organoid`
  in `docs/pathseq_validation_results_2026-08-15.md`).

## Per-dataset breakdown

| Dataset folder | Samples | Status | Notes |
|---|---:|---|---|
| `2025_Watchmaker_Asta.Jayden.Katherin.Alejandro` | 30 | ✅ PE, ready | See dedup note — net new |
| `2023_rheumatoidArthritis_AshokKulkarni` | 25 | ✅ PE, ready | **Already in repo**: `assets/config_dpn_ra_kulkarni.yaml` + samplesheet exist and match exactly (25 samples) |
| `2022_ThoracicDRG_doloromics` | 24 | ✅ PE, ready | Net new — not yet in `docs/cohort_registry.md` |
| `OSM_Juliet` | 18 | ✅ PE, ready | **Already in repo**: `assets/config_osm_juliet.yaml` + samplesheet exist and match exactly (18 samples) — see path-mismatch note below |
| `2025_REJOIN_Jayden` | 17 | ✅ PE, ready | **Already in `docs/cohort_registry.md`** as cohort #5 (473-1–473-17, n=17) — appears already run |
| `2022_MGOexplant_Saad` | 25 | ⚠️ mixed | 6 PE (`trial1`, Saad-1–6) + **19 R1-only** (`trial2_UTD`, 286-1–286-19) — see blocked list |
| `2023_c2DRGs_Asta` | 23 | 🛑 blocked | **All 23 samples R1-only**, no exceptions |
| `2024_Adult.Infant.Soma.Axon_Asta` | 10 | ✅ PE, ready | Net new |
| `2022_unknown_doloromics` | 8 | ✅ PE, ready | Name literally says "unknown" — metadata/provenance needs chasing before this is publication-usable, even though the FASTQs themselves are clean |
| `2025_MGOhighdoseEXPLANT_Sera` | 8 | 🛑 blocked | **All 8 samples R1-only** (524-1–524-8) — also had a redundant "All gender" folder duplicating Male+Female, already collapsed out |
| `2023_OSMexplant_doloromics.Juliet` | 7 | ✅ PE, ready | Net new |
| `2023_OSMcultured_doloromics.Juliet` | 7 | ⚠️ mostly ready | 6 PE + 1 R1-only orphan (366-10) |
| `2022_LumarDRG_doloromics` | 6 | ✅ PE, ready | **Already in `docs/cohort_registry.md`** as cohorts #2/#3 (Donor1 DRG + AIG1390 DRG) — **known duplicate-donor issue, see below** |
| `2022_PRDM12cultured_Saad` | 6 | 🛑 blocked | **All 6 samples R1-only** |

**Ready right now: 157 samples across 11 dataset folders. Blocked: 57 samples
across 5 dataset folders/sub-batches** (the 19 in `2022_MGOexplant_Saad`, all
23 in `2023_c2DRGs_Asta`, all 8 in `2025_MGOhighdoseEXPLANT_Sera`, 1 orphan in
`2023_OSMcultured_doloromics.Juliet`, all 6 in `2022_PRDM12cultured_Saad`).

## Already-registered cohorts — don't re-derive, cross-check instead

Four of these 14 folders correspond directly to cohorts already tracked in
`docs/cohort_registry.md`, two of which already have a working
config+samplesheet pair in this repo:

- **`2023_rheumatoidArthritis_AshokKulkarni`** → `assets/config_dpn_ra_kulkarni.yaml`
  + `assets/samplesheets/samplesheet_dpn_ra_kulkarni_juno.csv` (25/25 samples
    match exactly, including the already-resolved `hDRG_DPN_PolyA` vs `RA`
    subfolder duplicate-code overlap — 10 sample codes appear in both raw
    subfolders on Prometheus; the existing samplesheet already picks the
    `hDRG_DPN_PolyA` copy for those, consistent with this listing).
- **`OSM_Juliet`** → `assets/config_osm_juliet.yaml` +
  `assets/samplesheets/samplesheet_osm_juliet_juno.csv` (18/18 samples match
  exactly). **Path mismatch worth checking**: the existing config's comment
  says raw data lives at `P:\homo_sapiens\...\2026_OSM_Juliet\fastq_files\`,
  but this fresh scrape shows `z:\data\...\bulk_rnaseq\OSM_Juliet\Ish\` — a
  different drive letter, year prefix, and folder name. Could be a drive
  remount/reorganization since that config was written, or two separate
  copies. Verify which path is current before rsyncing for this one.
- **`2025_REJOIN_Jayden`** → matches cohort registry #5 exactly (473-1–473-17,
  n=17) — appears to already be a completed run, not new work.
- **`2022_LumarDRG_doloromics`** → matches cohort registry #2 ("Donor1 DRG",
  AIG1390_L1–L5+T12) and #3 ("AIG1390 DRG", AIG1390_L1–L4+T12). **Standing
  known issue** (already in project memory, not new): AIG1390 is a confirmed
  duplicate of Donor1, already excluded from the Early DRG cohort
  (n=16→11) in prior analysis — do not treat this folder's 6 files as 6 new
  independent samples without applying that same dedup logic.

**`2022_MGOexplant_Saad`'s `trial1` sub-batch** (Saad-1 through Saad-6, PE,
6 samples) is very likely the same as cohort registry #4 ("Saad DRG",
Saad_1–5, n=5) — one sample off (registry lists 5, this listing shows 6:
Saad-1 through Saad-6). Worth reconciling which one dropped and why before
assuming this sub-batch is either fully new or fully already-run.

**Net genuinely new, unregistered, ready-to-go cohorts**: `2025_Watchmaker_...`
(30), `2022_ThoracicDRG_doloromics` (24), `2024_Adult.Infant.Soma.Axon_Asta`
(10), `2022_unknown_doloromics` (8), `2023_OSMexplant_doloromics.Juliet` (7),
`2023_OSMcultured_doloromics.Juliet` (7, minus the 1 orphan) — **86 samples**.

## Specific issues found (all real, verified against the raw listing)

1. **Watchmaker raw-bcl duplicate copies (resolved, informational only).**
   24 of the 30 Watchmaker samples (all `JOA*`/`AO*`/`AA*`) exist in **two**
   places: an organized `fastq\<researcher>\Dataset_Copy_.../` folder (lane-
   numbered filenames) and a raw flowcell demux dropbox
   (`bcl\250124_VH00905_85_AACFYTWHV\Analysis\2\Data\fastq\`, same sample,
   no lane number in the filename) — same underlying sequencing data, not
   distinct samples. Use the organized `fastq\<researcher>\` copies; ignore
   the `bcl\` copies for these 24.
   **Exception**: the remaining 6 samples (`MB1`–`MB6`) exist **only** in the
   `bcl\` raw demux folder — no organized per-researcher copy was ever made
   for them. "Katherin" is named in the dataset folder title alongside Asta/
   Jayden/Alejandro but has no `fastq\Katherin\` subfolder the way the other
   three do — MB1–6 are almost certainly Katherin's samples, just never
   filed into a per-researcher folder. They're real and usable, just sourced
   from the raw bcl path specifically.
2. **`2025_MGOhighdoseEXPLANT_Sera`'s "All gender" folder (resolved,
   informational only).** Duplicates the same 8 samples split across `Male`
   (524-5,6,7,8) and `Female` (524-1,2,3,4) subfolders — same files, third
   redundant organization. Already collapsed out of the counts above.
3. **57 samples show only an R1 file — needs direct verification on
   Prometheus, not assumed.** Two possibilities: (a) genuinely single-end
   sequencing (older/pilot batches — `trial2_UTD` Saad, PRDM12cultured,
   c2DRGs_Asta, MGOhighdoseEXPLANT_Sera all read as historically distinct,
   plausibly single-end submissions), or (b) R2 mates exist on Prometheus
   under a naming convention or subpath this particular scrape didn't
   capture. Recommend a targeted `find`/`dir` pass scoped to just these 5
   folders before concluding they're truly SE-only. If genuinely SE, this
   pipeline has no single-end samplesheet support yet (same known gap
   blocking several public cohorts, see `docs/pathseq_validation_results_2026-08-15.md`).
4. **Sample ID reuse across dataset folders**: `366-10` appears in both
   `2023_OSMcultured_doloromics.Juliet` (as part of 366-11–366-16) and
   `2024_Adult.Infant.Soma.Axon_Asta` (as part of 366-1–366-10) — same "366"
   plate/submission numbering split across two dataset folders from
   different years. Could be the same physical sample referenced twice, or
   coincidental reuse of a shared numbering scheme across two related but
   distinct sub-experiments. Verify before pooling; don't assume either way.
5. **One orphan single-end file inside an otherwise-clean paired dataset**:
   `2023_OSMcultured_doloromics.Juliet`'s `366-10` has an R1 but no R2 (the
   other 6 samples in that folder, 366-11–366-16, are cleanly paired).
6. **`2022_unknown_doloromics`** — the FASTQs themselves are clean (8 samples,
   fully paired), but the dataset folder is literally named "unknown,"
   meaning provenance/experimental-condition metadata needs to be tracked
   down before this cohort is usable beyond a raw virus-detection pass.

## Recommended next step

Build samplesheets/configs for the 86 net-new, ready, unregistered samples
first (`2025_Watchmaker_...`, `2022_ThoracicDRG_doloromics`,
`2024_Adult.Infant.Soma.Axon_Asta`, `2022_unknown_doloromics`,
`2023_OSMexplant_doloromics.Juliet`, `2023_OSMcultured_doloromics.Juliet` minus
366-10) — no blockers, no open questions. Launch the two already-configured
cohorts (`dpn_ra_kulkarni`, `osm_juliet`) as-is once the OSM path discrepancy
is resolved. Chase the R2 question for the 57 blocked samples in parallel
before deciding whether they need single-end support built or are simply
mis-scraped.
