# NEXT SESSION — orientation (rewritten at the 14z-217 CLOSE, 2026-11-02)

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
idle`). Its checkout `~/vampire-saved` sits detached at the M24 freeze commit `be40e6f3`: move it to `main` before other work.
Deletable scratch: 14z-216's `~/rt216*` (12 GB, the re-trace), `~/m24_*`, `~/pilot_m24*.sh`, `~/pilot_emu*.sh`,
`~/pilot_rows216.sh`, `~/rows216*`, `~/t216_*`; 14z-217's `~/proof_sheets/` (the host proof-sheet run), `/tmp/emu_p217_*.tgz`,
and in `~/vampire-saved/build/`: `emu_p216_*`, `emu_p217_*`, `emu_p217_desk_fail1`, `desktop_release_fail1` (all copied to the Mac).
**ERIS** (WSL2, 24 threads, 47 GB) runs the release shape; its checkout sits at `be40e6f3`. Deletable: 14z-216's `~/rt216*`,
`~/psw216*`, `~/lad216*`, `~/e216*`, `~/eris_*216.sh`, `~/s5.bundle`, `~/freeze216.bundle`, `~/c329c.bundle`, `~/c333a.bundle`,
`~/t215b.bundle`; 14z-217's `~/rel216_out`, `~/vampire-saved/build/emu_rel216_eris` (copied to the Mac), and on the Windows side
`C:/Users/chaton/m22logs/{tree217.tgz,t217,emu_rel216_eris.tgz}`. Neither profile sets
ROMDIR (`ROMDIR=~/roms`). Work handed to either is a bundle of a COMMIT (a bare commit-tree needs a temporary ref; delete
it after); a remote script goes over `ssh <host> 'wsl -e bash -s' < script` (ERIS) or `ssh pilot 'bash -s' < script`,
never as a quoted command line (Windows' shell splits it at a pipe and mangles quotes), and a remote `pkill -f <pattern>`
matches its own shell: kill by PID, or by session (`pkill -KILL -s <sid>`), from a stdin script.

**THE SESSION CLOSE:** `docs/project/session_close.md`, run by `python3 tools/close.py`. The run of record is named in
STATE 14z-217's CLOSE section. A red tier is re-run on THE RED RUN'S results (#317).

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
1. **#310 — THE CRASH-INJECTION SWEEP** (the maintainer, 14z-215: **"Next session, first batch (Recommended)"**; it was
   item 2 behind the release at 14z-216 and 14z-217). Discovery ran over the 20 static gates at 14z-216 (STATE_HISTORY
   14z-216 (2), `build/agent216/t310/FINDINGS.md`, local: every runner mode PROVEN but one LIES; F1 `test_agent_hooks`'
   twins); the gate is not built. Its seed is `build/agent215/t310/rcmeas/measure.sh` (local). Then group 7's first batch.
2. **Clear PILOT's and ERIS's scratch** (the lists above): deletions, so put the lists to the maintainer first.
3. **Ask the maintainer for the order of work.** Open tickets (GitHub severity labels):
   - bugs: #345 (Blizzard Sword overrun), #347 (`--stale --freeze` refuses NOTE-class names), #349 (REFUSED control runs
     read SAFE), #351 (`proof_sheets run --host` and freeze-tag control builds), #353 (`--log` on an existing directory
     appends: the 14z-213 gotcha, paid again); evolution: #348 (no tracked-release-vs-build gate), #352 (the desktop gate's
     paused-FBNeo verdict), #354 (no gate on #294's dead span in the built image); cosmetic: #344 (Donovan's Dark Force
     colours), #346 (the Blizzard Sword ice streak); low: #310 (item 1).
   - parked: #123, #124, #125, #128.

## PARKED (not open work)

- #124 (Killshread's aura palette), #123, #125, #128 (Marionette, parked again 14z-216).
- **VampireSaved-Rebuilt#1** holds what is left of #120, closed 14z-205.

## INSTRUMENT FACTS LEARNED THIS SITTING (read before the work they bear on)

- **GNU `timeout` without `--foreground` takes the terminal from its command** (`docs/platform/gotchas.md`): an ssh
  password prompt never shows and Ctrl+C does not reach it. A bounded command that may prompt runs under `--foreground`.
- **FBNeo's SDL build pauses when its window loses focus** (`emu/fbneo/src/burner/sdl/run.cpp:456`): a desktop run on a
  session the maintainer is using can go red with PAUSE on every capture (#352). Re-run on a quiet session.
- **`gh issue view N --comments` prints only the comments**: for an issue with none it prints nothing. Save an issue's text
  for a packet with `gh issue view N` (rule-checker run `2026-11-02-1570`).
- **A release closure's packet needs the published bytes, not the tree's**: download the assets back and compare them
  with the freeze commit, apply EVERY package to the dumps, and list in each closing comment every NOT COVERED item and
  frozen-blind census part of each gate it cites (rule-checker runs `2026-11-02-1561` to `-1566`, six rounds).
- **A control that fires on an early failure is dead**: #350's first `no-foreground` copy failed before reaching its
  upload and still read FIRED; a control now has to show it reached the code it perturbs.

## WHAT CLOSED THIS SITTING (14z-217)

- **Released:** M24, `freeze/merged-m24` on GitHub from `be40e6f3` (9 assets; merged-m23's pruned); the proof sheets at
  alexrichard.org/vs-proof-sheets/.
- **Closed done:** #127, #162, #294 (rule-checker run `2026-11-02-1566`), #338 (`-1569`), #350 (`-1572`).
- **Filed:** #350, #351, #352, #353, #354.
