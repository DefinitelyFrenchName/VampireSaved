# NEXT SESSION — orientation (rewritten at the 14z-219 CLOSE, 2026-11-03)

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
idle`). It was back at the end of 14z-219, idle; its checkout `~/vampire-saved` still sits at `3e1a7091`: move it to `main`
before other work. **ERIS** (WSL2, 24 threads, 47 GB) runs the release shape; it was powering up at the 14z-219 close, its
checkout at `3e1a7091`. Neither profile sets ROMDIR (`ROMDIR=~/roms`). Work handed to either is a bundle of a COMMIT (a bare
commit-tree needs a temporary ref; delete it after); a remote script goes over `ssh <host> 'wsl -e bash -s' < script` (ERIS)
or `ssh pilot 'bash -s' < script`, never as a quoted command line (Windows' shell splits it at a pipe and mangles quotes), and
a remote `pkill -f <pattern>` matches its own shell: kill by PID, or by session (`pkill -KILL -s <sid>`), from a stdin script.

**THE SESSION CLOSE:** `docs/project/session_close.md`, run by `python3 tools/close.py`. The run of record is named in
STATE 14z-219's CLOSE section. A red tier is re-run on THE RED RUN'S results (#317).

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
1. **THE M25 FREEZE — #356 AND #345 A1b** (ruled: `DECISIONS_HISTORY.md` "Ruled 2026-11-02 (14z-218) — #356" — *"Yes, next
   session (Recommended)"* — and "Ruled 2026-11-03 (14z-219) — #345: the built A1b's timing is accepted" — **"Accept, freeze
   A1b (Recommended)"**; the maintainer at the 14z-219 close: *"let's close and freeze next session"*). Both are built and
   STAGED as `build/manifest/staged/356_345a1b.patch` — `git apply` it first; patch_notes 14z-219 lists what the freeze then
   re-freezes (the close tier's eight reds with the patch applied) and that `build/m5_wide/extract` must be re-extracted on
   purpose; the scratch builds `build/agent219/t356/mg1` (#356 alone) and `build/agent219/t345a/mg` (both) are local. Until
   M25 the two new gates, `tests/audit_don_speed_lines.sh` and `tests/audit_don_trail_nodraw.sh`, FAIL on merged-m24 at their
   precondition, by design. The freeze: the six tracks rebuilt with mark M25 (`build/don_m29`, `hui63`, `pyron48`, `m3b_merged33`; the
   stock twin and the stage-4 image measured unchanged at 14z-219), the registry rows, the four sets
   (`tools/freeze_expectation_set.py`), the byte diff, the re-point sweep, the freeze-cadence static tier, the emulator
   battery (`--freeze`, Mac + PILOT + ERIS), the concurrent-controls re-trace on PILOT (`test_emulator_runner` is OFF
   `tests/controls_concurrent.txt` since 14z-218, and the two new gates' scripts are new), the MiSTer tail,
   `release/merged-m25`, the freeze rule-checker run, the tags. **What A1b moves, each re-frozen through its own rule-checker
   run:** `tests/expected/pass_overrun.tsv` (ours' donovan_2 3094 -> none), `audit_lag_budget`'s ACCEPTED `donovan_2:3094`
   (stale: the gate says so), `tests/expected/move_parity_events.tsv` (donovan_2 events 2-25: 3-25 IDENT -> DIFF `after:2`),
   `audit_rng_forms`' rows; expect the usual relocations (placed addresses, the walker copy `0x4C23B0` -> about `0x4C39C0`, the
   renumbered tenant types +1). Then #346 (the streak) is fixed: comment it `done unshipped`; #345 and #356 likewise.
2. **#357 and #358 — attribute** (the captures read: *"Yes, the guard orbs"*, *"Yes, that figure"*; `DECISIONS_HISTORY.md`
   "Ruled 2026-11-03 (14z-219) — #357 and #358"). #357: native spawns the orbs (class 0x72 sub 0x16) from vs2 `PRG:0x090FF4`,
   a span no tenant region ports (`build/agent219/t345/CENSUS.md`, local). #358: the figure's x and pose
   (`build/agent219/t357/`, local). A fix needs the maintainer's green light.
3. **#310 — GROUP 7, in batches** (the crash-injection sweep: `tests/test_crash_sweep.sh`).
4. **#359** (cleanup traps on `EXIT INT TERM` with no `exit`; 210 scripts).
5. **Ask the maintainer for the order of the rest.** Open tickets (GitHub severity labels): bugs: #345 (freezes with M25);
   evolution: #348, #352, #354; cosmetic: #344, #346, #356, #357, #358, #360 (#356's Dark Force phase); test-integrity:
   #310, #359. Parked: #123, #124, #125, #128.

## PARKED (not open work)

- #124 (Killshread's aura palette), #123, #125, #128 (Marionette, parked again 14z-216).
- **VampireSaved-Rebuilt#1** holds what is left of #120, closed 14z-205.

## INSTRUMENT FACTS LEARNED THIS SITTING (read before the work they bear on)

- **The allocator's gap-fit ignored an assigned space** (`docs/project/gotchas.md`): a `region_space` region now skips it;
  after any placement change, diff the op set against the predecessor (relocation cascades show at once).
- **A `:d` DATA root whose sibling twin points elsewhere classes no pointer** (`docs/project/gotchas.md`): read a data root's
  report line before its build; `:dp` takes self-pointers only, checked against the third sibling.
- **`[[ref_pin]]`** pins one pointer field of a placed region (patch_index): for the placed-region-wins rule and a mapped
  target that must bypass `alloc_wrap`.
- **Whole-screen and OBJ-RAM identity are blind to a lost frame** here (the stage, the HUD and OBJ RAM change every frame);
  P1's anim node and a pixel count under rows 40-224 separate the legs, but a pixel HOLD also fires on still frames
  (`build/agent219/t345/rec/REC_lostframes.md`, local).
- **A comparison gate judging after the legs' match diverged compares two matches**: `audit_don_speed_lines` judges a dash
  group only while P1's state agrees through it.
- **The rule-checker took eight runs on one recommendation** (`2026-11-03-1591`..`-1598`): each caught a real overclaim — a
  single RNG form presented as general, a ranking that two measures order differently, an attribution resting on an
  uncontrolled diff. Scope every on-screen claim to its form, window and instrument before the first prepare.
- **Resolve, then prepare** — run `-1596` was prepared seconds before `-1595`'s resolve was accepted (an order slip).

## WHAT CLOSED THIS SITTING (14z-219)

- **Built (not frozen):** #356 (the speed-line copy) and #345 A1b (the no-draw table); gates `tests/audit_don_speed_lines.sh`,
  `tests/audit_don_trail_nodraw.sh`.
- **Ruled:** #356's look and its Dark Force phase (#360); #345 A1b and its timing; #357's and #358's captures.
- **Filed:** #360.
