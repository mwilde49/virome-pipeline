#!/usr/bin/env bash
# Stage the 157-sample gataca -> Titan(on Juno) virome batch, run from bbs88355.
# CORRECTED 2026-08-18: destination is a REMOTE host (juno.hpcre.utdallas.edu),
# not a local path on bbs88355 -- the first version of this script wrote to a
# bogus local directory instead and filled bbs88355's own root disk. Every rsync
# below now targets the real remote Titan mount over SSH, reusing the
# ControlMaster connection opened by the setup step so you only authenticate once.
set -euo pipefail

JUNO_HOST="maw210003@juno.hpcre.utdallas.edu"
CTRL_PATH="$HOME/.ssh/controlmasters/juno-%r@%h:%p"
TITAN_BASE="/titan/tprice/ingest/virome"

# Fail fast with a clear message if the ControlMaster connection from the setup
# step isn't actually up, rather than having every rsync below silently prompt
# for a password 11 separate times.
if ! ssh -O check -o ControlPath="${CTRL_PATH}" "${JUNO_HOST}" 2>/dev/null; then
  echo "ERROR: no live SSH ControlMaster connection to ${JUNO_HOST}." >&2
  echo "Run this first, then re-run this script:" >&2
  echo "  ssh -M -S ${CTRL_PATH} -o ControlPersist=1h ${JUNO_HOST} true" >&2
  exit 1
fi

