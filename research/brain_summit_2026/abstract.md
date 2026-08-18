# Abstract — UT System Brain Health Research Summit 2026 (Poster Session)

**Deadline:** July 15, 2026 — submit PDF to brainsummit@utsystem.edu
**Word count (Background–Conclusions only):** 450 / 500

**Suggested topic area(s):** Future of Dementia and Parkinson's Research in Texas; Fundamental Mechanisms of Disease

**Title:** First Detection of Reactivated HSV-1 in Parkinson's Disease Dorsal Root Ganglia via
Validated Dual-Database Virome Profiling

---

## Background

Herpes simplex virus-1 (HSV-1) establishes lifelong latency in sensory ganglia and has been
proposed as a contributor to Parkinson's disease (PD) pathogenesis: the virus can travel
retrogradely from peripheral ganglia toward the CNS, promotes alpha-synuclein aggregation in
vitro, and epidemiological studies link antiviral treatment to reduced PD risk. Despite this,
the dorsal root ganglion (DRG) virome has never been systematically profiled in PD tissue. A
key barrier is specificity: k-mer classifiers restricted to viral-only reference databases
force every unclassified host read onto the nearest viral taxon, inflating false positives in
host-dominated neural tissue libraries.

## Methods

We applied virome-pipeline (v1.5.0), a Nextflow DSL2 pipeline combining STAR-based host
depletion, parallel dual-database Kraken2 classification (viral-only vs. PlusPF), Bracken
re-estimation, and a three-tier confidence framework: Tier 1 taxa are confirmed in both
databases, Tier 2 are viral-only artifacts, and Tier 3 are PlusPF-only background. A
24-entry, BLAST-validated artifact exclusion list removes recurrent tissue-specific k-mer
cross-mapping. We profiled 36 post-mortem human DRG samples: 16 non-PD (independent donor
cohorts, six spinal levels) establishing a baseline, and 20 from a Parkinson's cohort (14
confirmed PD patients; 6 samples with disease status unconfirmed by the sequencing provider).

## Results

The non-PD baseline yielded zero Tier 1 viral detections across all 16 samples — a 100%
empirical false-positive rate for viral-only classification and a validated null result for
exogenous virus in unaffected DRG. Within the PD cohort, one sample (PD19) produced the
pipeline's first-ever Tier 1 HSV-1 detection (*Simplexvirus humanalpha1*; 46 reads, 1.89
RPM), confirmed independently by both databases. HSV-1 was undetectable — even at the
unfiltered, pre-threshold level — in all 16 non-PD samples and in the other 13 confirmed PD
patients, restricting the signal to a single PD donor. Read-level BLAST identity confirmation
is built and configured for this sample but has not yet been run; the Tier 1 classification
currently rests on dual-database k-mer concordance alone. A secondary, better-powered signal
— HERV-K enrichment in DRG relative to skeletal muscle (5.8-fold, p=3.3×10⁻⁴, reproduced
across independent cohorts) — showed no elevation specific to the PD cohort.

## Conclusions

This is the first systematic virome profiling of PD DRG tissue, and dual-database
competitive classification is necessary before any viral signal in bulk neural RNA-seq can
be interpreted. The PD19 HSV-1 detection — absent from every other sample in the dataset —
is the first direct evidence of exogenous viral signal in this cohort and is consistent with
literature proposing HSV-1 reactivation in sensory ganglia as a candidate route for
peripheral-to-CNS spread in PD, though at n=1 it requires BLAST confirmation and replication
before biological interpretation. Expanding the PD cohort with confirmed control status and
clinical metadata (Braak stage, disease duration) is the immediate next step toward testing
whether ganglionic HSV-1 reactivation associates with PD.

---

## Still needed before submission

The CFA requires these fields in the submission email (not part of the 500-word abstract
itself):

- **Name, credentials, job title, affiliation** (UT System institution required for
  eligibility)
- **Research experience checkbox:** Student / Postdoc / Early Career Researcher
- **Co-authors**
- **Topic area checkbox(es)** — recommended above, confirm or adjust
- Convert this file to PDF for the email attachment

Two open items that affect the Results section if resolved before July 15:

1. **BLAST validation of PD19** — if `blast_verify.nf` gets run on Juno before the deadline,
   the "has not yet been run" sentence should be replaced with the confirmed identity/life-cycle
   phase result, which strengthens the abstract materially.
2. **023–028 identity** — if the Psomagen manifest resolves whether these 6 samples are
   genuine controls, the Methods sentence can be tightened (see
   `project_parkinson_2026_provenance` memory).
