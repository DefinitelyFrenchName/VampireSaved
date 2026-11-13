# NEXT SESSION — orientation (rewritten at the 14z-226 CLOSE, 2026-11-13)

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
- **#369's rule is live (`23ccb65c`):** a control mode is HONOURED only on a `CONTROL CAUGHT: <mode> — ` line printed
  by `vs_ctl_caught <file> <ERE>` (`tests/lib/controls.sh`), unless its gate is on `tests/expected/ctl_caught_debt.tsv`
  (100 rows since 14z-225's batch 1, shrink-only). A NEW gate with control modes calls the helper; it cannot join the list
  (`tests/test_ctl_caught_lint.sh`). The literal may not appear in any other code file under `tests/` or `tools/`, comments
  included (`docs/project/must_fire_contract.md` § #369).
- **Never edit a script while it runs** ([MJC-54]); the emulator runner reports a tracked file changed during its run.

Say so at the opener. Never spawn any agent at `max`. A recommendation leans only on the maintainer's OWN words.
**PILOT** (6 vCPU, 47 GB, Ubuntu 24.04) carries xdelta3, Node, `strace`, podman and the GNOME session the desktop gate
drives (the maintainer logs in; it locks after 5 min idle, and a desktop run goes under `gnome-session-inhibit --inhibit
idle env --default-signal=PIPE`: the inhibitor alone leaves SIGPIPE ignored for every child, gotchas.md, 14z-223). It crashed
once on 2026-11-08 (no shutdown record; the maintainer brought it back). Idle at the 14z-226 close, its checkout
`~/vampire-saved` on `main` at `df4b0902` (fetch first); its disk 101 G of 249 G used, our home 80 G (the maintainer freed
space 2026-11-12; feedback memory `pilot-disk-cleanup-before-runs`). **ERIS** (WSL2, 24 threads, 47 GB) runs the release
shape; its checkout `~/vampire-saved` on `main` at `a2f8b817` (fetch first). Hold an ERIS run's ssh open
(`ssh eris 'wsl.exe -u koneko -- bash …'`): WSL shuts the distro down when the last session ends (gotchas.md, measured on
ERIS 14z-226). Neither profile sets ROMDIR (`ROMDIR=~/roms`). Work handed to either is a bundle of a COMMIT (a bare
commit-tree needs a temporary ref; delete it after); a remote script goes over `ssh <host> 'wsl -e bash -s' < script` (ERIS)
or `ssh pilot 'bash -s' < script`, never as a quoted command line (Windows' shell splits it at a pipe and mangles quotes), and
a remote `pkill -f <pattern>` matches its own shell: kill by PID, or by session (`pkill -KILL -s <sid>`), from a stdin script.

**THE SESSION CLOSE:** `docs/project/session_close.md`, run by `python3 tools/close.py`. The run of record is named in
STATE 14z-226's CLOSE section. A red tier is re-run on THE RED RUN'S results (#317).

**THE EMULATOR RUNNER SINCE 14z-210 (#321, `docs/project/operations.md`):**
- **Declared shares (#370 stage 1, `df4b0902`):** every gate carries one `# SHARES:` line; the emulator runner runs a
  gate's controls side by side only when its line is `none`; the two concurrent-controls lists are retired. The two Linux
  desktop gates claim the desktop session (`tests/lib/desktop_session.sh`) and run alone; `audit_dead_leg_linux` runs
  AFTER the two Linux release gates at release.
- **`--order <an earlier run>/results.tsv`** starts a pooled lane longest first.
- **Temp files on disk:** unless the caller set `TMPDIR`, a run's gates write under `build/tmp/emu_<stamp>.<pid>/`
  (removed at the end); the run refuses to start with under 10 GB free there (`VS_TMP_MIN_GB`). On Linux that in-repo
  path makes every MiSTer-lane gate refuse to run (#372): set `TMPDIR` outside the repo for that lane.
- **Every gate runs through design R since 14z-226 (`7b5938e9`, `tests/lib/session_run.py`):** its own session and a
  `gate.*` TMPDIR; what is left when it returns is TERMed, up to `REAP_WAIT` (10) s, then KILLed, and the TMPDIR removed;
  a TERM, INT or HUP to the runner reaches the gate's session. A child that starts its own session escapes the reap, and
  `tools/trace_controls.sh`, the static lanes and manual runs are not wrapped (`docs/project/operations.md`).
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
1. **Put the maintainer's concern about #310's cost first, with numbers, before any more of its work.** At the 14z-226
   close the maintainer said: **"we've been spending the best part of two whole weeks on #310 and its ramifications. And
   while it's fine since we're trying to build something truly reliable, that is still an insane amount of effort to fix
   something"**. #310 was filed 2026-10-22. It led to #364, #369, #370, #371 and #372, and touched commits in 14z-215 to
   14z-226. Bring the MEASURED breakdown they asked for on 2026-11-10 (feedback memory `explain-check-cost-with-data`):
   session hours and tier minutes per ticket in the family, and how much went to implementation, to scope, and to
   rework after a misreading. Then ask, in their words, how much of what is left to do: #369 batch 2 (100 debt rows), #370's
   token scheduler and write audit, and #372. Stopping where we are, with the debt list as a stated limit, is a real
   option. So is a fixed time budget.
2. **#369 batch 2 — the 100 rows left on `tests/expected/ctl_caught_debt.tsv`** (only if item 1 keeps it): the gates
   the dead-leg and crash-sweep tables tie to, so each migration re-measures its rows (contract step 7: the stripped / kb
   column becomes UNJUDGED-CAUGHT). `audit_release_linux_desktop` is among them. At the batch boundary, apply the standing
   lesson below. #369 closes, and #310 with it, when the list is empty and deleted.
3. **#370's remaining work** (only if item 1 keeps it): the emulator runner's token scheduler and the freeze-cadence
   cross-job write audit.
4. **#372** (bug, severity low): the MiSTer lane refuses the runner's in-repo temp on Linux with `TMPDIR` unset.
5. **Ask the maintainer for the order of the rest.** Open tickets: bug #310 (closes with #369), #372; evolution #369,
   #370, #348; cosmetic #360. #352 is done, labelled `done unshipped` until a release runs its mode. Parked: #123, #124,
   #125, #128, #344.
6. **PILOT's old scratch directories:** list them with their sizes (the session's `~/od`, `~/r371*` and earlier run copies
   under our 80 G home) and ask before deleting any.

**THE STANDING LESSON OF 14z-223** (feedback memory `step-back-before-patch-series`, gotcha "A FIX THAT LISTS THE WRONG
ANSWERS NEVER FINISHES"): at every batch boundary of a multi-batch ticket, if the next batch repeats a patch family, write
the one-paragraph alternative design and ask before starting it.

## PARKED (not open work)

- #124 (Killshread's aura palette), #123, #125, #128 (Marionette, parked again 14z-216).
- #344 (cosmetic; the `parked` label added 2026-11-08 by the maintainer's account).
- **VampireSaved-Rebuilt#1** holds what is left of #120, closed 14z-205.

## INSTRUMENT FACTS LEARNED THIS SITTING (read before the work they bear on)

- **The on-demand scope cannot be fully exercised on PILOT or ERIS:** `test_meter_gain`, `audit_throw_recovery` and
  `audit_guard_cancels` read data kept outside the tree (the community workbook, `~/charpages/framedata/` tables) that
  neither box holds, so they SKIP or FAIL there whatever the runner. `audit_mask_window_ff42a2` is an instrument the
  runner selects in no scope.
- **A stray file seen once is not evidence:** rule-checker run 2026-11-13-1788 caught a work directory the stock runner
  left on PILOT presented as evidence for R; one unrepeated run each way shows nothing about the difference.
- **The on-demand scope takes about 6 h on PILOT at `--jobs 4` for half its rows** (`audit_sdram_bank_load` alone
  6,715 s), about 3 h on ERIS at `--jobs 6`: split it between the boxes.

## WHAT HAPPENED THIS SITTING (14z-226)

- **Committed:** `7b5938e9` (#364/#371 design R; #369 batch 1's items 1, 3, 4).
- **Ruled:** #369 batch 1's limits ("fix items 1,34, accept the others as limitations and don't fix them"), #364/#371's
  design ("R, no lint (Recommended)") (`DECISIONS_HISTORY.md` 14z-226); the desktop gate's speed ideas declined ("since
  it's release-only let's do neither").
- **Closed:** #364, #371. **Filed:** #372.
