# Juno HPC Operations Guide

**Scope**: this is a general operations runbook for running Nextflow DSL2 pipelines
via Apptainer/SLURM on the Juno cluster (UT Dallas, TJP group). Everything in it
was learned the hard way running the `virome` pipeline in production — real
multi-cohort batch launches, real SLURM QOS limits, real Nextflow session bugs —
but **none of it is virome-specific**. Any TJP lab pipeline on Juno (`psoma`,
`bulkseq`, `10x`, `longreads`, `dconvatac`, or a new one not yet built) will hit
the same mechanics. Read this before debugging an HPC/SLURM/Nextflow issue in any
of those repos, not just here.

If you're a Claude Code session working in a *different* project under
`firebase2/` and landed here via the pointer in the root `CLAUDE.md`: everything
below applies to you too. Skim the section headers, jump to what's relevant.

---

## 1. Juno cluster geography

| Resource | Path | Notes |
|---|---|---|
| Shared pipeline root | `/groups/tprice/pipelines` | Group-owned, shared across all TJP pipelines |
| Nextflow binary | `/groups/tprice/pipelines/bin/nextflow` | Not a module — call it by full path |
| Per-user workspace | `/work/$USER/pipelines/<pipeline>/` | Groups filesystem — has a quota, don't put Nextflow `workDir` here under `-profile slurm` (see §3) |
| Fast scratch | `/scratch/juno/$USER/` | Compute-node-accessible, cleared periodically, this is where `workDir` and staged FASTQs should live |
| Titan archival storage | `/titan/tprice/...` | **Mounted on login nodes only — NOT on compute nodes.** See §6. |

**Login nodes vs. compute nodes** — the single most important geography fact:
login node memory is shared across every user logged in and gets exhausted
unpredictably; a Nextflow JVM can fail with `Cannot allocate memory` on a login
node even before it submits a single job. Never run `nextflow run` from a login
node. Always get an interactive compute node first:

```bash
srun --account=tprice --partition=normal --cpus-per-task=2 --mem=4G --time=4:00:00 --pty bash
```

Once on the compute node:
```bash
export NXF_JVM_ARGS="-Xms512m -Xmx2g"   # 512m default heap is insufficient tracking 15+ concurrent jobs
```

For unattended batch launches (the normal production pattern), the Nextflow head
process itself runs *as* an sbatch job (see §5's `run_*_config.sbatch` pattern) —
that sidesteps the login-node problem entirely since the job lands on a compute
node automatically, and it survives your SSH session disconnecting.

---

## 2. Apptainer / Singularity

- Build from the repo root — any `%files` directive in a `.def` uses paths
  relative to the *build invocation directory*, not the `.def` file's location:
  ```bash
  apptainer build --fakeroot --force containers/<tool>.sif containers/<tool>.def
  ```
- `--fakeroot` avoids needing `sudo` on Juno.
- **`ps` not found inside a container**: Nextflow's process monitor calls `ps`
  inside the container. Any custom container built on a slim/minimal base image
  (`python:3.11-slim`, bare `ubuntu`) needs `procps` added explicitly.
  Biocontainers/staphb images already include it.
- **WSL2 update (2026-07)**: contrary to older assumptions, Apptainer 1.4.5 on a
  6.6.87.2-microsoft-standard-WSL2 kernel runs real containers correctly —
  verified with a real STAR genome index build + splice-aware alignment, and a
  full multi-process DSL2 `-profile standard` orchestration run, not just
  `--version` checks. This means small-scale local smoke-testing (toy reference,
  subsampled FASTQs) is genuinely possible before a real Juno run — useful for
  catching bugs cheaply. Production-scale runs still belong on Juno. Still worth
  spot-checking any new container/tool combination rather than assuming full
  parity with Juno's Apptainer build (GPU passthrough and some mount/bind edge
  cases are the likeliest gaps).

---

## 3. Nextflow fundamentals on a SLURM executor

A typical `conf/slurm.config`:
```groovy
process {
    executor       = 'slurm'
    queue          = 'normal'
    clusterOptions = '--account=tprice --qos=<your-qos>'
    beforeScript   = 'module load apptainer && echo "SLURM_JOB_ID: $SLURM_JOB_ID"'
}
executor {
    name            = 'slurm'
    queueSize       = 10        // max concurrent jobs Nextflow will submit at once — tune to your QOS, see §5
    pollInterval    = '30 sec'
    submitRateLimit = '10/1min'
}
```

- `module load apptainer` must be in `beforeScript` — Juno compute nodes need it
  loaded explicitly, it's not present by default.
