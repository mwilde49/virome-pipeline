# CMV Taxonomy Investigation
**Date**: 2026-03-24 (original), updated 2026-08-15
**Pipeline version**: v1.0.0 (original), v2.0.0 (2026-08-15 update)
**Samples examined**: donor1_T12, donor1_L5 (DRG tissue); Sample_19, 21, 22 (muscle tissue); SRR5660016-19 (2026-08-15 update, see below)
**Status**: COMPLETE (original root-cause analysis) — reopened 2026-08-15 with a genuine positive control, see update below

---

## Observation

`Cytomegalovirus papiinebeta3` (taxon ID 3050337) appears in the final abundance matrix for DRG and muscle samples:

| Sample | Tissue | Reads |
|---|---|---|
| donor1_T12 | DRG | 114 |
| donor1_L5  | DRG | 279 |
| Sample_19  | Muscle | 16 |
| Sample_21  | Muscle | 16 |
| Sample_22  | Muscle | 16 |

3050337 is labeled as a Papiine (baboon/NHP) cytomegalovirus. Its presence in human tissue is biologically implausible as a true infection — this triggered investigation.

---

## Investigation

### Step 1: Is Kraken2 or Bracken making this call?

Kraken2 `.report` files (located via `find /scratch/juno/$USER/nf_work -name "*.report"`) show 3050337 with clade reads. Bracken inherits from Kraken2. The root cause is in Kraken2's classification.

### Step 2: Does the database have sequences for papiinebeta3?

```bash
grep -P "\t3050337\t" seqid2taxid.map
# Result: no output
```

No sequences directly mapped to 3050337. Reads cannot land there by direct k-mer match.

### Step 3: Trace the taxonomy tree

```bash
grep "^3050295" nodes.dmp  # Cytomegalovirus humanbeta5 (human CMV species)
# Result: 3050295 | 10358 | species | ...

grep "^3050337" nodes.dmp  # Cytomegalovirus papiinebeta3
# Result: 3050337 | 10358 | species | ...

grep "^10358" names.dmp
# Result: 10358 | Cytomegalovirus | scientific name
```

Both 3050295 (humanbeta5) and 3050337 (papiinebeta3) are **sibling species** under taxon 10358 (genus *Cytomegalovirus*). My initial hypothesis (humanbeta5 placed under papiinebeta3) was wrong.

### Step 4: Examine the actual Kraken2 report lines

```
  0.00  16      0       G       10358       Cytomegalovirus
  0.00  16      0       S       3050337       Cytomegalovirus papiinebeta3
  0.00  16      16      S1      2169863         Papiine betaherpesvirus 3
```

Column 3 (direct reads) is **0** for 3050337 but **16** for its S1 child **2169863** (`Papiine betaherpesvirus 3`). All reads are assigned directly to 2169863.

3050337 appears in the report only as the parent aggregation node. The actual assignment is to 2169863.

### Step 5: Database has a Papiine betaherpesvirus 3 sequence

```bash
grep "2169863" seqid2taxid.map | head -5
# Result: kraken:taxid|2169863|NC_055235.1   2169863
```

The database contains one complete Papiine betaherpesvirus 3 genome: **NC_055235.1** (baboon CMV, ~241 kb). Human CMV reference: **NC_006273.2** (HHV-5 Merlin, ~235 kb). Both are complete betaherpesvirus genomes with high sequence similarity.

---

## Root Cause

**Cross-species k-mer matching.** The database has exactly one human CMV genome (NC_006273.2, HHV-5 Merlin strain) and one baboon CMV genome (NC_055235.1, Papiine betaherpesvirus 3). Both are complete ~235–241 kb betaherpesvirus genomes.

k-mers shared by both → LCA = genus 10358, not assigned to either species.
k-mers unique to NC_055235.1 → assigned to 2169863 (baboon CMV).
k-mers unique to NC_006273.2 → assigned to 10359 (human CMV).

Reads from a patient CMV strain that has diverged from the Merlin reference strain will have fewer k-mer matches to NC_006273.2 and may retain or exceed matches to NC_055235.1 in shared but variable regions. These reads resolve to 2169863 rather than 10359.

