# NEXT SESSION — orientation (rewritten at the 14z-211 CLOSE, 2026-10-28)

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
**PILOT** (6 vCPU, 47 GB, Ubuntu 24.04, disk at 95%, about 12 GB free) carries xdelta3, Node and `strace`; its
checkout `~/t210_trace` sits at the 14z-210 staged tree `f6ba8f02` (detached) and is the write-trace clone. Deletable
scratch: `~/t210_trace*`, `~/t210r_*`, `~/t210_*.bundle`, `~/q210_out`, `~/c229*`, `~/e321*`, `~/b209_*`, `~/c209_*`, and
fork X2's `~/x2wt`, `~/x2out`, `~/x2.bundle`, `~/t229.tar`, `~/x2f5`. **ERIS** (WSL2) runs the release shape; deletable
scratch `~/k210` (6.3 GB, at `86d1ca10`), `~/k210_out`, `~/e2_out`, `C:\Users\Chaton\k210.bundle`,
`C:\Users\Chaton\c86d1ca1.bundle`, and 14z-209's `~/a209_*`, `~/e321`. Neither profile sets ROMDIR (`ROMDIR=~/roms`).
Work handed to either is a bundle of a COMMIT (a bare commit-tree needs a temporary ref; delete it after); a remote
script goes over `ssh <host> 'wsl -e bash -s' < script`.

**THE SESSION CLOSE:** `docs/project/session_close.md`, run by `python3 tools/close.py`. The run of record is named in
STATE 14z-211's CLOSE section. A red tier is re-run on THE RED RUN'S results (#317).

**THE EMULATOR RUNNER SINCE 14z-210 (#321, `docs/project/operations.md`):**
- **Concurrent controls:** a gate on `tests/controls_concurrent_emu.txt` (60 of 61, from a PILOT write trace) runs each
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

**THE STATIC TIER:** unchanged since 14z-209 (#312, #315, #324, #304; `tests/lib/static_pool.py`). A strict run fails on a
file it leaves behind outside `build/`, and `build/`'s top-level directories are classed in `tests/expected/build_dirs.tsv`
(a new one fails `test_build_dirs`; `build/tmp/` was added as scratch this sitting).

## START HERE

0. **AT THE OPENER, RUN `python3 tools/agent/sweep.py`.**
1. **THE WORKING TREE CARRIES UNCOMMITTED WORK: #333 and #334** (STATE 14z-211 (3); the maintainer: *"Commit #330
   only"*). Confirm PILOT and ERIS are reachable from the Mac (14z-211 lost both when the Mac moved to 10.200.0.89).
   Then:
   - **re-trace the stale concurrent-controls rows on PILOT:** 46 static and 22 emulator gates whose scripts changed
     (`build/agent211/t334/cc_static.txt`, `cc_emu.txt`). Use `tools/trace_controls.sh`, scored by
     `tools/controls_overlap.py`; 14z-210's scripts are in `build/agent210/t321retrace/`.
   - update both lists' blobs and TRACES lines;
   - read ERIS's #333 release-shape run (finished: 417 PASS, 4 host-environment SKIPs; `build/agent211/t333/eris/`);
   - time #334 item 2's edited gates before and after on ERIS;
   - time `test_mame_parity` under a tier's load on the Mac (#334 item 1's one remaining leg);
   - then one strict GREEN tier on the staged tree, the commit, and the #333 and #334 closures on their rule-checker
     runs.
   `git status` shows the edited gates; `git stash` is never the way to set them aside.
2. **#330 IS OPEN: ITS COMMAND THROWS AND TWO VICTIMS NEXT** (STATE 14z-211 (2); the normal throws are in the tree; the maintainer: *"Commit ground+air, rest next"*).
   - **The command throws:** re-measure their whiffs IN range against a victim that cannot be grabbed. From the wide
     pins, 28 of the 82 events started a plain normal (state seq `0x0A`; `docs/project/gotchas.md` "OUT OF RANGE A
     RANGE-CHECKED GRAB'S INPUT IS A NORMAL"); check every whiff's state on its press frame. The first measurement's
     tool code is `TR_FAMILY=command` in `tools/throw_recovery_rigs.py`, its scratch in `build/agent211/t330/`
     (`cmd_*.py`, `held/`).
   - **The air and command throws on Demitri and Lilith:** the maintainer's *"Measure them too"*. The first runs failed
     (`air_victims.out`: empty states on Lilith's air rigs; `cmd_victims.out`: grabs that never hold on the other
     victims).
   - **The sheets** (`tools/throw_recovery_sheet.py`, the state printed under every tile) for what is added. Then
     #330's closure on a fresh rule-checker run (run `2026-10-28-1361` stopped the first one).
3. **Ask the maintainer for the order of work.** Open tickets (GitHub severity labels):
   - medium: none.
   - low: #118, #310 (the UNJUDGED census; deferred, ruled "Record and defer"), #330 (above), #333 (106 gate scripts carry
     on after a failed `mktemp -d`; done in the tree), #334 (#321's remainder; done in the tree but item 1's Mac leg);
   - parked: #123, #124, #125, #127, #128, #129, #162, #267, #294.
   - **Before planning any freeze or release, read each open ticket's comments for a step that runs AT it.**
4. **The next freeze or release** runs the six #229 gates only on demand, ERIS's tier takes `--skip test_mame_parity`,
   and the Mac runs parity (#321).

## PARKED (not open work)

- #124 and #294 (Killshread's aura palette, filed parked by the maintainer 2026-10-18).
- **VampireSaved-Rebuilt#1** holds what is left of #120, closed 14z-205.

## INSTRUMENT FACTS LEARNED THIS SITTING (read before the work they bear on)

- **A state the engine passes through is not "the fighter can act"** (`docs/project/gotchas.md`, #330). Measure it by
  what the game accepts, and check a state-read predicate on every event it is used for.
- **A rig's first event stands at another stage x** (#330): put a sacrificial event first when comparing events.
- **A rig timed in frames at one speed level does something else at another** (#330): re-time it in ticks, and check it
  against the original by the state at its commit. Export a per-family setting once for the whole run.
- **`tests/audit_throw_recovery.sh` keeps its ticks outside the tree** (`../charpages/framedata/throw_recovery*_full*.tsv`,
  #319): a host without them SKIPs; on-demand sets via `TR_VICTIM`, `TR_FAMILY=air TR_HEIGHT`.
- **The replay range is inclusive** (#329): two directions written end to start share a frame.

## WHAT CLOSED THIS SITTING (14z-211)

- **Closed `done`:** #329 (the half circles' minimal inputs), on its rule-checker run with its closing comment.
- **Landed, ticket open:** #330's normal throws, ground and air: `tests/audit_throw_recovery.sh`, classified on the
  cross-check page, the captures read by the maintainer. #333 and #334 stay open, done in the tree and waiting for PILOT.
- **Ruled** (`DECISIONS_HISTORY.md`, 14z-211 entries):
  - the opener's cleanup; #329's re-rig;
  - #334 item 1 "All 35 on PILOT", #333 "Re-trace after #334", #334 item 2 "All 62";
  - #330: "First accepted input", "New gate, Victor only", "Against the 3-victim range", "Against a height range",
    "Whiff recovery + techability";
  - the close "Commit #330 only"; the captures "Now, before the close"; "Measure them too"; "Commit ground+air, rest
    next"; the maintainer's reading of the sheets, "Yes, commit them".
