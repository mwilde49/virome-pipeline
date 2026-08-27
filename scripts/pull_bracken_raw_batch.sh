#!/bin/bash
# =============================================================================
# Pull the highest-sensitivity Kraken2/Bracken output (bracken_raw_matrix.tsv --
# all viral species, zero read threshold, no artifact exclusion) for all 11
# cohorts from the 2026-08-19 gataca->Titan->scratch batch, plus each run's
# provenance manifest for a quick sanity check. Skips everything heavy
# (BAMs, star_unmapped/, work/) -- this is meant to be fast.
#
# Usage:
#   bash scripts/pull_bracken_raw_batch.sh [local_dest_dir]
#   (default local_dest_dir: results/bracken_raw_2026-08-19_batch)
# =============================================================================

set -euo pipefail

JUNO_USER="maw210003"
JUNO_HOST="juno.hpcre.utdallas.edu"
DEST_ROOT="${1:-results/bracken_raw_2026-08-19_batch}"

# cohort_name:juno_outdir
COHORTS=(
  "watchmaker:/scratch/juno/maw210003/virome_watchmaker"
  "dpn_ra_kulkarni:/scratch/juno/maw210003/virome_dpn_ra_kulkarni_titan"
  "thoracic_drg:/scratch/juno/maw210003/virome_thoracic_drg"
  "osm_juliet:/scratch/juno/maw210003/virome_osm_juliet_titan"
  "rejoin_jayden:/scratch/juno/maw210003/virome_rejoin_jayden"
  "adult_infant_soma_axon:/scratch/juno/maw210003/virome_adult_infant_soma_axon"
  "unknown_doloromics:/scratch/juno/maw210003/virome_unknown_doloromics"
  "mgoexplant_saad:/scratch/juno/maw210003/virome_mgoexplant_saad"
  "osmexplant_juliet:/scratch/juno/maw210003/virome_osmexplant_juliet"
  "osmcultured_juliet:/scratch/juno/maw210003/virome_osmcultured_juliet"
  "tg_2018_emma_nih:/scratch/juno/maw210003/virome_tg_2018_emma_nih"
)

mkdir -p "${DEST_ROOT}"

for entry in "${COHORTS[@]}"; do
  name="${entry%%:*}"
  remote="${entry#*:}"
  local_dir="${DEST_ROOT}/${name}"
  mkdir -p "${local_dir}"
  echo "=== ${name} ==="
  rsync -avP --no-perms --no-owner --no-group \
    --include="results/" \
    --include="results/bracken_raw_matrix.tsv" \
    --include="provenance/" \
    --include="provenance/manifest.json" \
    --exclude="*" \
    "${JUNO_USER}@${JUNO_HOST}:${remote}/" \
    "${local_dir}/" \
    || echo "  !! rsync failed or nothing matched for ${name} (outdir may not exist / run may have failed)"
  echo
done

echo "Done. Pulled files land under ${DEST_ROOT}/<cohort>/results/bracken_raw_matrix.tsv"