- `stageInMode = 'copy'` (in `process {}`) is required if any process uses
  Apptainer with `--cleanenv` — that flag blocks following symlinks across work
  directories, which is Nextflow's default staging behavior (`'symlink'`).
- **Nextflow's eager profile-config validation (>= ~25.x)**: `nextflow.config`'s
  `profiles {}` block has *every* `includeConfig` path validated at parse time
  for *all* profiles, not just the one you select via `-profile`. If any
  profile's included config file goes missing — even one you're not using —
  every profile fails to parse with `Invalid include source`. Keep a minimal
  stub for any profile referenced in `profiles {}` that doesn't have real
  content yet, rather than leaving the path dangling.
- Never point `-profile slurm`'s `workDir` at the groups filesystem
  (`/work/$USER/...`) — STAR-scale BAM files plus `stageInMode = 'copy'` will
  exhaust the groups quota fast. Point it at `/scratch/juno/$USER/nf_work`.

---

## 4. Nextflow session/resume mechanics — the most dangerous gotcha here

This caused more real failures in one week of batch launches than everything
else in this doc combined. Understand it before running any multi-cohort batch.

**The mechanism**: every Nextflow run has a session ID (a UUID). `-resume`
without an explicit ID doesn't mean "resume *this pipeline's* last run" — it
means "resume whatever session is most recent in `.nextflow/history`, in this
exact launch directory." `.nextflow/history` is a single shared file per launch
directory, appended to by *every* pipeline invocation from that directory,
regardless of which config/samplesheet/cohort it was for.

**The failure mode**: if you launch multiple cohorts/samples from the *same*
launch directory (e.g. `/groups/tprice/pipelines/containers/<pipeline>`, the
normal pattern when every batch job does `cd` there before calling
`nextflow run`), a bare `-resume` on cohort B can silently grab cohort A's
session if A's was the more recent entry in the shared history file — even
though B's own command line says `-params-file config_B.yaml`. This is not a
hypothetical: it happened three separate times in one real batch (a resume
grabbed a *different currently-running cohort's* session, on two different
occasions, plus a third case where a "confirmed via timing" session ID
attribution later turned out to be wrong).

**Symptoms**:
- `Unable to acquire lock on session with ID <uuid>` — the session you (or a
  bare `-resume`) grabbed is currently held by a different, actively-running
  Nextflow process. This fails fast (a few seconds) and harmlessly — no
  corruption, just wasted a submission slot.
- A resume that "succeeds" but does none of the expected cache hits — you
  attached to the wrong session's cache DB, so every task hash misses and
  everything reruns from scratch (wasteful, not corrupting — task hashes are
  content-addressed, so results are still correct, just expensively
  recomputed).

**The fix — always use an explicit session ID, never a bare `-resume`, once
more than one pipeline invocation might share a launch directory**:

```bash
# WRONG in a shared launch directory:
nextflow run main.nf -profile slurm -params-file config_X.yaml -resume

# RIGHT:
nextflow run main.nf -profile slurm -params-file config_X.yaml -resume <explicit-session-id>
```

**How to find the *correct* session ID — verify, don't infer.** The one
technique that is always reliable: grep `.nextflow/history` for text that
uniquely identifies *your* pipeline invocation (the config filename, samplesheet
name, or cohort name embedded in the command line) — never for a session ID
itself, and never by "this timing roughly matches."

```bash
grep <cohort_or_config_name> .nextflow/history
```

`.nextflow/history` is tab-separated: `timestamp  duration  run_name  status
revision_id  session_id  command_line`. The command-line field is what makes
this grep trustworthy — it's tied to *that specific invocation*, so filtering on
it is immune to any session-ID cross-contamination happening elsewhere. Extract
the session ID (field 6) with:
```bash
grep <name> .nextflow/history | tail -1 | awk -F'\t' '{print $6}'
```
Use `tail -1` for the most recent matching line; if a cohort has been resumed
multiple times, earlier lines may show earlier (possibly wrong, possibly
mid-mistake) session IDs.

**A concrete worked example from this project**, because the failure mode is
subtle enough to be worth seeing end to end: two different sessions, hours
apart, were each attributed to the wrong cohort — once "confirmed via
duration/timing matching" (wrong), once by direct command-line grep (right,
but only checked for one cohort, not cross-checked against the other). The
mistake was only caught because a *third* independent grep, run for a different
purpose, turned up a `.nextflow/history` line whose command text flatly
contradicted the earlier attribution. The general lesson: timing/duration
matching is not verification. Only a grep on the actual command-line text (or,
short of that, directly inspecting `.nextflow/cache/<session-id>/db/` file
timestamps) counts as verification. If a session ID was ever obtained by
inference rather than a direct grep, re-verify it before trusting it in a
production relaunch.

