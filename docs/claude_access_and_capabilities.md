# Claude Code Access to Remote Infrastructure

**Purpose**: the permanent record of exactly what remote access a Claude Code
session has (and doesn't have) for this project, so a future session — on
this machine or a different one, with a fresh `~/.ssh` or an existing one —
knows what to check for and what the known gotchas are, without rediscovering
any of it by trial and error. See `RESTART_CLAUDE.md` for the broader
project-resumption context this doc is one piece of.

No private key material, fingerprints, or passphrases are recorded here —
only filenames, scopes, setup mechanics, and public key strings (public keys
are not secrets).

## 1. The general access model

Claude Code sessions in this environment have **no general/interactive SSH or
shell access to Juno**. A direct `ssh maw210003@juno.hpcre.utdallas.edu` using
the general `~/.ssh/id_ed25519` key is rejected outright at publickey auth —
confirmed repeatedly. Juno most likely requires password + Duo 2FA, which
needs a real TTY this environment doesn't have.

Any broad cluster action — `sbatch` submission, `squeue`/`sacct` beyond what
the narrow status key below covers, git operations inside Juno's own deployed
pipeline checkout, arbitrary file reads outside the pull-only key's jail —
has to be relayed through the user: they run it in their own already-
authenticated Juno session and paste the output back into the conversation.

**Never present a Juno-side command as something Claude actually ran or
checked** unless it went through one of the three narrow keys in §2. Always
frame anything else explicitly as "run this yourself and paste the output
back," and never guess at or assume cluster state (job status, file
existence, download progress) — ask for real pasted output instead.

## 2. Juno — three purpose-built restricted keys (set up 2026-08-22, verified working)

### `id_ed25519_juno_pullonly` — read-only rsync pull

- Jailed via `rrsync -ro` to `/scratch/juno/maw210003` only.
- Public key: `ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFtmbd9U2OT3qaGGxJ3f9VNCLT3qLmyAvPClEip0Ac1Q claude-code-juno-pullonly`
- Verified via 4 adversarial tests: arbitrary shell command rejected,
  legitimate pull succeeded byte-for-byte identical to a known-good copy,
  push rejected, `..`-escape rejected.
- **The #1 gotcha**: paths must be given *relative to the jail root as if it
  were the filesystem root* — e.g.
  `maw210003@juno...:/virome_thoracic_drg/results/...`, **not** the real
  absolute path `/scratch/juno/maw210003/virome_thoracic_drg/...`. Giving the
  real absolute path double-prepends the jail server-side and fails with a
  `change_dir` error.
- The server-side `rrsync` on Juno **must be the v3.2.7-tagged release**
  (`https://raw.githubusercontent.com/WayneD/rsync/v3.2.7/support/rrsync`),
  not current `master`. Master's O_NONBLOCK/O_NOFOLLOW anti-race-hardening
  reopen fails on Juno's `/scratch` mount (WekaFS) with a misleading
  `post-realpath open failed (race detected)` error, even for provably-
  existing regular files. v3.2.7's simpler rrsync (chdir + realpath
  containment, no O_NONBLOCK reopen) works correctly on it.

### `id_ed25519_juno_inspect` — read-only inspection

- Public key: `ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEmufzaT69g6Y3htUXwLwIKsropCrwK++bUBi8qGLten claude-code-juno-inspect`
- Intended purpose per project memory: a broader read-only shell-inspection
  dispatcher, narrower than general shell access but wider than the pull-only
  key's rsync jail. **The exact current mechanics (which commands/keywords it
  accepts, whether it's a keyword dispatcher using `os.execvp` with no shell
  interpolation, matching the status-only key's pattern below) were not
  independently re-verified in the session that wrote this file** — treat the
  broad shape as reliable but confirm the precise accepted-command surface
  before depending on it for anything sensitive.

### `id_ed25519_juno_statusonly` — status-only keyword dispatcher

- Public key: `ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGuRSSPF/A9NGn4Bjgz+w5GvkED035hj6/5Vkt/BFaAJ claude-code-juno-statusonly`
- For `squeue`/`sacct`-style job-status checks without general shell access.
- Same caveat as `id_ed25519_juno_inspect` above: the broad purpose is known
  and documented, but the exact current keyword surface wasn't independently
  re-verified this session — confirm before relying on it for anything beyond
  routine status polling.

### Setup mechanics (all three keys)

