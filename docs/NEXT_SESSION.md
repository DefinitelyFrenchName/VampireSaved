# NEXT SESSION — orientation (rewritten at the 14z-209 CLOSE, 2026-10-26)

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
2026-10-23) and has `strace`. Deletable scratch from 14z-209: `~/c229_gc5` (#229's guard-cancel lane), `~/e321s`, `~/e321s2`,
`~/e321_trace*`, `~/e321_*.diff`, `~/e327c*` (#321, #327), `~/b209_306*`, `~/c209_*` (#306, #327); older: fork X2's `~/x2wt`,
`~/x2out`, `~/x2.bundle`, `~/t229.tar`, `~/x2f5`. **ERIS** (WSL2 and MSYS2) has a source-built MAME at its pin; its freeze
tier is now `tests/run_all_emulator.sh --freeze --strict --jobs 8 --skip test_mame_parity` (#321: parity runs on the Mac only,
ruled 2026-10-26); deletable scratch `~/a209_*`, `~/e321`, `C:\Users\Chaton\a209*`, `C:\Users\Chaton\e321_*`. Neither profile
sets ROMDIR (`ROMDIR=~/roms`). Work handed to either is a bundle of a COMMIT; a remote script goes over
`ssh <host> 'wsl -e bash -s' < script` (nested quotes break).

**THE SESSION CLOSE:** `docs/project/session_close.md`, run by `python3 tools/close.py` (`start --key … --row - --prev
<results> --transcript <id>`, then `next`, `done`, `status`). The run of record is named in STATE 14z-209's CLOSE section.
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
1. **Ask the maintainer for the order of work.** Open tickets (GitHub severity labels):
   - low: #118, #310, #311, #318, #320, #327 (fix applied 14z-209; the 14z-208c red not reproduced, 183 sites of the form
     remain elsewhere — its progress comment), #328 (two stale build defaults), #329 (minimal half-circle inputs), #330 (the
     throws' recovery and throw tech), #331 (#229's remainder: Demitri's ES Demon Cradle GC, the FE..JE page section, two
     stale page lines);
   - parked: #123, #124, #125, #127, #128, #129, #162, #267, #294.
   - **Before planning any freeze or release, read each open ticket's comments for a step that runs AT it.**
2. **The next freeze or release** runs the six #229 gates only on demand (`ondemand`, pristine vsavj); ERIS's tier takes
   `--skip test_mame_parity` and the Mac runs parity (#321).

## PARKED (not open work)

- #124 and #294 (Killshread's aura palette, filed parked by the maintainer 2026-10-18).
- **VampireSaved-Rebuilt#1** holds what is left of #120, closed 14z-205.

## INSTRUMENT FACTS LEARNED THIS SITTING (read before the work they bear on)

- **A pristine-vsavj gate proves which ROM, image, ROM path and MAME it measured** (`tests/lib/pristine_vsavj.sh`, four
  controls): a new pristine gate sources it after `decrypt_view`.
- **A sh function has no locals** (`docs/project/gotchas.md`, #323): a library's scratch variable can be its caller's loop
  variable; prefix them.
- **A ruled output format is checked by an oracle written from the ruling's words** (`docs/project/gotchas.md`, #244).
- **A gate whose legs are "every replay with a basis log" goes red the day one is added** (`docs/project/gotchas.md`, #302).
- **The rule-checker on six freezes and three closures** (runs `2026-10-25-1294` to `2026-10-26-1330`): it found the
  provenance gap, clocks frozen before a re-rig, 71 rows never shown to the maintainer, eleven moves no answer named, a
  row check comparing a tool with itself, and a workbook row joined nowhere. The maintainer ruled re-checks only on new
  evidence for #229's freezes (2026-10-25).

## WHAT CLOSED THIS SITTING (14z-209)

- **Closed `done`:** #229 (split: #331), #244, #302, #305, #306, #321, #323 — each on its rule-checker run with its
  closing comment. **Filed:** #328, #329, #330, #331. **#301** found closed by the maintainer, recorded declined.
- **Ruled** (`DECISIONS_HISTORY.md`, 14z-209 entries): #321 phase 2 (all four speed-ups; parity on the Mac only; #305
  with #306); #244 "Class + flags"; #229's freezes re-checked only on new evidence; the motion rows and the eleven
  unnamed moves confirmed; #229 split and closed.
