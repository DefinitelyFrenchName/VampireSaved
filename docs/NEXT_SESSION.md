# NEXT SESSION — orientation (rewritten at the 14z-213 CLOSE, 2026-10-30)

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
**PILOT** (6 vCPU, 47 GB, Ubuntu 24.04, 56 GB free, 77% used; checked 14z-213 close) carries xdelta3, Node and `strace`. Its
checkout `~/vampire-saved` sits at `e68f8842`. Deletable scratch, 9.1 GB in 75 entries: 14z-213's `~/t213*` (bundles
`t213a`..`t213j`, re-trace clones `~/t213_tr*`, logs `~/t213r*`) and `~/pilot_retrace*.sh`, `~/t213_score*.sh`. **ERIS**
(WSL2, 922 GB free) runs the release shape; its checkout sits at the scratch commit `3117828a` (move it to `main` before
the next run); its scratch `~/e213*` and `~/vampire-saved/build/emu_e213`, `emu_e213c` is deletable. Neither profile sets
ROMDIR (`ROMDIR=~/roms`). Work handed to either is a bundle of a COMMIT (a bare commit-tree needs a temporary ref; delete
it after); a remote script goes over `ssh <host> 'wsl -e bash -s' < script` (ERIS) or `ssh pilot 'bash -s' < script`,
never as a quoted command line (Windows' shell splits it at a pipe), and a remote `pkill -f <pattern>` matches its own
shell: kill by PID from a stdin script.

**THE SESSION CLOSE:** `docs/project/session_close.md`, run by `python3 tools/close.py`. The run of record is named in
STATE 14z-213's CLOSE section. A red tier is re-run on THE RED RUN'S results (#317).

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
1. **#118 — THE RIGS.** The batch plan (`build/agent213/t118/batch_plan_draft.md`, local) and its static pass S0
   (`build/agent213/t118/s0/S0_REPORT.md`, local: leads, not facts) are done. Next: the emulator batches, B6 first (B4
   droppable), on PILOT/ERIS, each with a capture sheet for the maintainer before any conclusion. S0 flags
   `docs/game/atlas/character_tables.md:76` ("14 tables", 15 measured): unchecked.
2. **The `archive/` tags** `archive/t118-196` and `archive/t118-196-struct` exist locally but not on `origin` (checked
   14z-213 close); the hook refuses the session's tag push, so the maintainer pushes them:
   `! git push --no-verify origin archive/t118-196 archive/t118-196-struct`.
3. **Clear PILOT's and ERIS's scratch** (the list above) once nothing cites it, and move ERIS's checkout to `main`.
4. **Ask the maintainer for the order of work.** Open tickets (GitHub severity labels):
   - low: #118 (item 1), #310 (kept open 14z-213, **"Keep open (Recommended)"**: classifier rules 1-4 in and the emulator
     tier read 222 honoured; the 14z-210 census's other shapes, deferred as "Record and defer", are its remaining work),
     #339 (37 ledger rows with session `-` dropped by both ledger pages), #340 (found and fixed 14z-213, the fix in the close commit; close it on its rule-checker run).
   - awaiting release: #338 (the proof sheets' web build; drawn and published at the next tagged release, which closes it;
     its comment says so).
   - parked: #123, #124, #125, #127, #128, #129, #162, #294.
   - **Before planning any freeze or release, read each open ticket's comments for a step that runs AT it.** #333's
     closing comment names one: the 11 sites guarded after run 1366 have not yet run in a release-shape emulator tier.
5. **The next freeze or release** runs the six #229 gates only on demand, ERIS's tier takes `--skip test_mame_parity`,
   and the Mac runs parity (#321); it draws the proof sheets' web build (#338, `docs/project/release_format.md` «The proof
   sheets' web build»).

## PARKED (not open work)

- #124 and #294 (Killshread's aura palette, filed parked by the maintainer 2026-10-18).
- **VampireSaved-Rebuilt#1** holds what is left of #120, closed 14z-205.

## INSTRUMENT FACTS LEARNED THIS SITTING (read before the work they bear on)

- **A fresh run pointed at an old `--log` directory inherits that run's rows and commit of record**
  (`docs/project/gotchas.md`): #310's ERIS rerun still showed the LIES it was run to clear.
- **Two readers that "share no code" can still share a pattern**: #338's independent reader once carried the tool's own
  path regex verbatim; an independent check is written by a different method (14z-213, rule-checker run 2026-10-30-1439).
- **A rule-checker artifact over 25,000 tokens is read in part**: `prepare` refuses it; split it (one diff per file).
- **A control's gate can print its own `CONTROL DEAD` under its mode** when in-gate copies of the controls run on the
  mode's perturbed data: `audit_move_parity` now skips its in-gate controls under a mode, and two gates print their main
  check's DEAD only outside it (#310 rule 1).

## WHAT CLOSED THIS SITTING (14z-213)

- **Closed `done`** with their closing comments: #267 (rule-checker run `2026-10-30-1416`, OK), #335 (`-1425`, OK), #337
  (after runs `-1406` to `-1411`, the last resolved by stating its remaining form a limit).
- **Done, awaiting release:** #338 (run `2026-10-30-1440`, after thirteen VIOLATED runs).
- **Filed:** #339, #340.
- **Ruled** (`DECISIONS_HISTORY.md`, 14z-213 entries): the order; #267 the guard patch and "I switched GH pages deploy";
  #335 "The dashboard new sections are fine"; #337 "Fix (b), state (a)"; #338 the clips, "vs-proof-sheets/", the looks,
  "do it", the JUDGED FILE line, "Count from the run"; #118 the branches; #310 "Classifier rules 1-4", "Keep open"; the
  close "Start the close now".
