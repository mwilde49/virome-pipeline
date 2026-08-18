#!/usr/bin/env bash
# =============================================================================
# Print SLURM partition/node resource info -- run this on Juno before
# submitting a big job (virus_test_datasets download, PathSeq, etc.) to pick
# a partition with enough free/fast nodes and a walltime limit that actually
# fits the job's --time request.
#
# Usage:
#   bash scripts/check_partitions.sh
# =============================================================================

set -uo pipefail   # not -e: keep going even if one command below errors

section() { echo ""; echo "=== $* ==="; }

section "Partition overview"
sinfo

section "Per-partition table (avail, max walltime, node count, CPU alloc/idle/total, memory, features)"
sinfo -o "%20P %.6a %.12l %.6D %.16C %.10m %.25f %N"

section "Per-node detail"
sinfo -N -l

section "Full partition config (limits, QOS, node list, TRES) -- includes real MaxTime per partition"
scontrol show partition

section "Full node hardware detail (exact CPUs, RealMemory, Features, Gres)"
scontrol show nodes

section "GPU partitions/nodes, if any"
sinfo -o "%P %G %D %C" | grep -v "(null)"

section "Current queue load (spot an underused partition)"
squeue -a -o "%.10i %.12P %.8u %.10T %.10M %.6D %.4C"

section "Your account's QOS limits (max walltime/nodes/cpus you're allowed to request)"
sacctmgr show qos format=Name,MaxWall,MaxTRESPerUser,MaxJobsPerUser -p