**If you don't have `lsof`** (not installed on Juno login nodes): don't try to
identify which process holds a session lock that way. Use the history grep
method above instead — it answers "which cohort does this session belong to,"
which is usually the question that actually matters.

---

## 5. SLURM job management

### Useful commands

```bash
# Full, non-truncated job listing with QOS and reason visible
squeue -u $USER -o "%.10i %.9P %.9q %.24j %.2t %.12M %R"

# Why is a specific job pending / what's its actual dependency?
scontrol show job <jobid> | grep -i depend

# Did a job actually fail, and how long did it run?
sacct -j <jobid>

# Capture a job ID for use in a dependency chain
JOBID=$(sbatch --parsable <script> <args>)
```

### QOS limits: two different mechanisms, one soft, one hard

- **`MaxJobsPerUser`** — concurrent jobs (running + pending), a **soft** limit.
  Jobs beyond it just sit `PD` with reason `QOSMaxJobsPerUserLimit` — harmless
  backpressure, Nextflow handles it gracefully, nothing fails.
- **`MaxSubmitJobsPerUser`** — total jobs submitted, a **hard** limit. A
  rejected `sbatch` call here means `sbatch: error:
  QOSMaxSubmitJobPerUserLimit`, and Nextflow treats a failed job submission as
  a **fatal** error — it aborts the *entire* pipeline run, not just the one
  task that couldn't submit.

The practical consequence: size `executor.queueSize` (in `nextflow.config`) to
respect `MaxSubmitJobsPerUser` far more carefully than `MaxJobsPerUser` — hitting
the soft limit costs you nothing but the hard limit kills a whole run.

**`sacctmgr show qos` / `show assoc` can report blank or missing limits even
when a real ceiling exists** — the real limit may be enforced elsewhere (e.g.
partition-level in `slurm.conf`) and simply isn't visible client-side. Don't
trust an empty `sacctmgr` result to mean "no limit" — if you hit a real ceiling
in practice, that empirical number is more trustworthy than what the client
tooling reports (or fails to report).

If Juno support grants an elevated QOS (e.g. a named QOS with higher limits),
it needs `--qos=<name>` added explicitly to every `#SBATCH` script *and* to
`clusterOptions` in `conf/slurm.config` — it is not automatic just because it's
associated with your account.

### `--dependency=afterany:<jobid>` — the right tool for chaining, with a sharp edge

Use this (not time-based `--begin=now+Nh` staggering) to chain jobs so B starts
only once A reaches a terminal state — the normal pattern for "run these 8
cohorts one at a time" or "run PathSeq for this cohort once its main run is
done."

```bash
sbatch --dependency=afterany:<jobid> <script> <args>
```

**The sharp edge**: `afterany` triggers on *any* terminal state — completion,
failure, timeout, **or manual `scancel`** — not just success. If you cancel a
job that something else depends on, the dependent fires immediately, even
though nothing about the actual pipeline run finished. This has a real cascade
risk: if you're mid-way through cancelling and relaunching one job in a chain,
and you cancel jobs one at a time, each cancellation can immediately unblock
and start the next thing in the chain prematurely, atop whatever changes you
were still making.

**The fix**: when you need to break into a running `afterany` chain (to fix a
bug and relaunch one link), cancel the *entire remaining chain* in one `scancel`
command, not one job at a time — then rebuild the chain fresh against the real,
current job IDs once everything is settled.

```bash
scancel <jobid1> <jobid2> <jobid3> ...   # all at once, not sequentially
```

### Building a multi-stage chain in one shot

`sbatch --parsable` returns just the numeric job ID, which lets you chain
several `sbatch` calls together in one paste using shell variables — no need to
run each command, wait, and copy the ID back manually:

```bash
BACKFILL=$(sbatch --parsable --dependency=afterany:<main_jobid> <backfill_script> <args>)
echo "Backfill job: $BACKFILL"
sbatch --dependency=afterany:$BACKFILL <downstream_script> <args>
```

### Tuning `queueSize` / `submitRateLimit`

