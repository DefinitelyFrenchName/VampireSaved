# NEXT SESSION — orientation (rewritten at the 14z-208b CLOSE, 2026-10-25)

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
2026-10-23) and has `strace`; its clone sits at `a14e811e` (the freeze commit) with a dirty `emu/fbneo` and an untracked
`-V` file in its root (#324: leave it until #324 finds its writer); fork X2's scratch there is deletable
(`~/x2wt`, `~/x2out`, `~/x2.bundle`, `~/t229.tar`, `~/x2f5`, `~/x2_run_*.sh`). **ERIS** (WSL2 and MSYS2) has a
source-built MAME at its pin (`C:\Users\Chaton\.cache\vampire-saved\mame\cps2.exe`), no xdelta3 and no node; its lane
folders were deleted 2026-10-24 (ruled). Neither profile sets ROMDIR (`ROMDIR=~/roms`). Work handed to either is a bundle
of a COMMIT ("When to commit"); a remote script goes over `ssh <host> 'wsl -e bash -s' < script` (nested quotes break).

**THE SESSION CLOSE:** `docs/project/session_close.md`, run by `python3 tools/close.py` (`start --key … --row - --prev
<results> --transcript <id>`, then `next`, `done`, `status`). The run of record is named in STATE 14z-208's CLOSE section.
A red tier is re-run by the driver on THE RED RUN'S results, not `--prev` (#317); a snapshot's setup is about 25 s now (#304,
#317), so a red costs the gates it re-runs, not a second copy.

**A RELEASE ON A FREEZE'S COMMIT REUSES THE FREEZE'S RUNS (#316, measured 14z-208b, `docs/project/release_format.md`):**
the controls still run, so the emulator tier stays hours; run the Mac's and PILOT's host gates AFTER ERIS's run ends
(`docs/project/gotchas.md`), and ERIS at `--jobs 8` can push a long MAME control over half its cap (#321).

**THE STATIC TIER (14z-207, #312, #315):** a gate's controls run as pool jobs of their own once the gate's run ends
(`tests/lib/static_pool.py`); for the gates on `tests/controls_concurrent.txt` they run side by side, chosen from a write
trace of every control on Linux; `tests/test_controls_concurrent.sh` fails a listed gate whose script changed since its
trace. `test_run_on_snapshot` (#304) and `test_session_close` (#317) came OFF the list this sitting; the freeze's re-trace
(HANDOFF.md) puts them back.

**THE SNAPSHOT LEAVES SCRATCH OUT (#304)** and `build/` keeps closed work only by the retention rule (#307,
`docs/project/build_dir_triage.md`; the 84-tar archive is on files-hades). `tools/build_retention.py` plans a prune;
the maintainer approves it before anything is deleted.

## START HERE

0. **AT THE OPENER, RUN `python3 tools/agent/sweep.py`.**
1. **#229 — WAITING ON THE MAINTAINER'S F4 LOOK** (STATE_HISTORY 14z-208 (6), STATE 14z-208b (1)): Q1 on F4's 18-tile
   command-throw sheets, *"needs more time on my end but apparently it seems we have gaps/wrong moves"* (2026-10-24); ask
   which tiles. Q2, Q4 (a), Q5 and Q7 are ruled; Q7's findings are #318, #319, #320.
   - **The work is LOCAL and UNTRACKED:** the six gates, their expectations, rigs and Lua (105 files,
     `build/agent205/t229/pending_gates_229.list`, backed up in `pending_gates_229.tar` beside it). Never `git clean`.
   - **The guard-cancel expectation** with dealt legs is ready beside the frozen one (`build/agent208/X2/new/`, hash
     `6f6f14a3`); the swap needs its own rule-checker run.
   - **The maintainer's docs (private):** questions https://claude.ai/artifact/88mHYGNsf1wyYZ2EFfzPCE, community
     cross-check https://claude.ai/artifact/Wfn7XUHignvbQphap3MwyK. Read the questions doc for new answers first.
2. **Then ask the maintainer for the order of work.** Open tickets by GitHub severity label:
   - medium: #321 (parallelise the serial-by-default gates; its headroom data point is on the issue);
   - low: #118, #229, #244, #305, #306, #310, #311, #323, #324, #325 (and #129 and #301, parked);
   - no severity label: #278 (release-only, measured, open: its comment of 14z-207), #302, #318, #319, #320;
   - parked: #121, #123, #124, #125, #127, #128, #162, #267, #294.
3. **`tests/replays/118_chain.rpl`'s header names a leg of `audit_mizuumi_inputs` that gate never ran** (STATE_HISTORY
   14z-198 finding (i)); the one-line correction rides a session that runs the emulator gates following `tests/replays/`.

## PARKED (not open work)

- #124 and #294 (Killshread's aura palette, filed parked by the maintainer 2026-10-18), and #121.
- **VampireSaved-Rebuilt#1** holds what is left of #120, closed 14z-205.

## INSTRUMENT FACTS LEARNED THIS SITTING (read before the work they bear on)

- **A host-covered gate re-run before the remote run ends is hidden by the remote's later SKIP** (`docs/project/gotchas.md`):
  the staleness audit reads each gate's NEWEST row; run the Mac's and PILOT's host gates after ERIS's run has ENDED.
- **A gate's own Python fixture is outside `test_host_text_opens`** (#322, `docs/platform/gotchas.md`): when a reader gains
  an encoding, grep the gates that write its file for the host default too; a gate's Windows half runs only at release.
- **The half-cap headroom rule fires on load, not on a fault** (#321): `audit_hitclass_map_cost@drift-clock` took 2,921 s
  of 5,400 s at `--jobs 8` on ERIS and 1,122 s alone at `--jobs 4`. Re-run such a gate alone on the same commit.
- **The rule-checker caught real gaps before the closures this sitting**: run `2026-10-25-1274` (the ERIS run's FAIL and
  SKIP rows unnamed, the desktop gate's fresh cut asserted, not shown). A shared packet for several closures works when
  they rest on one body of evidence (#316, #266, #284, #297 in one run).

## WHAT CLOSED THIS SITTING (14z-208b)

- **The freeze:** a battery on HEAD with no new build (*"Battery, no new build"*), committed as `a14e811e`.
- **The release:** merged-m23 re-released from `a14e811e` with #316's reuse; the nine assets replaced and re-verified
  from GitHub (*"Upload with --prune (Recommended)"*).
- **Closed `done`:** #316, #266, #284, #297, #322. **Filed:** #318, #319, #320 (#229 Q7), #321, #322, #323, #324, #325.
- **Ruled** (`DECISIONS_HISTORY.md`, 14z-208b entries): #229 Q1, Q4, Q7 and #301; the freeze's form; #321's filing; #322
  ship-and-fix; the upload with `--prune`.
