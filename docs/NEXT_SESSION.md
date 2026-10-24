# NEXT SESSION — orientation (rewritten at the 14z-207 CLOSE, 2026-10-24)

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
**PILOT** (6 vCPU, 47 GB, Ubuntu 24.04) now carries xdelta3 3.2.0 and Node v24.22.1 user-local (`~/.local/bin`, ruled
2026-10-23) and has `strace`; its clone sits at `1c59a7cd` with a dirty `emu/fbneo`. **ERIS** (WSL2 and MSYS2) has a
source-built MAME at its pin (`C:\Users\Chaton\.cache\vampire-saved\mame\cps2.exe`), no xdelta3 and no node; its lane
folders were deleted 2026-10-24 (ruled). Neither profile sets ROMDIR (`ROMDIR=~/roms`). Work handed to either is a bundle
of a COMMIT ("When to commit"); a remote script goes over `ssh <host> 'wsl -e bash -s' < script` (nested quotes break).

**THE SESSION CLOSE:** `docs/project/session_close.md`, run by `python3 tools/close.py` (`start --key … --row - --prev
<results> --transcript <id>`, then `next`, `done`, `status`). The run of record is named in STATE 14z-207's CLOSE section.

**THE STATIC TIER CHANGED THIS SITTING (14z-207, #312, #315):** a gate's controls run as pool jobs of their own once the
gate's run ends (`tests/lib/static_pool.py`); for the 97 gates on `tests/controls_concurrent.txt` they run side by side,
chosen from a write trace of every control on Linux; `tests/test_controls_concurrent.sh` fails a listed gate whose script
changed since its trace ("re-trace it or take it off the list"). The re-trace is a freeze step (HANDOFF.md).

## START HERE

0. **AT THE OPENER, RUN `python3 tools/agent/sweep.py`.**
1. **THE FREEZE + RELEASE** — the maintainer's plan: *"the plan is to have a freeze+release as soon as we have a stable
   situation"* (2026-10-23). The release-only tickets #279, #280, #281 closed done 14z-207 (kept closed, ruled
   2026-10-24); #278 is measured but open (its comment of 14z-207). The freeze runs every gate with every control and,
   since #315, re-runs the controls' write trace (HANDOFF.md, before the tags). Ask the maintainer when.
3. **#304 item 2 (severity high)** — the snapshot without scratch: fork J found emulator-tier audits reading scratch-named
   directories (`audit_chains174` reads `build/agent185`), which item 2 must reclass first (STATE 14z-207 (4)).
4. **#229 — WAITING ON THE MAINTAINER, Q2 especially** (*"I still have answers to provide for Q2 especially"*,
   2026-10-21); everything is listed on #229 (comment of 2026-10-20) and in STATE_HISTORY 14z-205b (1)-(5).
   - **The work is LOCAL and UNTRACKED:** the six gates, their expectations, rigs and Lua (105 files,
     `build/agent205/t229/pending_gates_229.list`, backed up in `pending_gates_229.tar` beside it). Never `git clean`.
   - **The maintainer's docs (private):** questions https://claude.ai/artifact/88mHYGNsf1wyYZ2EFfzPCE, community
     cross-check https://claude.ai/artifact/Wfn7XUHignvbQphap3MwyK (#301). Read the questions doc for new answers first.
   - **Waiting:** Q1 for the rest of the specials, ES/EX, the guard cancels and the command throws
     (`build/agent205/t229/look_first_index.md`); Q2 (the four 14z-194 pursuit claims); Q4's (a) join or (b) leave
     unjoined; Q5, Q6, Q7; whether to comment on #301 that its vswiki "inputs no rig could make fire" are answered.
5. **#266 and #284 — done, awaiting release**: #266 closes when the next release's battery records
   `audit_release_linux_desktop` PASSING on PILOT (ask the maintainer to be logged in to PILOT's desktop first); #284 when
   the next release ships the new READMEs and `test_readme_recording` runs its Windows and Linux legs.
6. **#297 stays open until a freeze has run the 109 moved gates green**; a freeze runs every gate anyway.
7. **Then ask the maintainer for the order of work.** Open tickets by GitHub severity label:
   - high: #304;
   - medium: #284;
   - low: #118, #229, #244, #301, #305, #306, #310, #311 (and #129, parked);
   - no severity label: #266, #278 (release-only), #289, #297, #302, #307;
   - parked: #121, #123, #124, #125, #127, #128, #162, #170, #267, #294.
8. **`tests/replays/118_chain.rpl`'s header names a leg of `audit_mizuumi_inputs` that gate never ran** (STATE_HISTORY
   14z-198 finding (i)); the one-line correction rides a session that runs the emulator gates following `tests/replays/`.

## PARKED (not open work)

- #124 and #294 (Killshread's aura palette, filed parked by the maintainer 2026-10-18), and #121.
- **VampireSaved-Rebuilt#1** holds what is left of #120, closed 14z-205.

## INSTRUMENT FACTS LEARNED THIS SITTING (read before the work they bear on)

- **A trace taken where a gate SKIPs scores the skip, not the gate** (#286, #315; `docs/project/gotchas.md`): 15 gates
  SKIPped and 8 printed no verdict under ERIS's strace, and four jtcores gates were listed as concurrency-safe from empty
  traces; one of them shares 340 written paths. Trace each gate where it runs, and name the host.
- **macOS `mktemp -d` with no template ignores `TMPDIR`** (`docs/platform/gotchas.md`): contain a temp folder by passing
  it explicitly; a fresh-`TMPDIR` census on Linux does not stand for the Mac.
- **xdelta3 3.0.11 writes verbatim reference-ROM runs where 3.2.0 copies** (#279, `docs/project/gotchas.md`): rule 7
  depends on the encoder's version; the packager refuses anything older than 3.2.0.
- **A synthetic fixture string can trip a static census**: `test_mame_bin_pinned` read the new `test_tmp_hygiene`'s
  sample call `run_replay_guarded.sh vsavjw …` as an unpinned boot and failed the first tier of the third commit.
- **The rule-checker caught real gaps before every closure this sitting**: #286 (runs `1215`-`1225`), #303 (`1220`-`1235`),
  #279-#281 (`1230`-`1233`, the "3.0.11" refused was a fake until PILOT's real binary was run), #312/#315
  (`1237`-`1242`, eight rounds: the serial reference ran older code, 18 listed gates never passed on ERIS, no trace on
  macOS). Give a closure packet the evidence for every clause, and run the real thing, not a stub, when the claim
  names it.

## WHAT CLOSED THIS SITTING (14z-207)

- **Closed `done`:** #291, #308, #313, #314, #286, #303, #279, #280, #281, #312, #315.
- **Filed:** #314, #315. **Ruled** (`DECISIONS_HISTORY.md`, 2026-10-23 and 2026-10-24 entries): #291's S4-D moments,
  #314 severity low, #304's four recommendations and 12 planner processes, the poke read-back classes, the PILOT and
  ERIS lanes, #286's precision cost, PILOT's release tools and `/tmp`, #303's audits cleaning up, #298's middle option,
  #312's census gate, ERIS's folders deleted, #279-#281 kept closed.
- **Five commits** this sitting (`23856367`, `bbeedfed`, `031c09d8`, `723b148f`, and the close's), the last pushed with
  the close.
