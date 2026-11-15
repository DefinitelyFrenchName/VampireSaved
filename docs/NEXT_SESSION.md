# NEXT SESSION — orientation (rewritten at the 14z-228 CLOSE, 2026-11-15)

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
- **WHEN TO COMMIT (ruled 2026-10-17):** only at a ticket closure, a freeze or release, work handed to PILOT or ERIS, or the close. Before EVERY tier, regenerate the generated files and run the bookkeeping gates the change touches — THE WHOLE LIST in `docs/project/working_methods.md` ("Before every tier"), not a remembered subset: 14z-223's tier went red on three of them (`test_must_fire_census`, `test_gate_descriptions`, `test_expectation_provenance` for a new gate and table) — IN A CLEAN CHECKOUT of the staged tree (`git worktree add --detach` of a commit-tree object): the main tree holds #229's untracked gates, which break the generators.
- **#369's rule is live (`23ccb65c`):** a control mode is HONOURED only on a `CONTROL CAUGHT: <mode> — ` line printed
  by `vs_ctl_caught <file> <ERE>` (`tests/lib/controls.sh`), unless its gate is on `tests/expected/ctl_caught_debt.tsv`
  (99 rows since 14z-227, shrink-only; #369 and #310 CLOSED with them left as #369's stated limit, so no batch migrates
  them, and a listed gate migrated for its own reasons leaves the list in that commit, as `audit_guard_corpus` did for
  #373). A NEW gate with control modes calls the helper; it cannot join the list
  (`tests/test_ctl_caught_lint.sh`). The literal may not appear in any other code file under `tests/` or `tools/`, comments
  included (`docs/project/must_fire_contract.md` § #369).
- **Never edit a script while it runs** ([MJC-54]); the emulator runner reports a tracked file changed during its run.

Say so at the opener. Never spawn any agent at `max`. A recommendation leans only on the maintainer's OWN words.
**PILOT** (6 vCPU, 47 GB, Ubuntu 24.04) carries xdelta3, Node, `strace`, podman and the GNOME session the desktop gate
drives (the maintainer logs in; it locks after 5 min idle, and a desktop run goes under `gnome-session-inhibit --inhibit
idle env --default-signal=PIPE`: the inhibitor alone leaves SIGPIPE ignored for every child, gotchas.md, 14z-223). It crashed
once on 2026-11-08 (no shutdown record; the maintainer brought it back). Idle at the 14z-228 close, its checkout
`~/vampire-saved` detached at scratch `5d2a87ff` (= `b072551c` + the dead-leg cap; fetch `main` first); its disk 94 G of 249 G used after the 14z-227 cleanup of our old
scratch directories (feedback memory `pilot-disk-cleanup-before-runs`). **ERIS** (WSL2, 24 threads, 47 GB) runs the release
shape; its checkout `~/vampire-saved` detached at `b072551c` (fetch first). Hold an ERIS run's ssh open
(`ssh eris 'wsl.exe -u koneko -- bash …'`): WSL shuts the distro down when the last session ends (gotchas.md, measured on
ERIS 14z-226). Neither profile sets ROMDIR (`ROMDIR=~/roms`). Work handed to either is a bundle of a COMMIT (a bare
commit-tree needs a temporary ref; delete it after); a remote script goes over `ssh <host> 'wsl -e bash -s' < script` (ERIS)
or `ssh pilot 'bash -s' < script`, never as a quoted command line (Windows' shell splits it at a pipe and mangles quotes), and
a remote `pkill -f <pattern>` matches its own shell: kill by PID, or by session (`pkill -KILL -s <sid>`), from a stdin script.

**THE SESSION CLOSE:** `docs/project/session_close.md`, run by `python3 tools/close.py`. The run of record is named in
STATE 14z-228's CLOSE section. A red tier is re-run on THE RED RUN'S results (#317).

**THE EMULATOR RUNNER SINCE 14z-210 (#321, `docs/project/operations.md`):**
- **Declared shares (#370 stage 1, `df4b0902`):** every gate carries one `# SHARES:` line; the emulator runner runs a
  gate's controls side by side only when its line is `none`; the two concurrent-controls lists are retired. The two Linux
  desktop gates claim the desktop session (`tests/lib/desktop_session.sh`) and run alone; `audit_dead_leg_linux` runs
  AFTER the two Linux release gates at release.
- **`--order <an earlier run>/results.tsv`** starts a pooled lane longest first.
- **Temp files on disk:** unless the caller set `TMPDIR`, a run's gates write under
  `${XDG_CACHE_HOME:-$HOME/.cache}/vampire-saved/tmp/emu_<stamp>.<pid>/`, outside the repo since 14z-227 (#372; removed at
  the end); the run refuses to start with under 10 GB free there (`VS_TMP_MIN_GB`).
- **A gate naming a shared token runs alone (#370, 14z-227):** in a pooled lane a gate whose `# SHARES:` line names a
  token of `tests/shares.tsv` is held back and run after the pool, one at a time.
- **Every gate runs through design R since 14z-226 (`7b5938e9`, `tests/lib/session_run.py`):** its own session and a
  `gate.*` TMPDIR; what is left when it returns is TERMed, up to `REAP_WAIT` (10) s, then KILLed, and the TMPDIR removed;
  a TERM, INT or HUP to the runner reaches the gate's session. A child that starts its own session escapes the reap, and
  `tools/trace_controls.sh`, the static lanes and manual runs are not wrapped (`docs/project/operations.md`).
- **Three verdict holes closed:** a control mode stopped by its host (full disk, failed mktemp) is DIED, never HONOURED;
  a selected gate, or a passing gate's declared control, with no row is a FAIL ("LOST"); `tests/lib/measures.sh` no longer
  shares a scratch file across pooled subshells. **Before trusting a runner change, run its gate on PILOT as well as the
  Mac** — the `$$` race showed only on Linux.
- **ERIS's release shape:** `--scope all --strict --controls --jobs 6 --skip test_mame_parity [--reuse <freeze run>]
  --order <the previous release's results>` (14z-208b: about 2 h 12 min at `--jobs 8` with reuse; `--jobs 8` pushed one
  MAME control past half its cap, #321; 14z-228 without reuse: 3 h 39 min, PASS 458). A write trace may be SPLIT across Linux machines, each running nothing else
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
1. **Ask the maintainer what comes next.** One ticket is open: evolution #348 (no gate checks that a tracked
   `release/<name>` is the package of its build; estimated 14z-228 at 2.5 to 4 active hours, ruled "Not now"). #352
   closed done on the 14z-228 release run; #360 closed declined. Parked: #123, #124, #125, #128, #344.
2. **Before more harness hardening, show its measured cost** (feedback memory `hardening-cost-vs-benefit`): #310's family
   took 35.65 to 40.49 active hours over 22 transcripts (STATE_HISTORY 14z-227 § (1)). Offer stopping or a
   time budget with any new hardening item.

**THE STANDING LESSON OF 14z-223** (feedback memory `step-back-before-patch-series`, gotcha "A FIX THAT LISTS THE WRONG
ANSWERS NEVER FINISHES"): at every batch boundary of a multi-batch ticket, if the next batch repeats a patch family, write
the one-paragraph alternative design and ask before starting it.

## PARKED (not open work)

- #124 (Killshread's aura palette), #123, #125, #128 (Marionette, parked again 14z-216).
- #344 (cosmetic; cause found 14z-228 and widened to all three tenants, kept parked on "Record cause, keep parked").
- **VampireSaved-Rebuilt#1** holds what is left of #120, closed 14z-205.

## INSTRUMENT FACTS LEARNED THIS SITTING (read before the work they bear on)

- **A host-only gate's runtime is judged only where its record lands** (`docs/project/gotchas.md`, 14z-228):
  `audit_dead_leg_linux`'s cap was registered at 0.56 of its measured runtime and no record reached the Mac until the
  release, whose static tier then FAILed the half-cap rule. A cap moved in `tests/ci_emulator.tsv` stales that gate (the
  registry is judged per row, every column), so the fix costs a re-run of the gate and of the static release tier.
  Set a cap at measured × more than 2, rounded up to the hour, the day it is measured.
- **The desktop gate cuts its assets with `tools/upload_release_assets.sh --dry-run`**; it does not download the
  published ones.
- **`tools/close.py start` needs `--row "(none — no findings table since #288)"`** when STATE's newest group has no
  findings-table section (every close since #288).

## WHAT HAPPENED THIS SITTING (14z-228)

- **Committed:** `b072551c` (#360's mechanism and closure, #344's cause, #348's estimate); the close commit carries the
  release run's records, #352's row and the dead-leg cap (3600 to 7200 s).
- **Ruled:** "Not now" (#348); "Record and close declined" (#360); "Check Phobos/Pyron first", then "Record cause, keep
  parked" (#344); "Release run, no new assets" and "Continue in this session" (`DECISIONS_HISTORY.md` 14z-228).
- **The release run** (no upload; M26 stays the release): every emulator lane with controls GREEN on ERIS, PILOT and the
  Mac; the static release tier PASS 244, FAIL 0, SKIP 1 (the launcher's Windows half, PASS on ERIS) at scratch `5d2a87ff`
  after the cap fix (STATE 14z-228 § (4)).
- **Closed:** #360 (declined), #352 (done). Commented: #344, #348.
