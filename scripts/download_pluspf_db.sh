#!/usr/bin/env bash
#SBATCH --job-name=dl_pluspf
#SBATCH --output=logs/dl_pluspf_%j.log
#SBATCH --time=06:00:00
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=4
#SBATCH --mem=16G
#SBATCH --partition=normal

# Download and extract the Kraken2 PlusPF standard database (k2_pluspf_20240904)
# from the Langmead Lab S3 bucket. PlusPF includes: archaea, bacteria, viral,
# plasmid, human, UniVec_Core, protozoa, fungi, plant — competitive classification
# prevents host/environmental reads from being forced into viral bins.
#
# Output: /groups/tprice/pipelines/references/kraken2_pluspf_db/
# Size:   ~70 GB compressed, ~120 GB extracted
# Time:   ~2–4 hours depending on network

set -euo pipefail

DB_DIR="/groups/tprice/pipelines/references/kraken2_pluspf_db"
DB_URL="https://genome-idx.s3.amazonaws.com/kraken/k2_pluspf_20240904.tar.gz"
TARBALL="${DB_DIR}/k2_pluspf_20240904.tar.gz"

mkdir -p "${DB_DIR}"
mkdir -p logs

echo "Downloading PlusPF database to ${DB_DIR} ..."
echo "URL: ${DB_URL}"
echo "Start: $(date)"

# Resume-capable download
wget --continue --show-progress -O "${TARBALL}" "${DB_URL}"

echo "Download complete: $(date)"
echo "Extracting ..."

tar -xzf "${TARBALL}" -C "${DB_DIR}"

echo "Extraction complete: $(date)"
echo "Contents:"
ls -lh "${DB_DIR}/"

# Remove tarball to save space
rm -f "${TARBALL}"
echo "Done. Database ready at ${DB_DIR}"