# --- watchmaker  (2025_Watchmaker_Asta.Jayden.Katherin.Alejandro)  [60 files] ---
ssh -o ControlPath="${CTRL_PATH}" "${JUNO_HOST}" "mkdir -p '${TITAN_BASE}/2025_Watchmaker_Asta.Jayden.Katherin.Alejandro'"
rsync -avP -e "ssh -o ControlPath=${CTRL_PATH}" \
  "/mnt/gataca/data/homo_sapiens/Dorsal_root_ganglia/bulk_rnaseq/2025_Watchmaker_Asta.Jayden.Katherin.Alejandro/bcl/250124_VH00905_85_AACFYTWHV/Analysis/2/Data/fastq/MB1_S14_R1_001.fastq.gz" \
  "/mnt/gataca/data/homo_sapiens/Dorsal_root_ganglia/bulk_rnaseq/2025_Watchmaker_Asta.Jayden.Katherin.Alejandro/bcl/250124_VH00905_85_AACFYTWHV/Analysis/2/Data/fastq/MB1_S14_R2_001.fastq.gz" \
  "/mnt/gataca/data/homo_sapiens/Dorsal_root_ganglia/bulk_rnaseq/2025_Watchmaker_Asta.Jayden.Katherin.Alejandro/bcl/250124_VH00905_85_AACFYTWHV/Analysis/2/Data/fastq/MB2_S13_R1_001.fastq.gz" \
  "/mnt/gataca/data/homo_sapiens/Dorsal_root_ganglia/bulk_rnaseq/2025_Watchmaker_Asta.Jayden.Katherin.Alejandro/bcl/250124_VH00905_85_AACFYTWHV/Analysis/2/Data/fastq/MB2_S13_R2_001.fastq.gz" \
  "/mnt/gataca/data/homo_sapiens/Dorsal_root_ganglia/bulk_rnaseq/2025_Watchmaker_Asta.Jayden.Katherin.Alejandro/bcl/250124_VH00905_85_AACFYTWHV/Analysis/2/Data/fastq/MB3_S12_R1_001.fastq.gz" \
  "/mnt/gataca/data/homo_sapiens/Dorsal_root_ganglia/bulk_rnaseq/2025_Watchmaker_Asta.Jayden.Katherin.Alejandro/bcl/250124_VH00905_85_AACFYTWHV/Analysis/2/Data/fastq/MB3_S12_R2_001.fastq.gz" \
  "/mnt/gataca/data/homo_sapiens/Dorsal_root_ganglia/bulk_rnaseq/2025_Watchmaker_Asta.Jayden.Katherin.Alejandro/bcl/250124_VH00905_85_AACFYTWHV/Analysis/2/Data/fastq/MB4_S11_R1_001.fastq.gz" \
  "/mnt/gataca/data/homo_sapiens/Dorsal_root_ganglia/bulk_rnaseq/2025_Watchmaker_Asta.Jayden.Katherin.Alejandro/bcl/250124_VH00905_85_AACFYTWHV/Analysis/2/Data/fastq/MB4_S11_R2_001.fastq.gz" \
  "/mnt/gataca/data/homo_sapiens/Dorsal_root_ganglia/bulk_rnaseq/2025_Watchmaker_Asta.Jayden.Katherin.Alejandro/bcl/250124_VH00905_85_AACFYTWHV/Analysis/2/Data/fastq/MB5_S10_R1_001.fastq.gz" \
  "/mnt/gataca/data/homo_sapiens/Dorsal_root_ganglia/bulk_rnaseq/2025_Watchmaker_Asta.Jayden.Katherin.Alejandro/bcl/250124_VH00905_85_AACFYTWHV/Analysis/2/Data/fastq/MB5_S10_R2_001.fastq.gz" \
  "/mnt/gataca/data/homo_sapiens/Dorsal_root_ganglia/bulk_rnaseq/2025_Watchmaker_Asta.Jayden.Katherin.Alejandro/bcl/250124_VH00905_85_AACFYTWHV/Analysis/2/Data/fastq/MB6_S9_R1_001.fastq.gz" \
  "/mnt/gataca/data/homo_sapiens/Dorsal_root_ganglia/bulk_rnaseq/2025_Watchmaker_Asta.Jayden.Katherin.Alejandro/bcl/250124_VH00905_85_AACFYTWHV/Analysis/2/Data/fastq/MB6_S9_R2_001.fastq.gz" \
  "/mnt/gataca/data/homo_sapiens/Dorsal_root_ganglia/bulk_rnaseq/2025_Watchmaker_Asta.Jayden.Katherin.Alejandro/fastq/Alejandro/Dataset_Copy_3_31_2025_7_51_15_PM-814562756/_copy_AO1-ds.c85759094340431d8ba1ba7c87c91025/AO1_S8_L001_R1_001.fastq.gz" \
  "/mnt/gataca/data/homo_sapiens/Dorsal_root_ganglia/bulk_rnaseq/2025_Watchmaker_Asta.Jayden.Katherin.Alejandro/fastq/Alejandro/Dataset_Copy_3_31_2025_7_51_15_PM-814562756/_copy_AO1-ds.c85759094340431d8ba1ba7c87c91025/AO1_S8_L001_R2_001.fastq.gz" \
  "/mnt/gataca/data/homo_sapiens/Dorsal_root_ganglia/bulk_rnaseq/2025_Watchmaker_Asta.Jayden.Katherin.Alejandro/fastq/Alejandro/Dataset_Copy_3_31_2025_7_51_15_PM-814571768/_copy_AO6-ds.6a135c78175742c7b15343ae1fce678d/AO6_S3_L001_R1_001.fastq.gz" \
  "/mnt/gataca/data/homo_sapiens/Dorsal_root_ganglia/bulk_rnaseq/2025_Watchmaker_Asta.Jayden.Katherin.Alejandro/fastq/Alejandro/Dataset_Copy_3_31_2025_7_51_15_PM-814571768/_copy_AO6-ds.6a135c78175742c7b15343ae1fce678d/AO6_S3_L001_R2_001.fastq.gz" \
  "/mnt/gataca/data/homo_sapiens/Dorsal_root_ganglia/bulk_rnaseq/2025_Watchmaker_Asta.Jayden.Katherin.Alejandro/fastq/Alejandro/Dataset_Copy_3_31_2025_7_51_15_PM-814596794/_copy_AO5-ds.a481a37e8b9b45028437142b1ebc308f/AO5_S4_L001_R1_001.fastq.gz" \
  "/mnt/gataca/data/homo_sapiens/Dorsal_root_ganglia/bulk_rnaseq/2025_Watchmaker_Asta.Jayden.Katherin.Alejandro/fastq/Alejandro/Dataset_Copy_3_31_2025_7_51_15_PM-814596794/_copy_AO5-ds.a481a37e8b9b45028437142b1ebc308f/AO5_S4_L001_R2_001.fastq.gz" \
  "/mnt/gataca/data/homo_sapiens/Dorsal_root_ganglia/bulk_rnaseq/2025_Watchmaker_Asta.Jayden.Katherin.Alejandro/fastq/Alejandro/Dataset_Copy_3_31_2025_7_51_15_PM-814677868/_copy_AO2-ds.c1f0e7da6ca9479b8b2fb31230e31b86/AO2_S7_L001_R1_001.fastq.gz" \
  "/mnt/gataca/data/homo_sapiens/Dorsal_root_ganglia/bulk_rnaseq/2025_Watchmaker_Asta.Jayden.Katherin.Alejandro/fastq/Alejandro/Dataset_Copy_3_31_2025_7_51_15_PM-814677868/_copy_AO2-ds.c1f0e7da6ca9479b8b2fb31230e31b86/AO2_S7_L001_R2_001.fastq.gz" \
  "/mnt/gataca/data/homo_sapiens/Dorsal_root_ganglia/bulk_rnaseq/2025_Watchmaker_Asta.Jayden.Katherin.Alejandro/fastq/Alejandro/Dataset_Copy_3_31_2025_7_51_15_PM-814698887/_copy_AO3-ds.87e0594b7407477d9fd775dd285f7b79/AO3_S6_L001_R1_001.fastq.gz" \
  "/mnt/gataca/data/homo_sapiens/Dorsal_root_ganglia/bulk_rnaseq/2025_Watchmaker_Asta.Jayden.Katherin.Alejandro/fastq/Alejandro/Dataset_Copy_3_31_2025_7_51_15_PM-814698887/_copy_AO3-ds.87e0594b7407477d9fd775dd285f7b79/AO3_S6_L001_R2_001.fastq.gz" \
  "/mnt/gataca/data/homo_sapiens/Dorsal_root_ganglia/bulk_rnaseq/2025_Watchmaker_Asta.Jayden.Katherin.Alejandro/fastq/Alejandro/Dataset_Copy_3_31_2025_7_51_16_PM-814090321/_copy_AO7-ds.39af906c40f24f6cb5c483c828223389/AO7_S2_L001_R1_001.fastq.gz" \
  "/mnt/gataca/data/homo_sapiens/Dorsal_root_ganglia/bulk_rnaseq/2025_Watchmaker_Asta.Jayden.Katherin.Alejandro/fastq/Alejandro/Dataset_Copy_3_31_2025_7_51_16_PM-814090321/_copy_AO7-ds.39af906c40f24f6cb5c483c828223389/AO7_S2_L001_R2_001.fastq.gz" \
  "/mnt/gataca/data/homo_sapiens/Dorsal_root_ganglia/bulk_rnaseq/2025_Watchmaker_Asta.Jayden.Katherin.Alejandro/fastq/Alejandro/Dataset_Copy_3_31_2025_7_51_16_PM-814349550/_copy_AO8-ds.c67068696c434d3e82f293ae6edadb7e/AO8_S1_L001_R1_001.fastq.gz" \
  "/mnt/gataca/data/homo_sapiens/Dorsal_root_ganglia/bulk_rnaseq/2025_Watchmaker_Asta.Jayden.Katherin.Alejandro/fastq/Alejandro/Dataset_Copy_3_31_2025_7_51_16_PM-814349550/_copy_AO8-ds.c67068696c434d3e82f293ae6edadb7e/AO8_S1_L001_R2_001.fastq.gz" \
  "/mnt/gataca/data/homo_sapiens/Dorsal_root_ganglia/bulk_rnaseq/2025_Watchmaker_Asta.Jayden.Katherin.Alejandro/fastq/Alejandro/Dataset_Copy_3_31_2025_7_51_16_PM-814388594/_copy_AO4-ds.e4920ec24afd40dd823228229a08e78f/AO4_S5_L001_R1_001.fastq.gz" \
  "/mnt/gataca/data/homo_sapiens/Dorsal_root_ganglia/bulk_rnaseq/2025_Watchmaker_Asta.Jayden.Katherin.Alejandro/fastq/Alejandro/Dataset_Copy_3_31_2025_7_51_16_PM-814388594/_copy_AO4-ds.e4920ec24afd40dd823228229a08e78f/AO4_S5_L001_R2_001.fastq.gz" \
  "/mnt/gataca/data/homo_sapiens/Dorsal_root_ganglia/bulk_rnaseq/2025_Watchmaker_Asta.Jayden.Katherin.Alejandro/fastq/Asta/Dataset_Copy_3_31_2025_7_51_15_PM-814431628/_copy_AA5-ds.ebfc1db796f448bc963c709adb85974e/AA5_S18_L001_R1_001.fastq.gz" \
  "/mnt/gataca/data/homo_sapiens/Dorsal_root_ganglia/bulk_rnaseq/2025_Watchmaker_Asta.Jayden.Katherin.Alejandro/fastq/Asta/Dataset_Copy_3_31_2025_7_51_15_PM-814431628/_copy_AA5-ds.ebfc1db796f448bc963c709adb85974e/AA5_S18_L001_R2_001.fastq.gz" \
  "/mnt/gataca/data/homo_sapiens/Dorsal_root_ganglia/bulk_rnaseq/2025_Watchmaker_Asta.Jayden.Katherin.Alejandro/fastq/Asta/Dataset_Copy_3_31_2025_7_51_15_PM-814451657/_copy_AA6-ds.553bf7c732be454bb9d35af034304350/AA6_S17_L001_R1_001.fastq.gz" \
  "/mnt/gataca/data/homo_sapiens/Dorsal_root_ganglia/bulk_rnaseq/2025_Watchmaker_Asta.Jayden.Katherin.Alejandro/fastq/Asta/Dataset_Copy_3_31_2025_7_51_15_PM-814451657/_copy_AA6-ds.553bf7c732be454bb9d35af034304350/AA6_S17_L001_R2_001.fastq.gz" \
  "/mnt/gataca/data/homo_sapiens/Dorsal_root_ganglia/bulk_rnaseq/2025_Watchmaker_Asta.Jayden.Katherin.Alejandro/fastq/Asta/Dataset_Copy_3_31_2025_7_51_15_PM-814500692/_copy_AA4-ds.a3266e389e214f6d885a46394a04305f/AA4_S19_L001_R1_001.fastq.gz" \
  "/mnt/gataca/data/homo_sapiens/Dorsal_root_ganglia/bulk_rnaseq/2025_Watchmaker_Asta.Jayden.Katherin.Alejandro/fastq/Asta/Dataset_Copy_3_31_2025_7_51_15_PM-814500692/_copy_AA4-ds.a3266e389e214f6d885a46394a04305f/AA4_S19_L001_R2_001.fastq.gz" \
  "/mnt/gataca/data/homo_sapiens/Dorsal_root_ganglia/bulk_rnaseq/2025_Watchmaker_Asta.Jayden.Katherin.Alejandro/fastq/Asta/Dataset_Copy_3_31_2025_7_51_15_PM-814569764/_copy_AA3-ds.047a6d9eb7f94b7e983e7777f57e7e10/AA3_S20_L001_R1_001.fastq.gz" \
  "/mnt/gataca/data/homo_sapiens/Dorsal_root_ganglia/bulk_rnaseq/2025_Watchmaker_Asta.Jayden.Katherin.Alejandro/fastq/Asta/Dataset_Copy_3_31_2025_7_51_15_PM-814569764/_copy_AA3-ds.047a6d9eb7f94b7e983e7777f57e7e10/AA3_S20_L001_R2_001.fastq.gz" \
  "/mnt/gataca/data/homo_sapiens/Dorsal_root_ganglia/bulk_rnaseq/2025_Watchmaker_Asta.Jayden.Katherin.Alejandro/fastq/Asta/Dataset_Copy_3_31_2025_7_51_15_PM-814595789/_copy_AA8-ds.14099ec3c0c14b09a4be1be3a7e95997/AA8_S15_L001_R1_001.fastq.gz" \
  "/mnt/gataca/data/homo_sapiens/Dorsal_root_ganglia/bulk_rnaseq/2025_Watchmaker_Asta.Jayden.Katherin.Alejandro/fastq/Asta/Dataset_Copy_3_31_2025_7_51_15_PM-814595789/_copy_AA8-ds.14099ec3c0c14b09a4be1be3a7e95997/AA8_S15_L001_R2_001.fastq.gz" \
  "/mnt/gataca/data/homo_sapiens/Dorsal_root_ganglia/bulk_rnaseq/2025_Watchmaker_Asta.Jayden.Katherin.Alejandro/fastq/Asta/Dataset_Copy_3_31_2025_7_51_15_PM-814598794/_copy_AA1-ds.852b1889aeca46e39d8b4153b8a7ee35/AA1_S22_L001_R1_001.fastq.gz" \
  "/mnt/gataca/data/homo_sapiens/Dorsal_root_ganglia/bulk_rnaseq/2025_Watchmaker_Asta.Jayden.Katherin.Alejandro/fastq/Asta/Dataset_Copy_3_31_2025_7_51_15_PM-814598794/_copy_AA1-ds.852b1889aeca46e39d8b4153b8a7ee35/AA1_S22_L001_R2_001.fastq.gz" \
  "/mnt/gataca/data/homo_sapiens/Dorsal_root_ganglia/bulk_rnaseq/2025_Watchmaker_Asta.Jayden.Katherin.Alejandro/fastq/Asta/Dataset_Copy_3_31_2025_7_51_15_PM-814642834/_copy_AA2-ds.4b6c5d59bc034a14b06189de5bb6063e/AA2_S21_L001_R1_001.fastq.gz" \
  "/mnt/gataca/data/homo_sapiens/Dorsal_root_ganglia/bulk_rnaseq/2025_Watchmaker_Asta.Jayden.Katherin.Alejandro/fastq/Asta/Dataset_Copy_3_31_2025_7_51_15_PM-814642834/_copy_AA2-ds.4b6c5d59bc034a14b06189de5bb6063e/AA2_S21_L001_R2_001.fastq.gz" \
  "/mnt/gataca/data/homo_sapiens/Dorsal_root_ganglia/bulk_rnaseq/2025_Watchmaker_Asta.Jayden.Katherin.Alejandro/fastq/Asta/Dataset_Copy_3_31_2025_7_51_15_PM-814718908/_copy_AA7-ds.5b1c339788d04f32980815f5623e09fc/AA7_S16_L001_R1_001.fastq.gz" \
  "/mnt/gataca/data/homo_sapiens/Dorsal_root_ganglia/bulk_rnaseq/2025_Watchmaker_Asta.Jayden.Katherin.Alejandro/fastq/Asta/Dataset_Copy_3_31_2025_7_51_15_PM-814718908/_copy_AA7-ds.5b1c339788d04f32980815f5623e09fc/AA7_S16_L001_R2_001.fastq.gz" \
  "/mnt/gataca/data/homo_sapiens/Dorsal_root_ganglia/bulk_rnaseq/2025_Watchmaker_Asta.Jayden.Katherin.Alejandro/fastq/Jayden/Dataset_Copy_3_31_2025_7_51_15_PM-814464663/_copy_JOA6-ds.a5a9b366bd8a4b2b8324957c0e8d3f07/JOA6_S25_L001_R1_001.fastq.gz" \
  "/mnt/gataca/data/homo_sapiens/Dorsal_root_ganglia/bulk_rnaseq/2025_Watchmaker_Asta.Jayden.Katherin.Alejandro/fastq/Jayden/Dataset_Copy_3_31_2025_7_51_15_PM-814464663/_copy_JOA6-ds.a5a9b366bd8a4b2b8324957c0e8d3f07/JOA6_S25_L001_R2_001.fastq.gz" \
  "/mnt/gataca/data/homo_sapiens/Dorsal_root_ganglia/bulk_rnaseq/2025_Watchmaker_Asta.Jayden.Katherin.Alejandro/fastq/Jayden/Dataset_Copy_3_31_2025_7_51_15_PM-814566767/_copy_JOA8-ds.eb220c5ed0d042f2abeb854bc8246330/JOA8_S23_L001_R1_001.fastq.gz" \
  "/mnt/gataca/data/homo_sapiens/Dorsal_root_ganglia/bulk_rnaseq/2025_Watchmaker_Asta.Jayden.Katherin.Alejandro/fastq/Jayden/Dataset_Copy_3_31_2025_7_51_15_PM-814566767/_copy_JOA8-ds.eb220c5ed0d042f2abeb854bc8246330/JOA8_S23_L001_R2_001.fastq.gz" \
  "/mnt/gataca/data/homo_sapiens/Dorsal_root_ganglia/bulk_rnaseq/2025_Watchmaker_Asta.Jayden.Katherin.Alejandro/fastq/Jayden/Dataset_Copy_3_31_2025_7_51_15_PM-814567771/_copy_JOA7-ds.60b0c12efc514397a9bf6ba5603ecc44/JOA7_S24_L001_R1_001.fastq.gz" \
  "/mnt/gataca/data/homo_sapiens/Dorsal_root_ganglia/bulk_rnaseq/2025_Watchmaker_Asta.Jayden.Katherin.Alejandro/fastq/Jayden/Dataset_Copy_3_31_2025_7_51_15_PM-814567771/_copy_JOA7-ds.60b0c12efc514397a9bf6ba5603ecc44/JOA7_S24_L001_R2_001.fastq.gz" \
  "/mnt/gataca/data/homo_sapiens/Dorsal_root_ganglia/bulk_rnaseq/2025_Watchmaker_Asta.Jayden.Katherin.Alejandro/fastq/Jayden/Dataset_Copy_3_31_2025_7_51_15_PM-814585778/_copy_JOA5-ds.b607dfff7ba944e8b6a0d5fe7d2eddfe/JOA5_S26_L001_R1_001.fastq.gz" \
  "/mnt/gataca/data/homo_sapiens/Dorsal_root_ganglia/bulk_rnaseq/2025_Watchmaker_Asta.Jayden.Katherin.Alejandro/fastq/Jayden/Dataset_Copy_3_31_2025_7_51_15_PM-814585778/_copy_JOA5-ds.b607dfff7ba944e8b6a0d5fe7d2eddfe/JOA5_S26_L001_R2_001.fastq.gz" \
  "/mnt/gataca/data/homo_sapiens/Dorsal_root_ganglia/bulk_rnaseq/2025_Watchmaker_Asta.Jayden.Katherin.Alejandro/fastq/Jayden/Dataset_Copy_3_31_2025_7_51_15_PM-814587781/_copy_JOA2-ds.aedf3a208f86464a85b6e41d0d542d30/JOA2_S29_L001_R1_001.fastq.gz" \
  "/mnt/gataca/data/homo_sapiens/Dorsal_root_ganglia/bulk_rnaseq/2025_Watchmaker_Asta.Jayden.Katherin.Alejandro/fastq/Jayden/Dataset_Copy_3_31_2025_7_51_15_PM-814587781/_copy_JOA2-ds.aedf3a208f86464a85b6e41d0d542d30/JOA2_S29_L001_R2_001.fastq.gz" \
  "/mnt/gataca/data/homo_sapiens/Dorsal_root_ganglia/bulk_rnaseq/2025_Watchmaker_Asta.Jayden.Katherin.Alejandro/fastq/Jayden/Dataset_Copy_3_31_2025_7_51_15_PM-814621819/_copy_JOA4-ds.ed00a4d35f434392b061fe1a4a980dfc/JOA4_S27_L001_R1_001.fastq.gz" \
  "/mnt/gataca/data/homo_sapiens/Dorsal_root_ganglia/bulk_rnaseq/2025_Watchmaker_Asta.Jayden.Katherin.Alejandro/fastq/Jayden/Dataset_Copy_3_31_2025_7_51_15_PM-814621819/_copy_JOA4-ds.ed00a4d35f434392b061fe1a4a980dfc/JOA4_S27_L001_R2_001.fastq.gz" \
  "/mnt/gataca/data/homo_sapiens/Dorsal_root_ganglia/bulk_rnaseq/2025_Watchmaker_Asta.Jayden.Katherin.Alejandro/fastq/Jayden/Dataset_Copy_3_31_2025_7_51_15_PM-814732921/_copy_JOA1-ds.683731ee1a6145f296089529c8202fc2/JOA1_S30_L001_R1_001.fastq.gz" \
  "/mnt/gataca/data/homo_sapiens/Dorsal_root_ganglia/bulk_rnaseq/2025_Watchmaker_Asta.Jayden.Katherin.Alejandro/fastq/Jayden/Dataset_Copy_3_31_2025_7_51_15_PM-814732921/_copy_JOA1-ds.683731ee1a6145f296089529c8202fc2/JOA1_S30_L001_R2_001.fastq.gz" \
  "/mnt/gataca/data/homo_sapiens/Dorsal_root_ganglia/bulk_rnaseq/2025_Watchmaker_Asta.Jayden.Katherin.Alejandro/fastq/Jayden/Dataset_Copy_3_31_2025_7_51_15_PM-814763950/_copy_JOA3-ds.141c47de5b154905a2b2df7d341cbc26/JOA3_S28_L001_R1_001.fastq.gz" \
  "/mnt/gataca/data/homo_sapiens/Dorsal_root_ganglia/bulk_rnaseq/2025_Watchmaker_Asta.Jayden.Katherin.Alejandro/fastq/Jayden/Dataset_Copy_3_31_2025_7_51_15_PM-814763950/_copy_JOA3-ds.141c47de5b154905a2b2df7d341cbc26/JOA3_S28_L001_R2_001.fastq.gz" \
  "${JUNO_HOST}:${TITAN_BASE}/2025_Watchmaker_Asta.Jayden.Katherin.Alejandro/"

