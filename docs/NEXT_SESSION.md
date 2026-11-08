# NEXT SESSION — orientation (rewritten at the 14z-223 CLOSE, 2026-11-08)

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
- **WHEN TO COMMIT (ruled 2026-10-17):** only at a ticket closure, a freeze or release, work handed to PILOT or ERIS, or the close. Before EVERY tier, regenerate the generated files and run the bookkeeping gates the change touches — THE WHOLE LIST in `docs/project/working_methods.md` ("Before every tier"), not a remembered subset: 14z-223's tier went red on three of them (`test_must_fire_census`, `test_gate_descriptions`, `test_expectation_provenance` for a new gate and table) — IN A CLEAN CHECKOUT of the staged tree (`git worktree add --detach` of a commit-tree object): the main tree holds #229's untracked gates, which break the generators.
- **Never edit a script while it runs** ([MJC-54]); the emulator runner reports a tracked file changed during its run.

Say so at the opener. Never spawn any agent at `max`. A recommendation leans only on the maintainer's OWN words.
**PILOT** (6 vCPU, 47 GB, Ubuntu 24.04) carries xdelta3, Node, `strace`, podman and the GNOME session the desktop gate
drives (the maintainer logs in; it locks after 5 min idle, and a desktop run goes under `gnome-session-inhibit --inhibit
idle env --default-signal=PIPE`: the inhibitor alone leaves SIGPIPE ignored for every child, gotchas.md, 14z-223). It crashed
once on 2026-11-08 (no shutdown record; the maintainer brought it back). Idle at the 14z-223 close, its checkout
`~/vampire-saved` detached at the scratch `d29fa100` (never pushed): move it to `main` first. **ERIS** (WSL2, 24 threads,
47 GB) runs the release shape; idle at the 14z-223 close, its checkout `~/vampire-saved` detached at the scratch `7150f4c3`
(never pushed): move it to `main` first. Neither profile sets ROMDIR (`ROMDIR=~/roms`). Work handed to either is a bundle of a COMMIT (a bare
commit-tree needs a temporary ref; delete it after); a remote script goes over `ssh <host> 'wsl -e bash -s' < script` (ERIS)
or `ssh pilot 'bash -s' < script`, never as a quoted command line (Windows' shell splits it at a pipe and mangles quotes), and
a remote `pkill -f <pattern>` matches its own shell: kill by PID, or by session (`pkill -KILL -s <sid>`), from a stdin script.

**THE SESSION CLOSE:** `docs/project/session_close.md`, run by `python3 tools/close.py`. The run of record is named in
STATE 14z-223's CLOSE section. A red tier is re-run on THE RED RUN'S results (#317).

**THE EMULATOR RUNNER SINCE 14z-210 (#321, `docs/project/operations.md`):**
- **Concurrent controls:** a gate on `tests/controls_concurrent_emu.txt` (from a PILOT write trace) runs each
  control as a pool job of its own; a listed gate whose script changed must be re-traced on PILOT before it stays listed
  (`tests/test_controls_concurrent.sh`), and the static list `tests/controls_concurrent.txt` the same. Both lists are to be
  replaced by declared shares (#370). The two Linux desktop gates claim the desktop session (`tests/lib/desktop_session.sh`)
  and run alone; `audit_dead_leg_linux` runs AFTER the two Linux release gates at release.
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
1. **#369 — a control mode is honoured only on positive evidence from its own check** (ruled 14z-223: the #310
   post-mortem's first recommendation; STATE 14z-223 (9), `DECISIONS_HISTORY.md`). Design first and show it before
   migrating: the one classifier rule, the static lint (a `CONTROL FIRED` print sits in the failure branch of the check it
   names), a control on the classifier, then the migration — 117 of 297 emulator modes (kept logs, an upper bound) and 418
   of 694 static modes (84 gates) print no firing line of their own (the table: `build/agent223/postmortem/static_fired/`,
   local). When #369 lands, **#310 closes** (ruled). #310's batch 6 is dropped.
2. **#370 — gates declare what they share; the runners schedule by it** (the post-mortem's second recommendation),
   replacing the two concurrent-control allow-lists and the desktop-session lock.
3. **#364 — under dash an EXIT-only cleanup trap does not run on TERM** (`docs/platform/gotchas.md`): about 277 scripts;
   #359's pattern beside each EXIT-only trap, then `tests/test_signal_traps.sh` refuses the form.
4. **Ask the maintainer for the order of the rest.** Open tickets: bug #310 (closes with #369), #364; evolution #369,
   #370, #348, #352; cosmetic #344, #360. Parked: #123, #124, #125, #128.

**THE STANDING LESSON OF 14z-223** (feedback memory `step-back-before-patch-series`, gotcha "A FIX THAT LISTS THE WRONG
ANSWERS NEVER FINISHES"): at every batch boundary of a multi-batch ticket, if the next batch repeats a patch family,
write the one-paragraph alternative design and ask before starting it.

## PARKED (not open work)

- #124 (Killshread's aura palette), #123, #125, #128 (Marionette, parked again 14z-216).
- **VampireSaved-Rebuilt#1** holds what is left of #120, closed 14z-205.

## INSTRUMENT FACTS LEARNED THIS SITTING (read before the work they bear on)

- **A wrapper can leave SIGPIPE ignored for every child** (`gnome-session-inhibit`): dash then prints `printf: I/O
  error` on a closed pipe and `tests/lib/controls.sh` reads the copy as unable to run. Put `env --default-signal=PIPE`
  after any wrapper that is not a plain exec; check `SigIgn` in `/proc/self/status`.
- **A write trace sees files, never a shared session** (display, sink, focus): it cannot clear a gate whose controls
  share one (`docs/project/gotchas.md`, 14z-223).
- **A dead instrument on `PATH` does not show where a leg died**: `test_dead_leg_unjudged.sh`'s only-the-instrument check
  varies only `MAME_BIN`. A stub that logs its calls, and the leg named by the NOT JUDGED line, do (14z-223's where-died runs).
- **The rule-checker found a real gap in each of six rounds on one commit** (runs -1725 to -1730): assemble the evidence
  for what each claim rests on, including which blob each run executed, before preparing.

## WHAT CLOSED THIS SITTING (14z-223)

- **Closed done:** #365, #366 (run -1712), #367 (run -1720), #368 (run -1724).
- **#310:** group 7 batches 3-5 (166 dead-leg rows) and the Linux gate's 5 rows (`8973b301`, run -1730); the post-mortem
  posted on it; it closes with #369.
- **Filed:** #367, #368, #369, #370.
