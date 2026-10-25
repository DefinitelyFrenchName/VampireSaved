# NEXT SESSION — orientation (rewritten at the 14z-208c CLOSE, 2026-10-25)

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
**PILOT** (6 vCPU, 47 GB, Ubuntu 24.04) carries xdelta3 3.2.0 and Node v24.22.1 user-local (`~/.local/bin`, ruled
2026-10-23) and has `strace`; its clone sits at `25dbfea1` with a dirty `emu/fbneo` (its `-V` file removed, #324). Deletable scratch: `~/p208b_t278/`,
`~/t278chk/`, `~/p278_*.sh` (#278); `~/t326`, `~/p326*`, `~/t326.bundle` (#326); `~/t324t`, `~/p324*`, `~/t324*.bundle`,
`~/t325t`, `~/p325*`, `~/t325.bundle` (#324, #325); fork X2's scratch
(`~/x2wt`, `~/x2out`, `~/x2.bundle`, `~/t229.tar`, `~/x2f5`, `~/x2_run_*.sh`). **ERIS** (WSL2 and MSYS2) has a
source-built MAME at its pin (`C:\Users\Chaton\.cache\vampire-saved\mame\cps2.exe`), no xdelta3 and no node; its lane
folders were deleted 2026-10-24 (ruled). Neither profile sets ROMDIR (`ROMDIR=~/roms`). Work handed to either is a bundle
of a COMMIT ("When to commit"); a remote script goes over `ssh <host> 'wsl -e bash -s' < script` (nested quotes break).

**THE SESSION CLOSE:** `docs/project/session_close.md`, run by `python3 tools/close.py` (`start --key … --row - --prev
<results> --transcript <id>`, then `next`, `done`, `status`). The run of record is named in STATE 14z-208c's CLOSE section.
A red tier is re-run by the driver on THE RED RUN'S results, not `--prev` (#317); a snapshot's setup is about 25 s now (#304,
#317), so a red costs the gates it re-runs, not a second copy.

**A RELEASE ON A FREEZE'S COMMIT REUSES THE FREEZE'S RUNS (#316, measured 14z-208b, `docs/project/release_format.md`):**
the controls still run, so the emulator tier stays hours; run the Mac's and PILOT's host gates AFTER ERIS's run ends
(`docs/project/gotchas.md`), and ERIS at `--jobs 8` can push a long MAME control over half its cap (#321).

**THE STATIC TIER (14z-207, #312, #315):** a gate's controls run as pool jobs of their own once the gate's run ends
(`tests/lib/static_pool.py`); for the gates on `tests/controls_concurrent.txt` they run side by side, chosen from a write
trace of every control on Linux; `tests/test_controls_concurrent.sh` fails a listed gate whose script changed since its
trace. `test_release_reuse`, `test_static_runner` and `test_run_on_snapshot` were re-traced on PILOT at 14z-208c (their
scripts changed: #326, #324, #325); `tools/trace_controls.sh` in a scratch clone at a bundled commit object does it.

**A STRICT STATIC RUN NOW FAILS ON A FILE IT LEAVES BEHIND (#324):** the runner compares the untracked files outside
`build/` before and after a run (`LEFT BEHIND`); a gate that writes into the clone instead of a temp dir turns a strict
tier red. It does not see a file written outside a runner run, an ignored file, or `build/`.

**THE SNAPSHOT LEAVES SCRATCH OUT (#304)** and `build/` keeps closed work only by the retention rule (#307,
`docs/project/build_dir_triage.md`; the 84-tar archive is on files-hades). `tools/build_retention.py` plans a prune;
the maintainer approves it before anything is deleted.

## START HERE

0. **AT THE OPENER, RUN `python3 tools/agent/sweep.py`.**
1. **#229 — every F4 row is confirmed** (the maintainer, 2026-10-25: *"all good"*, STATE 14z-208c (1)): the re-rig,
   the motion test (`docs/game/engine_internals.md`), the air throws in the TRACKED `audit_ground_throws`. What is left:
   - **The work is LOCAL and UNTRACKED:** the six gates, their expectations, rigs and Lua (131 files,
     `build/agent205/t229/pending_gates_229.list`, backed up in `pending_gates_229.tar` beside it). Never `git clean`.
     Registering them (gate index, ci lists, gate descriptions) is #229's next step: ask the maintainer when.
   - **The guard-cancel expectation** with dealt legs is ready beside the frozen one (`build/agent208/X2/new/`, hash
     `6f6f14a3`); the swap needs its own rule-checker run.
   - **The maintainer's docs (private):** questions https://claude.ai/artifact/88mHYGNsf1wyYZ2EFfzPCE, community
     cross-check https://claude.ai/artifact/Wfn7XUHignvbQphap3MwyK. Read the questions doc for new answers first.
2. **Then ask the maintainer for the order of work.** Open tickets by GitHub severity label:
   - medium: #321 (parallelise the serial-by-default gates; its headroom data point is on the issue);
   - low: #118, #229, #244, #305, #306, #310, #311, #323, #327 (the close's red: `printf | grep -q` races in
     `test_static_runner`) (and #129 and #301, parked);
   - no severity label: #302, #318, #320;
   - **Before planning any freeze or release, read each open ticket's comments for a step that runs AT it** (#278's
     locale step was missed at the 14z-208b freeze: `docs/project/gotchas.md`, the UTF-8 collation entry).
   - parked: #123, #124, #125, #127, #128, #162, #267, #294.
3. **`tests/replays/118_chain.rpl`'s header names a leg of `audit_mizuumi_inputs` that gate never ran** (STATE_HISTORY
   14z-198 finding (i)); the one-line correction rides a session that runs the emulator gates following `tests/replays/`.

## PARKED (not open work)

- #124 and #294 (Killshread's aura palette, filed parked by the maintainer 2026-10-18).
- **VampireSaved-Rebuilt#1** holds what is left of #120, closed 14z-205.

## INSTRUMENT FACTS LEARNED THIS SITTING (read before the work they bear on)

- **A "far" event's position pins do not hold while the previous event's throw still runs, and a probe's result is not
  the gate's** (`docs/project/gotchas.md`): measure a far event's start distance on its trace; report a row from the
  gate run's own rows.
- **Half circles on vsavj** (`docs/game/engine_internals.md`): back needs its final 4 (6324, 6214, 624 grab; 6321 never);
  forward takes all five spellings; a 360 is the four cardinals.
- **Linux Python writes `__pycache__/` beside the module** (`docs/platform/gotchas.md`): a gate's synthetic repo needs the
  real `.gitignore`'s bytecode lines.
- **A stub must answer every call its caller can make** (`docs/project/gotchas.md`, #324); **a check-then-create on a shared
  name is a race** (#325).
- **The rule-checker caught real gaps before every closure this sitting** (runs `2026-10-25-1284`, `-1289` to `-1292`):
  a red path never shown, a hash checked by its own function, a mis-counted dead control, a deletion not shown, a
  cause not separated from its fixture, a limit unnamed. Six rounds on #324 cost about an hour; each found a real gap.

## WHAT CLOSED THIS SITTING (14z-208c)

- **Closed `done`:** #278 (`e0965d4d`, pushed with this close), #326, #319, #324, #325 — each on its rule-checker run
  with its closing comment.
- **#229:** F4 re-rigged on the maintainer's fourteen answers and confirmed; the air throws moved to the normal throws
  (*"Remove all, Victor too, but add them to the normal throws!"*).
- **Ruled** (`DECISIONS_HISTORY.md`, 14z-208c entries): the air throws; the "far" rows re-placed, #324's guard
  runner-wide, #319 converted now; #121 closed by the maintainer.