# --- dpn_ra_kulkarni  (2023_rheumatoidArthritis_AshokKulkarni)  [50 files] ---
ssh -o ControlPath="${CTRL_PATH}" "${JUNO_HOST}" "mkdir -p '${TITAN_BASE}/2023_rheumatoidArthritis_AshokKulkarni'"
rsync -avP -e "ssh -o ControlPath=${CTRL_PATH}" \
  "/mnt/gataca/data/homo_sapiens/Dorsal_root_ganglia/bulk_rnaseq/2023_rheumatoidArthritis_AshokKulkarni/fastq/RA/1VYA1.R1.fastq.gz" \
  "/mnt/gataca/data/homo_sapiens/Dorsal_root_ganglia/bulk_rnaseq/2023_rheumatoidArthritis_AshokKulkarni/fastq/RA/1VYA1.R2.fastq.gz" \
  "/mnt/gataca/data/homo_sapiens/Dorsal_root_ganglia/bulk_rnaseq/2023_rheumatoidArthritis_AshokKulkarni/fastq/RA/1VYB2.R1.fastq.gz" \
  "/mnt/gataca/data/homo_sapiens/Dorsal_root_ganglia/bulk_rnaseq/2023_rheumatoidArthritis_AshokKulkarni/fastq/RA/1VYB2.R2.fastq.gz" \
  "/mnt/gataca/data/homo_sapiens/Dorsal_root_ganglia/bulk_rnaseq/2023_rheumatoidArthritis_AshokKulkarni/fastq/RA/4LIA1.R1.fastq.gz" \
  "/mnt/gataca/data/homo_sapiens/Dorsal_root_ganglia/bulk_rnaseq/2023_rheumatoidArthritis_AshokKulkarni/fastq/RA/4LIA1.R2.fastq.gz" \
  "/mnt/gataca/data/homo_sapiens/Dorsal_root_ganglia/bulk_rnaseq/2023_rheumatoidArthritis_AshokKulkarni/fastq/RA/4LIB2.R1.fastq.gz" \
  "/mnt/gataca/data/homo_sapiens/Dorsal_root_ganglia/bulk_rnaseq/2023_rheumatoidArthritis_AshokKulkarni/fastq/RA/4LIB2.R2.fastq.gz" \
  "/mnt/gataca/data/homo_sapiens/Dorsal_root_ganglia/bulk_rnaseq/2023_rheumatoidArthritis_AshokKulkarni/fastq/RA/CA7A2.R1.fastq.gz" \
  "/mnt/gataca/data/homo_sapiens/Dorsal_root_ganglia/bulk_rnaseq/2023_rheumatoidArthritis_AshokKulkarni/fastq/RA/CA7A2.R2.fastq.gz" \
  "/mnt/gataca/data/homo_sapiens/Dorsal_root_ganglia/bulk_rnaseq/2023_rheumatoidArthritis_AshokKulkarni/fastq/RA/CA7B1.R1.fastq.gz" \
  "/mnt/gataca/data/homo_sapiens/Dorsal_root_ganglia/bulk_rnaseq/2023_rheumatoidArthritis_AshokKulkarni/fastq/RA/CA7B1.R2.fastq.gz" \
  "/mnt/gataca/data/homo_sapiens/Dorsal_root_ganglia/bulk_rnaseq/2023_rheumatoidArthritis_AshokKulkarni/fastq/RA/FL0A2.R1.fastq.gz" \
  "/mnt/gataca/data/homo_sapiens/Dorsal_root_ganglia/bulk_rnaseq/2023_rheumatoidArthritis_AshokKulkarni/fastq/RA/FL0A2.R2.fastq.gz" \
  "/mnt/gataca/data/homo_sapiens/Dorsal_root_ganglia/bulk_rnaseq/2023_rheumatoidArthritis_AshokKulkarni/fastq/RA/FL0B1.R1.fastq.gz" \
  "/mnt/gataca/data/homo_sapiens/Dorsal_root_ganglia/bulk_rnaseq/2023_rheumatoidArthritis_AshokKulkarni/fastq/RA/FL0B1.R2.fastq.gz" \
  "/mnt/gataca/data/homo_sapiens/Dorsal_root_ganglia/bulk_rnaseq/2023_rheumatoidArthritis_AshokKulkarni/fastq/RA/G1NA1.R1.fastq.gz" \
  "/mnt/gataca/data/homo_sapiens/Dorsal_root_ganglia/bulk_rnaseq/2023_rheumatoidArthritis_AshokKulkarni/fastq/RA/G1NA1.R2.fastq.gz" \
  "/mnt/gataca/data/homo_sapiens/Dorsal_root_ganglia/bulk_rnaseq/2023_rheumatoidArthritis_AshokKulkarni/fastq/RA/G1NB2.R1.fastq.gz" \
  "/mnt/gataca/data/homo_sapiens/Dorsal_root_ganglia/bulk_rnaseq/2023_rheumatoidArthritis_AshokKulkarni/fastq/RA/G1NB2.R2.fastq.gz" \
  "/mnt/gataca/data/homo_sapiens/Dorsal_root_ganglia/bulk_rnaseq/2023_rheumatoidArthritis_AshokKulkarni/fastq/hDRG_DPN_PolyA/1AN1.R1.fastq.gz" \
  "/mnt/gataca/data/homo_sapiens/Dorsal_root_ganglia/bulk_rnaseq/2023_rheumatoidArthritis_AshokKulkarni/fastq/hDRG_DPN_PolyA/1AN1.R2.fastq.gz" \
  "/mnt/gataca/data/homo_sapiens/Dorsal_root_ganglia/bulk_rnaseq/2023_rheumatoidArthritis_AshokKulkarni/fastq/hDRG_DPN_PolyA/2AC1.R1.fastq.gz" \
  "/mnt/gataca/data/homo_sapiens/Dorsal_root_ganglia/bulk_rnaseq/2023_rheumatoidArthritis_AshokKulkarni/fastq/hDRG_DPN_PolyA/2AC1.R2.fastq.gz" \
  "/mnt/gataca/data/homo_sapiens/Dorsal_root_ganglia/bulk_rnaseq/2023_rheumatoidArthritis_AshokKulkarni/fastq/hDRG_DPN_PolyA/2OE1.R1.fastq.gz" \
  "/mnt/gataca/data/homo_sapiens/Dorsal_root_ganglia/bulk_rnaseq/2023_rheumatoidArthritis_AshokKulkarni/fastq/hDRG_DPN_PolyA/2OE1.R2.fastq.gz" \
  "/mnt/gataca/data/homo_sapiens/Dorsal_root_ganglia/bulk_rnaseq/2023_rheumatoidArthritis_AshokKulkarni/fastq/hDRG_DPN_PolyA/8EN1.R1.fastq.gz" \
  "/mnt/gataca/data/homo_sapiens/Dorsal_root_ganglia/bulk_rnaseq/2023_rheumatoidArthritis_AshokKulkarni/fastq/hDRG_DPN_PolyA/8EN1.R2.fastq.gz" \
  "/mnt/gataca/data/homo_sapiens/Dorsal_root_ganglia/bulk_rnaseq/2023_rheumatoidArthritis_AshokKulkarni/fastq/hDRG_DPN_PolyA/J1M2.R1.fastq.gz" \
  "/mnt/gataca/data/homo_sapiens/Dorsal_root_ganglia/bulk_rnaseq/2023_rheumatoidArthritis_AshokKulkarni/fastq/hDRG_DPN_PolyA/J1M2.R2.fastq.gz" \
  "/mnt/gataca/data/homo_sapiens/Dorsal_root_ganglia/bulk_rnaseq/2023_rheumatoidArthritis_AshokKulkarni/fastq/hDRG_DPN_PolyA/JE81.R1.fastq.gz" \
  "/mnt/gataca/data/homo_sapiens/Dorsal_root_ganglia/bulk_rnaseq/2023_rheumatoidArthritis_AshokKulkarni/fastq/hDRG_DPN_PolyA/JE81.R2.fastq.gz" \
  "/mnt/gataca/data/homo_sapiens/Dorsal_root_ganglia/bulk_rnaseq/2023_rheumatoidArthritis_AshokKulkarni/fastq/hDRG_DPN_PolyA/L1V1.R1.fastq.gz" \
  "/mnt/gataca/data/homo_sapiens/Dorsal_root_ganglia/bulk_rnaseq/2023_rheumatoidArthritis_AshokKulkarni/fastq/hDRG_DPN_PolyA/L1V1.R2.fastq.gz" \
  "/mnt/gataca/data/homo_sapiens/Dorsal_root_ganglia/bulk_rnaseq/2023_rheumatoidArthritis_AshokKulkarni/fastq/hDRG_DPN_PolyA/LE41.R1.fastq.gz" \
  "/mnt/gataca/data/homo_sapiens/Dorsal_root_ganglia/bulk_rnaseq/2023_rheumatoidArthritis_AshokKulkarni/fastq/hDRG_DPN_PolyA/LE41.R2.fastq.gz" \
  "/mnt/gataca/data/homo_sapiens/Dorsal_root_ganglia/bulk_rnaseq/2023_rheumatoidArthritis_AshokKulkarni/fastq/hDRG_DPN_PolyA/ME61.R1.fastq.gz" \
  "/mnt/gataca/data/homo_sapiens/Dorsal_root_ganglia/bulk_rnaseq/2023_rheumatoidArthritis_AshokKulkarni/fastq/hDRG_DPN_PolyA/ME61.R2.fastq.gz" \
  "/mnt/gataca/data/homo_sapiens/Dorsal_root_ganglia/bulk_rnaseq/2023_rheumatoidArthritis_AshokKulkarni/fastq/hDRG_DPN_PolyA/N4N2.R1.fastq.gz" \
  "/mnt/gataca/data/homo_sapiens/Dorsal_root_ganglia/bulk_rnaseq/2023_rheumatoidArthritis_AshokKulkarni/fastq/hDRG_DPN_PolyA/N4N2.R2.fastq.gz" \
  "/mnt/gataca/data/homo_sapiens/Dorsal_root_ganglia/bulk_rnaseq/2023_rheumatoidArthritis_AshokKulkarni/fastq/hDRG_DPN_PolyA/PA71.R1.fastq.gz" \
  "/mnt/gataca/data/homo_sapiens/Dorsal_root_ganglia/bulk_rnaseq/2023_rheumatoidArthritis_AshokKulkarni/fastq/hDRG_DPN_PolyA/PA71.R2.fastq.gz" \
  "/mnt/gataca/data/homo_sapiens/Dorsal_root_ganglia/bulk_rnaseq/2023_rheumatoidArthritis_AshokKulkarni/fastq/hDRG_DPN_PolyA/RO52.R1.fastq.gz" \
  "/mnt/gataca/data/homo_sapiens/Dorsal_root_ganglia/bulk_rnaseq/2023_rheumatoidArthritis_AshokKulkarni/fastq/hDRG_DPN_PolyA/RO52.R2.fastq.gz" \
  "/mnt/gataca/data/homo_sapiens/Dorsal_root_ganglia/bulk_rnaseq/2023_rheumatoidArthritis_AshokKulkarni/fastq/hDRG_DPN_PolyA/S1D1.R1.fastq.gz" \
  "/mnt/gataca/data/homo_sapiens/Dorsal_root_ganglia/bulk_rnaseq/2023_rheumatoidArthritis_AshokKulkarni/fastq/hDRG_DPN_PolyA/S1D1.R2.fastq.gz" \
  "/mnt/gataca/data/homo_sapiens/Dorsal_root_ganglia/bulk_rnaseq/2023_rheumatoidArthritis_AshokKulkarni/fastq/hDRG_DPN_PolyA/T0M2.R1.fastq.gz" \
  "/mnt/gataca/data/homo_sapiens/Dorsal_root_ganglia/bulk_rnaseq/2023_rheumatoidArthritis_AshokKulkarni/fastq/hDRG_DPN_PolyA/T0M2.R2.fastq.gz" \
  "/mnt/gataca/data/homo_sapiens/Dorsal_root_ganglia/bulk_rnaseq/2023_rheumatoidArthritis_AshokKulkarni/fastq/hDRG_DPN_PolyA/WE52.R1.fastq.gz" \
  "/mnt/gataca/data/homo_sapiens/Dorsal_root_ganglia/bulk_rnaseq/2023_rheumatoidArthritis_AshokKulkarni/fastq/hDRG_DPN_PolyA/WE52.R2.fastq.gz" \
  "${JUNO_HOST}:${TITAN_BASE}/2023_rheumatoidArthritis_AshokKulkarni/"

