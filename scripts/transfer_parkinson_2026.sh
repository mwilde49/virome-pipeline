#!/usr/bin/env bash
# transfer_parkinson_2026.sh
# Transfer 2026 Parkinson's DRG FASTQs and pipeline assets to Juno
#
# Run from local WSL:
#   bash scripts/transfer_parkinson_2026.sh
#
# Prerequisites:
#   - SSH key configured for maw210003@juno.hpcre.utdallas.edu
#   - MD5 checksums verified locally before transfer (see verify step below)
#   - Juno destination directory created

set -euo pipefail

JUNO="maw210003@juno.hpcre.utdallas.edu"
LOCAL_FASTQ="/mnt/c/users/mwild/firebase2/bulk_rnaseq/2026_ParkinsonsDRG/AN00028264"
JUNO_DATA="/groups/tprice/data/2026_ParkinsonsDRG"
JUNO_PIPE="/groups/tprice/pipelines/containers/virome"
LOCAL_PIPE="/mnt/c/users/mwild/firebase2/virome"

echo "=============================================="
echo " virome-pipeline — Parkinson's 2026 transfer"
echo " $(date)"
echo "=============================================="

# ── Step 1: create destination directory on Juno ──────────────────────────
echo ""
echo "[1/4] Creating data directory on Juno..."
ssh "$JUNO" "mkdir -p ${JUNO_DATA}"

# ── Step 2: transfer FASTQs ───────────────────────────────────────────────
echo ""
echo "[2/4] Transferring FASTQs (~70 GB, will take time)..."
echo "      Source:      ${LOCAL_FASTQ}/*.fastq.gz"
echo "      Destination: ${JUNO}:${JUNO_DATA}/"
rsync -avP --no-links --no-perms --no-owner --no-group \
    "${LOCAL_FASTQ}"/*.fastq.gz \
    "${LOCAL_FASTQ}"/*.md5 \
    "${JUNO}:${JUNO_DATA}/"

# ── Step 3: verify checksums on Juno after transfer ───────────────────────
echo ""
echo "[3/4] Verifying checksums on Juno..."
ssh "$JUNO" "cd ${JUNO_DATA} && cat *.md5 > /tmp/parkinson_all.md5 && md5sum -c /tmp/parkinson_all.md5"

# ── Step 4: sync updated pipeline assets to Juno ─────────────────────────
echo ""
echo "[4/4] Syncing pipeline assets (samplesheet, config, containers)..."
rsync -avP --no-links --no-perms --no-owner --no-group \
    "${LOCAL_PIPE}/assets/samplesheets/samplesheet_parkinson_2026_juno.csv" \
    "${LOCAL_PIPE}/assets/config_parkinson_2026.yaml" \
    "${LOCAL_PIPE}/assets/artifact_taxa.tsv" \
    "${LOCAL_PIPE}/assets/taxon_remap.tsv" \
    "${JUNO}:${JUNO_PIPE}/assets/"

echo ""
echo "=============================================="
echo " Transfer complete. Next steps:"
echo ""
echo " 1. SSH to Juno and get a compute node:"
echo "    ssh ${JUNO}"
echo "    srun --account=tprice --partition=normal --cpus-per-task=2 --mem=4G --time=4:00:00 --pty bash"
echo ""
echo " 2. Launch the pipeline:"
echo "    export NXF_JVM_ARGS=\"-Xms512m -Xmx2g\""
echo "    /groups/tprice/pipelines/bin/nextflow run ${JUNO_PIPE}/main.nf \\"
echo "        -profile slurm \\"
echo "        -params-file ${JUNO_PIPE}/assets/config_parkinson_2026.yaml"
echo "=============================================="