- Set up via forced `command=`/`restrict` entries appended to Juno-side
  `~/.ssh/authorized_keys` — **appended, never rewrote the file**, because a
  real, pre-existing NUL-byte corruption was found in that file (unrelated to
  this work — ~29 NUL bytes prepended directly onto an existing unrelated
  key's line, no separating newline). Flagged to the user; root cause
  unconfirmed (leading guess: Warewulf provisioning automation touching the
  file concurrently).
- The `.gitignore` entries protecting all three keypairs from accidental
  commit existed in the working tree but sat **uncommitted** for a while —
  committed 2026-08-27 (commit `40d39bb`) alongside the Threadripper entries
  below.

## 3. A genuine git-submodule gotcha on Juno's deployed pipeline checkout

Juno's deployed copy of this pipeline lives at
`/groups/tprice/pipelines/containers/virome`, a **real git submodule** of the
`hpc` superproject (`.git` there is a file/gitlink, not a directory — not an
independent clone, correcting earlier documentation that assumed it was).

Submodule checkouts sit in **detached HEAD** by default — normal git
behavior, not corruption. Consequence that actually bit once: a plain
`git pull` there fails with `You are not currently on a branch. Please
specify which branch you want to merge with.` (`pull` = fetch+merge, and
merge needs a branch to merge *into*, which detached HEAD doesn't have). The
fetch half silently still succeeds (updates `origin/main`), which makes it
easy to miss that the working tree itself never moved. Real incident: this
exact failure once let an `sbatch` job launch referencing a config file that
only existed in the fetched-but-not-checked-out commit, fast-failing 3
seconds later on "config file does not exist."

**The correct command on this checkout is `git fetch && git checkout
origin/main`** (or a specific SHA) — **never `git pull`**. Always check
`git log -1 --oneline` after any Juno-side "pull" before trusting new files
are actually there.

## 4. Threadripper — two keys discovered 2026-08-27, origin and purpose UNKNOWN

- `~/.ssh/id_ed25519_threadripper_inspect` and
  `~/.ssh/id_ed25519_threadripper_pullonly`, both created 2026-08-27 12:15 —
  **today, but not by the conversation that wrote this file**: that
  conversation never touched SSH keys before discovering these already
  present on disk.
- Public keys:
  - `ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIM3GSYUcFeG4y4Qmz6yHwXvMfp1y1Ovgyx53ut999HtA claude-code-threadripper-inspect`
  - `ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFkvuA5D1/1R/vRMYRdYGL7pOBtGB4u53y4pOkjkj8u6 claude-code-threadripper-pullonly`
- The naming convention exactly mirrors the Juno inspect/pullonly pattern (no
  `statusonly` variant exists for Threadripper, unlike Juno's 3-key set) —
  suggestive of a deliberate setup mirroring the Juno access model for a
  second machine, presumably a lab workstation or server named "Threadripper"
  (AMD Threadripper is a workstation/server CPU line). **This is an
  inference, not a confirmed fact** — do not treat it as established.
- Found via a modified-but-uncommitted `.gitignore` that already contained
  matching ignore entries with the comment "Threadripper read-only inspection
  SSH keys" — meaning whoever set this up already intended it to follow the
  same never-commit convention as the Juno keys, but never finished by
  committing that protection (now done, 2026-08-27, commit `40d39bb`) or
  documenting what the target host/user/scope actually is anywhere in the
  repo. No `~/.ssh/config` host alias exists for it, no repo doc mentions
  "threadripper" anywhere except that `.gitignore` comment, and no bash
  history entry was found referencing it.
- **Action needed**: ask the user directly what this machine is, what it's
  for, and whether the corresponding `authorized_keys`-side restriction
  (rrsync jail path for `pullonly`, inspect dispatcher for `inspect`) has
  actually been set up on that host yet. **Do not assume it's fully
  configured and working just because the local keypairs exist**, and do not
  attempt to use either key against any host without the user first
  confirming the target hostname/IP.

## 5. General lessons for setting up a restricted key on a new host

The Juno pattern (§2) is the one to replicate for any future host:

1. Dedicated, no-passphrase ed25519 keypair per capability tier (don't reuse
   one key for pull + inspect + status).
2. Forced `command=`/`restrict` in the target's `authorized_keys` —
   **append-only, never overwrite** the file.
3. For pull-only: a jailed `rrsync -ro`, pinned to a known-working version —
   verify against the target filesystem type first (WekaFS specifically
   needed the older v3.2.7 rrsync, not current master).
4. Before trusting a new key, adversarially test all four cases: arbitrary
   command rejected, legitimate operation succeeds and matches a known-good
   copy byte-for-byte, push/write rejected, path-escape (`..`) rejected.