# --- thoracic_drg  (2022_ThoracicDRG_doloromics)  [48 files] ---
ssh -o ControlPath="${CTRL_PATH}" "${JUNO_HOST}" "mkdir -p '${TITAN_BASE}/2022_ThoracicDRG_doloromics'"
rsync -avP -e "ssh -o ControlPath=${CTRL_PATH}" \
  "/mnt/gataca/data/homo_sapiens/Dorsal_root_ganglia/bulk_rnaseq/2022_ThoracicDRG_doloromics/fastq/101T5L_L002-ds.49f8e7bc1f894afe956281de712c1c21/101T5L_S15_L002_R1_001.fastq.gz" \
  "/mnt/gataca/data/homo_sapiens/Dorsal_root_ganglia/bulk_rnaseq/2022_ThoracicDRG_doloromics/fastq/101T5L_L002-ds.49f8e7bc1f894afe956281de712c1c21/101T5L_S15_L002_R2_001.fastq.gz" \
  "/mnt/gataca/data/homo_sapiens/Dorsal_root_ganglia/bulk_rnaseq/2022_ThoracicDRG_doloromics/fastq/104T8L_L002-ds.902737ec46da4fa7b7bc16db58a5303f/104T8L_S16_L002_R1_001.fastq.gz" \
  "/mnt/gataca/data/homo_sapiens/Dorsal_root_ganglia/bulk_rnaseq/2022_ThoracicDRG_doloromics/fastq/104T8L_L002-ds.902737ec46da4fa7b7bc16db58a5303f/104T8L_S16_L002_R2_001.fastq.gz" \
  "/mnt/gataca/data/homo_sapiens/Dorsal_root_ganglia/bulk_rnaseq/2022_ThoracicDRG_doloromics/fastq/104T8R_L002-ds.e23b1cdba5934b828debc6d00f3de0f3/104T8R_S17_L002_R1_001.fastq.gz" \
  "/mnt/gataca/data/homo_sapiens/Dorsal_root_ganglia/bulk_rnaseq/2022_ThoracicDRG_doloromics/fastq/104T8R_L002-ds.e23b1cdba5934b828debc6d00f3de0f3/104T8R_S17_L002_R2_001.fastq.gz" \
  "/mnt/gataca/data/homo_sapiens/Dorsal_root_ganglia/bulk_rnaseq/2022_ThoracicDRG_doloromics/fastq/105T8L_L002-ds.7b9ffd59091740bdb029ab8a0e633b34/105T8L_S18_L002_R1_001.fastq.gz" \
  "/mnt/gataca/data/homo_sapiens/Dorsal_root_ganglia/bulk_rnaseq/2022_ThoracicDRG_doloromics/fastq/105T8L_L002-ds.7b9ffd59091740bdb029ab8a0e633b34/105T8L_S18_L002_R2_001.fastq.gz" \
  "/mnt/gataca/data/homo_sapiens/Dorsal_root_ganglia/bulk_rnaseq/2022_ThoracicDRG_doloromics/fastq/105T8R_L002-ds.161457c2ae22447d800de6f92b91811c/105T8R_S19_L002_R1_001.fastq.gz" \
  "/mnt/gataca/data/homo_sapiens/Dorsal_root_ganglia/bulk_rnaseq/2022_ThoracicDRG_doloromics/fastq/105T8R_L002-ds.161457c2ae22447d800de6f92b91811c/105T8R_S19_L002_R2_001.fastq.gz" \
  "/mnt/gataca/data/homo_sapiens/Dorsal_root_ganglia/bulk_rnaseq/2022_ThoracicDRG_doloromics/fastq/106T3L_L002-ds.b00eb733a3954a90a63824c04e4a78f8/106T3L_S20_L002_R1_001.fastq.gz" \
  "/mnt/gataca/data/homo_sapiens/Dorsal_root_ganglia/bulk_rnaseq/2022_ThoracicDRG_doloromics/fastq/106T3L_L002-ds.b00eb733a3954a90a63824c04e4a78f8/106T3L_S20_L002_R2_001.fastq.gz" \
  "/mnt/gataca/data/homo_sapiens/Dorsal_root_ganglia/bulk_rnaseq/2022_ThoracicDRG_doloromics/fastq/106T3R_L002-ds.1279abc4423f4aabb780c32346803888/106T3R_S21_L002_R1_001.fastq.gz" \
  "/mnt/gataca/data/homo_sapiens/Dorsal_root_ganglia/bulk_rnaseq/2022_ThoracicDRG_doloromics/fastq/106T3R_L002-ds.1279abc4423f4aabb780c32346803888/106T3R_S21_L002_R2_001.fastq.gz" \
  "/mnt/gataca/data/homo_sapiens/Dorsal_root_ganglia/bulk_rnaseq/2022_ThoracicDRG_doloromics/fastq/109T3_L002-ds.0d338060be1846f1ad9bbb8b638ad43f/109T3_S23_L002_R1_001.fastq.gz" \
  "/mnt/gataca/data/homo_sapiens/Dorsal_root_ganglia/bulk_rnaseq/2022_ThoracicDRG_doloromics/fastq/109T3_L002-ds.0d338060be1846f1ad9bbb8b638ad43f/109T3_S23_L002_R2_001.fastq.gz" \
  "/mnt/gataca/data/homo_sapiens/Dorsal_root_ganglia/bulk_rnaseq/2022_ThoracicDRG_doloromics/fastq/111T9R_L003-ds.1a9ae9e0b9b24186b2689a7a2d82286f/111T9R_S1_L003_R1_001.fastq.gz" \
  "/mnt/gataca/data/homo_sapiens/Dorsal_root_ganglia/bulk_rnaseq/2022_ThoracicDRG_doloromics/fastq/111T9R_L003-ds.1a9ae9e0b9b24186b2689a7a2d82286f/111T9R_S1_L003_R2_001.fastq.gz" \
  "/mnt/gataca/data/homo_sapiens/Dorsal_root_ganglia/bulk_rnaseq/2022_ThoracicDRG_doloromics/fastq/113T2R_L003-ds.349573656e2042498a14d608e261a8cf/113T2R_S2_L003_R1_001.fastq.gz" \
  "/mnt/gataca/data/homo_sapiens/Dorsal_root_ganglia/bulk_rnaseq/2022_ThoracicDRG_doloromics/fastq/113T2R_L003-ds.349573656e2042498a14d608e261a8cf/113T2R_S2_L003_R2_001.fastq.gz" \
  "/mnt/gataca/data/homo_sapiens/Dorsal_root_ganglia/bulk_rnaseq/2022_ThoracicDRG_doloromics/fastq/114T11L_L003-ds.68c1b5bf06c547e78de31da252b7f30f/114T11L_S3_L003_R1_001.fastq.gz" \
  "/mnt/gataca/data/homo_sapiens/Dorsal_root_ganglia/bulk_rnaseq/2022_ThoracicDRG_doloromics/fastq/114T11L_L003-ds.68c1b5bf06c547e78de31da252b7f30f/114T11L_S3_L003_R2_001.fastq.gz" \
  "/mnt/gataca/data/homo_sapiens/Dorsal_root_ganglia/bulk_rnaseq/2022_ThoracicDRG_doloromics/fastq/114T12R_L003-ds.82fccd0badb54b419390c8fb03fa1bf1/114T12R_S4_L003_R1_001.fastq.gz" \
  "/mnt/gataca/data/homo_sapiens/Dorsal_root_ganglia/bulk_rnaseq/2022_ThoracicDRG_doloromics/fastq/114T12R_L003-ds.82fccd0badb54b419390c8fb03fa1bf1/114T12R_S4_L003_R2_001.fastq.gz" \
  "/mnt/gataca/data/homo_sapiens/Dorsal_root_ganglia/bulk_rnaseq/2022_ThoracicDRG_doloromics/fastq/115T7R_L003-ds.54fdec5dd53749b4af6112d8f3017355/115T7R_S5_L003_R1_001.fastq.gz" \
  "/mnt/gataca/data/homo_sapiens/Dorsal_root_ganglia/bulk_rnaseq/2022_ThoracicDRG_doloromics/fastq/115T7R_L003-ds.54fdec5dd53749b4af6112d8f3017355/115T7R_S5_L003_R2_001.fastq.gz" \
  "/mnt/gataca/data/homo_sapiens/Dorsal_root_ganglia/bulk_rnaseq/2022_ThoracicDRG_doloromics/fastq/115T8L_L003-ds.9e5ee8cf9d014131ae1bddf3687f7497/115T8L_S6_L003_R1_001.fastq.gz" \
  "/mnt/gataca/data/homo_sapiens/Dorsal_root_ganglia/bulk_rnaseq/2022_ThoracicDRG_doloromics/fastq/115T8L_L003-ds.9e5ee8cf9d014131ae1bddf3687f7497/115T8L_S6_L003_R2_001.fastq.gz" \
  "/mnt/gataca/data/homo_sapiens/Dorsal_root_ganglia/bulk_rnaseq/2022_ThoracicDRG_doloromics/fastq/116TR5_L003-ds.8ad8961a78954f5a9a7c1f1370ac52ae/116TR5_S7_L003_R1_001.fastq.gz" \
  "/mnt/gataca/data/homo_sapiens/Dorsal_root_ganglia/bulk_rnaseq/2022_ThoracicDRG_doloromics/fastq/116TR5_L003-ds.8ad8961a78954f5a9a7c1f1370ac52ae/116TR5_S7_L003_R2_001.fastq.gz" \
  "/mnt/gataca/data/homo_sapiens/Dorsal_root_ganglia/bulk_rnaseq/2022_ThoracicDRG_doloromics/fastq/117T7L_L003-ds.8096e7135b3e42eba3bb01de56e51b05/117T7L_S8_L003_R1_001.fastq.gz" \
  "/mnt/gataca/data/homo_sapiens/Dorsal_root_ganglia/bulk_rnaseq/2022_ThoracicDRG_doloromics/fastq/117T7L_L003-ds.8096e7135b3e42eba3bb01de56e51b05/117T7L_S8_L003_R2_001.fastq.gz" \
  "/mnt/gataca/data/homo_sapiens/Dorsal_root_ganglia/bulk_rnaseq/2022_ThoracicDRG_doloromics/fastq/117T7R_L003-ds.4dcc39d55395469ba4ca64490f01f4f0/117T7R_S9_L003_R1_001.fastq.gz" \
  "/mnt/gataca/data/homo_sapiens/Dorsal_root_ganglia/bulk_rnaseq/2022_ThoracicDRG_doloromics/fastq/117T7R_L003-ds.4dcc39d55395469ba4ca64490f01f4f0/117T7R_S9_L003_R2_001.fastq.gz" \
  "/mnt/gataca/data/homo_sapiens/Dorsal_root_ganglia/bulk_rnaseq/2022_ThoracicDRG_doloromics/fastq/118T8R_L003-ds.833a7946b1bb484f9aae4f9af7e56e96/118T8R_S10_L003_R1_001.fastq.gz" \
  "/mnt/gataca/data/homo_sapiens/Dorsal_root_ganglia/bulk_rnaseq/2022_ThoracicDRG_doloromics/fastq/118T8R_L003-ds.833a7946b1bb484f9aae4f9af7e56e96/118T8R_S10_L003_R2_001.fastq.gz" \
  "/mnt/gataca/data/homo_sapiens/Dorsal_root_ganglia/bulk_rnaseq/2022_ThoracicDRG_doloromics/fastq/80T2R_L003-ds.9b13ce46c41b4c4db6192a6da49a4e61/80T2R_S11_L003_R1_001.fastq.gz" \
  "/mnt/gataca/data/homo_sapiens/Dorsal_root_ganglia/bulk_rnaseq/2022_ThoracicDRG_doloromics/fastq/80T2R_L003-ds.9b13ce46c41b4c4db6192a6da49a4e61/80T2R_S11_L003_R2_001.fastq.gz" \
  "/mnt/gataca/data/homo_sapiens/Dorsal_root_ganglia/bulk_rnaseq/2022_ThoracicDRG_doloromics/fastq/83T8R_L003-ds.4d3d3ce4fcc542e7954651bebb42c6fa/83T8R_S12_L003_R1_001.fastq.gz" \
  "/mnt/gataca/data/homo_sapiens/Dorsal_root_ganglia/bulk_rnaseq/2022_ThoracicDRG_doloromics/fastq/83T8R_L003-ds.4d3d3ce4fcc542e7954651bebb42c6fa/83T8R_S12_L003_R2_001.fastq.gz" \
  "/mnt/gataca/data/homo_sapiens/Dorsal_root_ganglia/bulk_rnaseq/2022_ThoracicDRG_doloromics/fastq/84T5R_L003-ds.83b2403a53a94cc797a015c1dd294ff3/84T5R_S13_L003_R1_001.fastq.gz" \
  "/mnt/gataca/data/homo_sapiens/Dorsal_root_ganglia/bulk_rnaseq/2022_ThoracicDRG_doloromics/fastq/84T5R_L003-ds.83b2403a53a94cc797a015c1dd294ff3/84T5R_S13_L003_R2_001.fastq.gz" \
  "/mnt/gataca/data/homo_sapiens/Dorsal_root_ganglia/bulk_rnaseq/2022_ThoracicDRG_doloromics/fastq/84T8L_L003-ds.20639b4aef1e47f88cb4f711cd90fd0a/84T8L_S14_L003_R1_001.fastq.gz" \
  "/mnt/gataca/data/homo_sapiens/Dorsal_root_ganglia/bulk_rnaseq/2022_ThoracicDRG_doloromics/fastq/84T8L_L003-ds.20639b4aef1e47f88cb4f711cd90fd0a/84T8L_S14_L003_R2_001.fastq.gz" \
  "/mnt/gataca/data/homo_sapiens/Dorsal_root_ganglia/bulk_rnaseq/2022_ThoracicDRG_doloromics/fastq/85T3L_L003-ds.cddb3124a59b4397b97bc27be59929dc/85T3L_S15_L003_R1_001.fastq.gz" \
  "/mnt/gataca/data/homo_sapiens/Dorsal_root_ganglia/bulk_rnaseq/2022_ThoracicDRG_doloromics/fastq/85T3L_L003-ds.cddb3124a59b4397b97bc27be59929dc/85T3L_S15_L003_R2_001.fastq.gz" \
  "/mnt/gataca/data/homo_sapiens/Dorsal_root_ganglia/bulk_rnaseq/2022_ThoracicDRG_doloromics/fastq/85T3R_L003-ds.5fdf85b9cdac4456bd83e6f39989f00a/85T3R_S16_L003_R1_001.fastq.gz" \
  "/mnt/gataca/data/homo_sapiens/Dorsal_root_ganglia/bulk_rnaseq/2022_ThoracicDRG_doloromics/fastq/85T3R_L003-ds.5fdf85b9cdac4456bd83e6f39989f00a/85T3R_S16_L003_R2_001.fastq.gz" \
  "${JUNO_HOST}:${TITAN_BASE}/2022_ThoracicDRG_doloromics/"

