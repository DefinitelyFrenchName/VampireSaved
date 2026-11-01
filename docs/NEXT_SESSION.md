# NEXT SESSION — orientation (rewritten at the 14z-215 CLOSE, 2026-10-31)

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
**PILOT** (6 vCPU, 47 GB, Ubuntu 24.04) carries xdelta3, Node and `strace`. Its checkout `~/vampire-saved` sits at
`550958ad`. Deletable scratch: 14z-214's (`~/t214*`) and 14z-215's (`~/t215*`, the bundles `~/t215*.bundle`, the clones
`~/t215*_tr`, the outputs `~/t215*_out`); older, not on any list and left alone: `~/p211_*` and the refs
`refs/tmp/f207-286rec`, `refs/tmp/f207-313`. **ERIS** (WSL2) runs the release shape; its checkout sits at `550958ad`; its
14z-214 scratch (`~/e214_out`, `~/e214_order.tsv`, `~/vampire-saved/build/emu_e214`) and 14z-215's #129 capture trees
(`~/t129`, `~/t129b`, `~/t129w`) are deletable. Neither profile sets
ROMDIR (`ROMDIR=~/roms`). Work handed to either is a bundle of a COMMIT (a bare commit-tree needs a temporary ref; delete
it after); a remote script goes over `ssh <host> 'wsl -e bash -s' < script` (ERIS) or `ssh pilot 'bash -s' < script`,
never as a quoted command line (Windows' shell splits it at a pipe), and a remote `pkill -f <pattern>` matches its own
shell: kill by PID from a stdin script.

**THE SESSION CLOSE:** `docs/project/session_close.md`, run by `python3 tools/close.py`. The run of record is named in
STATE 14z-215's CLOSE section. A red tier is re-run on THE RED RUN'S results (#317).

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
- **ERIS's release shape:** `--scope all --strict --controls --jobs 8 --skip test_mame_parity --reuse <freeze run>
  --order <the previous release's results>`, about 2 h 12 min with TMPDIR on disk (7,947 s at `86d1ca10`). `--jobs 12`
  gains nothing.
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
   **THE WORKING TREE CARRIES UNCOMMITTED RECORDS** written after the 14z-215 push: the CLOSE section's last lines and
   this note. They ride this session's close.
1. **#310 — THE CRASH-INJECTION SWEEP, FIRST** (the maintainer, 14z-215: **"Next session, first batch (Recommended)"**,
   `DECISIONS_HISTORY.md`). A sweep gate that forces each changed gate's perturbed copies to crash and requires DIED or
   UNJUDGED, never HONOURED: the ~20 other group-5 gates (`vs_ctl_show_err`), every changed control mode outside the six
   planted ones, and group 6's edits in the eight gates the extended census named (STATE 14z-215 (8)). Its seed is
   `build/agent215/t310/rcmeas/measure.sh` (local): it planted a raise only where a mode's probe captures output, and was
   validated by reading HONOURED on the pre-fix gate for exactly the three modes the census named before reading none on
   the fixed gate (`docs/project/gotchas.md`, "A CRASH PLANTED ON EVERY CALL PROVES NOTHING"). Copy it into the tree as
   the gate's start, never as a scratch check. Then group 7's first batch (the classifier-order fix first).
   **For the maintainer, on #310's comment:** the chosen option read "the 4 group-5 unknowns are measured first";
   `test_rule_checker`, the fourth, was measured after its fix, not first.
2. **#118 is closed; #129 is closed `declined`.** Nothing to carry for either.
3. **Clear PILOT's and ERIS's scratch** (the list above).
4. **Ask the maintainer for the order of work.** Open tickets (GitHub severity labels):
   - low: #310 (item 1).
   - awaiting release: #338 (the proof sheets' web build; drawn and published at the next tagged release, which closes it).
   - parked: #123, #124, #125, #127, #128, #162, #294.
   - **Before planning any freeze or release, read each open ticket's comments for a step that runs AT it.**
5. **The next freeze or release** runs the six #229 gates only on demand, ERIS's tier takes `--skip test_mame_parity`,
   and the Mac runs parity (#321); it draws the proof sheets' web build (#338).

## PARKED (not open work)

- #124 and #294 (Killshread's aura palette, filed parked by the maintainer 2026-10-18).
- **VampireSaved-Rebuilt#1** holds what is left of #120, closed 14z-205.

## INSTRUMENT FACTS LEARNED THIS SITTING (read before the work they bear on)

- **A crash measurement is validated like a verdict** (`docs/project/gotchas.md`, 14z-215): it must read HONOURED on the
  known-bad (pre-fix) leg before its clean reading on the fixed leg counts; a raise on every call leaked through an
  uncaptured helper call and read DIED on both.
- **Declared control modes are counted with `vs_ctl_declared`** (the leading comment block), never a grep of the file:
  a heredoc stub's column-0 `# MUST-FIRE:` line is not a mode of its gate.
- **A "moved line" plant removes its target**; renaming a marker left an `re.subn` prefix match standing.
- **A new declared control needs its in-gate twin** in the plain run, or the tier reads `controls RED: <name>(not fired)`.
- **A `${VAR:?}` written literally in a gate's text** (even a label or a printf for a stub) is read by
  `test_demand_after_trap`; write it through `%s`.
- **A range bound written in an atlas ROM-tier document counts toward `test_checkdocs_rom`'s ruled denominator**; and a
  literal `*` in a quoted community name breaks the docs site — put it in a code span (and regenerate
  `docs/game/atlas/mizuumi_candidates.tsv`).
- **A PILOT re-trace needs a tree whose plain run passes:** a scratch commit lacks untracked rule-checker run dirs, so
  `git add` them into the scratch index before bundling.

## WHAT CLOSED THIS SITTING (14z-215)

- **Closed `done`:** #341 (its re-check), #342, #343, #118 (rule-checker run `2026-10-31-1485`).
- **Closed `declined`:** #129 (the maintainer: "Neither, close #129"; run `2026-10-31-1524`).
- **#310:** groups 1-4 re-traced, groups 5 and 6 done (run `2026-10-31-1514`), kept open for the sweep and group 7.
- **Ruled** (`DECISIONS_HISTORY.md`, 14z-215 entries): #310 "5 and 6 now, 7 in batches"; the #129 gate's rows
  "READS-BACK"; #310's per-gate proofs "Next session, first batch"; #129 "Neither, close #129".
