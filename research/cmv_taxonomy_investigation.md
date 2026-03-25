# CMV Taxonomy Investigation
**Date**: 2026-03-24
**Pipeline version**: v1.0.0
**Samples examined**: donor1_T12, donor1_L5 (DRG tissue); Sample_19, 21, 22 (muscle tissue)
**Status**: COMPLETE

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
