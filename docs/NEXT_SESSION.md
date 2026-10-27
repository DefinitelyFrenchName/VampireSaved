# NEXT SESSION — orientation (rewritten at the 14z-210 CLOSE, 2026-10-27)

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
STATE 14z-210's CLOSE section. A red tier is re-run on THE RED RUN'S results (#317).

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
1. **Ask the maintainer for the order of work.** Open tickets (GitHub severity labels):
   - medium: none.
   - low: #118, #310 (the UNJUDGED census; deferred, ruled "Record and defer"), #329 (minimal half-circle inputs), #330
     (the throws' recovery and throw tech), #333 (106 gate scripts carry on after a failed `mktemp -d`), #334 (#321's
     remainder: the job knobs on PILOT and under load; the knob-less gates' survey);
   - parked: #123, #124, #125, #127, #128, #129, #162, #267, #294.
   - **Before planning any freeze or release, read each open ticket's comments for a step that runs AT it.**
2. **The next freeze or release** runs the six #229 gates only on demand, ERIS's tier takes `--skip test_mame_parity`,
   and the Mac runs parity (#321).

## PARKED (not open work)

- #124 and #294 (Killshread's aura palette, filed parked by the maintainer 2026-10-18).
- **VampireSaved-Rebuilt#1** holds what is left of #120, closed 14z-205.

## INSTRUMENT FACTS LEARNED THIS SITTING (read before the work they bear on)

- **In `sh`, every pooled subshell shares the parent's `$$`** — a scratch file named by it is shared, and two workers
  finishing together remove each other's (#321; `tests/lib/measures.sh`). Name scratch with `mktemp`, or keep it in a
  here-document.
- **A check that counts what is wrong reads "ok" on an empty input** (`docs/project/gotchas.md`, #331): hold a set to its
  expected members first.
- **A builtin `printf`/`echo` into `grep -q` can print the shell's write error** when SIGPIPE is ignored
  (`docs/platform/gotchas.md`, #327).
- **MAME 0.288's change-notifier teardown crash** is stopped by the committed pin (0 of 30 against 30 of 30 under forced
  GC; `docs/platform/gotchas.md`, #320).
- **`git describe --dirty` takes `.git/index.lock` even under `GIT_OPTIONAL_LOCKS=0`** (git 2.43); two control modes
  running it at once collide (#321; `audit_release_linux_cleanhost`'s head line now lock-free).
- **The rule-checker on eleven closures and one freeze** (runs `2026-10-27-1334` to `-1351`): it found a scratch pin
  measured instead of the committed one, a lint whose census used the fix's own regex, "loaded" control runs that had no
  load, carried tier rows read as executed, and a freeze checked only against its own hash. Each was answered with a
  new measurement before the closure.

## WHAT CLOSED THIS SITTING (14z-210)

- **Closed `done`:** #321 (remainder #334), #331, #318, #328, #320, #311, #327, #332 — each on its rule-checker run with
  its closing comment. **Filed:** #332, #333, #334.
- **Ruled** (`DECISIONS_HISTORY.md`, 14z-210 entries): #321 reopened with all four avenues; the PILOT write trace for
  emulator controls; longest first; the merged-legacy queue; #310 "Record and defer"; #332 "File and fix now"; #331's rig
  and "Enough, integrate"; "Signatures -> DIED"; "Runner sets disk TMPDIR"; #333 "File a ticket"; #320 closes on the 139
  gates; #328 waits for a clean-clone run; #321 "Close; file the remainder".