# --- osm_juliet  (OSM_Juliet)  [36 files] ---
ssh -o ControlPath="${CTRL_PATH}" "${JUNO_HOST}" "mkdir -p '${TITAN_BASE}/OSM_Juliet'"
rsync -avP -e "ssh -o ControlPath=${CTRL_PATH}" \
  "/mnt/gataca/data/homo_sapiens/Dorsal_root_ganglia/bulk_rnaseq/OSM_Juliet/Ish/Bulk_D1O1_1.fastq.gz" \
  "/mnt/gataca/data/homo_sapiens/Dorsal_root_ganglia/bulk_rnaseq/OSM_Juliet/Ish/Bulk_D1O1_2.fastq.gz" \
  "/mnt/gataca/data/homo_sapiens/Dorsal_root_ganglia/bulk_rnaseq/OSM_Juliet/Ish/Bulk_D1O2_1.fastq.gz" \
  "/mnt/gataca/data/homo_sapiens/Dorsal_root_ganglia/bulk_rnaseq/OSM_Juliet/Ish/Bulk_D1O2_2.fastq.gz" \
  "/mnt/gataca/data/homo_sapiens/Dorsal_root_ganglia/bulk_rnaseq/OSM_Juliet/Ish/Bulk_D1O3_1.fastq.gz" \
  "/mnt/gataca/data/homo_sapiens/Dorsal_root_ganglia/bulk_rnaseq/OSM_Juliet/Ish/Bulk_D1O3_2.fastq.gz" \
  "/mnt/gataca/data/homo_sapiens/Dorsal_root_ganglia/bulk_rnaseq/OSM_Juliet/Ish/Bulk_D1V1_1.fastq.gz" \
  "/mnt/gataca/data/homo_sapiens/Dorsal_root_ganglia/bulk_rnaseq/OSM_Juliet/Ish/Bulk_D1V1_2.fastq.gz" \
  "/mnt/gataca/data/homo_sapiens/Dorsal_root_ganglia/bulk_rnaseq/OSM_Juliet/Ish/Bulk_D1V2_1.fastq.gz" \
  "/mnt/gataca/data/homo_sapiens/Dorsal_root_ganglia/bulk_rnaseq/OSM_Juliet/Ish/Bulk_D1V2_2.fastq.gz" \
  "/mnt/gataca/data/homo_sapiens/Dorsal_root_ganglia/bulk_rnaseq/OSM_Juliet/Ish/Bulk_D1V3_1.fastq.gz" \
  "/mnt/gataca/data/homo_sapiens/Dorsal_root_ganglia/bulk_rnaseq/OSM_Juliet/Ish/Bulk_D1V3_2.fastq.gz" \
  "/mnt/gataca/data/homo_sapiens/Dorsal_root_ganglia/bulk_rnaseq/OSM_Juliet/Ish/Bulk_D2O1_1.fastq.gz" \
  "/mnt/gataca/data/homo_sapiens/Dorsal_root_ganglia/bulk_rnaseq/OSM_Juliet/Ish/Bulk_D2O1_2.fastq.gz" \
  "/mnt/gataca/data/homo_sapiens/Dorsal_root_ganglia/bulk_rnaseq/OSM_Juliet/Ish/Bulk_D2O2_1.fastq.gz" \
  "/mnt/gataca/data/homo_sapiens/Dorsal_root_ganglia/bulk_rnaseq/OSM_Juliet/Ish/Bulk_D2O2_2.fastq.gz" \
  "/mnt/gataca/data/homo_sapiens/Dorsal_root_ganglia/bulk_rnaseq/OSM_Juliet/Ish/Bulk_D2O3_1.fastq.gz" \
  "/mnt/gataca/data/homo_sapiens/Dorsal_root_ganglia/bulk_rnaseq/OSM_Juliet/Ish/Bulk_D2O3_2.fastq.gz" \
  "/mnt/gataca/data/homo_sapiens/Dorsal_root_ganglia/bulk_rnaseq/OSM_Juliet/Ish/Bulk_D2V1_1.fastq.gz" \
  "/mnt/gataca/data/homo_sapiens/Dorsal_root_ganglia/bulk_rnaseq/OSM_Juliet/Ish/Bulk_D2V1_2.fastq.gz" \
  "/mnt/gataca/data/homo_sapiens/Dorsal_root_ganglia/bulk_rnaseq/OSM_Juliet/Ish/Bulk_D2V2_1.fastq.gz" \
  "/mnt/gataca/data/homo_sapiens/Dorsal_root_ganglia/bulk_rnaseq/OSM_Juliet/Ish/Bulk_D2V2_2.fastq.gz" \
  "/mnt/gataca/data/homo_sapiens/Dorsal_root_ganglia/bulk_rnaseq/OSM_Juliet/Ish/Bulk_D2V3_1.fastq.gz" \
  "/mnt/gataca/data/homo_sapiens/Dorsal_root_ganglia/bulk_rnaseq/OSM_Juliet/Ish/Bulk_D2V3_2.fastq.gz" \
  "/mnt/gataca/data/homo_sapiens/Dorsal_root_ganglia/bulk_rnaseq/OSM_Juliet/Ish/Bulk_D3O1_1.fastq.gz" \
  "/mnt/gataca/data/homo_sapiens/Dorsal_root_ganglia/bulk_rnaseq/OSM_Juliet/Ish/Bulk_D3O1_2.fastq.gz" \
  "/mnt/gataca/data/homo_sapiens/Dorsal_root_ganglia/bulk_rnaseq/OSM_Juliet/Ish/Bulk_D3O2_1.fastq.gz" \
  "/mnt/gataca/data/homo_sapiens/Dorsal_root_ganglia/bulk_rnaseq/OSM_Juliet/Ish/Bulk_D3O2_2.fastq.gz" \
  "/mnt/gataca/data/homo_sapiens/Dorsal_root_ganglia/bulk_rnaseq/OSM_Juliet/Ish/Bulk_D3O3_1.fastq.gz" \
  "/mnt/gataca/data/homo_sapiens/Dorsal_root_ganglia/bulk_rnaseq/OSM_Juliet/Ish/Bulk_D3O3_2.fastq.gz" \
  "/mnt/gataca/data/homo_sapiens/Dorsal_root_ganglia/bulk_rnaseq/OSM_Juliet/Ish/Bulk_D3V1_1.fastq.gz" \
  "/mnt/gataca/data/homo_sapiens/Dorsal_root_ganglia/bulk_rnaseq/OSM_Juliet/Ish/Bulk_D3V1_2.fastq.gz" \
  "/mnt/gataca/data/homo_sapiens/Dorsal_root_ganglia/bulk_rnaseq/OSM_Juliet/Ish/Bulk_D3V2_1.fastq.gz" \
  "/mnt/gataca/data/homo_sapiens/Dorsal_root_ganglia/bulk_rnaseq/OSM_Juliet/Ish/Bulk_D3V2_2.fastq.gz" \
  "/mnt/gataca/data/homo_sapiens/Dorsal_root_ganglia/bulk_rnaseq/OSM_Juliet/Ish/Bulk_D3V3_1.fastq.gz" \
  "/mnt/gataca/data/homo_sapiens/Dorsal_root_ganglia/bulk_rnaseq/OSM_Juliet/Ish/Bulk_D3V3_2.fastq.gz" \
  "${JUNO_HOST}:${TITAN_BASE}/OSM_Juliet/"

