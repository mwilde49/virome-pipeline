# SfN Neuroscience 2026 Abstract — Draft

**Status:** Draft, not yet submitted. `[AGE RANGE]` placeholder needs real donor
demographics filled in before submission (SfN requires disclosure of species/age/sex
per abstract, and a statement on whether sex-specific effects were tested).

## Timing — read this first

The regular Neuroscience 2026 abstract window (May 27 – June 11, 2026) has already
closed. The only remaining path to present this at the November 14–18, 2026 meeting
is the **late-breaking abstract window: September 8–15, 2026**. Late-breaking is
explicitly intended for work whose results weren't ready by the regular deadline
("preliminary results are acceptable") — a good fit here, not a downgrade.
Late-breaking notifications go out late September. Source: SfN dates and deadlines
page (sfn.org/meetings/neuroscience-2026/general-information/dates-and-deadlines).

## Format rules this draft was built against

- Body: max **2,300 characters**, counted **excluding spaces**, including
  punctuation. Draft below: **1,987 chars** (313 to spare).
- Title: max **1,200 characters including spaces**, sentence case (first word
  capitalized, rest lowercase except proper nouns/acronyms), no bold/italic. Draft
  below: **138 chars**.
- Must state: research objective, rationale, methods, results, conclusions.
  **Abstracts lacking an explicit conclusion are auto-rejected** — this draft ends
  on one on purpose.
- Must report *currently available* data — no future tense ("will be discussed" is
  explicitly banned). Preliminary results are fine; unfinished framing is not.
- Must disclose biological variables: species, age, sex, and whether sex-specific
  effects were assessed. Placeholder inserted below — fill in real numbers.
- Must disclose funding sources and any conflicts of interest (separate form
  fields, not part of the 2,300-char body).
- Human-subjects work must attest compliance with the Declaration of Helsinki /
  SfN Ethics Policy — confirm the donor-tissue IRB/ethics documentation is on hand
  before submitting.
- Up to 3 keywords, selected from SfN's own list where possible.
- Theme/topic must be selected from SfN's live theme list at submission time — not
  reproduced here since it wasn't looked up; likely candidates are a peripheral
  nervous system / sensory ganglia topic under Disorders of the Nervous System, or
  a neuroimmunology/neurovirology topic — worth a quick look at the actual
  drop-down before submitting.

Sources: [Rules for Regular Abstract Submissions](https://www.sfn.org/meetings/neuroscience-2026/call-for-abstracts/rules-for-abstract-submissions),
[Dates and Deadlines](https://www.sfn.org/meetings/neuroscience-2026/general-information/dates-and-deadlines),
[How to Submit an Impactful Abstract for Neuroscience 2026](https://neuronline.sfn.org/professional-development/how-to-submit-an-impactful-abstract-for-neuroscience-2026).

## Title (138 chars)

> HERV-K derepression tracks HSV-1 and other viral transcript signatures in human dorsal root ganglia: a dual-database RNA-seq virome survey

## Body (1,987 chars excl. spaces)

> Latent neurotropic viruses are hypothesized to reactivate within sensory ganglia and contribute to chronic pain and sensory neuron dysfunction, but this has been characterized mainly in trigeminal ganglion (TG) and CNS tissue. We developed a dual-database viral RNA-seq classification pipeline to systematically survey the human dorsal root ganglion (DRG) virome and applied it to bulk RNA-seq from 160 postmortem donor DRG/TG samples (adult men and women, [AGE RANGE]) spanning 11 independent cohorts; sex-specific effects have not yet been formally tested. Host-depleted, unmapped reads were classified with Kraken2 against two independent reference databases in parallel and cross-validated with GATK PathSeq, an orthogonal alignment-based classifier, so only concordant taxon calls were treated as high-confidence.
>
> HSV-1 was detected, and cross-validated by both classifiers, in ~10% of samples, at a higher rate in TG than DRG, consistent with known TG latency biology and now extending detection into DRG. No Epstein-Barr virus or varicella-zoster virus reads were detected despite near-universal population seroprevalence, suggesting bulk RNA-seq under-samples deep latent reservoirs and arguing for deeper, targeted sequencing. Additional low-abundance, cohort-restricted candidate signals (e.g., HHV-8-like and AAV-like taxa) were observed and require read-level validation before biological interpretation.
>
> Across cohorts with more than one HSV-1-positive sample, HERV-K (human endogenous retrovirus K) transcript abundance correlated significantly and positively with HSV-1 detection (regression, p<0.01 per cohort), replicating in DRG for the first time a HERV-K-HSV-1 relationship previously reported only in TG. A genome-wide, within-cohort-normalized correlation survey across all 160 samples showed HERV-K also correlates significantly with additional, taxonomically distant viral signals beyond HSV-1, and a combined multi-taxon predictor of HERV-K remained significant after false-discovery-rate correction. These results position HERV-K derepression as a candidate convergent host-response marker of viral reactivation-associated activity in human DRG, motivating downstream analysis of host antiviral/inflammatory transcriptional signatures in this sample set.

## Suggested keywords (pick closest official matches at submission)

- dorsal root ganglion
- endogenous retrovirus
- viral reactivation (or: herpes simplex virus)

## Notes on what's deliberately excluded

- **No CMV/CMV-proxy content**, per explicit direction — the "Human CMV (HHV-5)
  [proxy]" taxon's near-universal presence and non-standard behavior (see
  `[[project_hervk_hsv_cmv_relationship]]` memory) make it unsuitable to present as
  a real finding either way (positive or negative) without the BLAST-level
  confirmation this offshoot hasn't run yet. EBV and VZV are cited as clean true
  negatives instead — that part of the underlying biology is solid.
- The HHV-8-like and AAV-like signals are flagged as candidates requiring
  validation, not asserted findings, since neither has been BLAST-confirmed.
- No specific p-value/R² numbers beyond "p<0.01 per cohort" are quoted in the body
  to save characters; exact figures (e.g. the Iadorola-replication R²=0.459,
  p=0.0039, n=16 stat, and the combination-table BH-q values from
  `hervk_taxa_combination_table_2026-08-24.pdf`) are available if you want the
  poster itself (not the abstract) to cite them directly.
