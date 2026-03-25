# SRA + Zenodo Submission Guide — Paper 1

## Overview
Two parallel tracks, start both today. SRA takes 1–2 weeks to process; Zenodo is same-day.

---

## Track 1 — SRA (NCBI) — Raw sequencing data

### Step 1: Create a BioProject (~10 min)
1. Go to: https://submit.ncbi.nlm.nih.gov/subs/bioproject/
2. Click **New submission**
3. Fill in:
   - **Project title:** Systematic computational virome profiling of human dorsal root ganglion and skeletal muscle from bulk RNA-seq
   - **Description:** Paired-end bulk RNA-seq from 15 human samples (11 DRG, 5 skeletal muscle) used to develop and validate a k-mer-based virome profiling pipeline. Raw FASTQs submitted for data availability; processed results available via the pipeline repository.
   - **Relevance:** Medical
   - **Sample scope:** Multiisolate
4. Save the **BioProject accession (PRJNA######)** — you'll need it for BioSamples

### Step 2: Register BioSamples (~20 min)
1. Go to: https://submit.ncbi.nlm.nih.gov/subs/biosample/
2. Choose **Human package** (since these are human tissue samples — IRB/consent info will be required)
3. Upload `biosample_attributes.tsv` from this directory
4. Replace all `PRJNA_PLACEHOLDER` with your actual BioProject accession first
5. **Important:** You will need IRB protocol number and confirmation that samples are de-identified
6. Record all **SAMN###### accessions** returned

### Step 3: Submit SRA runs (~30 min + upload time)
1. Go to: https://submit.ncbi.nlm.nih.gov/subs/sra/
2. Link to your BioProject and BioSamples
3. For each sample, provide:
   - Library strategy: RNA-Seq
   - Library source: TRANSCRIPTOMIC
   - Library selection: cDNA
   - Library layout: PAIRED
   - Platform: ILLUMINA
   - Instrument: NovaSeq 6000
   - File format: FASTQ (gzipped)
4. Upload FASTQs — options:
   - **FTP upload** (recommended for large files): ncbi provides credentials after starting submission
   - **Aspera** (faster for large files)
5. Processing takes 5–14 days after files are received

### What you need before starting SRA
- [ ] IRB protocol number (or confirmation samples are exempt/de-identified)
- [ ] Consent documentation confirming data can be publicly shared (or controlled access)
- [ ] Confirmation of NovaSeq 6000 instrument model
- [ ] Collection dates (can use "not collected" if unavailable)
- [ ] Donor sex/age (can use "not collected" — mark as restricted if identifiable)

**Note on controlled vs. open access:** If donors are not fully de-identified, use dbGaP (controlled access) instead of SRA (open access). Check with your IRB.

---

## Track 2 — Zenodo — Pipeline code DOI (~1 hour)

### Step 1: Connect GitHub to Zenodo
1. Go to: https://zenodo.org
2. Log in with GitHub (or create account)
3. Go to **GitHub** tab in your Zenodo profile
4. Find `virome-pipeline` in the repository list
5. Toggle it **ON** — Zenodo will now watch for releases

### Step 2: Create a GitHub release
```bash
# Tag the current commit as v1.2.0
git tag -a v1.2.0 -m "v1.2.0: taxon remapping, expanded artifact list, research directory"
git push origin v1.2.0
```
Then on GitHub.com:
- Go to Releases → Draft a new release
- Tag: v1.2.0
- Title: "virome-pipeline v1.2.0"
- Description: copy from git log or CLAUDE.md version notes
- Click **Publish release**

### Step 3: Get the DOI
- Zenodo automatically creates a DOI within ~5 minutes of the release
- Go to your Zenodo dashboard to find it: `10.5281/zenodo.XXXXXXX`
- This is what goes in the Methods section: *"Pipeline code available at https://github.com/mwilde49/virome-pipeline (DOI: 10.5281/zenodo.XXXXXXX)"*

### Zenodo metadata to fill in
- **Title:** virome-pipeline: Nextflow pipeline for systematic viral profiling of human neural tissue from bulk RNA-seq
- **Authors:** [your name + co-authors]
- **Description:** paste from GitHub README or paper abstract
- **Keywords:** virome, Kraken2, Bracken, Nextflow, dorsal root ganglion, bulk RNA-seq, metagenomics
- **License:** MIT (or whichever is in your repo)
- **Related identifiers:** add SRA BioProject accession once obtained

---

## Timeline
| Day | Action |
|-----|--------|
| Today | Create GitHub release tag v1.2.0; enable Zenodo integration; start BioProject + BioSample registration |
| Day 2 | Upload FASTQs to SRA FTP |
| Day 3–7 | SRA processing underway; begin manuscript draft |
| Day 7–14 | SRA accession confirmed; insert into manuscript |
| Day 14 | Manuscript + figures complete; submit |