# --- rejoin_jayden  (2025_REJOIN_Jayden)  [34 files] ---
ssh -o ControlPath="${CTRL_PATH}" "${JUNO_HOST}" "mkdir -p '${TITAN_BASE}/2025_REJOIN_Jayden'"
rsync -avP -e "ssh -o ControlPath=${CTRL_PATH}" \
  "/mnt/gataca/data/homo_sapiens/Dorsal_root_ganglia/bulk_rnaseq/2025_REJOIN_Jayden/fastq/473-10_S10_R1_001.fastq.gz" \
  "/mnt/gataca/data/homo_sapiens/Dorsal_root_ganglia/bulk_rnaseq/2025_REJOIN_Jayden/fastq/473-10_S10_R2_001.fastq.gz" \
  "/mnt/gataca/data/homo_sapiens/Dorsal_root_ganglia/bulk_rnaseq/2025_REJOIN_Jayden/fastq/473-11_S11_R1_001.fastq.gz" \
  "/mnt/gataca/data/homo_sapiens/Dorsal_root_ganglia/bulk_rnaseq/2025_REJOIN_Jayden/fastq/473-11_S11_R2_001.fastq.gz" \
  "/mnt/gataca/data/homo_sapiens/Dorsal_root_ganglia/bulk_rnaseq/2025_REJOIN_Jayden/fastq/473-12_S12_R1_001.fastq.gz" \
  "/mnt/gataca/data/homo_sapiens/Dorsal_root_ganglia/bulk_rnaseq/2025_REJOIN_Jayden/fastq/473-12_S12_R2_001.fastq.gz" \
  "/mnt/gataca/data/homo_sapiens/Dorsal_root_ganglia/bulk_rnaseq/2025_REJOIN_Jayden/fastq/473-13_S13_R1_001.fastq.gz" \
  "/mnt/gataca/data/homo_sapiens/Dorsal_root_ganglia/bulk_rnaseq/2025_REJOIN_Jayden/fastq/473-13_S13_R2_001.fastq.gz" \
  "/mnt/gataca/data/homo_sapiens/Dorsal_root_ganglia/bulk_rnaseq/2025_REJOIN_Jayden/fastq/473-14_S14_R1_001.fastq.gz" \
  "/mnt/gataca/data/homo_sapiens/Dorsal_root_ganglia/bulk_rnaseq/2025_REJOIN_Jayden/fastq/473-14_S14_R2_001.fastq.gz" \
  "/mnt/gataca/data/homo_sapiens/Dorsal_root_ganglia/bulk_rnaseq/2025_REJOIN_Jayden/fastq/473-15_S15_R1_001.fastq.gz" \
  "/mnt/gataca/data/homo_sapiens/Dorsal_root_ganglia/bulk_rnaseq/2025_REJOIN_Jayden/fastq/473-15_S15_R2_001.fastq.gz" \
  "/mnt/gataca/data/homo_sapiens/Dorsal_root_ganglia/bulk_rnaseq/2025_REJOIN_Jayden/fastq/473-16_S16_R1_001.fastq.gz" \
  "/mnt/gataca/data/homo_sapiens/Dorsal_root_ganglia/bulk_rnaseq/2025_REJOIN_Jayden/fastq/473-16_S16_R2_001.fastq.gz" \
  "/mnt/gataca/data/homo_sapiens/Dorsal_root_ganglia/bulk_rnaseq/2025_REJOIN_Jayden/fastq/473-17_S17_R1_001.fastq.gz" \
  "/mnt/gataca/data/homo_sapiens/Dorsal_root_ganglia/bulk_rnaseq/2025_REJOIN_Jayden/fastq/473-17_S17_R2_001.fastq.gz" \
  "/mnt/gataca/data/homo_sapiens/Dorsal_root_ganglia/bulk_rnaseq/2025_REJOIN_Jayden/fastq/473-1_S1_R1_001.fastq.gz" \
  "/mnt/gataca/data/homo_sapiens/Dorsal_root_ganglia/bulk_rnaseq/2025_REJOIN_Jayden/fastq/473-1_S1_R2_001.fastq.gz" \
  "/mnt/gataca/data/homo_sapiens/Dorsal_root_ganglia/bulk_rnaseq/2025_REJOIN_Jayden/fastq/473-2_S2_R1_001.fastq.gz" \
  "/mnt/gataca/data/homo_sapiens/Dorsal_root_ganglia/bulk_rnaseq/2025_REJOIN_Jayden/fastq/473-2_S2_R2_001.fastq.gz" \
  "/mnt/gataca/data/homo_sapiens/Dorsal_root_ganglia/bulk_rnaseq/2025_REJOIN_Jayden/fastq/473-3_S3_R1_001.fastq.gz" \
  "/mnt/gataca/data/homo_sapiens/Dorsal_root_ganglia/bulk_rnaseq/2025_REJOIN_Jayden/fastq/473-3_S3_R2_001.fastq.gz" \
  "/mnt/gataca/data/homo_sapiens/Dorsal_root_ganglia/bulk_rnaseq/2025_REJOIN_Jayden/fastq/473-4_S4_R1_001.fastq.gz" \
  "/mnt/gataca/data/homo_sapiens/Dorsal_root_ganglia/bulk_rnaseq/2025_REJOIN_Jayden/fastq/473-4_S4_R2_001.fastq.gz" \
  "/mnt/gataca/data/homo_sapiens/Dorsal_root_ganglia/bulk_rnaseq/2025_REJOIN_Jayden/fastq/473-5_S5_R1_001.fastq.gz" \
  "/mnt/gataca/data/homo_sapiens/Dorsal_root_ganglia/bulk_rnaseq/2025_REJOIN_Jayden/fastq/473-5_S5_R2_001.fastq.gz" \
  "/mnt/gataca/data/homo_sapiens/Dorsal_root_ganglia/bulk_rnaseq/2025_REJOIN_Jayden/fastq/473-6_S6_R1_001.fastq.gz" \
  "/mnt/gataca/data/homo_sapiens/Dorsal_root_ganglia/bulk_rnaseq/2025_REJOIN_Jayden/fastq/473-6_S6_R2_001.fastq.gz" \
  "/mnt/gataca/data/homo_sapiens/Dorsal_root_ganglia/bulk_rnaseq/2025_REJOIN_Jayden/fastq/473-7_S7_R1_001.fastq.gz" \
  "/mnt/gataca/data/homo_sapiens/Dorsal_root_ganglia/bulk_rnaseq/2025_REJOIN_Jayden/fastq/473-7_S7_R2_001.fastq.gz" \
  "/mnt/gataca/data/homo_sapiens/Dorsal_root_ganglia/bulk_rnaseq/2025_REJOIN_Jayden/fastq/473-8_S8_R1_001.fastq.gz" \
  "/mnt/gataca/data/homo_sapiens/Dorsal_root_ganglia/bulk_rnaseq/2025_REJOIN_Jayden/fastq/473-8_S8_R2_001.fastq.gz" \
  "/mnt/gataca/data/homo_sapiens/Dorsal_root_ganglia/bulk_rnaseq/2025_REJOIN_Jayden/fastq/473-9_S9_R1_001.fastq.gz" \
  "/mnt/gataca/data/homo_sapiens/Dorsal_root_ganglia/bulk_rnaseq/2025_REJOIN_Jayden/fastq/473-9_S9_R2_001.fastq.gz" \
  "${JUNO_HOST}:${TITAN_BASE}/2025_REJOIN_Jayden/"