The taxonomy tree is structurally correct — this is not a tree placement error. It is a **reference representation problem**: single-strain human CMV reference unable to capture clinical CMV diversity, while the baboon CMV sequence captures conserved betaherpesvirus regions that happen to match patient reads better than Merlin.

---

## Biological Interpretation

Despite the wrong species label, the signal is consistent with **human CMV (HHV-5)**:

- HHV-5 is a well-established neurotropic betaherpesvirus
- HHV-5 establishes latency in sensory ganglia, including DRG — detection here is biologically expected
- DRG signal (114–279 reads) is 7–17× higher than muscle (16 reads) — this tissue enrichment is consistent with CMV neurotropism and inconsistent with a uniform reagent contaminant
- No plausible biological route for actual Papiine betaherpesvirus 3 infection in human DRG

**Conclusion**: The 3050337/2169863 signal represents human CMV cross-mapping to a primate CMV reference. This is likely real biology — CMV latency in DRG — mislabeled due to reference imbalance in the database.

---

## Remediation Plan

### Do NOT add to artifact exclusion list
This signal has biological relevance. Excluding it would hide a potentially important CMV finding.

### Short-term: Annotate in analysis
Note in any publication that "Cytomegalovirus papiinebeta3 / Papiine betaherpesvirus 3 (taxon 3050337/2169863) represents cross-reactive human CMV (HHV-5) reads due to reference database imbalance."

### Medium-term: Taxon relabeling layer
Add `assets/taxon_remap.tsv` — a curated TSV for renaming known cross-reactive or mislabeled taxa:
```tsv
taxon_id  current_name                    correct_name                         reason
2169863   Papiine betaherpesvirus 3       Human CMV (HHV-5, cross-reactive)    reference_imbalance: single HHV-5 genome vs complete primate CMV genome
3050337   Cytomegalovirus papiinebeta3    Human CMV (HHV-5, cross-reactive)    parent_of_2169863
```
Apply in `bin/filter_kraken2_report.py` before output, and display corrected names in the report.

### Long-term: Database augmentation
Add more human CMV genome diversity (clinical strains, HCMV Toledo, TB40/E, etc.) to the Kraken2 database so reads correctly resolve to 10359/3050295 rather than cross-mapping to primate references.

---

## Reusable Protocol

This investigation followed a general pattern applicable to any suspicious taxon. See `methodology_taxonomy_investigation.md` (memory) for the full step-by-step protocol.

**Key lesson**: When a taxon has 0 direct reads but nonzero clade reads with no visible children in the grep output, the actual assignment is to a child taxon whose ID is not in your grep pattern. Always check `grep -A 5` around the suspicious line in the Kraken2 report to expose the real assignment.

---

## Update 2026-08-15: first real positive-control test

**Context**: every prior observation of this taxon (above) came from real patient DRG/muscle tissue with low, ambiguous counts (16-279 reads) — there was never a genuine, high-confidence CMV-positive sample to check the classifier against. One became available as part of building the `pathseq_verify.nf` offshoot: `GSE99823`/`SRP108855` (Cheng et al., *PNAS* 2017), MRC-5 fibroblasts with confirmed WT human CMV (strain-lineage TB40/E-adjacent) infection, 12/24/48/72 hpi time course, 4 samples (`SRR5660016-19`). Full dataset selection/verification: `docs/pathseq_and_test_datasets_2026-08-14.md`. Run through the main pipeline for real on Juno 2026-08-15 (`assets/config_cmv_fibroblast.yaml`), 43/43 tasks succeeded.

**Result** — `results/bracken_raw_matrix.tsv` (completely unfiltered, no `min_reads` or artifact-exclusion threshold applied), top rows:

| taxon_id | taxon_name | rank | 12hpi reads (RPM) | 24hpi reads (RPM) | 48hpi reads (RPM) | 72hpi reads (RPM) |
|---|---|---|---|---|---|---|
| **3050295** | **Cytomegalovirus humanbeta5** | S | 1,588,558 (83,926) | 3,969,423 (206,507) | 5,841,101 (388,453) | 1,985,167 (215,847) |
| 3050258 | Cytomegalovirus cercopithecinebeta5 | S | 833 (44) | 1,795 (93) | 3,154 (210) | 0 (0) |
| 3050334 | Cytomegalovirus paninebeta2 | S | 288 (15) | 236 (12) | 211 (14) | 60 (7) |

