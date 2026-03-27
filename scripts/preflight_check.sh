#!/bin/bash
# =============================================================================
# preflight_check.sh — Virome pipeline preflight verification
#
# Verifies that all required resources, containers, databases, and configs
# are in place before submitting a pipeline run on Juno.
#
# Usage:
#   bash scripts/preflight_check.sh                    # standard run check
#   bash scripts/preflight_check.sh --dual-db          # also check PlusPF DB
#   bash scripts/preflight_check.sh --params-file assets/config_pluspf.yaml
#
# Run this from the pipeline root on a Juno compute node (not login node):
#   srun --account=tprice --partition=normal --cpus-per-task=2 --mem=4G --time=0:30:00 --pty bash
#   bash scripts/preflight_check.sh [options]
# =============================================================================

set -uo pipefail

# ---------------------------------------------------------------------------
# Defaults
# ---------------------------------------------------------------------------
DUAL_DB=false
PARAMS_FILE=""
PIPELINE_DIR="/groups/tprice/pipelines/containers/virome"
CONTAINER_DIR="/groups/tprice/pipelines/containers/virome"
REFS_DIR="/groups/tprice/pipelines/references"
NF_BIN="/groups/tprice/pipelines/bin/nextflow"

PASS=0
FAIL=0
WARN=0

# ---------------------------------------------------------------------------
# Argument parsing
# ---------------------------------------------------------------------------
while [[ $# -gt 0 ]]; do
    case "$1" in
        --dual-db)       DUAL_DB=true; shift ;;
        --params-file)   PARAMS_FILE="$2"; shift 2 ;;
        *) echo "Unknown option: $1"; exit 1 ;;
    esac
done

# ---------------------------------------------------------------------------
# Helper functions
# ---------------------------------------------------------------------------
pass() { echo "  [PASS] $1"; ((PASS++)); }
fail() { echo "  [FAIL] $1"; ((FAIL++)); }
warn() { echo "  [WARN] $1"; ((WARN++)); }
section() { echo ""; echo "── $1 ──────────────────────────────────────────────"; }

# ---------------------------------------------------------------------------
# Check 1: Environment
# ---------------------------------------------------------------------------
section "Environment"

if [[ -n "${SLURM_JOB_ID:-}" ]]; then
    pass "Running inside SLURM job $SLURM_JOB_ID (not on login node)"
else
    warn "Not inside a SLURM job — recommend running via: srun --account=tprice --partition=normal --cpus-per-task=2 --mem=4G --time=0:30:00 --pty bash"
fi

if [[ -n "${NXF_JVM_ARGS:-}" ]]; then
    pass "NXF_JVM_ARGS set: $NXF_JVM_ARGS"
else
    warn "NXF_JVM_ARGS not set — run: export NXF_JVM_ARGS=\"-Xms512m -Xmx2g\" before nextflow"
fi

# ---------------------------------------------------------------------------
# Check 2: Nextflow binary
# ---------------------------------------------------------------------------
section "Nextflow"

if [[ -x "$NF_BIN" ]]; then
    NF_VERSION=$("$NF_BIN" -version 2>&1 | grep -oP 'version \K[0-9.]+' | head -1)
    pass "Nextflow binary found: $NF_BIN (v${NF_VERSION:-unknown})"
else
    fail "Nextflow binary not found or not executable: $NF_BIN"
fi

if command -v apptainer &>/dev/null; then
    pass "Apptainer in PATH: $(command -v apptainer)"
else
    # Try loading the module
    if module load apptainer 2>/dev/null && command -v apptainer &>/dev/null; then
        pass "Apptainer available via module load"
    else
        fail "Apptainer not in PATH and module load failed — required for all pipeline processes"
    fi
fi

# ---------------------------------------------------------------------------
# Check 3: Pipeline repo
# ---------------------------------------------------------------------------
section "Pipeline repo ($PIPELINE_DIR)"

if [[ -d "$PIPELINE_DIR" ]]; then
    pass "Pipeline directory exists"
else
    fail "Pipeline directory not found: $PIPELINE_DIR"
fi