# --- mgoexplant_saad  (2022_MGOexplant_Saad)  [12 files] ---
ssh -o ControlPath="${CTRL_PATH}" "${JUNO_HOST}" "mkdir -p '${TITAN_BASE}/2022_MGOexplant_Saad'"
rsync -avP -e "ssh -o ControlPath=${CTRL_PATH}" \
  "/mnt/gataca/data/homo_sapiens/Dorsal_root_ganglia/bulk_rnaseq/2022_MGOexplant_Saad/bulk_rna_seq/trial1/raw_seq_files/Saad-1_S19_L001_R1_001.fastq.gz" \
  "/mnt/gataca/data/homo_sapiens/Dorsal_root_ganglia/bulk_rnaseq/2022_MGOexplant_Saad/bulk_rna_seq/trial1/raw_seq_files/Saad-1_S19_L001_R2_001.fastq.gz" \
  "/mnt/gataca/data/homo_sapiens/Dorsal_root_ganglia/bulk_rnaseq/2022_MGOexplant_Saad/bulk_rna_seq/trial1/raw_seq_files/Saad-2_S20_L001_R1_001.fastq.gz" \
  "/mnt/gataca/data/homo_sapiens/Dorsal_root_ganglia/bulk_rnaseq/2022_MGOexplant_Saad/bulk_rna_seq/trial1/raw_seq_files/Saad-2_S20_L001_R2_001.fastq.gz" \
  "/mnt/gataca/data/homo_sapiens/Dorsal_root_ganglia/bulk_rnaseq/2022_MGOexplant_Saad/bulk_rna_seq/trial1/raw_seq_files/Saad-3_S21_L001_R1_001.fastq.gz" \
  "/mnt/gataca/data/homo_sapiens/Dorsal_root_ganglia/bulk_rnaseq/2022_MGOexplant_Saad/bulk_rna_seq/trial1/raw_seq_files/Saad-3_S21_L001_R2_001.fastq.gz" \
  "/mnt/gataca/data/homo_sapiens/Dorsal_root_ganglia/bulk_rnaseq/2022_MGOexplant_Saad/bulk_rna_seq/trial1/raw_seq_files/Saad-4_S22_L001_R1_001.fastq.gz" \
  "/mnt/gataca/data/homo_sapiens/Dorsal_root_ganglia/bulk_rnaseq/2022_MGOexplant_Saad/bulk_rna_seq/trial1/raw_seq_files/Saad-4_S22_L001_R2_001.fastq.gz" \
  "/mnt/gataca/data/homo_sapiens/Dorsal_root_ganglia/bulk_rnaseq/2022_MGOexplant_Saad/bulk_rna_seq/trial1/raw_seq_files/Saad-5_S23_L001_R1_001.fastq.gz" \
  "/mnt/gataca/data/homo_sapiens/Dorsal_root_ganglia/bulk_rnaseq/2022_MGOexplant_Saad/bulk_rna_seq/trial1/raw_seq_files/Saad-5_S23_L001_R2_001.fastq.gz" \
  "/mnt/gataca/data/homo_sapiens/Dorsal_root_ganglia/bulk_rnaseq/2022_MGOexplant_Saad/bulk_rna_seq/trial1/raw_seq_files/Saad-6_S24_L001_R1_001.fastq.gz" \
  "/mnt/gataca/data/homo_sapiens/Dorsal_root_ganglia/bulk_rnaseq/2022_MGOexplant_Saad/bulk_rna_seq/trial1/raw_seq_files/Saad-6_S24_L001_R2_001.fastq.gz" \
  "${JUNO_HOST}:${TITAN_BASE}/2022_MGOexplant_Saad/"

# --- adult_infant_soma_axon  (2024_Adult.Infant.Soma.Axon_Asta)  [20 files] ---
ssh -o ControlPath="${CTRL_PATH}" "${JUNO_HOST}" "mkdir -p '${TITAN_BASE}/2024_Adult.Infant.Soma.Axon_Asta'"
rsync -avP -e "ssh -o ControlPath=${CTRL_PATH}" \
  "/mnt/gataca/data/homo_sapiens/Dorsal_root_ganglia/bulk_rnaseq/2024_Adult.Infant.Soma.Axon_Asta/fastq_files/366-10_S10_R1_001.fastq.gz" \
  "/mnt/gataca/data/homo_sapiens/Dorsal_root_ganglia/bulk_rnaseq/2024_Adult.Infant.Soma.Axon_Asta/fastq_files/366-10_S10_R2_001.fastq.gz" \
  "/mnt/gataca/data/homo_sapiens/Dorsal_root_ganglia/bulk_rnaseq/2024_Adult.Infant.Soma.Axon_Asta/fastq_files/366-1_S1_R1_001.fastq.gz" \
  "/mnt/gataca/data/homo_sapiens/Dorsal_root_ganglia/bulk_rnaseq/2024_Adult.Infant.Soma.Axon_Asta/fastq_files/366-1_S1_R2_001.fastq.gz" \
  "/mnt/gataca/data/homo_sapiens/Dorsal_root_ganglia/bulk_rnaseq/2024_Adult.Infant.Soma.Axon_Asta/fastq_files/366-2_S2_R1_001.fastq.gz" \
  "/mnt/gataca/data/homo_sapiens/Dorsal_root_ganglia/bulk_rnaseq/2024_Adult.Infant.Soma.Axon_Asta/fastq_files/366-2_S2_R2_001.fastq.gz" \
  "/mnt/gataca/data/homo_sapiens/Dorsal_root_ganglia/bulk_rnaseq/2024_Adult.Infant.Soma.Axon_Asta/fastq_files/366-3_S3_R1_001.fastq.gz" \
  "/mnt/gataca/data/homo_sapiens/Dorsal_root_ganglia/bulk_rnaseq/2024_Adult.Infant.Soma.Axon_Asta/fastq_files/366-3_S3_R2_001.fastq.gz" \
  "/mnt/gataca/data/homo_sapiens/Dorsal_root_ganglia/bulk_rnaseq/2024_Adult.Infant.Soma.Axon_Asta/fastq_files/366-4_S4_R1_001.fastq.gz" \
  "/mnt/gataca/data/homo_sapiens/Dorsal_root_ganglia/bulk_rnaseq/2024_Adult.Infant.Soma.Axon_Asta/fastq_files/366-4_S4_R2_001.fastq.gz" \
  "/mnt/gataca/data/homo_sapiens/Dorsal_root_ganglia/bulk_rnaseq/2024_Adult.Infant.Soma.Axon_Asta/fastq_files/366-5_S5_R1_001.fastq.gz" \
  "/mnt/gataca/data/homo_sapiens/Dorsal_root_ganglia/bulk_rnaseq/2024_Adult.Infant.Soma.Axon_Asta/fastq_files/366-5_S5_R2_001.fastq.gz" \
  "/mnt/gataca/data/homo_sapiens/Dorsal_root_ganglia/bulk_rnaseq/2024_Adult.Infant.Soma.Axon_Asta/fastq_files/366-6_S6_R1_001.fastq.gz" \
  "/mnt/gataca/data/homo_sapiens/Dorsal_root_ganglia/bulk_rnaseq/2024_Adult.Infant.Soma.Axon_Asta/fastq_files/366-6_S6_R2_001.fastq.gz" \
  "/mnt/gataca/data/homo_sapiens/Dorsal_root_ganglia/bulk_rnaseq/2024_Adult.Infant.Soma.Axon_Asta/fastq_files/366-7_S7_R1_001.fastq.gz" \
  "/mnt/gataca/data/homo_sapiens/Dorsal_root_ganglia/bulk_rnaseq/2024_Adult.Infant.Soma.Axon_Asta/fastq_files/366-7_S7_R2_001.fastq.gz" \
  "/mnt/gataca/data/homo_sapiens/Dorsal_root_ganglia/bulk_rnaseq/2024_Adult.Infant.Soma.Axon_Asta/fastq_files/366-8_S8_R1_001.fastq.gz" \
  "/mnt/gataca/data/homo_sapiens/Dorsal_root_ganglia/bulk_rnaseq/2024_Adult.Infant.Soma.Axon_Asta/fastq_files/366-8_S8_R2_001.fastq.gz" \
  "/mnt/gataca/data/homo_sapiens/Dorsal_root_ganglia/bulk_rnaseq/2024_Adult.Infant.Soma.Axon_Asta/fastq_files/366-9_S9_R1_001.fastq.gz" \
  "/mnt/gataca/data/homo_sapiens/Dorsal_root_ganglia/bulk_rnaseq/2024_Adult.Infant.Soma.Axon_Asta/fastq_files/366-9_S9_R2_001.fastq.gz" \
  "${JUNO_HOST}:${TITAN_BASE}/2024_Adult.Infant.Soma.Axon_Asta/"

# --- unknown_doloromics  (2022_unknown_doloromics)  [16 files] ---
ssh -o ControlPath="${CTRL_PATH}" "${JUNO_HOST}" "mkdir -p '${TITAN_BASE}/2022_unknown_doloromics'"
rsync -avP -e "ssh -o ControlPath=${CTRL_PATH}" \
  "/mnt/gataca/data/homo_sapiens/Dorsal_root_ganglia/bulk_rnaseq/2022_unknown_doloromics/fastq/2A_L_L002-ds.0e9df46ee3bd41c3b5c5e6e65b41ff22/2A-L_S1_L002_R1_001.fastq.gz" \
  "/mnt/gataca/data/homo_sapiens/Dorsal_root_ganglia/bulk_rnaseq/2022_unknown_doloromics/fastq/2A_L_L002-ds.0e9df46ee3bd41c3b5c5e6e65b41ff22/2A-L_S1_L002_R2_001.fastq.gz" \
  "/mnt/gataca/data/homo_sapiens/Dorsal_root_ganglia/bulk_rnaseq/2022_unknown_doloromics/fastq/2A_R_L002-ds.df79bdc7cdc04123a6abbd6d351e2546/2A-R_S2_L002_R1_001.fastq.gz" \
  "/mnt/gataca/data/homo_sapiens/Dorsal_root_ganglia/bulk_rnaseq/2022_unknown_doloromics/fastq/2A_R_L002-ds.df79bdc7cdc04123a6abbd6d351e2546/2A-R_S2_L002_R2_001.fastq.gz" \
  "/mnt/gataca/data/homo_sapiens/Dorsal_root_ganglia/bulk_rnaseq/2022_unknown_doloromics/fastq/3A_L_L002-ds.f88e2e1af7aa48d6aa35a9584c96c4b9/3A-L_S3_L002_R1_001.fastq.gz" \
  "/mnt/gataca/data/homo_sapiens/Dorsal_root_ganglia/bulk_rnaseq/2022_unknown_doloromics/fastq/3A_L_L002-ds.f88e2e1af7aa48d6aa35a9584c96c4b9/3A-L_S3_L002_R2_001.fastq.gz" \
  "/mnt/gataca/data/homo_sapiens/Dorsal_root_ganglia/bulk_rnaseq/2022_unknown_doloromics/fastq/3A_R_L002-ds.b0ebbd95a1794915a5b1c449c341aff6/3A-R_S4_L002_R1_001.fastq.gz" \
  "/mnt/gataca/data/homo_sapiens/Dorsal_root_ganglia/bulk_rnaseq/2022_unknown_doloromics/fastq/3A_R_L002-ds.b0ebbd95a1794915a5b1c449c341aff6/3A-R_S4_L002_R2_001.fastq.gz" \
  "/mnt/gataca/data/homo_sapiens/Dorsal_root_ganglia/bulk_rnaseq/2022_unknown_doloromics/fastq/4A_L_L002-ds.62968c07fb884d489083073a41fa7860/4A-L_S5_L002_R1_001.fastq.gz" \
  "/mnt/gataca/data/homo_sapiens/Dorsal_root_ganglia/bulk_rnaseq/2022_unknown_doloromics/fastq/4A_L_L002-ds.62968c07fb884d489083073a41fa7860/4A-L_S5_L002_R2_001.fastq.gz" \
  "/mnt/gataca/data/homo_sapiens/Dorsal_root_ganglia/bulk_rnaseq/2022_unknown_doloromics/fastq/4A_R_L002-ds.99f6a75d614143b1bfc4c724123b0a98/4A-R_S6_L002_R1_001.fastq.gz" \
  "/mnt/gataca/data/homo_sapiens/Dorsal_root_ganglia/bulk_rnaseq/2022_unknown_doloromics/fastq/4A_R_L002-ds.99f6a75d614143b1bfc4c724123b0a98/4A-R_S6_L002_R2_001.fastq.gz" \
  "/mnt/gataca/data/homo_sapiens/Dorsal_root_ganglia/bulk_rnaseq/2022_unknown_doloromics/fastq/5A_L_L002-ds.cff854d191f645ae9d2d3e42001b60b7/5A-L_S7_L002_R1_001.fastq.gz" \
  "/mnt/gataca/data/homo_sapiens/Dorsal_root_ganglia/bulk_rnaseq/2022_unknown_doloromics/fastq/5A_L_L002-ds.cff854d191f645ae9d2d3e42001b60b7/5A-L_S7_L002_R2_001.fastq.gz" \
  "/mnt/gataca/data/homo_sapiens/Dorsal_root_ganglia/bulk_rnaseq/2022_unknown_doloromics/fastq/5A_R_L002-ds.1752ed1b97944329b1b6e358dfb248ad/5A-R_S8_L002_R1_001.fastq.gz" \
  "/mnt/gataca/data/homo_sapiens/Dorsal_root_ganglia/bulk_rnaseq/2022_unknown_doloromics/fastq/5A_R_L002-ds.1752ed1b97944329b1b6e358dfb248ad/5A-R_S8_L002_R2_001.fastq.gz" \
  "${JUNO_HOST}:${TITAN_BASE}/2022_unknown_doloromics/"

