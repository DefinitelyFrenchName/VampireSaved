# NEXT SESSION — orientation (rewritten at the 14z-193 CLOSE, 2026-10-07)

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

0. **AT THE OPENER, RUN `python3 tools/agent/sweep.py`.** M23 is FROZEN (`c884e6d8`, tags `freeze/donovan-m27`,
   `huitzil-m34`, `pyron-m28`, `merged-m23`); 14z-193 froze no build. What the close found and did is in STATE 14z-193's
   CLOSE row.
1. **THE NEXT RELEASE carries M23** with #214 and #227 (both fixed in the generator; `release/merged-m23/` is
   packaged). #234 (the MAME README never explains the red bad-ROM box at every start) is the same kind of
   generator note and could ride along. The release itself is the maintainer's call.
2. **#129 — RE-CHECK THE WORKER'S REPORT, THEN PUT THE DECISION** (STATE 14z-192 row (10);
   `build/agent192/r129/REPORT_handback.md`): two vs2 CPU-AI behaviours our build lacks; the report's two faults are
   named there. Re-check, measure each behaviour's legacy reach and cost, then put the port to the maintainer
   through the rule-checker ([VSP-10]).
3. **#226 — THE LINUX RELEASE AS A PLAYER GETS IT**: step 2's window, rendering and a match passed on PILOT's desktop
   (STATE 14z-193 row (4); the driver `build/agent193/t226/pilot_drive.py`); left are sound and the physical
   keyboard (PILOT's VM has no audio device), step 3 (the `-recipe` asset on a clean host), and the scripted case.
4. **Kept for a future session at the maintainer's word** (*"Let's keep them for a future session"*): #229 (naming
   rigs for vanilla specials, supers, EX/ES, throws and pursuits) and #118 (the remaining mizuumi candidates) —
   scope each before any rig. Also open: #228 (breakpoint instruments on the frame_done clock), #235 (Pyron's and
   Donovan's kick and air throws as throwers), #236 (the asset cutter's dry run claims an upload).

## INSTRUMENT FACTS LEARNED THIS SITTING (read before the work they bear on)

- PILOT's `mame` too is on the LOGIN PATH only: a plain `ssh pilot 'cmd'` does not see it (`bash -lc` does) — the
  ERIS gotcha's class (`docs/project/gotchas.md` "A REMOTE BATTERY STARTED FROM A NON-LOGIN SHELL").
- PILOT's GNOME session can be driven from SSH: `DISPLAY=:0`, `XAUTHORITY=/run/user/1000/.mutter-Xwaylandauth.*`,
  keys through Xwayland's XTEST (ctypes on `libXtst.so.6`, no install), the window captured with `xwd -id`.
- MAME runs an `-autoboot_script` only after its startup screens: the release MAME's red bad-ROM box (#234) blocks a
  scripted run until a key is pressed; the project's own runs use `-video none` and never see it.
- A check that reads back a byte the gate itself pokes proves nothing; a per-cell claim compared as two sets hides a
  swap; a cross-game gate without the matched level reads the speed level as a difference
  (`docs/project/gotchas.md` "A CHECK THAT READS BACK ITS OWN POKE PROVES NOTHING").
- `tools/upload_release_assets.sh --dry-run` ends with "done: N asset(s) on https://github.com/…" though it publishes
  nothing; check `gh release view` before believing a line like it.
- A freeze now records its whole program change: `python3 tools/freeze_bytediff.py render`, review, `freeze`
  (HANDOFF "AND THE FREEZE'S WHOLE PROGRAM CHANGE"); `tests/test_freeze_bytediff.sh` is red until it does.

## WHAT CLOSED THIS SITTING (14z-193)

**#122**, **#217**, **#230**, **#231**, **#232**, **#233** `done`. Filed: #234, #235, #236. HANDOFF's naked-eye tell set
to M23; `test_freeze_bytediff` listed at freeze cadence (ruled).
