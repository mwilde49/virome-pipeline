#!/usr/bin/env bash
# Stage all 12 cohorts from Titan to scratch, run from a Juno LOGIN node
# (e.g. juno-l-01) inside tmux -- compute nodes do not have /titan mounted
# (confirmed 2026-08-18 via a real SLURM job failing at main.nf's
# samplesheet-parsing checkIfExists step against a Titan path), so every
# cohort's FASTQs need a real copy onto scratch before any config can launch.
# Safe to re-run/resume (rsync skips files that already match).
#
# 2026-08-19: "2018_Emma_NIH" was missing from this array entirely (added to
# the batch after this script was first written, with its own staging note
# only in its own config header -- never folded in here), and three more
# entries here (2022_unknown_doloromics, 2023_OSMexplant_doloromics.Juliet,
# 2023_OSMcultured_doloromics.Juliet) turned out empty or partial on scratch
# despite being in this array and despite Titan itself having full counts for
# all of them -- exact cause of the partial original run not fully
# reconstructed, but re-running this script (idempotent, rsync-based) is a
# complete, safe fix regardless of what happened. Real batch launches then
# hit all four as fast (~10s) checkIfExists failures, not slow per-sample
# failures -- that speed is itself the tell that it's a staging gap, not a
# pipeline/data problem.
set -euo pipefail

TITAN_BASE="/titan/tprice/ingest/virome"
SCRATCH_BASE="/scratch/juno/${USER}/gataca_fastq"

DATASETS=(
  "2025_Watchmaker_Asta.Jayden.Katherin.Alejandro"
  "2023_rheumatoidArthritis_AshokKulkarni"
  "2022_ThoracicDRG_doloromics"
  "OSM_Juliet"
  "2025_REJOIN_Jayden"
  "2022_MGOexplant_Saad"
  "2024_Adult.Infant.Soma.Axon_Asta"
  "2022_unknown_doloromics"
  "2023_OSMexplant_doloromics.Juliet"
  "2023_OSMcultured_doloromics.Juliet"
  "2022_LumarDRG_doloromics"
  "2018_Emma_NIH"
)

mkdir -p "${SCRATCH_BASE}"

for ds in "${DATASETS[@]}"; do
  echo "=== ${ds} ==="
  mkdir -p "${SCRATCH_BASE}/${ds}"
  rsync -avP "${TITAN_BASE}/${ds}/" "${SCRATCH_BASE}/${ds}/"
  echo
done

echo "Done. Verify counts below match docs/cohort_registry.md's Planned-batch table:"
for ds in "${DATASETS[@]}"; do
  n=$(( $(find "${SCRATCH_BASE}/${ds}" -name '*.fastq.gz' | wc -l) / 2 ))
  echo "${ds}: ${n} samples"
done