if [[ -f "$PIPELINE_DIR/main.nf" ]]; then
    pass "main.nf present"
else
    fail "main.nf not found in $PIPELINE_DIR"
fi

# Git status
if cd "$PIPELINE_DIR" && git rev-parse --git-dir &>/dev/null; then
    LOCAL=$(git rev-parse HEAD)
    REMOTE=$(git rev-parse origin/main 2>/dev/null || echo "unknown")
    if [[ "$LOCAL" == "$REMOTE" ]]; then
        pass "Git: up to date with origin/main ($LOCAL)"
    else
        warn "Git: local ($LOCAL) differs from origin/main ($REMOTE) — run 'git pull' to sync"
    fi
else
    warn "Not a git repo or git not available — cannot check sync status"
fi

# bin/ scripts executable
section "bin/ scripts"
BIN_SCRIPTS=("$PIPELINE_DIR/bin/filter_kraken2_report.py"
             "$PIPELINE_DIR/bin/aggregate_bracken.py"
             "$PIPELINE_DIR/bin/compare_db_results.py"
             "$PIPELINE_DIR/bin/virome_report.py")
for script in "${BIN_SCRIPTS[@]}"; do
    name=$(basename "$script")
    if [[ -f "$script" && -x "$script" ]]; then
        pass "bin/$name: present and executable"
    elif [[ -f "$script" ]]; then
        fail "bin/$name: present but NOT executable — run: chmod +x $PIPELINE_DIR/bin/*.py"
    else
        fail "bin/$name: missing — run 'git pull' in pipeline directory"
    fi
done

# ---------------------------------------------------------------------------
# Check 4: Containers
# ---------------------------------------------------------------------------
section "Containers ($CONTAINER_DIR)"

CONTAINERS=("python.sif" "kraken2.sif" "bracken.sif" "star.sif"
            "trimmomatic.sif" "fastqc.sif" "multiqc.sif")
for sif in "${CONTAINERS[@]}"; do
    path="$CONTAINER_DIR/$sif"
    if [[ -f "$path" ]]; then
        size=$(du -sh "$path" 2>/dev/null | cut -f1)
        pass "$sif: present ($size)"
    else
        fail "$sif: MISSING — rebuild with: apptainer build --fakeroot --force containers/$sif containers/${sif%.sif}.def"
    fi
done

# Verify python.sif contains compare_db_results.py (important for dual-DB runs)
if [[ -f "$CONTAINER_DIR/python.sif" ]]; then
    if apptainer exec "$CONTAINER_DIR/python.sif" test -f /usr/local/bin/compare_db_results.py 2>/dev/null || \
       apptainer exec "$CONTAINER_DIR/python.sif" python3 -c "import importlib.util; exit(0 if importlib.util.find_spec('compare_db_results') else 1)" 2>/dev/null; then
        pass "python.sif: compare_db_results.py found inside container"
    else
        warn "python.sif: compare_db_results.py not confirmed inside container — pipeline uses host bin/ PATH injection, but consider rebuilding for portability"
    fi
fi

# ---------------------------------------------------------------------------
# Check 5: Reference databases
# ---------------------------------------------------------------------------
section "Reference databases"

# STAR index
STAR_INDEX="$REFS_DIR/star_index"
if [[ -d "$STAR_INDEX" ]]; then
    if ls "$STAR_INDEX"/SA &>/dev/null || ls "$STAR_INDEX"/Genome &>/dev/null; then
        STAR_SIZE=$(du -sh "$STAR_INDEX" 2>/dev/null | cut -f1)
        pass "STAR index: $STAR_INDEX ($STAR_SIZE)"
    else
        fail "STAR index directory exists but appears incomplete (missing SA/Genome files): $STAR_INDEX"
    fi
else
    fail "STAR index not found: $STAR_INDEX"
fi

