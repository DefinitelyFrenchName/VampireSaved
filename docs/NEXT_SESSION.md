# NEXT SESSION — orientation (rewritten at the 14z-225 CLOSE, 2026-11-11)

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
  (310 rows, shrink-only). A NEW gate with control modes calls the helper; it cannot join the list
  (`tests/test_ctl_caught_lint.sh`). The literal may not appear in any other code file under `tests/` or `tools/`, comments
  included (`docs/project/must_fire_contract.md` § #369).
- **Never edit a script while it runs** ([MJC-54]); the emulator runner reports a tracked file changed during its run.

Say so at the opener. Never spawn any agent at `max`. A recommendation leans only on the maintainer's OWN words.
**PILOT** (6 vCPU, 47 GB, Ubuntu 24.04) carries xdelta3, Node, `strace`, podman and the GNOME session the desktop gate
drives (the maintainer logs in; it locks after 5 min idle, and a desktop run goes under `gnome-session-inhibit --inhibit
idle env --default-signal=PIPE`: the inhibitor alone leaves SIGPIPE ignored for every child, gotchas.md, 14z-223). It crashed
once on 2026-11-08 (no shutdown record; the maintainer brought it back). Idle at the 14z-225 close, its checkout
`~/vampire-saved` on `main` at `df4b0902` (fetch: it lacks the 14z-225 commits until the push). **ERIS** (WSL2, 24 threads,
47 GB) runs the release shape; not reached in 14z-225's second part, its checkout `~/vampire-saved` last at the scratch `f0007e54`
(never pushed, the #369 batch-1 run): move it to `main` first. Neither profile sets ROMDIR (`ROMDIR=~/roms`). Work handed to either is a bundle of a COMMIT (a bare
commit-tree needs a temporary ref; delete it after); a remote script goes over `ssh <host> 'wsl -e bash -s' < script` (ERIS)
or `ssh pilot 'bash -s' < script`, never as a quoted command line (Windows' shell splits it at a pipe and mangles quotes), and
a remote `pkill -f <pattern>` matches its own shell: kill by PID, or by session (`pkill -KILL -s <sid>`), from a stdin script.

**THE SESSION CLOSE:** `docs/project/session_close.md`, run by `python3 tools/close.py`. The run of record is named in
STATE 14z-225's CLOSE section. A red tier is re-run on THE RED RUN'S results (#317).

**THE EMULATOR RUNNER SINCE 14z-210 (#321, `docs/project/operations.md`):**
- **Declared shares (#370 stage 1, `df4b0902`):** every gate carries one `# SHARES:` line; the emulator runner runs a
  gate's controls side by side only when its line is `none`; the two concurrent-controls lists are retired. The two Linux
  desktop gates claim the desktop session (`tests/lib/desktop_session.sh`) and run alone; `audit_dead_leg_linux` runs
  AFTER the two Linux release gates at release.
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
1. **Ask the open decision first:** #369 batch 1's session-named limits (STATE "Decisions pending").
2. **#364 / #371 — put the recommendation through its rule-checker run, then to the maintainer.** Measured and prototyped
   on PILOT in 14z-225 (`build/agent225/t364/design.md`, local; STATE 14z-225 (4)): design R, the emulator runner ending a
   timed-out gate's whole session (TERM, a bounded wait, KILL) and removing a per-gate TMPDIR, ran with zero survivors and
   the passing gates' verdicts unchanged (`session_run.py`). The options against it: the 276-file trap patch; R plus a lint
   for new files. Not yet measured: the Mac, the pooled lanes at `--jobs N`, the desktop and Verilator gates.
3. **#369 batch 2 — the 100 rows left on `tests/expected/ctl_caught_debt.tsv`:** the gates the dead-leg and crash-sweep
   tables tie to, so each migration re-measures its rows (contract step 7: the stripped / kb column becomes UNJUDGED-CAUGHT).
   `audit_release_linux_desktop` is among them. At the batch boundary apply the standing lesson below. #369 closes, and
   #310 with it, when the list is empty and deleted.
4. **#370's remaining work:** the emulator runner's token scheduler and the freeze-cadence cross-job write audit.
5. **Ask the maintainer for the order of the rest.** Open tickets: bug #310 (closes with #369), #364, #371; evolution
   #369, #370, #348; cosmetic #360. #352 is done, labelled `done unshipped` until a release runs its mode. Parked:
   #123, #124, #125, #128, #344 (labelled `parked` on GitHub 2026-11-08 by the maintainer's account).

**THE STANDING LESSON OF 14z-223** (feedback memory `step-back-before-patch-series`, gotcha "A FIX THAT LISTS THE WRONG
ANSWERS NEVER FINISHES"): at every batch boundary of a multi-batch ticket, if the next batch repeats a patch family, write
the one-paragraph alternative design and ask before starting it. **14z-225 applied it twice**: #369 batch 1's evidence
gaps closed as a class (every gate directly reading a changed path re-run, not one gate per finding), and #352 closed as
a matrix (every leg state under every way the gate runs, 16 cells) after three rounds that each found one narrower branch.

## PARKED (not open work)

- #124 (Killshread's aura palette), #123, #125, #128 (Marionette, parked again 14z-216).
- #344 (cosmetic; the `parked` label added 2026-11-08 by the maintainer's account, the row reconciled at the 14z-225 close).
- **VampireSaved-Rebuilt#1** holds what is left of #120, closed 14z-205.

## INSTRUMENT FACTS LEARNED THIS SITTING (read before the work they bear on)

- **`pgrep mame` is blind to the emulators:** the binary is `cps2` (and `fbneo`): count with `pgrep -x cps2`. A timed-out
  emulator gate's MAME catches TERM and outlives its gate and runner (gotcha, #371).
- **A pinned working-tree run sees no untracked file:** the Mac pins checked the index tree and unstaged changes under
  tests/ and tools/ only; `test_retraction_reach` and `test_rule_checker` passed on untracked files. Evidence meant to
  stand for a tree is run on a snapshot (`tests/run_on_snapshot.sh`), or the limit is named.
- **`rulecheck.py record` refuses a run whose reader failed the spawn check** (a transient permission-check failure on the
  first spawn of -1767): such a run is marked `NOT-RUN.txt` and redone with `--redoes`; so is a packet withdrawn before
  spawning (-1769, -1771) when re-reading it shows a defect — cheaper than spending a round on it.
- **`prepare` refuses an artifact a reader cannot read whole** (over ~25,000 tokens): pass it as `path:FIRST-LAST` slices.
- **zsh: `path` is the array tied to `PATH`** — a loop variable named `path` empties the command search path; and `$S:t`
  is a modifier (write `"${S}:path"`).
- **FBNeo's SDL2 pause outlasts its cause** (gotcha, #352): a key step's focus resumes it, behind the step schedule.

## WHAT HAPPENED THIS SITTING (14z-225)

- **Committed:** `df4b0902` (#370 stage 1), `25621357` (#369 batch 1), `511d4c59` (#352).
- **Ruled:** #352's design ("build it this way but only as a release-time mode") and its finish ("Close it as a matrix,
  then commit") (`DECISIONS_HISTORY.md` 14z-225); the first part's three rulings are recorded there too.
- **Filed:** #371. **Commented:** #364 (the PILOT measurement), #352 (the measurement and a correction). **Closed:** none.
