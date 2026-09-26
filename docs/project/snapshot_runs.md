# Snapshot runs — a tier run immune to the working tree, at a named commit

> **STATUS: REFERENCE (opened 14z-183b, GitHub #153).** How `tests/run_on_snapshot.sh` runs a
> test tier on a snapshot, what it records, and what is and is not proved about it. Ruled
> 2026-09-26: `DECISIONS_HISTORY.md` "Ruled 2026-09-26 (14z-183b) — #153".

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

0. **The runner itself.** `sh` reads a script as it runs, so the runner first re-executes from a
   private copy of itself: an edit to `tests/run_on_snapshot.sh` in the tree during a run cannot reach
   the run. Paid 14z-183b: the first real run's tier finished (PASS 177 / FAIL 1) and then the runner
   died at a syntax error, its header having been edited under it.
1. **The commit's files.** A plain local clone of the tree (its own object store: hardlinked,
   immutable object files — never `--shared`, whose borrowed objects a gc in the tree could remove),
   checked out at `<commit>` (default `HEAD`), and verified whole: the commit's tracked-file count,
   and no tracked change outside the submodules.
2. **Everything else it reads, snapshotted at the start by copy-on-write** (`cp -Rc`, APFS
   clonefile; about 9 s for all of `build/`, 62,298 files, measured 14z-183b; no disk space until a
   file diverges): all of `build/` with the commit's own tracked `build/` files restored over it;
   each initialised submodule's checkout with its `.git/modules` dir (refused unless its `HEAD` is
   the commit's gitlink; the applied patches travel with it and `test_fbneo_tree_integrity` checks
   them against `emu/fbneo-patches/` inside the run); the siblings the gates read — `../community`
   and the bbh checkout (`$BBH_HOME`, else `../../blackbox-harness`), exported to the run as
   `BBH_HOME`. `ROMDIR` is read in place and checksum-verified by `tools/audit_roms.py` at start and
   at end.
3. **Where.** `~/.cache/vampire-saved/snapshots/<commit>-<stamp>` (`SNAPSHOT_ROOT` overrides; a
   temporary directory is refused — the macOS reaper hollowed this project's scratch clones twice,
   `docs/platform/gotchas.md`). Removed after the record is written unless `--keep`.
4. **The record**, `build/snapshot_runs/<stamp>-<commit>/` in the working tree: `record.txt` (the
   commit, the runner and its arguments, its exit, the submodule and bbh commits, the ROMDIR
   verdicts), `tree_porcelain_start.txt` (what the run did NOT test: the tree's uncommitted changes),
   `listing.tsv` (every snapshotted file outside git: path, size, mtime), `fingerprints.tsv` (every
   `build/*/rompath` through the commit's `tools/build_fingerprint.py`), `runner.log`. The record is
   a listing plus fingerprints by ruling; full content hashes were not chosen.

A run costs about 50 s of setup before the runner starts (the clone, the snapshot, the listing
and 76 fingerprints; measured 14z-183b on this Mac).

## What is proved, and by what

- **Immunity:** `tests/test_run_on_snapshot.sh` (ci_portable) pauses a probe under the runner in a
  throwaway world, edits and commits a tracked file, rewrites a `build/` output and a tracked `build/`
  file, a submodule file and both siblings, and truncates the runner's own file, then releases it: all six readings must be unchanged, the
  record must be complete,
  and the record's commit must be the one taken before the perturbation. The same perturbation must
  reach the same probe run in place (the positive leg). Four controls — `build/` linked instead of
  snapshotted, the command run in the working tree, `BBH_HOME` left on the working checkout, the
  runner run from its own file — must each let the perturbation through and turn the gate red.
- **The census it rests on (14z-183b, `build/agent183b/plan_153.md`):** in a clone with nothing
  supplied, the freeze-cadence static tier read PASS 128 / SKIP 30 / FAIL 20; every one of the 50 read
  an input git does not carry, three of them named in data or beside the tree rather than in the gate's
  text — which is why the whole of `build/` is snapshotted, not a list. With those inputs supplied,
  the real runner in the clone read PASS 177 / FAIL 1, the one FAIL being a verdict the working tree
  gives too.

## What is not

- **The emulator tier** is a later slice: its inputs under `~/.cache/vampire-saved` (MAME, FBNeo,
  Verilator builds) have not been probed.
- **A commit other than `HEAD`** is refused whenever a submodule's gitlink differs from the tree's
  checkout; building the submodules at another commit is not implemented.
- **Inputs outside `build/`, the submodules and the two siblings** are not snapshotted; none showed
  in the census, which ran without `--exec-controls all`.
- **A harness that re-implements the runner is not the runner.** A per-gate script used in the census
  omitted the `VS_CADENCE` the runner exports and read one gate differently; only the runner itself
  decides.
