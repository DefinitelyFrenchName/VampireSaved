# NEXT SESSION — orientation (rewritten at the 14z-192 CLOSE, 2026-10-06)

> Rewritten at every session close ([VSP-17]). ROLLOVER: the previous opener
> moves VERBATIM to the top of `NEXT_SESSION_HISTORY.md` — this file holds ONLY
> the live orientation. Session state, not knowledge: facts belong in the docs,
> status in STATE.md.

## THE SETUP, RESTATED

A plain **Opus 5.5 session at effort High** (the ruled orchestrator — STATE 'Standing rulings') on the
#172 setup: every quoted figure from a `measurer` / `reader` spec (`docs/project/worker_spec.md`, the spec
text IN the prompt, no model), every freeze and recommendation through the pinned `rule-checker` with the
prompt files pasted VERBATIM, `record --session`, `resolve` on ONE line with one label per violated question
(never chained with the next `prepare`). Say so at the opener. Never spawn any agent at `max`.
A recommendation leans only on the maintainer's OWN words. When no ruling covers it, ask plainly instead.
**Before any long job, check whether PILOT (`ssh pilot`) or ERIS (`ssh eris`) is idle and run independent
work there in parallel.**

## START HERE

0. **AT THE OPENER, RUN `python3 tools/agent/sweep.py`.** M23 is FROZEN (`c884e6d8`, tags
   `freeze/donovan-m27`, `huitzil-m34`, `pyron-m28`, `merged-m23`; STATE 14z-192 row (13)) and carries Phobos's air-dash
   minimum and the vs2 landing sounds, with the small tickets. What the close found and did is in its CLOSE row.
1. **THE NEXT RELEASE carries M23** with #214 and #227 (both fixed in the generator; `release/merged-m23/` is
   packaged, and its Windows launcher half PASSed on ERIS). The release itself is the maintainer's call; when it is
   made, #214 and #227 close with it.
2. **#129 — RE-CHECK THE WORKER'S REPORT, THEN PUT THE DECISION** (STATE 14z-192 row (10);
   `build/agent192/r129/REPORT_handback.md`). It names two vs2 CPU-AI behaviours our build lacks: a Phobos-only guard
   in the in-move continuation check (vs2 `0x2D374`) and a low-attack crouch-guard stance test (vs2 `0x2CD38`, five
   call sites). The orchestrator has NOT re-checked the report. Re-check it, then measure each behaviour's legacy
   reach and cost (does it run for legacy CPU fighters, and how many cycles), and only then put the port to the
   maintainer with options and a recommendation through the rule-checker ([VSP-10]).
3. **#231 — the freeze's byte-level program diff as a step that cannot be skipped**, and `attribute_patch_delta.py`
   without a `gen.log` (filed at the M23 close; `tools/program_bytediff.py` is the instrument, its control the
   M21 -> M22 pair).
4. **#217 — A PACKET PER FORK, IN THE TOOL** (ruled 14z-191, after the close): a `tools/rulecheck.py` change, tested
   with controls, when a session takes it up.
5. **#226 — THE LINUX RELEASE AS A PLAYER GETS IT**, ideally on the next release: step 2 (a desktop session — the
   maintainer), step 3 (the `-recipe` asset on a clean host), the scripted headless case.
6. **Open from this sitting:** #228 (breakpoint instruments on the frame_done clock), #229 (community naming rigs),
   #230 (capture geometry), #118 (the mizuumi candidates, scope commented),
   #232 (the jtsim scratch heal misses submodules — the reaper broke the MiSTer lane once at this close), #233
   (`audit_legacy_pairings` deletes a dead leg's log — one leg died in the final ERIS run and its cause is lost).

## INSTRUMENT FACTS LEARNED THIS SITTING (read before the work they bear on)

- A remote tier started from a non-login shell runs without the reference `mame` on PATH: every ERIS script begins
  with `. "$HOME/.profile"` (`ssh eris 'wsl -e sh -s' < script`).
- ERIS's MINGW64 is MSYS2: `ssh eris 'C:\msys64\usr\bin\env.exe MSYSTEM=MINGW64 CHERE_INVOKING=1 /usr/bin/bash -l
  /c/Users/chaton/m22logs/<script>.sh'` (there is no Git for Windows bash).
- A re-point sweep at a freeze must leave pinned predecessors alone (`CTL_*`, `REF`, `--old`, "before"/"pre-"),
  must not rewrite dated records, and must be followed by a grep for release-name defaults (`merged-m<prev>`).
- An op-set delta cannot see a byte inside a placed data file: read every track's program change with
  `tools/program_bytediff.py <old> <new>`.
- A moved `test_mister_prg_window` pair at a freeze: first swap the graphics members alone (the mark moves it).
- `tests/run_all_emulator.sh --only` takes ONE shell glob; `|` alternatives select nothing. `--stale` refuses names
  outside the selection: stale `out`-of-release-scope gates need `--scope all`.
- A freeze battery run on an uncommitted tree leaves every gate stale at freeze cadence: the `--stale` re-run on the
  freeze commit is about a whole battery (187 gates at M23). Bring every lane's run dir home and read
  `tools/audit_emulator_staleness.py --cadence freeze` as soon as the battery ends: the M23 battery's own rows were
  over half their cap, unseen until its run dir reached the Mac.
- Since 14z-192 the staleness audit judges a moved path by CONTENT against the run's `run_record_start.json`
  (the patched `emu/fbneo` included, index-blind), judges a red newest row, and at freeze cadence FAILs only what a
  freeze selects. Every emulator gate follows `tests/ci_emulator.tsv`, so any registry edit re-stales them all.

## WHAT CLOSED THIS SITTING (14z-192)

**#210**, **#211**, **#213**, **#216**, **#222**, **#223** `done`; **#116** and **#117** split and closed `done`.
Filed: #228, #229, #230, #231, #232, #233. M23 FROZEN; the staleness audit judges by content (ruled).
