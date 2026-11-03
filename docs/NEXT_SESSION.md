# NEXT SESSION — orientation (rewritten at the 14z-218 CLOSE, 2026-11-02)

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
idle`). Its checkout `~/vampire-saved` sits at `3e1a7091` (14z-217's close): move it to `main` before other work.
It still holds 14z-218's scratch `~/rt218` (1.9 GB: the re-trace clones and the runner-gate mode runs; their results are
copied to the Mac under `build/agent218/`).
**ERIS** (WSL2, 24 threads, 47 GB) runs the release shape; its checkout sits at `3e1a7091`; it still holds 14z-218's crash
sweep scratch `~/t310p3b`, `~/t310r`, `~/t310s`, `~/t310u` (results on the Mac, `build/agent218/t310/`). Delete both
hosts' 14z-218 scratch only on the maintainer's word, after a listing. Neither profile sets ROMDIR (`ROMDIR=~/roms`). Work handed to either is a bundle of a COMMIT (a
bare commit-tree needs a temporary ref; delete it after); a remote script goes over `ssh <host> 'wsl -e bash -s' <
script` (ERIS) or `ssh pilot 'bash -s' < script`, never as a quoted command line (Windows' shell splits it at a pipe and
mangles quotes), and a remote `pkill -f <pattern>` matches its own shell: kill by PID, or by session (`pkill -KILL -s
<sid>`), from a stdin script.

**THE SESSION CLOSE:** `docs/project/session_close.md`, run by `python3 tools/close.py`. The run of record is named in
STATE 14z-218's CLOSE section. A red tier is re-run on THE RED RUN'S results (#317).

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
1. **#356 — BUILD THE SPEED-LINE COPY** (ruled 14z-218, `DECISIONS_HISTORY.md` "Ruled 2026-11-02 (14z-218) — #356": the
   maintainer, *"ideally Option 1 (new copy of the effect, using vs2 effect)"*, then **"Yes, next session (Recommended)"** and
   **"Raw allocator (Recommended)"**). A tenant-only copy of effect class 0x0F with vs2's 14-row tables (Donovan's dash subs
   0x0C and 0x0D), spawned with the raw allocator; legacy class 0x0F untouched by construction. The census and the
   feasibility study: `build/agent218/tspeed/REPORT.md`, `build/agent218/tspeed/feas/REPORT.md` (local). Gate it, capture
   it against native vs2 for the maintainer, then the M25 freeze.
2. **#345 — OPTION A** (ruled 14z-218, `DECISIONS_HISTORY.md` "Ruled 2026-11-02 (14z-218) — #345": the maintainer,
   **"A first, B held (Recommended)"**). Donovan's class-0x72 trail pieces take vs2's no-draw form (format 10), which also
   removes #346's ice streak (its source measured 14z-218, `docs/game/engine_internals.md`). FIRST the class-0x72 legacy
   census (#357: vs2 DRAWS class-0x72 pieces on Ifrit Sword's guard-cancel) and A's plan, put to the maintainer before
   anything is built; then re-measure the lost frames under all three RNG forms and compare A's build against native vs2 on
   screen. B (a cheaper slot-clearing wrapper) waits for A's measurement. The recommendation and its evidence:
   `build/agent218/t345/rec/` (local), and #345's 14z-218 comment.
3. **#310 — GROUP 7, in batches** (the crash-injection sweep is built: `tests/test_crash_sweep.sh`; #310's 14z-218 progress
   comment holds what it found and its stated limits).
4. **Captures for #357 and #358** (the #356 census's leads), before any mechanism theory.
5. **#359** (cleanup traps on `EXIT INT TERM` with no `exit`: a TERM'd gate keeps running; 210 scripts).
6. **Ask the maintainer for the order of the rest.** Open tickets (GitHub severity labels):
   - bugs: #345 (item 2); evolution: #348 (no tracked-release-vs-build gate), #352 (the desktop gate's paused-FBNeo verdict),
     #354 (no gate on #294's dead span in the built image); cosmetic: #344 (Donovan's Dark Force colours), #346 (the ice
     streak: #345's option A), #356 (item 1), #357, #358; test-integrity: #310 (item 3), #359 (item 5).
   - parked: #123, #124, #125, #128.

## PARKED (not open work)

- #124 (Killshread's aura palette), #123, #125, #128 (Marionette, parked again 14z-216).
- **VampireSaved-Rebuilt#1** holds what is left of #120, closed 14z-205.

## INSTRUMENT FACTS LEARNED THIS SITTING (read before the work they bear on)

- **A cleanup trap on `EXIT INT TERM` with no `exit` lets a TERM'd script carry on** after its cleanup, its work directory
  gone (`docs/platform/gotchas.md`; #359). Kill a stuck driver with KILL, and give a new script's trap `'exit 143' INT TERM`.
- **GNU `timeout` runs its command in a process group of its own** (`docs/platform/gotchas.md`): killing the driver's session
  leaves it running; end the group, and stop a podman container by name.
- **`sitecustomize` swallows an exception raised inside it** (`docs/platform/gotchas.md`): a planted crash there prints a
  traceback and calls `os._exit(1)`.
- **A PATH tracing shim makes `test_agent_sweep` fail** (`docs/project/gotchas.md`): a tracer artefact, not a finding.
- **The Bash tool's zsh command-substitutes backticks inside a double-quoted argument**: a rule-checker `--claim` with
  `` `name` `` in it loses the name (run `2026-11-02-1582`). Write the claim to a file and pass `--claim "$(cat FILE)"`.
- **A call whose output is a list must not read its failure as an empty list** (`docs/project/gotchas.md`):
  `run_all_emulator.sh --stale` took a crashed staleness audit for "no gate is stale" until 14z-218 (fixed, section 25g).
  `test_emulator_runner` is OFF `tests/controls_concurrent.txt` until the next freeze's re-trace; re-trace it then.
- **A caller census needs the unfiltered grep, its lines classed, and a known caller as its control**: a pattern-filtered
  grep missed the `ROMDIR=… tests/…` call form (rule-checker run `2026-11-02-1582`).
- **A one-frame OBJ suppression tap is a clean A/B; a format-word read tap is not**: moving a piece's OBJ entries off
  screen as they are written leaves work RAM identical, while making the drawer skip the piece shortens the pass and
  moves the frame (`build/agent218/t345/streak/REPORT.md`, local).

## WHAT CLOSED THIS SITTING (14z-218)

- **Built:** #310's crash-injection sweep gate (`tests/test_crash_sweep.sh`, `tests/audit_crash_sweep_emu.sh`): 88 rows for
  96 call sites; crash-hiding paths fixed in 18 gates.
- **Closed done:** #355 (rule-checker run `2026-11-02-1574`), #349 (`-1575`), #351 (`-1579`), #347 and #353 (`2026-11-03-1588`; the closure found and fixed the runner reading a failed staleness audit as an empty list).
- **Ruled:** #356 (Option 1, next session, the raw allocator); #345 (option A first, B held; runs `-1576` to `-1585`).
- **Filed:** #356, #357, #358, #359.
