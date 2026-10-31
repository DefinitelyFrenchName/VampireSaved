# NEXT SESSION — orientation (rewritten at the 14z-214 CLOSE, 2026-10-31)

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
**PILOT** (6 vCPU, 47 GB, Ubuntu 24.04, 64 GB free, 73% used; checked 14z-214 close) carries xdelta3, Node and `strace`. Its
checkout `~/vampire-saved` sits at `550958ad`. Deletable scratch, 1.6 GB: 14z-214's `~/t214a.bundle`, `~/t214b.bundle`,
`~/t214a_out`, `~/t214b_out`, `~/t214_tr`, `~/t214_tr2`, `~/t214s`, `~/t214s.tgz`, `~/t214_score.sh`, and the close's
`~/t214c.bundle`, `~/t214c_out`, `~/t214_tr3`, `~/t214c_score.sh`; older, not on any
list and left alone: `~/p211_*` and the refs `refs/tmp/f207-286rec`, `refs/tmp/f207-313`. **ERIS** (WSL2, 922 GB free)
runs the release shape; its checkout sits at `550958ad`; its scratch `~/e214_out`, `~/e214_order.tsv` and
`~/vampire-saved/build/emu_e214` is deletable. Neither profile sets
ROMDIR (`ROMDIR=~/roms`). Work handed to either is a bundle of a COMMIT (a bare commit-tree needs a temporary ref; delete
it after); a remote script goes over `ssh <host> 'wsl -e bash -s' < script` (ERIS) or `ssh pilot 'bash -s' < script`,
never as a quoted command line (Windows' shell splits it at a pipe), and a remote `pkill -f <pattern>` matches its own
shell: kill by PID from a stdin script.

**THE SESSION CLOSE:** `docs/project/session_close.md`, run by `python3 tools/close.py`. The run of record is named in
STATE 14z-214's CLOSE section. A red tier is re-run on THE RED RUN'S results (#317).

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
   **#341** (test_tickets' `parked-disagrees` went DEAD once the newest ticket closed) is fixed in the 14z-214 close commit
   and re-traced on PILOT: close it on its rule-checker run.
1. **#118 — THE REMAINING RIGS.** Done this sitting: B6 (Sasquatch's penguins, +0x36C) and rows B (+0x384, +0x3A8,
   +0x3BE/+0x3BF, +0x3B6's bit 7), each gated. Left, by the batch plan (`build/agent213/t118/batch_plan_draft.md`, local)
   and S0 (`build/agent213/t118/s0/S0_REPORT.md`, local: leads, not facts): +0x354 (Jedah's child-slot words; needs a
   slot-ownership rig), B1, B5, B7; and what rows B could not separate: a type-3 KO won by P1, a human winner's type-3
   KO, and finish types 2 and 4-7 (type 4 would show +0x3BF). S0 flags `docs/game/atlas/character_tables.md:76`
   ("14 tables", 15 measured): unchecked. Every conclusion a player could see goes to the maintainer on captures first;
   a chain of events gets a clip of every frame and a page per link.
2. **Clear PILOT's and ERIS's 14z-214 scratch** (the list above).
3. **Ask the maintainer for the order of work.** Open tickets (GitHub severity labels):
   - low: #341 (item 0), #118 (item 1), #310 (kept open 14z-213, **"Keep open (Recommended)"**: classifier rules 1-4 in; the 14z-210
     census's other shapes, deferred as "Record and defer", are its remaining work).
   - awaiting release: #338 (the proof sheets' web build; drawn and published at the next tagged release, which closes it;
     its comment says so).
   - parked: #123, #124, #125, #127, #128, #129, #162, #294.
   - **Before planning any freeze or release, read each open ticket's comments for a step that runs AT it.** #333's
     step (the 11 sites guarded after run 1366 in a release-shape emulator tier) ran on ERIS this sitting at `550958ad`:
     417 PASS, 0 FAIL, the 4 SKIPs the host's environment (STATE 14z-214 (5)).
4. **The next freeze or release** runs the six #229 gates only on demand, ERIS's tier takes `--skip test_mame_parity`,
   and the Mac runs parity (#321); it draws the proof sheets' web build (#338, `docs/project/release_format.md` «The proof
   sheets' web build»).

## PARKED (not open work)

- #124 and #294 (Killshread's aura palette, filed parked by the maintainer 2026-10-18).
- **VampireSaved-Rebuilt#1** holds what is left of #120, closed 14z-205.

## INSTRUMENT FACTS LEARNED THIS SITTING (read before the work they bear on)

- **A collector that groups records by a key drops a record with no key, silently** (`docs/project/gotchas.md`, #339):
  `tools/session_metrics.py` now stops on any ledger row no session claims; a correction to the append-only ledger goes
  in `tests/rulecheck/session_corrections.tsv` with its evidence.
- **A camera-follow rig can hide the subject:** Sasquatch at the left wall put his penguins off screen; check the camera
  shows the subject before the sheet goes out (B6, 14z-214).
- **The boot RAM test at PRG:0x000D34 fills work RAM at f15** (`docs/platform/gotchas.md`): a write tap over any
  work-RAM field sees it, so judge "no other writer" after the boot, as rows B's T3/T3b do.
- **The rule-checker's rounds on a RAM record catch wording the gate never measured** (1P/2P labels, a routine named as
  fact, a listed writer never checked to write, a confound by side): rows B took twelve runs.

## WHAT CLOSED THIS SITTING (14z-214)

- **Closed `done`** with their closing comments: #340 (rule-checker run `2026-10-30-1443`, OK, after `-1441`, `-1442`),
  #339 (`-1450`, OK, after `-1446`, `-1448`, `-1449`).
- **Filed and fixed in the close commit:** #341 (the close tier's one red).
- **Recorded and gated under #118** (kept open): B6 (`tests/audit_sas_penguin_count.sh`, run `2026-10-30-1445`) and rows B
  (`tests/audit_mizuumi_rows_b.sh`, run `2026-10-31-1464`).
- **Ruled** (`DECISIONS_HISTORY.md`, 14z-214 entries): the order; B6's first sheet "no", the chain as read, "yes"; #339
  "either is fine, just make it future proof", "no", "Extend #339 now"; the B6 read-back findings "CONTROL-PLANT",
  "CROSS-LEG"; the close "Both".