**3050337 (the documented proxy species from the original investigation above) does not appear in this file at all** — no row, meaning Bracken assigned essentially none of this sample's reads there.

**Interpretation — this changes the original investigation's practical conclusion**: given a strong, unambiguous, high-titer infection, Kraken2/Bracken correctly resolves the overwhelming majority of reads directly to the true human CMV species node (**3050295**, "Cytomegalovirus humanbeta5") — RPM climbing 12h→48h then dropping at 72h, exactly the shape expected of lytic infection kinetics. The cross-mapping-to-proxy artifact this file's original investigation characterized (Steps 1-5 above) appears to be **specifically a low-titer / noisy-tissue-background phenomenon** — real patient DRG/muscle samples with only tens to low-hundreds of ambiguous reads — not a blanket failure of this database to ever identify human CMV correctly. The reference-imbalance root cause (single HHV-5 Merlin genome vs. a complete baboon CMV genome, Steps 1-5 above) is still real and still explains *why* low-count, divergent-strain reads misresolve — it just doesn't dominate when there's enough unambiguous signal to swamp the ambiguous fraction.

**Taxon ID correction/clarification** (a self-correction made mid-conversation while checking this — logged so it isn't lost): the original investigation's Step 3/Root-Cause sections already correctly document **10359 as a real human-CMV-associated taxon ID** ("k-mers unique to NC_006273.2 → assigned to 10359 (human CMV)", line ~84 above) — so recalling "10359 = human CMV" from memory was not fabricated. However, it is **not the species-rank (`S`) node Bracken reports abundance at** — that's `3050295`. Since this pipeline's Bracken step is configured at `bracken_level: "S"` (species), every row in any `*_matrix.tsv` file is species-rank, so a `grep` for `10359` against those files will always come up empty even though the ID is real — it would only appear in a raw, pre-Bracken Kraken2 `.report` file (direct per-read counts at every rank, not just species). Worth remembering for any future taxon lookup in this project: **check which rank a candidate ID actually is (via `nodes.dmp`) before grepping a Bracken-derived matrix for it.**

**Next**: `pathseq_verify.nf` was already launched on this same sample set before this finding surfaced, with `target_taxa: "10359,3050337"` — neither of which is the taxon that actually matters here (`3050295`). This doesn't invalidate the run (`PATHSEQ_SCORE` always scores the full taxonomy regardless of `target_taxa`; only the auto-generated concordance table's curated view is affected), but the real comparison point once it finishes is: does PathSeq's own alignment-based classifier — built from a December-2017 reference/taxonomy bundle, likely predating this ICTV binomial rename — also land on genuine human CMV signal, and under which taxon ID? See [[project_pathseq_offshoot]] memory for the live run status.

---

## Update 2026-08-15 (same day): PathSeq cross-validation — independent confirmation

`pathseq_verify.nf` completed on this same 4-sample set. Result, from `pathseq_abundance_matrix.tsv`:

| Sample | PathSeq reads (taxon 10359) | Normalized score |
|---|---|---|
| SRR5660016 | 643,233 | 99.91% |
| SRR5660017 | 1,133,300 | 99.95% |
| SRR5660018 | 1,515,321 | 99.95% |
| SRR5660019 | 690,672 | 99.96% |

