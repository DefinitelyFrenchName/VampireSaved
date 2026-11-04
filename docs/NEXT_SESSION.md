# NEXT SESSION — orientation (rewritten at the 14z-220 CLOSE, 2026-11-04)

> Rewritten at every session close ([VSP-17]). ROLLOVER: the previous opener
> moves VERBATIM to the top of `NEXT_SESSION_HISTORY.md` (then `python3 tools/gen_history_index.py`
> regenerates its index, #282) — this file holds ONLY
> the live orientation, within 500 lines and 50,000 bytes (`tests/test_live_budget.sh`, #282). Session state, not knowledge: facts belong in the docs,
> status in STATE.md.

## THE SETUP, RESTATED

A plain **Opus 5.5 session at effort High** (the ruled orchestrator — STATE 'Standing rulings') on the
#172 setup:
- Every quoted figure comes from a `measurer` / `reader` spec (`docs/project/worker_spec.md`, the spec text IN the prompt, no model). The Bash tool's shell is zsh: write a revision and a path as `"${c}:path"`, never `$c:path` (zsh reads `:t` as a modifier; it cost 14z-207 a wrong hash table). An adapting worker that is not `measurer`/`reader` is called `general-purpose` with `model: opus` (the call gate refuses it without a model).
- **The rule-checker runs ONLY BEFORE AN ACTION** (a freeze, a build, an expectation, a recommendation, a ticket closure; `docs/project/rule_checker.md`), **as soon as that action's work is done, never held for the close** (ruled 2026-10-16). The pinned `rule-checker`, the prompt files pasted VERBATIM, then `record --session <the CURRENT transcript's prefix>` and `resolve` on ONE line answering every violated question by its label. Prepare the next run only after the last one is resolved; a reader whose answer runs over six lines is asked to restate it in six (14z-207, run `2026-10-24-1240`).
- **THE GREEN GUARD (#290):** a commit needs a strict GREEN whole-tier row for the staged tree; tier the STAGED tree on a snapshot (`tests/run_on_snapshot.sh --commit "$(git commit-tree "$(git write-tree)" -p HEAD -m …)"`), then commit. Base a `--confirm` on a recent run of record.
- **WHEN TO COMMIT (ruled 2026-10-17):** only at a ticket closure, a freeze or release, work handed to PILOT or ERIS, or the close. Before EVERY tier, regenerate the generated files and run the bookkeeping gates the change touches IN A CLEAN CHECKOUT of the staged tree (`git worktree add --detach` of a commit-tree object): the main tree holds #229's untracked gates, which break the generators.
- **Never edit a script while it runs** ([MJC-54]); the emulator runner reports a tracked file changed during its run.

Say so at the opener. Never spawn any agent at `max`. A recommendation leans only on the maintainer's OWN words.
**PILOT** (6 vCPU, 47 GB, Ubuntu 24.04) carries xdelta3, Node, `strace`, podman and the GNOME session the desktop gate
drives (the maintainer logs in; it locks after 5 min idle, and a desktop run goes under `gnome-session-inhibit --inhibit
idle`). Idle at the 14z-220 close; its checkout `~/vampire-saved` sits at snapshot S6 `4617659f` (detached): move it to `main`
before other work. **ERIS** (WSL2, 24 threads, 47 GB) runs the release shape; idle at the 14z-220 close, its checkout at
snapshot S7 `37150456` (detached): move it to `main` first. Neither profile sets ROMDIR (`ROMDIR=~/roms`). Work handed to either is a bundle of a COMMIT (a bare
commit-tree needs a temporary ref; delete it after); a remote script goes over `ssh <host> 'wsl -e bash -s' < script` (ERIS)
or `ssh pilot 'bash -s' < script`, never as a quoted command line (Windows' shell splits it at a pipe and mangles quotes), and
a remote `pkill -f <pattern>` matches its own shell: kill by PID, or by session (`pkill -KILL -s <sid>`), from a stdin script.

**THE SESSION CLOSE:** `docs/project/session_close.md`, run by `python3 tools/close.py`. The run of record is named in
STATE 14z-220's CLOSE section. A red tier is re-run on THE RED RUN'S results (#317).

**THE EMULATOR RUNNER SINCE 14z-210 (#321, `docs/project/operations.md`):**
- **Concurrent controls:** a gate on `tests/controls_concurrent_emu.txt` (from a PILOT write trace) runs each
  control as a pool job of its own; a listed gate whose script changed must be re-traced on PILOT before it stays listed
  (`tests/test_controls_concurrent.sh`), and the static list `tests/controls_concurrent.txt` the same.
- **`--order <an earlier run>/results.tsv`** starts a pooled lane longest first.
- **Temp files on disk:** unless the caller set `TMPDIR`, a run's gates write under `build/tmp/emu_<stamp>.<pid>/`
  (removed at the end); the run refuses to start with under 10 GB free there (`VS_TMP_MIN_GB`).
- **Three verdict holes closed:** a control mode stopped by its host (full disk, failed mktemp) is DIED, never HONOURED;
  a selected gate, or a passing gate's declared control, with no row is a FAIL ("LOST"); `tests/lib/measures.sh` no longer
  shares a scratch file across pooled subshells. **Before trusting a runner change, run its gate on PILOT as well as the
  Mac** — the `$$` race showed only on Linux.
- **ERIS's release shape:** `--scope all --strict --controls --jobs 6 --skip test_mame_parity [--reuse <freeze run>]
  --order <the previous release's results>` (14z-208b: about 2 h 12 min at `--jobs 8` with reuse; `--jobs 8` pushed one
  MAME control past half its cap, #321). A write trace may be SPLIT across Linux machines, each running nothing else
  (the maintainer, 14z-216, DECISIONS_HISTORY).
- **A fresh run gets a fresh `--log` directory** (14z-213, `docs/project/gotchas.md`): the runner keeps an existing
  `results.tsv` and `commit.txt`, so a reused directory mixes the old run's rows and commit of record with the new.
- **The registry check reads 240 of 240** since #340 (14z-213): a gate that reads `tests/ci_emulator.tsv` counts as
  emulator-tier, so `audit_pool_drop` is no longer a DEAD ROW and a strict run can read GREEN again.
- **A PILOT write trace of an emulator gate needs `CMDS=`** (gate, expanded registry arguments, timeout; `tools/trace_controls.sh`),
  and the clone's build dirs that hold tracked files (`build/don_m5`) topped up with `cp -Rn`, never linked into.

**THE STATIC TIER:** unchanged since 14z-209 (#312, #315, #324, #304; `tests/lib/static_pool.py`). A strict run fails on a
file it leaves behind outside `build/`, and `build/`'s top-level directories are classed in `tests/expected/build_dirs.tsv`
(a new one fails `test_build_dirs`; `build/tmp/` was added as scratch this sitting).

## START HERE

0. **AT THE OPENER, RUN `python3 tools/agent/sweep.py`.**
2. **#362** (`test_crash_sweep` writes its perturbed copies into the live `tests/`; `test_gate_descriptions`' modes do not refuse
   a vanished target): both gates are OFF `tests/controls_concurrent.txt` until it is fixed and they are re-traced on PILOT.
3. **THE M25 RELEASE, WHEN THE MAINTAINER ASKS FOR IT** (M25 frozen 14z-220 at `91bde83b`, tags `freeze/donovan-m29`,
   `freeze/huitzil-m36`, `freeze/pyron-m30`, `freeze/merged-m25`; `release/merged-m25` packaged). #345, #346 and #356 carry
   done-awaiting-release comments and close with that release.
4. **#357 and #358 — attribute** (the captures read: *"Yes, the guard orbs"*, *"Yes, that figure"*; `DECISIONS_HISTORY.md`
   "Ruled 2026-11-03 (14z-219) — #357 and #358"). #357: native spawns the orbs (class 0x72 sub 0x16) from vs2 `PRG:0x090FF4`,
   a span no tenant region ports (`build/agent219/t345/CENSUS.md`, local). #358: the figure's x and pose
   (`build/agent219/t357/`, local). A fix needs the maintainer's green light.
5. **#310 — GROUP 7, in batches** (the crash-injection sweep: `tests/test_crash_sweep.sh`).
6. **#359** (cleanup traps on `EXIT INT TERM` with no `exit`; 210 scripts).
7. **Ask the maintainer for the order of the rest.** Open tickets (GitHub severity labels): bugs: #345 (frozen, awaits the
   release), #362; evolution: #348, #352, #354; cosmetic: #344, #346, #356 (both frozen, await the release), #357, #358,
   #360 (#356's Dark Force phase); test-integrity: #310, #359. Parked: #123, #124, #125, #128.