- `executor.queueSize` in `nextflow.config` caps how many SLURM jobs a single
  Nextflow run will have submitted (running + pending) at once. Set it based on
  the *real* QOS `MaxJobsPerUser`, not a round number — exceeding it by design
  is fine (the excess just backpressures harmlessly) but exceeding
  `MaxSubmitJobsPerUser` across *multiple concurrent Nextflow runs* sharing one
  account is what actually causes fatal aborts. If several pipelines/cohorts
  run concurrently under the same account, their `queueSize` values are
  additive against the shared submit ceiling — account for that, not just each
  run's own `queueSize` in isolation.
- `submitRateLimit` (e.g. `'10/1min'`) throttles how fast Nextflow submits new
  jobs — worth keeping conservative to avoid submission bursts tripping rate
  limits independent of the job-count ceilings above.

---

## 6. Data staging patterns

A common shape for getting data onto Juno for a pipeline run: **source → Titan
(durable archival) → scratch (compute-accessible)**, not source → scratch
directly, when the source is a different, non-Juno host (an external share, a
lab NAS, etc.).

**Titan is mounted on Juno login nodes only, not compute nodes.** This is the
single most expensive-to-discover fact in this whole staging pattern — a
samplesheet pointing directly at `/titan/...` paths will pass every check run
from a login node (`ls`, manual `cat`) but fail deep inside a real pipeline run,
specifically at whatever step first tries to open those files from a compute
node (Nextflow's `checkIfExists` on samplesheet parsing, or an actual read
inside a task) — with a plain "No such file or directory," which looks
identical to a typo or a genuinely missing file. If a path check succeeds from
the login node but a real run still can't find the file, mount scope (login
vs. compute) is the first thing to check, not the path itself.

**The fix**: stage the final hop from Titan to `/scratch/juno/$USER/...`
explicitly, and point pipeline configs/samplesheets at the scratch copy, never
at `/titan/...` directly. That final staging step (`rsync -avP
/titan/.../ /scratch/juno/$USER/.../`) must itself be run from a login node —
same mount-scope constraint, just for the copy operation instead of the
pipeline run.

**For the source → Titan hop from an external, non-Juno host**:
- Use `rsync -avP -e "ssh -o ControlPath=..."` with an SSH `ControlMaster`
  socket set up in advance — authenticates once, reuses the connection for
  every subsequent `rsync`/remote-`mkdir` call instead of re-prompting.
- Double-check the destination path actually includes the remote host
  (`user@host:/path`, not just `/path`) before kicking off a large transfer —
  a missing host prefix silently writes to the *local* filesystem of whatever
  machine you're running `rsync` from, which is easy to not notice until that
  machine's disk fills up.
- Run inside `tmux` (or `screen`) for any transfer that will outlive your SSH
  session — large transfers (hundreds of GB, hours) will otherwise die the
  moment the connection drops.
- Verify what actually appears in the source's file listing before assuming a
  read of "0 bytes" or an oddly small file means a broken transfer — check the
  *source* file's size and integrity too (`gzip -t`, `zcat | wc -l`) before
  concluding the copy is at fault; sometimes the source itself is genuinely a
  stub or empty file, not a transfer bug.

---

## 7. Git / filesystem gotchas (WSL2-specific but consequential on real Linux)

