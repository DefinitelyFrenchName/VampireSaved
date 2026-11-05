# NEXT SESSION — orientation (rewritten at the 14z-221 CLOSE, 2026-11-05)

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
idle`). Idle at the 14z-221 close; its checkout `~/vampire-saved` moved to `main` at the close (it had held scratch commit
`aefcb1a7`, #310 group 7): check it is on `main` before other work. **ERIS** (WSL2, 24 threads, 47 GB) runs the release shape;
UNREACHABLE all of 14z-221 (ssh timed out), its checkout last at
snapshot S7 `37150456` (detached): move it to `main` first. Neither profile sets ROMDIR (`ROMDIR=~/roms`). Work handed to either is a bundle of a COMMIT (a bare
commit-tree needs a temporary ref; delete it after); a remote script goes over `ssh <host> 'wsl -e bash -s' < script` (ERIS)
or `ssh pilot 'bash -s' < script`, never as a quoted command line (Windows' shell splits it at a pipe and mangles quotes), and
a remote `pkill -f <pattern>` matches its own shell: kill by PID, or by session (`pkill -KILL -s <sid>`), from a stdin script.

**THE SESSION CLOSE:** `docs/project/session_close.md`, run by `python3 tools/close.py`. The run of record is named in
STATE 14z-221's CLOSE section. A red tier is re-run on THE RED RUN'S results (#317).

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
3. **THE M25 RELEASE, WHEN THE MAINTAINER ASKS FOR IT** (M25 frozen 14z-220 at `91bde83b`, tags `freeze/donovan-m29`,
   `freeze/huitzil-m36`, `freeze/pyron-m30`, `freeze/merged-m25`; `release/merged-m25` packaged). #345, #346 and #356 carry
   done-awaiting-release comments and close with that release.
4. **#357 — the maintainer's call (put 14z-221 after rule-checker run 2026-11-04-1637 OK, the attribution on the issue):**
   port the type-0x13 guard-orb watcher (row 0x13 of the `$FFD400` walker, Huitzil's row-16 precedent) or leave it open;
   `docs/game/engine_internals.md` «Donovan's guard orbs». **#358 — the maintainer's read of the beam sheets**
   (`build/agent221/t358/sheets/358_beam_3row_p1.png`, `_p2.png`, `358_zoom_corner.png`, local; STATE 14z-221 (4)): the
   intro difference is the entrance draw (the maintainer: *"the captures do represent two of these intros"*); from the
   beam to f2839 native draws Cecil in front of Phobos's legs, ours behind, even on the same entrance. Its mechanism is not
   measured. A fix for either needs the maintainer's word ([VSP-10]).
5. **#310 — GROUP 7, BATCH 2** (batch 1, 25 modes, landed 14z-221: `tests/test_dead_leg_unjudged.sh` and its table, STATE
   14z-221 (5)). Next: `test_dualtrack` (its leg is FBNeo, so the proof needs a dead FBNeo, not `MAME_BIN=/usr/bin/false`),
   the six held out before the baseline (four MiSTer gates, which need verilator, though `test_mister_obj_oracle` and
   `test_mister_tenant_oracle` have a MAME leg too; `test_release_roundtrip`; `audit_stock_emulator_stall`, whose stock
   binary is `MAME_REF_BIN`), the four baseline rows that DIED on a traceback (`audit_pyron_ring`, `audit_tech_roll`, `test_down_flash_mechanism`,
   `test_random_select_tenants`), `audit_column_flash`'s header-only mode (REFUSED), then the group's gates with more than one
   PRESENT mode (`build/agent215/t310/census57/group7.tsv`, `build/agent221/t310g7/base/classes.tsv`, local). Each new row
   joins the table and is proven by the same gate.
6. **#359** (cleanup traps on `EXIT INT TERM` with no `exit`; 210 scripts).
7. **Ask the maintainer for the order of the rest.** Open tickets (GitHub severity labels): bugs: #345 (frozen, awaits the
   release); evolution: #348, #352, #354; cosmetic: #344, #346, #356 (both frozen, await the release), #357, #358,
   #360 (#356's Dark Force phase); test-integrity: #310, #359. Parked: #123, #124, #125, #128.

## PARKED (not open work)

- #124 (Killshread's aura palette), #123, #125, #128 (Marionette, parked again 14z-216).
- **VampireSaved-Rebuilt#1** holds what is left of #120, closed 14z-205.

## INSTRUMENT FACTS LEARNED THIS SITTING (read before the work they bear on)

- **A dead emulator is a cheap proof of a control's liveness handling**: `MAME_BIN=/usr/bin/false` with `CONTROL=<mode>`,
  classified by `tests/lib/classify.sh`, must read UNJUDGED; `tests/test_dead_leg_unjudged.sh` holds the batch's rows. It
  kills only legs launched through `MAME_BIN`: FBNeo (`test_dualtrack`), a second stock MAME at `MAME_REF_BIN` and the
  Verilator legs need their own dead instrument.
- **A control's FAIL proves nothing until its log shows the plant's own effect** (`docs/project/gotchas.md`, "A PLANTED
  COPY THAT CRASHES FIRES ITS CONTROL FOR THE WRONG REASON"): a plant that crashes reads HONOURED when the crash is quoted
  inside the gate's own FAIL line; have the gate check the effect and print FIRED or DEAD itself.
- **A stripped-copy control NEUTERS its tagged lines, never deletes them**: a tag marks a line, and the line may carry the
  gate's own command.
- **A verdict over a glob must know how many entries it expects** (`audit_dispatch_census` passed on zero legs).
- **An apostrophe inside `${VAR:?message}` opens a quote** (`docs/platform/gotchas.md`): bisect a `sh -n` error with
  `head -N | sh -n`.
- **PILOT is reached with a bundle on a commit it already has** (`git bundle create … <scratch ref> ^<a commit PILOT has>`), and a
  long run is launched with `setsid nohup timeout` from a script, watched by an until-loop on a DONE marker.

## WHAT CLOSED THIS SITTING (14z-221)

- **Closed done:** #361 (rule-checker run `2026-11-04-1633`), #362 (run `-1640`; committed `d3e8810d`).
- **Put to the maintainer:** #357 (port the guard-orb watcher or leave it; run `-1637`), #358 (the beam draw-order sheets).
- **#310 group 7 batch 1:** 25 modes UNJUDGED on a dead leg, `tests/test_dead_leg_unjudged.sh`, the table frozen on run
  `2026-11-05-1644`; progress comment posted on #310.
