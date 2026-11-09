# NEXT SESSION — orientation (rewritten at the 14z-224 CLOSE, 2026-11-09)

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
once on 2026-11-08 (no shutdown record; the maintainer brought it back). Idle at the 14z-224 close, its checkout
`~/vampire-saved` detached at the scratch `cfcdc2e3` (never pushed): move it to `main` first. **ERIS** (WSL2, 24 threads,
47 GB) runs the release shape; idle through 14z-224, its checkout `~/vampire-saved` detached at the scratch `7150f4c3`
(never pushed): move it to `main` first. Neither profile sets ROMDIR (`ROMDIR=~/roms`). Work handed to either is a bundle of a COMMIT (a bare
commit-tree needs a temporary ref; delete it after); a remote script goes over `ssh <host> 'wsl -e bash -s' < script` (ERIS)
or `ssh pilot 'bash -s' < script`, never as a quoted command line (Windows' shell splits it at a pipe and mangles quotes), and
a remote `pkill -f <pattern>` matches its own shell: kill by PID, or by session (`pkill -KILL -s <sid>`), from a stdin script.

**THE SESSION CLOSE:** `docs/project/session_close.md`, run by `python3 tools/close.py`. The run of record is named in
STATE 14z-224's CLOSE section. A red tier is re-run on THE RED RUN'S results (#317).

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
1. **#369 — migrate the 310 gates on `tests/expected/ctl_caught_debt.tsv`** (STATE 14z-224 (1); `DECISIONS_HISTORY.md`
   14z-224): each gate's modes to `vs_ctl_caught <its check's output> <the mode's finding>`, its row removed in the same
   commit; a migrated gate's modes must read HONOURED on CAUGHT (and every listed gate it changes re-traced, or its
   concurrent row taken off). Work in batches by family; at each batch boundary apply the standing lesson below. Piece 5
   (the crash-sweep `fx` classes and the dead-leg tables under the new rule) is NOT designed: design it and show it before
   the batches reach those gates. #369 closes, and **#310 with it** (ruled), when the list is empty and deleted.
2. **#370 — build it as ruled: A1, B1, C1** (`DECISIONS_HISTORY.md` 14z-224; design `build/agent224/t370/design.md`,
   local, summarised in the ruling). The design's order: interleave with #369's migration — each migrated gate gets its
   `# SHARES:` line in the same edit — or land the field and scheduler first; say which at the opener.
3. **#364 — under dash an EXIT-only cleanup trap does not run on TERM** (`docs/platform/gotchas.md`): about 277 scripts.
4. **Ask the maintainer for the order of the rest.** Open tickets: bug #310 (closes with #369), #364; evolution #369,
   #370, #348, #352; cosmetic #344, #360. Parked: #123, #124, #125, #128.

**THE STANDING LESSON OF 14z-223** (feedback memory `step-back-before-patch-series`, gotcha "A FIX THAT LISTS THE WRONG
ANSWERS NEVER FINISHES"): at every batch boundary of a multi-batch ticket, if the next batch repeats a patch family,
write the one-paragraph alternative design and ask before starting it.

## PARKED (not open work)

- #124 (Killshread's aura palette), #123, #125, #128 (Marionette, parked again 14z-216).
- **VampireSaved-Rebuilt#1** holds what is left of #120, closed 14z-205.

## INSTRUMENT FACTS LEARNED THIS SITTING (read before the work they bear on)

- **A text lint of shell source cannot be made airtight** (gotcha, 14z-224): `tools/ctl_caught_lint.py` lost to one more
  shape in each of runs -1743 to -1749; it now states what it covers. Do not patch it shape by shape again: the limits stand
  as stated (ruled 14z-225, `DECISIONS_HISTORY.md`).
- **zsh expands a word that starts with `=`** (`echo ======` looks up a command named `=====`); quote separators.
- **The rule-checker found a real gap in seven rounds on one commit** (runs -1743 to -1749): for a lint, list the shapes it
  claims to see and the ones it does not BEFORE preparing, and plant a control for each claimed one.
- **A `{ …; } >>` block's redirect is invisible to a line reader**: a planted near miss must give each line its own
  redirect (`tests/test_ctl_caught_lint.sh`).

## WHAT HAPPENED THIS SITTING (14z-224)

- **Committed:** `23ccb65c` (#369 pieces 1-3, the ledger page's era tiles).
- **Ruled:** #369's design (A1, B1, C1), #370's design (A1, B1, C1), #369's lint limit (`DECISIONS_HISTORY.md`, 14z-224).
- **Pushed mid-sitting on the maintainer's word:** the ledger page to `gh-pages` (`87372240`).
- **Closed:** none. **Filed:** none.