## PARKED (not open work)

- #124 (Killshread's aura palette), #123, #125, #128 (Marionette, parked again 14z-216).
- **VampireSaved-Rebuilt#1** holds what is left of #120, closed 14z-205.

## INSTRUMENT FACTS LEARNED THIS SITTING (read before the work they bear on)

- **Run the static freeze tier on the staged tree BEFORE preparing a freeze's re-freeze checks** (`docs/project/gotchas.md`,
  "A FREEZE'S STATIC EXPECTATIONS ARE NOT ONLY THE ONES THE BATTERY NAMES"): the M25 relocation moved five static expectations
  the battery never named, found only by the S6 tier.
- **Let `tools/setup_jtcores.sh` write the mirrored fork patch** once its name is in `PATCH_NAMES`: a plain `format-patch`
  copy carries a signature trailer `test_jtcores_twin` rejects.
- **A gate whose FOLLOWS names `docs/project/gotchas.md`** (`test_don_sound`) goes stale on any new gotcha: add a freeze's
  gotchas before the emulator rows are run, or re-run that gate's row.
- **`--confirm` is refused at freeze cadence** (`tests/run_all_static.sh`): a freeze tier runs in full; a red in it is
  confirmed by a session-cadence `--strict --confirm` on the freeze run's results.
- **The staleness audit judges against the snapshot's HEAD**: run it through `tests/run_on_snapshot.sh` on the commit you
  will make, with every remote run directory (ERIS's and PILOT's `build/emu_*`) copied into the Mac's `build/` first.
- **A byte classifier that silently skips a line form is no classifier**: count what it classed against the source's own
  total, and plant a dropped line (`build/agent220/m25/edit_classes2.py`, local).
- **Quote a ruling's own scope**: the 14z-209 written-resolution ruling covers #229's freezes, and 14z-163's option C covers
  Q3 and Q4; neither closes a Q1 finding in writing — re-check it afresh.

## WHAT CLOSED THIS SITTING (14z-220)

- **Frozen:** M25 at `91bde83b` (#356 and #345 A1b), freeze rule-checker run `2026-11-04-1631` OK; the static freeze tier on
  that tree PASS 237 with its one red confirmed GREEN; tags re-cut; the jtcores fork commit `930818f5` pushed.
- **Commented done-awaiting-release:** #345, #346, #356.
- **Filed:** #361, #362.
