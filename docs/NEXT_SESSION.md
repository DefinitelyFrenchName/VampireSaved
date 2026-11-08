# NEXT SESSION — orientation (rewritten at the 14z-222 CLOSE, 2026-11-07)

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
**PILOT** (6 vCPU, 47 GB, Ubuntu 24.04) carries xdelta3, Node, `strace`, podman and the GNOME session the desktop gate
drives (the maintainer logs in; it locks after 5 min idle, and a desktop run goes under `gnome-session-inhibit --inhibit
idle env --default-signal=PIPE`: the inhibitor alone leaves SIGPIPE ignored for every child, gotchas.md, 14z-223). Idle at the 14z-222 close, its checkout `~/vampire-saved` detached at `bb10ce97` (the freeze commit) with a LOCAL tag
`freeze/merged-m26` (`564775cf`, never pushed, not origin's tag object): delete that tag before PILOT fetches tags, then move
the checkout to the new `main`. **ERIS** (WSL2, 24 threads,
47 GB) runs the release shape; idle at the 14z-222 close, its checkout `~/vampire-saved` detached at `bb10ce97`: move it to `main` first. Neither profile sets ROMDIR (`ROMDIR=~/roms`). Work handed to either is a bundle of a COMMIT (a bare
commit-tree needs a temporary ref; delete it after); a remote script goes over `ssh <host> 'wsl -e bash -s' < script` (ERIS)
or `ssh pilot 'bash -s' < script`, never as a quoted command line (Windows' shell splits it at a pipe and mangles quotes), and
a remote `pkill -f <pattern>` matches its own shell: kill by PID, or by session (`pkill -KILL -s <sid>`), from a stdin script.

**THE SESSION CLOSE:** `docs/project/session_close.md`, run by `python3 tools/close.py`. The run of record is named in
STATE 14z-222's CLOSE section. A red tier is re-run on THE RED RUN'S results (#317).

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
1. **#366 and #365 — two small test-integrity fixes found at the M26 release** (STATE 14z-222 (4)). #366: correct
   `tests/test_dead_span_reach.sh`'s header (two spans and 10 judged pairs since M26, #363's span among them) and
   `tests/audit_pass_overrun.sh`'s EXPECTS line (ours `none` on all three parts since M25), and decide whether the reach
   gate plants a control on every span, not only the first. #365: give `tests/audit_crash_sweep_emu.sh` its `# SHEET:` line,
   then run `tests/test_sheet_census.sh` (ondemand: no tier runs it). Both gates may be on the concurrent-controls lists:
   an edit means a PILOT re-trace or a delisting.
2. **`test_release_binaries` is OFF the emulator concurrent-controls list** (`tests/controls_concurrent_emu.txt`, its
   `# NOT listed (14z-222 …)` note): its header was corrected after the PILOT trace. Re-trace it on PILOT and list it again.
3. **#310 — GROUP 7, BATCH 3** (batches 1 and 2 landed, 43 rows: `tests/test_dead_leg_unjudged.sh`, STATE_HISTORY 14z-221c
   (5)). Left: the six held out (four MiSTer gates needing verilator, `test_release_roundtrip`, `audit_stock_emulator_stall`
   on `MAME_REF_BIN`), podman's, the 14 two-mode gates on the concurrent list, and every gate with three or more modes
   (`build/agent215/t310/census57/group7.tsv`, local). A row's dead instrument goes in the table's fifth column; the gate
   then runs its mode with only that instrument dead.
4. **#364 — under dash an EXIT-only cleanup trap does not run on TERM** (`docs/platform/gotchas.md`). About 277 scripts
   leave their work directory behind when TERM'd on PILOT. The fix is #359's pattern beside each EXIT-only trap; then
   `tests/test_signal_traps.sh` refuses the form.
5. **Ask the maintainer for the order of the rest.** Open tickets: bugs/test-integrity #310, #364, #365, #366; evolution
   #348, #352; cosmetic #344, #360. Parked: #123, #124, #125, #128.

## PARKED (not open work)

- #124 (Killshread's aura palette), #123, #125, #128 (Marionette, parked again 14z-216).
- **VampireSaved-Rebuilt#1** holds what is left of #120, closed 14z-205.

## INSTRUMENT FACTS LEARNED THIS SITTING (read before the work they bear on)

- **A release-cadence static tier runs every control** (601 at M26): run it `--jobs 8` (50 min) with a cap well over two
  hours; serial, it was stopped at a 2 h cap after 97 gates. `--confirm` is refused at release cadence (#269), so a red is
  fixed and the whole tier re-run.
- **Run the release's static tier after every emulator release record is in.** `test_emulator_staleness` reads each gate's
  NEWEST row by `results.tsv` mtime: ERIS's host-bound SKIP rows, finished later than the Mac's and PILOT's PASS runs of the
  same gates, were the newest, so those host gates were re-run after ERIS.
- **The uploader creates the release with `--verify-tag`**: the freeze tag must be on `origin` first. Push the jtcores fork's
  pinned commit before the tag, so the published tag never names a missing submodule commit.
- **The build each host's release runs judged** is recorded as `build MERGED <fingerprint>` in each run's
  `identity.tsv`/`identity_end.tsv`. The fingerprint covers the zip container, so it differs between hosts whose 25 members
  are equal (`build/agent222/m26/release/close/build_identity.txt`).
- **A closing comment's coverage limits come from the gate's WHOLE header**, in every form: "Not covered", "NOT COVERED",
  "WHAT IT DOES NOT COVER", "Stated, not tested", "MEASURED, not asserted", "Not compared", "deliberately absent". Twelve
  rule-checker runs at this release each found one form or one gate missed.

## WHAT CLOSED THIS SITTING (14z-222)

- **M26 frozen** at `bb10ce97` (#357, #363) and **released** on `freeze/merged-m26` (merged-m24's zips pruned; M25 never
  published, its changes ship here).
- **Closed done:** #345, #346, #356, #357, #358, #363 (rule-checker run `2026-11-07-1708` after -1697 to -1707; the
  maintainer's Cecil reading posted on #358).
- **Filed:** #365, #366.
