# Snapshot runs — a tier run immune to the working tree, at a named commit

> **STATUS: REFERENCE (opened 14z-183b, GitHub #153; the emulator tier's inputs 14z-184, GitHub
> #181).** How `tests/run_on_snapshot.sh` runs a test tier on a snapshot, what it records, and what
> is and is not proved about it. Ruled 2026-09-26: `DECISIONS_HISTORY.md` "Ruled 2026-09-26
> (14z-183b) — #153"; the emulator tier's inputs ruled 2026-09-27: "Ruled 2026-09-27 (14z-184) — #181".

## Why

The maintainer's principle (2026-09-26, verbatim): *"being immune from any change in the tree while
tests, especially long tests, run. Also, know against which commit we ran the tests, just in case an
issue resolution could benefit from it."* A tier run in the working tree reads whatever the tree
holds at each moment, so a long run beside other work tests a mixture, and its log does not say
which commit it tested. The ticket's origin, #148's lever B, ruled 2026-09-17: *"the gain for session
is marginal but the gain for freeze or release is massive not so much for speed but for integrity
and traceability"* — so session cadence stays in the working tree.

## What a run is

    ROMDIR=... tests/run_on_snapshot.sh [--commit <rev>] [--keep] -- tests/run_all_static.sh --strict --cadence freeze
    ROMDIR=... tests/run_on_snapshot.sh -- tests/run_all_emulator.sh --freeze --lane all --strict

0. **The runner itself.** `sh` reads a script as it runs, so the runner first re-executes from a
   private copy of itself: an edit to `tests/run_on_snapshot.sh` in the tree during a run cannot reach
   the run. Paid 14z-183b: the first real run's tier finished (PASS 177 / FAIL 1) and then the runner
   died at a syntax error, its header having been edited under it. **A run started inside another
   run's snapshot copies itself too:** the copy is named in `RUN_ON_SNAPSHOT_SELF`, which a nested run
   inherits, so the runner honours it only when the running script IS that copy (`$0`). Paid 14z-199:
   the close tier on a snapshot ran `tests/test_run_on_snapshot.sh`, whose runner legs inherited the
   outer run's variable, skipped their own copies and died when their files were truncated (three
   controls DEAD, the gate red); a nested leg would also have taken the outer run's repo as its own
   and deleted the outer run's copy at its exit. The gate's section 2b now starts a leg under an
   outer run's variables (control `inherited-self`), and the gate clears them for its other legs.
1. **The commit's files.** A plain local clone of the tree (its own object store: hardlinked,
   immutable object files — never `--shared`, whose borrowed objects a gc in the tree could remove),
   checked out at `<commit>` (default `HEAD`), and verified whole: the commit's tracked-file count,
   and no tracked change outside the submodules. **Every tracked file then takes the time of the
   commit that last changed it** (#181, ruled "Last-commit time"): a checkout stamps every file
   "now", and `test_wide_profile` compares the tracked harness patch's mtime with the reference
   FBNeo binary's, so it refused in every census run of 14z-184; the commit time is the same for
   every snapshot of one commit. Submodule checkouts keep the working tree's times (they are
   copied, not checked out).
2. **Everything else it reads, snapshotted at the start by copy-on-write** (`cp -Rc`, APFS
   clonefile; about 9 s for all of `build/`, 62,298 files, measured 14z-183b; no disk space until a
   file diverges): `build/` with the commit's own tracked `build/` files restored over it, **but its
   scratch classes since #304 item 2** (14z-208; ruled 2026-10-23 "Adopt all four (Recommended)"): every
   top-level directory the COMMIT's `tools/build_dirs.py` classes `scratch` in its `tests/expected/build_dirs.tsv`
   (session and lane work dirs, the rule-checker's staging, the static and snapshot run records, the proof sheets)
   is left out, generated from that list and never written a second time, and the record's `build` line names
   what was left out. No gate of either tier reads an input under one (fork U's census, `build/agent208/U/REPORT.md`,
   local: 118 code lines in 38 files name them, every one a comment, a synthetic fixture, a runner's own write or a
   tool's own staging), and at the 14z-207 close they were 5,356,128 of the snapshot's 5,415,283 `build/` files
   (31.81 of 42.97 GB) and that snapshot's setup took 1,051 s. Measured with and without (fork U2,
   `build/agent208/U2/REPORT.md`, local; the same `--confirm` base): 5,308,810 files listed outside git against 59,213,
   setup about 1,112 s against 95 s, the whole run 2,050 s against 501 s, and no verdict differing. A runner argument naming a file under a left-out
   directory by a RELATIVE path (a `--confirm` base such as `build/agent207/close/tier_results.tsv`) is copied in on
   its own (ruled 2026-10-24, "Copy that file in (Recommended)"); an absolute one is read where it points, as it
   always was. A commit without `tools/build_dirs.py` copies `build/` whole but `snapshot_runs`, as before;
   each initialised submodule's checkout with its `.git/modules` dir (refused unless its `HEAD` is
   the commit's gitlink; the applied patches travel with it and `test_fbneo_tree_integrity` checks
   them against `emu/fbneo-patches/` inside the run); the sibling the gates read, `../community`
   (until 14z-197 the bbh checkout too, exported as `BBH_HOME` for `test_bbh_fidelity`; removed with
   that gate, maintainer-ruled 2026-10-10: bbh is its own project). `ROMDIR` is read in place and checksum-verified by `tools/audit_roms.py` at start and
   at end. The git-IGNORED inputs inside the tree are copied file by file too: `release/emulators/`
   (the prebuilt release binaries `test_release_binaries` and `test_readme_recording` read), which a
   clone never carries.