# --- osmexplant_juliet  (2023_OSMexplant_doloromics.Juliet)  [14 files] ---
ssh -o ControlPath="${CTRL_PATH}" "${JUNO_HOST}" "mkdir -p '${TITAN_BASE}/2023_OSMexplant_doloromics.Juliet'"
rsync -avP -e "ssh -o ControlPath=${CTRL_PATH}" \
  "/mnt/gataca/data/homo_sapiens/Dorsal_root_ganglia/bulk_rnaseq/2023_OSMexplant_doloromics.Juliet/fastq/DRG-OSM-1_S1_L001_R1_001.fastq.gz" \
  "/mnt/gataca/data/homo_sapiens/Dorsal_root_ganglia/bulk_rnaseq/2023_OSMexplant_doloromics.Juliet/fastq/DRG-OSM-1_S1_L001_R2_001.fastq.gz" \
  "/mnt/gataca/data/homo_sapiens/Dorsal_root_ganglia/bulk_rnaseq/2023_OSMexplant_doloromics.Juliet/fastq/DRG-OSM-2_S2_L001_R1_001.fastq.gz" \
  "/mnt/gataca/data/homo_sapiens/Dorsal_root_ganglia/bulk_rnaseq/2023_OSMexplant_doloromics.Juliet/fastq/DRG-OSM-2_S2_L001_R2_001.fastq.gz" \
  "/mnt/gataca/data/homo_sapiens/Dorsal_root_ganglia/bulk_rnaseq/2023_OSMexplant_doloromics.Juliet/fastq/DRG-OSM-3_S3_L001_R1_001.fastq.gz" \
  "/mnt/gataca/data/homo_sapiens/Dorsal_root_ganglia/bulk_rnaseq/2023_OSMexplant_doloromics.Juliet/fastq/DRG-OSM-3_S3_L001_R2_001.fastq.gz" \
  "/mnt/gataca/data/homo_sapiens/Dorsal_root_ganglia/bulk_rnaseq/2023_OSMexplant_doloromics.Juliet/fastq/DRG-OSM-4_S4_L001_R1_001.fastq.gz" \
  "/mnt/gataca/data/homo_sapiens/Dorsal_root_ganglia/bulk_rnaseq/2023_OSMexplant_doloromics.Juliet/fastq/DRG-OSM-4_S4_L001_R2_001.fastq.gz" \
  "/mnt/gataca/data/homo_sapiens/Dorsal_root_ganglia/bulk_rnaseq/2023_OSMexplant_doloromics.Juliet/fastq/DRG-VEH-2_S6_L001_R1_001.fastq.gz" \
  "/mnt/gataca/data/homo_sapiens/Dorsal_root_ganglia/bulk_rnaseq/2023_OSMexplant_doloromics.Juliet/fastq/DRG-VEH-2_S6_L001_R2_001.fastq.gz" \
  "/mnt/gataca/data/homo_sapiens/Dorsal_root_ganglia/bulk_rnaseq/2023_OSMexplant_doloromics.Juliet/fastq/DRG-VEH-3_S7_L001_R1_001.fastq.gz" \
  "/mnt/gataca/data/homo_sapiens/Dorsal_root_ganglia/bulk_rnaseq/2023_OSMexplant_doloromics.Juliet/fastq/DRG-VEH-3_S7_L001_R2_001.fastq.gz" \
  "/mnt/gataca/data/homo_sapiens/Dorsal_root_ganglia/bulk_rnaseq/2023_OSMexplant_doloromics.Juliet/fastq/DRG-VEH-4_S8_L001_R1_001.fastq.gz" \
  "/mnt/gataca/data/homo_sapiens/Dorsal_root_ganglia/bulk_rnaseq/2023_OSMexplant_doloromics.Juliet/fastq/DRG-VEH-4_S8_L001_R2_001.fastq.gz" \
  "${JUNO_HOST}:${TITAN_BASE}/2023_OSMexplant_doloromics.Juliet/"

# --- osmcultured_juliet  (2023_OSMcultured_doloromics.Juliet)  [12 files] ---
ssh -o ControlPath="${CTRL_PATH}" "${JUNO_HOST}" "mkdir -p '${TITAN_BASE}/2023_OSMcultured_doloromics.Juliet'"
rsync -avP -e "ssh -o ControlPath=${CTRL_PATH}" \
  "/mnt/gataca/data/homo_sapiens/Dorsal_root_ganglia/bulk_rnaseq/2023_OSMcultured_doloromics.Juliet/fastq/366-11_S11_R1_001.fastq.gz" \
  "/mnt/gataca/data/homo_sapiens/Dorsal_root_ganglia/bulk_rnaseq/2023_OSMcultured_doloromics.Juliet/fastq/366-11_S11_R2_001.fastq.gz" \
  "/mnt/gataca/data/homo_sapiens/Dorsal_root_ganglia/bulk_rnaseq/2023_OSMcultured_doloromics.Juliet/fastq/366-12_S12_R1_001.fastq.gz" \
  "/mnt/gataca/data/homo_sapiens/Dorsal_root_ganglia/bulk_rnaseq/2023_OSMcultured_doloromics.Juliet/fastq/366-12_S12_R2_001.fastq.gz" \
  "/mnt/gataca/data/homo_sapiens/Dorsal_root_ganglia/bulk_rnaseq/2023_OSMcultured_doloromics.Juliet/fastq/366-13_S13_R1_001.fastq.gz" \
  "/mnt/gataca/data/homo_sapiens/Dorsal_root_ganglia/bulk_rnaseq/2023_OSMcultured_doloromics.Juliet/fastq/366-13_S13_R2_001.fastq.gz" \
  "/mnt/gataca/data/homo_sapiens/Dorsal_root_ganglia/bulk_rnaseq/2023_OSMcultured_doloromics.Juliet/fastq/366-14_S14_R1_001.fastq.gz" \
  "/mnt/gataca/data/homo_sapiens/Dorsal_root_ganglia/bulk_rnaseq/2023_OSMcultured_doloromics.Juliet/fastq/366-14_S14_R2_001.fastq.gz" \
  "/mnt/gataca/data/homo_sapiens/Dorsal_root_ganglia/bulk_rnaseq/2023_OSMcultured_doloromics.Juliet/fastq/366-15_S15_R1_001.fastq.gz" \
  "/mnt/gataca/data/homo_sapiens/Dorsal_root_ganglia/bulk_rnaseq/2023_OSMcultured_doloromics.Juliet/fastq/366-15_S15_R2_001.fastq.gz" \
  "/mnt/gataca/data/homo_sapiens/Dorsal_root_ganglia/bulk_rnaseq/2023_OSMcultured_doloromics.Juliet/fastq/366-16_S16_R1_001.fastq.gz" \
  "/mnt/gataca/data/homo_sapiens/Dorsal_root_ganglia/bulk_rnaseq/2023_OSMcultured_doloromics.Juliet/fastq/366-16_S16_R2_001.fastq.gz" \
  "${JUNO_HOST}:${TITAN_BASE}/2023_OSMcultured_doloromics.Juliet/"

# --- lumar_drg  (2022_LumarDRG_doloromics)  [12 files] ---
ssh -o ControlPath="${CTRL_PATH}" "${JUNO_HOST}" "mkdir -p '${TITAN_BASE}/2022_LumarDRG_doloromics'"
rsync -avP -e "ssh -o ControlPath=${CTRL_PATH}" \
  "/mnt/gataca/data/homo_sapiens/Dorsal_root_ganglia/bulk_rnaseq/2022_LumarDRG_doloromics/fastq/AIG1390-L1_S9_L002_R1_001.fastq.gz" \
  "/mnt/gataca/data/homo_sapiens/Dorsal_root_ganglia/bulk_rnaseq/2022_LumarDRG_doloromics/fastq/AIG1390-L1_S9_L002_R2_001.fastq.gz" \
  "/mnt/gataca/data/homo_sapiens/Dorsal_root_ganglia/bulk_rnaseq/2022_LumarDRG_doloromics/fastq/AIG1390-L2_S10_L002_R1_001.fastq.gz" \
  "/mnt/gataca/data/homo_sapiens/Dorsal_root_ganglia/bulk_rnaseq/2022_LumarDRG_doloromics/fastq/AIG1390-L2_S10_L002_R2_001.fastq.gz" \
  "/mnt/gataca/data/homo_sapiens/Dorsal_root_ganglia/bulk_rnaseq/2022_LumarDRG_doloromics/fastq/AIG1390-L3_S11_L002_R1_001.fastq.gz" \
  "/mnt/gataca/data/homo_sapiens/Dorsal_root_ganglia/bulk_rnaseq/2022_LumarDRG_doloromics/fastq/AIG1390-L3_S11_L002_R2_001.fastq.gz" \
  "/mnt/gataca/data/homo_sapiens/Dorsal_root_ganglia/bulk_rnaseq/2022_LumarDRG_doloromics/fastq/AIG1390-L4_S12_L002_R1_001.fastq.gz" \
  "/mnt/gataca/data/homo_sapiens/Dorsal_root_ganglia/bulk_rnaseq/2022_LumarDRG_doloromics/fastq/AIG1390-L4_S12_L002_R2_001.fastq.gz" \
  "/mnt/gataca/data/homo_sapiens/Dorsal_root_ganglia/bulk_rnaseq/2022_LumarDRG_doloromics/fastq/AIG1390-L5_S13_L002_R1_001.fastq.gz" \
  "/mnt/gataca/data/homo_sapiens/Dorsal_root_ganglia/bulk_rnaseq/2022_LumarDRG_doloromics/fastq/AIG1390-L5_S13_L002_R2_001.fastq.gz" \
  "/mnt/gataca/data/homo_sapiens/Dorsal_root_ganglia/bulk_rnaseq/2022_LumarDRG_doloromics/fastq/AIG1390-T12_S14_L002_R1_001.fastq.gz" \
  "/mnt/gataca/data/homo_sapiens/Dorsal_root_ganglia/bulk_rnaseq/2022_LumarDRG_doloromics/fastq/AIG1390-T12_S14_L002_R2_001.fastq.gz" \
  "${JUNO_HOST}:${TITAN_BASE}/2022_LumarDRG_doloromics/"
