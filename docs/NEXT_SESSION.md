# NEXT SESSION — orientation (rewritten at the 14z-208 CLOSE, 2026-10-24)

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
2026-10-23) and has `strace`; its clone sits at `1c59a7cd` with a dirty `emu/fbneo`; fork X2's scratch there is deletable
(`~/x2wt`, `~/x2out`, `~/x2.bundle`, `~/t229.tar`, `~/x2f5`, `~/x2_run_*.sh`). **ERIS** (WSL2 and MSYS2) has a
source-built MAME at its pin (`C:\Users\Chaton\.cache\vampire-saved\mame\cps2.exe`), no xdelta3 and no node; its lane
folders were deleted 2026-10-24 (ruled). Neither profile sets ROMDIR (`ROMDIR=~/roms`). Work handed to either is a bundle
of a COMMIT ("When to commit"); a remote script goes over `ssh <host> 'wsl -e bash -s' < script` (nested quotes break).

**THE SESSION CLOSE:** `docs/project/session_close.md`, run by `python3 tools/close.py` (`start --key … --row - --prev
<results> --transcript <id>`, then `next`, `done`, `status`). The run of record is named in STATE 14z-208's CLOSE section.
A red tier is re-run by the driver on THE RED RUN'S results, not `--prev` (#317); a snapshot's setup is about 25 s now (#304,
#317), so a red costs the gates it re-runs, not a second copy.

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
1. **THE FREEZE, THEN THE RELEASE** — the maintainer's order: *"I lean towards close then freeze then release"*
   (2026-10-24); the close is done. Ask the maintainer to start the freeze.
   - **The freeze** runs every gate with every control and re-traces the concurrent-controls list on PILOT (HANDOFF.md,
     before the tags). `test_emulator_staleness` fails before it, by design (the freeze's emulator tier clears it).
   - **The release** runs its tiers on the freeze commit itself, nothing committed in between: *"Release tiers on the
     freeze commit (Recommended)"* (`docs/project/release_format.md`, #316). Both runners take `--reuse` with the
     freeze's run; any difference in the identity prints `REUSE REFUSED` and runs everything. **#316 closes on that
     release's measured figures** (what it ran, what it reused).
   - Closed by the release: #266 (`audit_release_linux_desktop` PASSING on PILOT; ask the maintainer to be logged in to
     PILOT's desktop first), #284 (the new READMEs, `test_readme_recording`'s Windows and Linux legs). #278 is measured,
     open (its comment of 14z-207). #297 closes once a freeze has run its 109 moved gates green.
2. **#229 — WAITING ON THE MAINTAINER'S F4 LOOK** (STATE 14z-208 (6), 14z-208b (1)): Q1 on F4's 18-tile command-throw
   sheets, *"needs more time on my end but apparently it seems we have gaps/wrong moves"* (2026-10-24); ask which tiles.
   Q2, Q4 (a), Q5 and Q7 are ruled; Q7's findings are #318, #319, #320.
   - **The work is LOCAL and UNTRACKED:** the six gates, their expectations, rigs and Lua (105 files,
     `build/agent205/t229/pending_gates_229.list`, backed up in `pending_gates_229.tar` beside it). Never `git clean`.
   - **The guard-cancel expectation** with dealt legs is ready beside the frozen one (`build/agent208/X2/new/`, hash
     `6f6f14a3`); the swap needs its own rule-checker run.
   - **The maintainer's docs (private):** questions https://claude.ai/artifact/88mHYGNsf1wyYZ2EFfzPCE, community
     cross-check https://claude.ai/artifact/Wfn7XUHignvbQphap3MwyK. Read the questions doc for new answers first.
3. **Then ask the maintainer for the order of work.** Open tickets by GitHub severity label:
   - medium: #284 (done, unshipped);
   - low: #118, #229, #244, #305, #306, #310, #311 (and #129 and #301, parked);
   - no severity label: #266, #278 (release-only), #297, #302, #316, #318, #319, #320;
   - parked: #121, #123, #124, #125, #127, #128, #162, #267, #294.
4. **`tests/replays/118_chain.rpl`'s header names a leg of `audit_mizuumi_inputs` that gate never ran** (STATE_HISTORY
   14z-198 finding (i)); the one-line correction rides a session that runs the emulator gates following `tests/replays/`.

## PARKED (not open work)

- #124 and #294 (Killshread's aura palette, filed parked by the maintainer 2026-10-18), and #121.
- **VampireSaved-Rebuilt#1** holds what is left of #120, closed 14z-205.

## INSTRUMENT FACTS LEARNED THIS SITTING (read before the work they bear on)

- **A stale submodule `index.lock` makes every `git status` re-read the whole submodule** (#317, `docs/project/gotchas.md`):
  `.git/modules/emu/mame/index.lock`, 0 bytes, from 2026-09-30, cost about 26 s of every snapshot's setup (`git status`
  in `emu/mame` 8.74 s → 0.11 s once removed). Look for one when a `git status` is slow.
- **A tool's own gate on the REAL tree catches what fixtures miss** (#307): the retention tool's first cut planned 83
  input-classed `emu_*` folders away; its gate, run on the real tree in a scratch-free tier, caught it before anything
  was deleted.
- **A hand-patched generated page is reverted by its generator** (#229): `docs/project/tables/community_crosscheck.md` is
  written by `tools/crosscheck_framedata.py`; change the generator, never the page.
- **The rule-checker caught real gaps before every closure this sitting**: #298 (`1244`-`1247`), #289 (`1249`-`1251`),
  #304 (`1254`-`1259`), #307 (`1261`-`1264`), #317 (`1266`, `1268`: the setup's four uncontrolled background waits and
  the fallback, named). A closure names every uncontrolled wait and fallback its change adds.

## WHAT CLOSED THIS SITTING (14z-208)

- **Closed `done`:** #298, #289, #304, #307, #317. **Built, open until a measured release:** #316. **Recorded declined:**
  #170 (closed on GitHub by the maintainer).
- **Filed:** #316, #317. **Ruled** (`DECISIONS_HISTORY.md`, 2026-10-24 entries): #298 runner apart, #289's cut stands,
  #304 item 2 (a relative scratch base copied in, `build/static_runs` left out), #307 (archive to files-hades, the
  maintainer's diff in place of a checksum), the leftover 14z-205c snapshot deleted, #229 Q2 and Q5, #316 and its
  order, #317 and change 2 dropped.
- **#307's prune** freed 49 → 78 GiB; **five commits** this sitting (`c30fc8cf`, `47c118e4`, `1e24cae1`, `dd1154f5`, and
  the close's), pushed with the close.