# Kraken2 viral-only DB
VIRAL_DB="$REFS_DIR/kraken2_viral_db"
if [[ -d "$VIRAL_DB" ]]; then
    MISSING_VIRAL=()
    for f in hash.k2d opts.k2d taxo.k2d; do
        [[ -f "$VIRAL_DB/$f" ]] || MISSING_VIRAL+=("$f")
    done
    if [[ ${#MISSING_VIRAL[@]} -eq 0 ]]; then
        DB_SIZE=$(du -sh "$VIRAL_DB" 2>/dev/null | cut -f1)
        pass "Kraken2 viral DB: $VIRAL_DB ($DB_SIZE)"
    else
        fail "Kraken2 viral DB: missing files: ${MISSING_VIRAL[*]}"
    fi
    # Check Bracken kmer_distrib for 150bp
    if ls "$VIRAL_DB"/database150mers.kmer_distrib &>/dev/null; then
        pass "Bracken 150bp kmer_distrib: present (viral DB)"
    else
        warn "Bracken database150mers.kmer_distrib not found in viral DB — Bracken step will fail at 150bp read length"
    fi
else
    fail "Kraken2 viral DB not found: $VIRAL_DB"
fi

# PlusPF DB (only if --dual-db or params file references it)
if [[ "$DUAL_DB" == true ]]; then
    PLUSPF_DB="$REFS_DIR/kraken2_pluspf_db"
    if [[ -d "$PLUSPF_DB" ]]; then
        MISSING_PF=()
        for f in hash.k2d opts.k2d taxo.k2d; do
            [[ -f "$PLUSPF_DB/$f" ]] || MISSING_PF+=("$f")
        done
        if [[ ${#MISSING_PF[@]} -eq 0 ]]; then
            PF_SIZE=$(du -sh "$PLUSPF_DB/hash.k2d" 2>/dev/null | cut -f1)
            pass "PlusPF DB: $PLUSPF_DB (hash.k2d: $PF_SIZE)"
        else
            fail "PlusPF DB: missing files: ${MISSING_PF[*]}"
        fi
        if ls "$PLUSPF_DB"/database150mers.kmer_distrib &>/dev/null; then
            pass "Bracken 150bp kmer_distrib: present (PlusPF DB)"
        else
            fail "Bracken database150mers.kmer_distrib not found in PlusPF DB — required for Bracken at 150bp"
        fi
    else
        fail "PlusPF DB not found: $PLUSPF_DB"
    fi
fi

# ---------------------------------------------------------------------------
# Check 6: Assets
# ---------------------------------------------------------------------------
section "Pipeline assets"

ASSETS_DIR="$PIPELINE_DIR/assets"
ASSET_FILES=("artifact_taxa.tsv" "taxon_remap.tsv" "NexteraPE-PE.fa")
for asset in "${ASSET_FILES[@]}"; do
    path="$ASSETS_DIR/$asset"
    if [[ -f "$path" ]]; then
        lines=$(wc -l < "$path")
        pass "$asset: present ($lines lines)"
    else
        fail "$asset: missing from $ASSETS_DIR"
    fi
done

# Count artifact list entries
ARTIFACT_FILE="$ASSETS_DIR/artifact_taxa.tsv"
if [[ -f "$ARTIFACT_FILE" ]]; then
    N_ARTIFACTS=$(grep -v '^#' "$ARTIFACT_FILE" | grep -v '^[[:space:]]*$' | wc -l)
    if [[ "$N_ARTIFACTS" -ge 24 ]]; then
        pass "Artifact exclusion list: $N_ARTIFACTS entries (expected ≥24)"
    else
        warn "Artifact exclusion list: only $N_ARTIFACTS entries (expected ≥24) — may be outdated"
    fi
fi

# Check NO_FILE sentinel
if [[ -f "$ASSETS_DIR/NO_FILE" ]]; then
    pass "NO_FILE sentinel: present"
else
    warn "NO_FILE sentinel missing from assets/ — optional module inputs (comparison_plot etc.) may fail"
    echo "       Fix: touch $ASSETS_DIR/NO_FILE"
fi

# ---------------------------------------------------------------------------
# Check 7: Params file (if provided)
# ---------------------------------------------------------------------------
if [[ -n "$PARAMS_FILE" ]]; then
    section "Params file ($PARAMS_FILE)"

    if [[ -f "$PARAMS_FILE" ]]; then
        pass "Params file exists"
    else
        fail "Params file not found: $PARAMS_FILE"
    fi

    # Check samplesheet
    SS=$(grep '^samplesheet:' "$PARAMS_FILE" | awk '{print $2}' | tr -d '"')
    if [[ -n "$SS" && -f "$SS" ]]; then
        N_SAMPLES=$(tail -n +2 "$SS" | grep -v '^[[:space:]]*$' | wc -l)
        pass "Samplesheet: $SS ($N_SAMPLES samples)"
    elif [[ -n "$SS" ]]; then
        fail "Samplesheet not found: $SS"
    else
        fail "samplesheet not defined in params file"
    fi

    # Check outdir parent is writable
    OUTDIR=$(grep '^outdir:' "$PARAMS_FILE" | awk '{print $2}' | tr -d '"')
    if [[ -n "$OUTDIR" ]]; then
        OUTDIR_PARENT=$(dirname "$OUTDIR")
        if [[ -w "$OUTDIR_PARENT" ]]; then
            pass "Outdir parent writable: $OUTDIR_PARENT"
        else
            fail "Outdir parent not writable: $OUTDIR_PARENT"
        fi
    else
        fail "outdir not defined in params file"
    fi

    # Warn if kraken2_db and kraken2_db2 are the same path (the config bug)
    DB1=$(grep '^kraken2_db:' "$PARAMS_FILE" | grep -v 'db2' | awk '{print $2}' | tr -d '"')
    DB2=$(grep '^kraken2_db2:' "$PARAMS_FILE" | awk '{print $2}' | tr -d '"')
    if [[ -n "$DB1" && -n "$DB2" && "$DB1" == "$DB2" ]]; then
        fail "kraken2_db and kraken2_db2 point to the SAME path ($DB1) — dual-DB comparison will be meaningless (PlusPF-vs-PlusPF bug)"
    elif [[ -n "$DB1" && -n "$DB2" ]]; then
        pass "kraken2_db ($DB1) and kraken2_db2 ($DB2) are different paths"
    fi
fi

# ---------------------------------------------------------------------------
# Check 8: Disk space
# ---------------------------------------------------------------------------
section "Disk space"

SCRATCH_DIR="/scratch/juno/${USER:-maw210003}"
if df -h "$SCRATCH_DIR" &>/dev/null; then
    AVAIL=$(df -h "$SCRATCH_DIR" | awk 'NR==2{print $4}')
    AVAIL_GB=$(df -BG "$SCRATCH_DIR" | awk 'NR==2{gsub("G","",$4); print $4}')
    if [[ "${AVAIL_GB:-0}" -ge 200 ]]; then
        pass "Scratch space: $AVAIL available at $SCRATCH_DIR"
    elif [[ "${AVAIL_GB:-0}" -ge 50 ]]; then
        warn "Scratch space: only $AVAIL available at $SCRATCH_DIR — STAR BAM files are large; may run out mid-run"
    else
        fail "Scratch space: critically low ($AVAIL at $SCRATCH_DIR) — clean up before running"
    fi
else
    warn "Cannot check scratch disk space at $SCRATCH_DIR"
fi

GROUPS_DIR="/groups/tprice/pipelines"
if df -h "$GROUPS_DIR" &>/dev/null; then
    AVAIL=$(df -h "$GROUPS_DIR" | awk 'NR==2{print $4}')
    pass "Groups filesystem: $AVAIL available"
else
    warn "Cannot check groups filesystem space"
fi

# ---------------------------------------------------------------------------
# Summary
# ---------------------------------------------------------------------------
echo ""
echo "════════════════════════════════════════════════════"
echo "  Preflight complete"
echo "  PASS: $PASS   WARN: $WARN   FAIL: $FAIL"
echo "════════════════════════════════════════════════════"

if [[ $FAIL -gt 0 ]]; then
    echo ""
    echo "  ✗ $FAIL check(s) failed — resolve before running the pipeline."
    exit 1
elif [[ $WARN -gt 0 ]]; then
    echo ""
    echo "  ⚠ $WARN warning(s) — review before running."
    exit 0
else
    echo ""
    echo "  ✓ All checks passed. Ready to run."
    exit 0
fi
