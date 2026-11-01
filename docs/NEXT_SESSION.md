# NEXT SESSION — orientation (rewritten at the 14z-216 CLOSE, 2026-11-01)

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
drives (the maintainer logs in). Its checkout `~/vampire-saved` sits at S4 `d1aed6a8` with a SCRATCH tag
`freeze/merged-m24` (S4, never pushed): **delete it before PILOT fetches tags** (`git tag -d freeze/merged-m24`), then move the
checkout to `main`. Deletable scratch (14z-216): `~/rt216*` (12 GB, the re-trace), `~/m24_*`, `~/pilot_m24*.sh`,
`~/pilot_emu*.sh`, `~/pilot_rows216.sh`, `~/rows216*`, `~/t216_*`, `~/vampire-saved/build/emu_p216_*` (copied to the Mac).
**ERIS** (WSL2, 24 threads, 47 GB) runs the release shape; its checkout sits at the freeze commit `be40e6f3`, RUNNING the M24
release emulator tier (below) — leave `~/rel216_out` and `~/vampire-saved/build/emu_rel216_eris` until the release is
recorded. Deletable (14z-216): `~/rt216*`, `~/psw216*`, `~/lad216*`, `~/e216*`, `~/eris_*216.sh`, `~/s5.bundle`,
`~/freeze216.bundle`, `~/c329c.bundle`, `~/c333a.bundle`, `~/t215b.bundle`. Neither profile sets
ROMDIR (`ROMDIR=~/roms`). Work handed to either is a bundle of a COMMIT (a bare commit-tree needs a temporary ref; delete
it after); a remote script goes over `ssh <host> 'wsl -e bash -s' < script` (ERIS) or `ssh pilot 'bash -s' < script`,
never as a quoted command line (Windows' shell splits it at a pipe and mangles quotes), and a remote `pkill -f <pattern>`
matches its own shell: kill by PID, or by session (`pkill -KILL -s <sid>`), from a stdin script.

**THE SESSION CLOSE:** `docs/project/session_close.md`, run by `python3 tools/close.py`. The run of record is named in
STATE 14z-216's CLOSE section. A red tier is re-run on THE RED RUN'S results (#317).

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

0. **AT THE OPENER, RUN `python3 tools/agent/sweep.py`.** ERIS's release tier (item 1) is this session's own process,
   left running on purpose: declare it, never kill it.
1. **THE M24 RELEASE, FIRST** (the maintainer, 14z-216: close first, then release — *"plan accepted. proceeed"*). M24 is
   frozen at `be40e6f3` (tags `freeze/donovan-m28`, `huitzil-m35`, `pyron-m29`, `merged-m24`; STATE 14z-216 (1b)). The
   release's tiers run on THAT commit (ruled 14z-208, `docs/project/release_format.md` "The release run on the freeze's
   tree"), through `tests/run_on_snapshot.sh --commit be40e6f3…`, whatever the close committed after it. In order:
   1. **ERIS's emulator tier**, started 2026-11-01 22:24 CET: `~/rel216_out/meta.txt` (its end line), `~/rel216_out/run.log`
      (the GREEN line), results in `~/vampire-saved/build/emu_rel216_eris/`. Read every red; bring the run dir to the Mac.
   2. **THEN the host-covered gates** (never before ERIS ends: the newest row wins): the Mac's `test_mame_parity`,
      `test_release_binaries`, `test_readme_recording` and its MiSTer lane with `--controls`; PILOT's
      `audit_release_linux_desktop` (the maintainer logged in) and `audit_release_linux_cleanhost`, one after the other,
      `RELEASE=merged-m24`, on a checkout of `be40e6f3`.
   3. **The static release tier** on a snapshot of `be40e6f3`: `--strict --cadence release --reuse
      build/agent216/m24/static_freeze_results_s5.tsv` (the freeze run of record, the same tree).
   4. **The Windows half of `test_release_launcher_bat`** on ERIS (release cadence).
   5. **The proof sheets (#338):** a local run of `be40e6f3` (`tools/proof_sheets.py run`), `web`, then
      `tools/publish_sheets.sh --dry-run` and, on the maintainer's word, the real publish (by hand: ssh asks for the
      password; `DEPLOY_TARGET` is the maintainer's site deploy's).
   6. **Publish** on the maintainer's word: the assets (`tools/upload_release_assets.sh freeze/merged-m24`), the GitHub
      release; then close #127, #162, #294 and #338 with the release (each has its done-awaiting-release comment).
   **Before it, read each open ticket's comments for a step that runs AT a release.**
2. **#310 — THE CRASH-INJECTION SWEEP** (the maintainer, 14z-215: **"Next session, first batch (Recommended)"**). Discovery
   ran over the 20 static gates this sitting (STATE 14z-216 (2), `build/agent216/t310/FINDINGS.md`, local: every runner mode
   PROVEN but one LIES; F1 `test_agent_hooks`' twins); the gate is not built. Its seed is
   `build/agent215/t310/rcmeas/measure.sh` (local). Then group 7's first batch.
3. **Clear PILOT's and ERIS's scratch** (the lists above), PILOT's scratch tag first.
4. **Ask the maintainer for the order of work.** Open tickets (GitHub severity labels):
   - awaiting release: #127, #162, #294, #338 (item 1).
   - bugs: #345 (Blizzard Sword overrun), #347 (`--stale --freeze` refuses NOTE-class names), #349 (REFUSED control runs
     read SAFE); evolution: #348 (no tracked-release-vs-build gate); cosmetic: #344 (Donovan's Dark Force colours),
     #346 (the Blizzard Sword ice streak); low: #310 (item 2).
   - parked: #123, #124, #125, #128.

## PARKED (not open work)

- #124 (Killshread's aura palette), #123, #125, #128 (Marionette, parked again 14z-216).
- **VampireSaved-Rebuilt#1** holds what is left of #120, closed 14z-205.

## INSTRUMENT FACTS LEARNED THIS SITTING (read before the work they bear on)

- **GNOME 46's first `xwininfo -tree` line naming a window is its FRAME** (`docs/platform/gotchas.md`): focusing it takes
  focus from the game since mutter `.18` (FBNeo pauses); `tools/desktop_session_play.py` targets the client window.
- **A byte-plant control that writes a constant is dead where the byte already holds it** (`docs/project/gotchas.md`):
  invert, and `cmp` the copy before reading DEAD.
- **A re-point sweep rewrites quoted records**, and the attribution tool's 8-byte window misses straddling pointers
  (`docs/project/gotchas.md`, 14z-216).
- **The concurrent-controls scorer reads an all-REFUSED gate SAFE** (#349): classify every traced log with
  `tests/lib/classify.sh` and certify only HONOURED runs.
- **`run_all_emulator.sh --stale --freeze`** refuses on NOTE-class names (#347): `--skip` each one meanwhile.
- **No gate ties a tracked release to its build** (#348): for M24 it was checked directly,
  `build/agent216/m24/rc_freeze/relid/` (local).

## WHAT CLOSED THIS SITTING (14z-216)

- **Frozen:** M24 at `be40e6f3` ((M) for #127/#162, #294's per-frame routine); freeze rule-checker run `2026-11-01-1560`.
- **Ruled** (`DECISIONS_HISTORY.md`, 14z-216 entries): (M) and #294's implementations; #294's lag frame accepted, then
  re-confirmed as a tradeoff; #345's rows exempt; the 45-row re-trace; the ERIS half accepted and the split clarified;
  #338's publisher by hand.
- **Filed:** #344, #345, #346, #347, #348, #349.