**This confirms the taxonomy-vintage prediction exactly**: PathSeq lands the massive, unambiguous signal on taxon **10359, "Human betaherpesvirus 5"** — the pre-2021 legacy NCBI ID, not Kraken2's `3050295` ("Cytomegalovirus humanbeta5"). Both are the same species; PathSeq's December-2017 taxonomy bundle simply predates the ICTV binomial rename that produced `3050295` (and `3050337`, and HSV-1's `3050292`). **Taxon `3050337` (the original documented proxy) does not appear anywhere in PathSeq's output** — not even as a placeholder node — because that ID doesn't exist in a 2017-vintage taxonomy tree at all.

Taxonomic path resolution is essentially perfect: genus-level *Cytomegalovirus* (10358, 643,236 reads for sample 1) vs. species-level human CMV (10359, 643,233 reads) — 99.995% of genus-level reads resolve specifically to the human species. The tiny remainder scatters across other primate CMV species (baboon, macaque, chimp — single digits to low hundreds of reads each), nowhere near enough to be mistaken for the dominant signal.

---

## Update 2026-08-15 (same day): the same pattern shows up in a second herpesvirus genus (EBV/Lymphocryptovirus) — and independently reproduces the low-titer prediction

`ebv_gm12878` (ENCODE ENCSR000AEC, GM12878 — constitutively EBV-transformed lymphoblastoid line, Type III latency, 2 replicates) run through the main pipeline. Full dataset/config detail: `docs/pathseq_validation_results_2026-08-15.md`. Result, `results/bracken_raw_matrix.tsv`:

| taxon_id | taxon_name | SRR3192396 reads (RPM) | SRR3192397 reads (RPM) |
|---|---|---|---|
| **3050299** | **Lymphocryptovirus humangamma4** (true human EBV/HHV-4) | 250,052 (2,480) | 184,950 (2,074) |
| 3050339 | Lymphocryptovirus papiinegamma1 (baboon relative) | 6,948 (69) | 2,861 (32) |
| 3050337 | **Human CMV (HHV-5) [proxy]** — the *original* taxon this whole investigation is about | 71 (0.70) | 90 (1.01) |

Two things confirmed here, independently of the CMV sample entirely:

1. **The same reference-imbalance pattern recurs one genus over.** `3050299` (true human EBV) dominates completely, but `3050339` (a baboon Lymphocryptovirus relative) picks up a real, non-trivial ~3% of the combined genus signal and — like the original CMV proxy — lands in the dual-DB `shared`/Tier-1 consensus tier too. Same likely mechanism as the CMV case (Steps 1-5 above): thin human-specific reference coverage relative to a complete non-human primate relative's genome, causing some fraction of divergent/ambiguous reads to cross-map. This is now observed in **two independent herpesvirus genera** (Cytomegalovirus and Lymphocryptovirus), suggesting it may be a structural property of how this Kraken2 viral database represents primate-infecting herpesviruses generally, not a one-off CMV-specific quirk.

2. **Direct, unprompted corroboration of the "low-titer artifact" conclusion from the update above.** This EBV-focused sample has nothing to do with CMV — yet the *original* proxy taxon (`3050337`) still shows up, at exactly the kind of low count (71-90 reads) the "low-titer/noisy-background" reading of the CMV finding predicted. This is now the second independent sample (after the March 2026 DRG/muscle observations) showing `3050337` specifically as background noise rather than a dominant signal, further supporting that reading over "database fundamentally can't resolve human CMV."

**Practical implication going forward**: when auditing any herpesvirus (or likely broader primate-virus) Kraken2 call in this pipeline, check not just whether the taxon is present, but whether it's the *dominant* fraction of its genus/family — a small non-human-primate-relative signal alongside a much larger correct human call is very likely this same artifact, not a real co-infection or contamination event, unless independently corroborated (e.g., by PathSeq, which uses a differently-sourced reference and hasn't reproduced this specific cross-mapping in any run so far).

**Conclusion, updated**: two methodologically independent classifiers (Kraken2's k-mer/LCA approach on a current-vintage database, PathSeq's BWA-MEM alignment approach on a 2017-vintage database) both correctly and confidently identify genuine human CMV in this sample, using different taxon IDs for the same organism because their underlying taxonomy trees are from different eras. This is strong, convergent, method-independent evidence that the original March 2026 proxy-taxon finding (`3050337`/`2169863`) is a low-titer/noisy-tissue-specific artifact of the *viral-only* Kraken2 database's reference imbalance — not a fundamental limitation that recurs whenever real signal is present, and not something PathSeq's differently-sourced reference reproduces at all.

This was also the first fully successful end-to-end run of the `pathseq_verify.nf` offshoot (see [[project_pathseq_offshoot]] memory) — validates the whole build, not just this one finding.
