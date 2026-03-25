#!/bin/bash
# =============================================================================
# Transfer new DRG samples (AIG1390 + Saad batches) to Juno
#
# Usage (run locally from repo root):
#   bash scripts/transfer_drg2.sh <local_test_data_dir>
#
# Example:
#   bash scripts/transfer_drg2.sh test_data
#
# Destination on Juno: /scratch/juno/maw210003/fastq/drg2/
# These paths are referenced in samplesheets/all_cohort.csv
# =============================================================================

set -euo pipefail

JUNO_USER="maw210003"
JUNO_HOST="juno.hpcre.utdallas.edu"
JUNO_DEST="/scratch/juno/maw210003/fastq/drg2"
LOCAL_DIR="${1:?Usage: transfer_drg2.sh <local_test_data_dir>}"

echo "=== Transferring new DRG samples to Juno ==="
echo "Source : ${LOCAL_DIR}/"
echo "Dest   : ${JUNO_USER}@${JUNO_HOST}:${JUNO_DEST}/"
echo ""

# Create destination directory on Juno
ssh "${JUNO_USER}@${JUNO_HOST}" "mkdir -p ${JUNO_DEST}"

# Transfer all AIG1390 and Saad fastq files
rsync -avP --no-perms --no-owner --no-group \
    "${LOCAL_DIR}/AIG1390-L1_S9_L002_R1_001.fastq.gz" \
    "${LOCAL_DIR}/AIG1390-L1_S9_L002_R2_001.fastq.gz" \
    "${LOCAL_DIR}/AIG1390-L2_S10_L002_R1_001.fastq.gz" \
    "${LOCAL_DIR}/AIG1390-L2_S10_L002_R2_001.fastq.gz" \
    "${LOCAL_DIR}/AIG1390-L3_S11_L002_R1_001.fastq.gz" \
    "${LOCAL_DIR}/AIG1390-L3_S11_L002_R2_001.fastq.gz" \
    "${LOCAL_DIR}/AIG1390-L4_S12_L002_R1_001.fastq.gz" \
    "${LOCAL_DIR}/AIG1390-L4_S12_L002_R2_001.fastq.gz" \
    "${LOCAL_DIR}/AIG1390-T12_S14_L002_R1_001.fastq.gz" \
    "${LOCAL_DIR}/AIG1390-T12_S14_L002_R2_001.fastq.gz" \
    "${LOCAL_DIR}/Saad-1_S19_L001_R1_001.fastq.gz" \
    "${LOCAL_DIR}/Saad-1_S19_L001_R2_001.fastq.gz" \
    "${LOCAL_DIR}/Saad-2_S20_L001_R1_001.fastq.gz" \
    "${LOCAL_DIR}/Saad-2_S20_L001_R2_001.fastq.gz" \
    "${LOCAL_DIR}/Saad-3_S21_L001_R1_001.fastq.gz" \
    "${LOCAL_DIR}/Saad-3_S21_L001_R2_001.fastq.gz" \
    "${LOCAL_DIR}/Saad-4_S22_L001_R1_001.fastq.gz" \
    "${LOCAL_DIR}/Saad-4_S22_L001_R2_001.fastq.gz" \
    "${LOCAL_DIR}/Saad-5_S23_L001_R1_001.fastq.gz" \
    "${LOCAL_DIR}/Saad-5_S23_L001_R2_001.fastq.gz" \
    "${JUNO_USER}@${JUNO_HOST}:${JUNO_DEST}/"

echo ""
echo "=== Transfer complete ==="
echo "Verify on Juno:"
echo "  ssh ${JUNO_USER}@${JUNO_HOST} 'ls -lh ${JUNO_DEST}/'"
