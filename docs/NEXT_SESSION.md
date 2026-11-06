# NEXT SESSION — orientation (rewritten at the 14z-221c CLOSE, 2026-11-06)

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
idle`). Idle at the 14z-221c close, its checkout `~/vampire-saved` on `a152efa7` (`main` before this close; the scratch refs
`refs/scratch/t359` and `refs/scratch/t221c` deleted): move it to the new `main` before other work. **ERIS** (WSL2, 24 threads,
47 GB) runs the release shape; reached all of 14z-221c, its checkout `~/vampire-saved` on `a152efa7`: move it to `main` first. Neither profile sets ROMDIR (`ROMDIR=~/roms`). Work handed to either is a bundle of a COMMIT (a bare
commit-tree needs a temporary ref; delete it after); a remote script goes over `ssh <host> 'wsl -e bash -s' < script` (ERIS)
or `ssh pilot 'bash -s' < script`, never as a quoted command line (Windows' shell splits it at a pipe and mangles quotes), and
a remote `pkill -f <pattern>` matches its own shell: kill by PID, or by session (`pkill -KILL -s <sid>`), from a stdin script.

**THE SESSION CLOSE:** `docs/project/session_close.md`, run by `python3 tools/close.py`. The run of record is named in
STATE 14z-221c's CLOSE section. A red tier is re-run on THE RED RUN'S results (#317).

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
1. **#357 AND #363 ARE STAGED FOR THE NEXT FREEZE** (`build/manifest/staged/357_363.patch`; STATE 14z-221c (1), (2)).
   The maintainer confirmed both on captures (#357: *"looks identical"*; #363: *"Demitri is frozen indeed"*). The freeze
   applies the patch and must: re-extract Donovan (`build/m5_wide/extract`); re-freeze `test_tenant_loop` (op counts
   donovan 360 -> 363, huitzil 381 -> 384, two tenants 642 -> 648, three tenants 855 -> 861, measured on the scratch builds);
   carry #363's row of `tests/expected/dead_span_reach.tsv` (it is in the patch). Until then `tests/audit_guard_orbs.sh` and
   `tests/audit_beam_slide.sh` are RED against the frozen builds (both are frozen on the scratch build `build/agent221c/m34x`,
   local). #358 closes with #363 (the maintainer, 2026-11-05: *"#358 can be closed when we close #363"*). Ask the
   maintainer when to freeze; the M25 release (item 2) is separate.
2. **THE M25 RELEASE, WHEN THE MAINTAINER ASKS FOR IT** (M25 frozen 14z-220 at `91bde83b`, tags `freeze/donovan-m29`,
   `freeze/huitzil-m36`, `freeze/pyron-m30`, `freeze/merged-m25`; `release/merged-m25` packaged). #345, #346 and #356 carry
   done-awaiting-release comments and close with that release.
3. **#310 — GROUP 7, BATCH 3** (batches 1 and 2 landed, 43 rows: `tests/test_dead_leg_unjudged.sh`, STATE 14z-221c (5)).
   Left: the six held out (four MiSTer gates needing verilator, `test_release_roundtrip`, `audit_stock_emulator_stall`
   on `MAME_REF_BIN`), podman's, the 14 two-mode gates on the concurrent list, and every gate with three or more modes
   (`build/agent215/t310/census57/group7.tsv`, local). A row's dead instrument goes in the table's fifth column; the gate
   then runs its mode with only that instrument dead.
4. **A FINDING TO PUT TO THE MAINTAINER (not yet a ticket): under dash an EXIT-only trap does not run on TERM**
   (`docs/platform/gotchas.md`, measured on the Mac's dash; PILOT's `/bin/sh` is dash). About 277 scripts carry an
   EXIT-only trap and would leave their work directories behind when TERM'd on PILOT. Ask whether to file it.
5. **Ask the maintainer for the order of the rest.** Open tickets (GitHub severity labels): bugs: #345 (frozen, awaits the
   release), #363 (staged, item 1); evolution: #348, #352; cosmetic: #344, #346, #356 (frozen, await the release), #357
   (staged, item 1), #358 (closes with #363), #360; test-integrity: #310. Parked: #123, #124, #125, #128.

## PARKED (not open work)

- #124 (Killshread's aura palette), #123, #125, #128 (Marionette, parked again 14z-216).
- **VampireSaved-Rebuilt#1** holds what is left of #120, closed 14z-205.

## INSTRUMENT FACTS LEARNED THIS SITTING (read before the work they bear on)

- **`tools/audit_dead_span.py` reads six rules now** (A, C, T, D, R, L; its header): D and R look 0x100 to BOTH sides of a
  base (an index may be negative), R takes a base of either parity and `adda.l`/`addi.l #imm`, the fence judges every
  reached instruction ending at the span start and refuses a straddler, and an accepted base or row is bound to its named
  sites (`BASE@SITE/SITE`). The 68000's bus has 24 bits: an operand is read with its top byte ignored, a data long counts with top byte 0x00 or
  0xFF (a full mask of every long finds chance hits in random data). Each listed instruction form has a control in `tests/test_dead_span_reach.sh`: capstone names
  `lea`/`pea` as `lea.l`/`pea.l`, and an exact-name test that never matched once hid every such base.
- **A capped data region can cut a table off** (`docs/project/gotchas.md`): Donovan's `hitbox_proj` copy (0x1000) ended
  inside vs2's motion table `0x0D1BBE`, so the guard orbs read our own code bytes; a per-piece diff found it where totals
  were equal.
- **A cleanup trap is `trap '<cleanup>' EXIT; trap 'exit 130' INT; trap 'exit 143' TERM`** (#359;
  `tests/test_signal_traps.sh` refuses any other stopping-signal trap).
- **A dead-leg proof for a non-MAME leg** puts the instrument in `tests/expected/dead_leg_unjudged.tsv`'s fifth column; the
  gate also runs that mode with only that instrument dead and MAME_BIN unset.
- **A heredoc delimiter inside a python heredoc ends the shell heredoc early**: write such scripts to a scratch file.

## WHAT CLOSED THIS SITTING (14z-221c)

- **Closed done:** #354 (the built-image reach gate; rule-checker run `2026-11-06-1679`), #359 (the split traps and
  `tests/test_signal_traps.sh`; run `2026-11-06-1673`).
- **Staged for the next freeze:** #357 (the guard orbs) and #363 (the freeze reaction), both confirmed by the maintainer on
  captures.
- **#310 group 7 batch 2:** 18 rows over 12 gates, run `2026-11-06-1668`; progress comment on #310.
- **The four emulator gates this sitting changed** re-traced SAFE on PILOT (`tests/controls_concurrent_emu.txt`).