**WSL2's DrvFs mount reports every file as executable (`777`) locally,
regardless of git's actual tracked file mode.** This means a script that's
`git`-tracked as `100644` (not executable) will *run fine* when tested locally
in WSL2 but fail on any real Linux checkout (Juno, CI, a colleague's machine)
with a permission error — because DrvFs doesn't reflect or enforce the real
tracked mode, it fakes full permissions unconditionally.

**Where this bites**: any script invoked as a bare command (`compare_db_results.py`,
not `python3 compare_db_results.py`) needs its executable bit set correctly in
git, not just locally. A script invoked via an explicit interpreter
(`python3 script.py`, `Rscript script.R`) is immune to this, since the
interpreter doesn't need the file's own x-bit.

**Diagnostic signal**: SLURM/container task failure with **exit code 126**
("found but not executable" — permission denied) points at exactly this. Exit
code **127** ("command not found") is a different problem — the file genuinely
isn't where the invocation expects it.

**Fix, without depending on local `chmod` (which WSL2 will happily let you run,
but it won't reflect in the real tracked git mode either)**:
```bash
git update-index --chmod=+x path/to/script.py
git commit -m "fix executable bit"
```
Confirm the real tracked mode directly rather than trusting a local `ls -l`:
```bash
git ls-files -s path/to/script.py   # 100755 = executable, 100644 = not
```
When one bare-invoked script is found with this bug, check every other
bare-invoked script in the same repo in one pass — it's very likely a
systemic issue (e.g. every script added in the same commit/PR), not a single
isolated mistake.

---

## 8. Monitoring a running pipeline

If `nextflow.config` has `trace { enabled = true; fields = '...' }` (worth
enabling in every pipeline — it's cheap and the single best status-check
mechanism), each run writes `${outdir}/pipeline_info/execution_trace.tsv`, a
live-updating, tab-separated per-task status log.

**Fast per-cohort/per-run status dashboard** — task counts by status, across
every active outdir at once:
```bash
for outdir in /scratch/juno/$USER/<pipeline>_*; do
    name=$(basename "$outdir")
    trace="$outdir/pipeline_info/execution_trace.tsv"
    if [ -f "$trace" ]; then
        total=$(($(wc -l < "$trace") - 1))
        done=$(awk -F'\t' 'NR>1 && $4=="COMPLETED"' "$trace" | wc -l)
        running=$(awk -F'\t' 'NR>1 && $4=="RUNNING"' "$trace" | wc -l)
        failed=$(awk -F'\t' 'NR>1 && $4=="FAILED"' "$trace" | wc -l)
        printf "%-35s %4d done  %4d running  %4d failed  / %4d logged\n" "$name" "$done" "$running" "$failed" "$total"
    else
        printf "%-35s not started yet (no trace file)\n" "$name"
    fi
done
```
(Field 4 assumes a trace `fields` list starting `task_id,process,tag,status,...`
— adjust the field index if a different `fields` order is configured.)

**Per-process breakdown for one run** — exactly which stage is the bottleneck:
```bash
awk -F'\t' 'NR>1 {print $2, $4}' <outdir>/pipeline_info/execution_trace.tsv | sort | uniq -c | sort -rn
```

**Important distinction in the `status` column**: `CACHED` (a `-resume` hit —
work already done in a prior run, not re-executed) is different from
`COMPLETED` (executed fresh in *this* run). A trace showing mostly `CACHED`
entries and a handful of `COMPLETED` ones after a `-resume` is exactly what a
healthy, efficient resume looks like — don't mistake a low `COMPLETED` count
for a stalled run when the real story is "everything else was already done."
Conversely, don't assume every fresh `COMPLETED` task after a bugfix relates to
the bug you just fixed — some may simply be tasks that had never been reached
yet in any prior (aborted) run, and would have executed identically with or
without the fix. Check what actually changed (e.g. the task's real output
content) before attributing a fresh completion to a specific fix.

**Live log tail** for a currently-running job:
```bash
tail -n 40 /scratch/juno/$USER/logs/<pipeline>_<jobid>.log
```
Nextflow reprints its whole process-status "board" to the log on every state
change in non-interactive mode — `tail` on a reasonably generous line count
(40+) usually captures the latest full board even for pipelines with many
processes.

---

## 9. Common container/tool gotchas

- **`ps` not found** — see §2 (add `procps` to slim base images).
- **MultiQC output naming**: with `--filename multiqc_report.html`, the data
  directory is `multiqc_report_data/`, *not* `multiqc_data/` — don't assume the
  default name if `--filename` was customized.
- **Click `multiple=True` CLI options**: need repeated flags
  (`--flag val1 --flag val2`), not `--flag val1 val2`. In a Nextflow module
  script, build this with `.collect { "--flag $it" }.join(' ')`, not a single
  space-joined string after one `--flag`.
- **Network drive rsync from WSL**: use `-r` instead of `-a` (drop the `-a`
  bundle), and add `--no-links --no-perms --no-owner --no-group` — WSL's
  network-drive semantics don't support what `-a` tries to preserve. If it
  still fails, drop to Windows PowerShell `scp` directly rather than fighting
  WSL's networking layer.

---

## 10. The one meta-lesson worth remembering

Every real failure in this doc was eventually root-caused correctly — and
every near-miss came from skipping direct verification in favor of a plausible
inference. Timing that "roughly matches," a job name that "should be" a
particular cohort, a session ID "confirmed via duration matching" — these are
all hypotheses, not answers, and this environment has produced a wrong answer
from exactly that kind of reasoning more than once. The pattern that actually
works, every time: grep the file that has the real answer (`.nextflow/history`
for session ownership, `execution_trace.tsv` for task status, the actual
`.kraken2.report`/`Log.final.out`/whatever content file for what a task really
produced), and only act on what it says. When two pieces of evidence disagree,
trust the more direct one and go re-derive the other — don't average them or
assume the more recent claim is automatically right.