2b. **The emulator tier's inputs outside the tree** (`--emulator-inputs`, implied when the runner is
   `tests/run_all_emulator.sh`; #181, ruled "Copy the cache" and "Private copies"). The instrument
   binaries live under `~/.cache/vampire-saved` (the WIDE MAME `mame/cps2`, the reference MAME
   `mame-ref/cps2`, the reference FBNeo `fbneo_ref`), and gates name them in at least three ways —
   a variable's default, a literal `$HOME/...` path, a fallback — so the whole cache (minus
   `snapshots/`) is copied, and the runner runs under a **private HOME** whose `.cache/vampire-saved`
   is that copy and whose every other entry (and every other entry of `.cache`) is a symlink to the
   real HOME's, so the Python user site and the rest resolve as before. The three binaries are
   hashed in the LIVE cache at the start and the end: the copy must equal the start, and a change in
   the live cache during the run turns the run's exit to 2 — a gate that bypassed the copy cannot
   then be ruled out. The Verilator scratch clones (`JTSIM_SCRATCH`, default
   `$TMPDIR/vampire-saved-jtsim`, and its `-slotN` / `-b` siblings, which every simulation WRITES)
   are copied into the snapshot and the run pointed there, so it cannot collide with a simulation in
   the tree; at the end the record counts, per copy, the files that still name the original's path
   (Verilator's dependency files carry absolute paths; a run that rebuilt leaves none).
3. **Where.** `~/.cache/vampire-saved/snapshots/<commit>-<stamp>` (`SNAPSHOT_ROOT` overrides; a
   temporary directory is refused — the macOS reaper hollowed this project's scratch clones twice,
   `docs/platform/gotchas.md`). Removed after the record is written unless `--keep`.
4. **The run of record comes home** (#181, ruled "Copied back"): every `build/emu_*` directory the
   run created inside the clone is copied into the working tree's `build/`, where
   `tools/audit_emulator_staleness.py` reads the newest one; a name already taken there is never
   overwritten (the run's exit turns to 2). Its `commit.txt` names the snapshot's commit.
   Every `build/static_runs/*` record the run created comes home the same way (#276, 14z-205), so
   `tools/session_metrics.py` counts a snapshot tier with the sitting's other tier runs; a name already taken is said
   and skipped, and the exit is unchanged, since the record is the dashboard's, not the run of record. The static
   runner copies its results into that record even when `STATIC_RESULTS_OUT` sends them elsewhere.
5. **The record**, `build/snapshot_runs/<stamp>-<commit>/` in the working tree: `record.txt` (the
   commit, the runner and its arguments, its exit, the submodule commits, the ROMDIR
   verdicts), `tree_porcelain_start.txt` (what the run did NOT test: the tree's uncommitted changes),
   `listing.tsv` (every snapshotted file outside git: path, size, mtime — with `--emulator-inputs` the
   copied cache and scratch clones too), `fingerprints.tsv` (every `build/*/rompath` through the
   commit's `tools/build_fingerprint.py`), `runner.log`; with `--emulator-inputs` also
   `instruments_start.tsv` / `instruments_copy.tsv` / `instruments_end.tsv` and `jtsim_copies.tsv`. The record is
   a listing plus fingerprints by ruling; full content hashes were not chosen. **A static tier's
   `results.tsv` is NOT in it:** `tests/run_all_static.sh` writes it under the clone's
   `build/static_runs/`, which the clone's removal deletes, though the tier prints that path as the
   one to `--confirm` a red from (paid 14z-199). Give the tier `STATIC_RESULTS_OUT=<absolute path in
   the working tree>` — the environment reaches the runner — to keep it. The runner keeps that path to
   itself (`RESULTS-OUT-PRIVATE`, 14z-199): the first tier given one handed it to every gate, and a
   gate that starts the runner in a synthetic repo truncated the file mid-tier, so the tier ended
   appending its rows under another run's header (`tests/test_static_runner.sh` section 12c, control
   `results-inherited`).
   **Since #290 (14z-203) the results file is kept in the record by default** (`<record>/results.tsv`, unless
   `STATIC_RESULTS_OUT` names another path), because the green guard's index row points at it.
6. **The green guard's row (#290, ruled 2026-10-16).** The runner is handed the WORKING repository's
   index, `.git/green_index.tsv` (`STATIC_GREEN_INDEX`, private to the runner like the results path) and appends one
   row there: the tree it tested, its verdict and its scope. The git hooks read that row
   (`tools/git-hooks/green_guard.py`). A snapshot may be taken of a commit that no branch names: the close tiers a
   commit object of the staged index (`git commit-tree "$(git write-tree)" -p HEAD -m …`), and the local clone
   holds it (measured 2026-10-16: "clone whole: 16818 tracked files" at `8986de91`, a commit of the staged tree).
   **The index lives under `.git/`, never `build/`** (14z-203): under `build/` it matched `tools/static_confirm.py`'s R6
   template `build/$b`, and since every run rewrites it, every `--confirm` staled gates on it. **What the hooks see**
   (measured on git 2.54.0, 2026-10-16): `pre-commit` fires on a plain commit and on `--amend`, and not on a clean merge,
   cherry-pick, rebase, revert or `--no-verify`; `pre-push` checks each pushed tip's tree only. The session's own
   `--no-verify`, `commit -n` and `core.hooksPath` changes are refused by `tools/agent/hooks/pre_bash.py`
   (`agentlib.hook_bypass_reason`, installed by the maintainer 2026-10-17; `tests/test_agent_hooks.sh`, control
   `blind-bypass`); the maintainer's own `!` command is the override.

A run costs about 27 s of setup before the runner starts, and about 12 s after it (the end checks and removing the
snapshot). **Since #317 (14z-208)** the setup overlaps its slow parts: the working tree's start porcelain runs while the
clone and `build/` are copied (and is waited for before the first submodule git dir is copied, since a status rewrites
those dirs' index files); `build/` is classed in the foreground and copied in the background while the submodules are,
and is waited for, its exit checked, before anything reads it; each submodule's changed-path count (a status, which in
a fresh copy re-reads every file — `emu/mame`, about 8.5 s) runs beside the steps after it and is said before the run;
the clone's two tracked-change checks pass `-uno --ignore-submodules=all` (they dropped the submodule and untracked
lines anyway, and the submodules' scan was the whole of their cost); and the fingerprints run eight at a time,
assembled in the glob's order. Measured at `1e24cae1` with runner `true`, three runs each, nothing else snapshotting
(fork S2, `build/agent208/S2/REPORT.md`, local): 64.3 to 70.2 s from the record's first line to the runner (74 to 80 s
with the start porcelain before it) against 26.9 to 27.9 s; the fingerprints (91 build dirs) 19.1 to 19.6 s against
3.6 to 3.8 s, byte-identical; the listing identical in path and size (its symlink rows carry the copy's time, which
differs between any two runs). **A stale `index.lock` in a submodule's git dir** (found 2026-10-24 in
`.git/modules/emu/mame/`, 0 bytes, dated 2026-09-30, no git process holding it) stops every status from saving its
refreshed index, so each status in the working tree and in every snapshot re-reads all 31,279 `emu/mame` files (6.3 to
8.9 s measured; 0.11 s once the lock was removed in a snapshot) — the runner copies the lock with the git dir.

## What is proved, and by what

- **Immunity:** `tests/test_run_on_snapshot.sh` (ci_portable) pauses a probe under the runner in a
  throwaway world, edits and commits a tracked file, rewrites a `build/` output and a tracked `build/`
  file, a submodule file and both siblings, and truncates the runner's own file, then releases it: all six readings must be unchanged, the
  record must be complete,
  and the record's commit must be the one taken before the perturbation. The same perturbation must
  reach the same probe run in place (the positive leg). Four controls — `build/` linked instead of
  snapshotted, the command run in the working tree, `BBH_HOME` left on the working checkout (control
  `shared-bbh`, removed 14z-197 with the bbh copy, which leaves the probe EIGHT readings), the
  runner run from its own file — must each let the perturbation through and turn the gate red.
  **Since 14z-184 (#181)** the probe runs with `--emulator-inputs` and reads three more inputs — a
  file of a fake `~/.cache/vampire-saved`, a scratch clone, the fake instrument `fbneo_ref` — that
  are perturbed too (nine readings in all, every one of which changes in place); the snapshot run
  must also read `t.txt` at its commit's FIXED time (2021-01-01, written 2020), reach an entry of the
  real HOME through the private one, and return its `build/emu_probe` to the working tree; section 3
  changes the instrument in the live cache mid-run and requires the run to read the copy AND exit 2
  with its AFTER line. Five more controls — the caller's HOME kept, `JTSIM_SCRATCH` left on the
  caller's clone, S1b skipped, the copy-back skipped, the end-of-run instrument comparison skipped —
  each turn the gate red for their own reason. **Since #304 item 2 (14z-208)** section 5 builds a world whose
  commit carries this tree's `tools/build_dirs.py` and class list, plants a file under an instance of every
  `scratch` pattern the list holds, under an input-classed dir, an unclassed dir and at `build/`'s top, and passes
  a relative argument under a scratch dir: the snapshot must hold no scratch plant, every other plant and the
  argument's file; controls `copy-all-build` (the pre-#304 copy) and `no-arg-copy` turn it red. A control counts only when the perturbed copy RAN
  (the `no-instrument-check` copy first "fired" by crashing on a syntax error its own edit made,
  14z-184 — `docs/project/gotchas.md`).
- **The emulator-tier census it rests on (14z-184, `build/agent184/c181/plan_181.md`):** four snapshot
  runs of the prereq and fbneo lanes (26 gates each): with an EMPTY HOME 16 did not pass, every one
  on a missing cache binary; with a HOME holding ONLY the three binaries 15 of those 16 passed and
  the 16th failed only on the mtime refusal S1b removes; with the real HOME, and with the private-HOME
  prototype, PASS 25 / FAIL 1 on that same refusal; the live cache was unchanged across all four.
- **The census it rests on (14z-183b, `build/agent183b/plan_153.md`):** in a clone with nothing
  supplied, the freeze-cadence static tier read PASS 128 / SKIP 30 / FAIL 20; every one of the 50 read
  an input git does not carry, three of them named in data or beside the tree rather than in the gate's
  text — which is why the whole of `build/` is snapshotted, not a list (since #304 item 2 its scratch classes
  are left out: a class list the census gate `test_build_dirs` holds, not a list of inputs). With those inputs supplied,
  the real runner in the clone read PASS 177 / FAIL 1, the one FAIL being a verdict the working tree
  gives too.

## What is not

- **The proof run (14z-184, 2026-09-27):** the whole emulator tier on a snapshot of `454a1e19` —
  `tests/run_on_snapshot.sh -- tests/run_all_emulator.sh --freeze --lane all --scope all --strict
  --jobs 4 --keep-going`, 3 h 25 min wall — read PASS 196 / SKIP 1 / FAIL 1: the SKIP the approved
  `audit_mask_window_ff42a2`, the FAIL `audit_x2b7ef4_reach_m18`, an out-of-scope gate that fails
  the same way in the working tree (its frozen rows predate a 14z-181 change to the `pyron_3` rig; the gate was retired the same session, maintainer-ruled 2026-09-27).
  `test_wide_profile` passed on a snapshot for the first time (S1b), the live instruments were
  unchanged, the run of record came back as `build/emu_sweep_20260927_065635` stamped `454a1e19`, and
  none of the six copied scratch clones still named its original after the run (the record,
  `build/snapshot_runs/20260927T065450-454a1e19c98b/`, and `build/agent184/proof181_outer.log`).
- **An incremental re-snapshot after a red** (#317's change 2) is measured and not built: a pristine copy of the
  snapshot, kept to re-clone from, cost 16.4 to 18.1 s to make and 8.3 to 11.0 s to remove, on every run, green or
  red, against a whole setup of about 27 s, so a re-run after a red could save at most about 10 s while every run
  paid about 25 s more. A re-run after a red tier is cut instead by its BASE: at a close or any commit tier, re-run it with
  `--confirm <the RED run's results.tsv>` — on a snapshot that is `<record>/results.tsv`, or the `STATIC_RESULTS_OUT`
  the red run named, copied aside first when the re-run writes the same path — so it re-runs what was not PASS there
  or changed since and carries the rest; the close driver does both (`docs/project/session_close.md`, the `tier` step).
- **Host tools** — Homebrew's SDL libraries the MAME binaries link, Verilator, python3, `timeout` —
  are neither snapshotted nor recorded.
- **A commit other than `HEAD`** is refused whenever a submodule's gitlink differs from the tree's
  checkout; building the submodules at another commit is not implemented.
- **Inputs outside `build/`, the submodules and the two siblings** are not snapshotted; none showed
  in the census, which ran without `--exec-controls all`.
- **A harness that re-implements the runner is not the runner.** A per-gate script used in the census
  omitted the `VS_CADENCE` the runner exports and read one gate differently; only the runner itself
  decides.
