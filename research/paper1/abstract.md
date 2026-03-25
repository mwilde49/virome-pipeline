# Abstract Draft — DRG Virome Study

## Title (working)
Computational Profiling of the Human Dorsal Root Ganglion Virome from Bulk RNA-Seq Reveals a Sparse Exogenous Viral Landscape with Low-Level Cytomegalovirus-Associated Signal

---

## Abstract

**Background.** Human dorsal root ganglia (DRG) are established latency reservoirs for neurotropic alphaherpesviruses, yet the broader viral landscape of sensory ganglia remains poorly characterized. Whether additional viruses (particularly betaherpesviruses such as cytomegalovirus (CMV/HHV-5)) persist in DRG, and whether viral activity contributes to neuropathic pain pathophysiology, are open questions. Systematic virome profiling of human DRG has not been reported.

**Methods.** We performed paired-end bulk RNA-seq (NovaSeq 6000, 2×150 bp; 17–92 million reads per sample) on 15 human samples: 11 DRG samples (6 from a single donor spanning spinal levels L1–L5 and T12, plus 5 from 5 additional donors) and 5 skeletal muscle samples from 5 independent donors included as non-neural tissue controls. A computational virome profiling pipeline was applied comprising adapter trimming (Trimmomatic), host read depletion via alignment to GRCh38 (STAR), k-mer-based viral taxonomic classification (Kraken2, confidence 0.1; Langmead viral database k2_viral_20240904), species-level abundance re-estimation (Bracken), and multi-stage filtering requiring a minimum of 5 classified reads per taxon. A curated artifact exclusion list removing 22 taxa (including ruminant orthobunyaviruses, baculoviruses, environmental phages, and metagenome-derived sequences lacking vertebrate host range) was applied to suppress consistent false positives.

**Results.** After stringent artifact curation, the detectable exogenous DRG virome was extremely sparse; no diverse active viral community was identified in any sample. Human endogenous retrovirus K (HERV-K/HML-2) was detected across all samples, with DRG showing modestly elevated expression relative to muscle (median approximately 50 versus 31 reads per million), consistent with previously reported neural HERV-K transcriptional activity. CMV-associated reads were detected at low but consistent levels across all samples (0.5–4 RPM), with DRG enriched over muscle, and thoracic-level DRG (T12) exhibiting the highest normalized signal. No other exogenous virus met confidence thresholds for genuine detection. The k-mer classification approach applied to a viral-only reference database operates near an intrinsic noise floor that limits both sensitivity and specificity for trace viral detection in host-dominated bulk RNA-seq libraries.

**Conclusions.** Human DRG does not harbor a diverse active exogenous virome detectable by bulk RNA-seq k-mer classification. Low-level CMV-associated signal enriched in DRG relative to muscle is consistent with betaherpesvirus latency in sensory ganglia but cannot be confirmed without orthogonal validation such as alignment-based read mapping or targeted PCR. The cross-sectional, multi-donor design of this study — with muscle samples from donors unrelated to DRG donors — precludes tissue-paired comparisons and limits interpretability of inter-tissue differences. Future studies should prioritize larger cohorts with tissue-paired sampling across defined clinical groups (e.g., neuropathic pain versus controls) to achieve the statistical power required to distinguish genuine virome signals from donor-to-donor variation. These findings establish baseline expectations for computational neural virome profiling and underscore the need for improved reference databases, alignment-based confirmation, and targeted viral enrichment strategies.

---

## Notes for revision

**Word count:** ~370 words. Compressible to 250 by condensing the Methods sentence if needed.

**Language choices:**
- "CMV-associated reads/signal" throughout (not "CMV detected") — appropriate hedge because 0.5–4 RPM from a k-mer classifier against a viral-only database cannot be distinguished from host sequences sharing k-mer similarity without alignment validation
- "Modestly elevated" for HERV-K DRG vs muscle — with n=2 donors, no statistical power for "significantly enriched"
- HERV-K framed as internal positive control demonstrating the pipeline detects real viral-derived sequences

**Sample counts:** 11 DRG + 5 muscle = 16 samples used here. AIG1390 excluded (confirmed donor1 duplicate). Saad_2 excluded (failed library). The 4 usable Saad samples were not available for this manuscript draft.

**Pending validation before finalizing:**
- Hantavirus batch signal — BLAST validation needed; not included in abstract
- CMV claim — alignment-based validation (minimap2 to HHV-5 reference) required to confirm
- HERV-K DRG enrichment — would benefit from normalized expression comparison
