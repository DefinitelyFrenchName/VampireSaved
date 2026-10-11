# NEXT SESSION — orientation (rewritten at the 14z-197 CLOSE, 2026-10-11)

> Rewritten at every session close ([VSP-17]). ROLLOVER: the previous opener
> moves VERBATIM to the top of `NEXT_SESSION_HISTORY.md` — this file holds ONLY
> the live orientation. Session state, not knowledge: facts belong in the docs,
> status in STATE.md.

## THE SETUP, RESTATED

A plain **Opus 5.5 session at effort High** (the ruled orchestrator — STATE 'Standing rulings') on the
#172 setup:
- Every quoted figure comes from a `measurer` / `reader` spec (`docs/project/worker_spec.md`, the spec text IN the prompt, no model).
- Every freeze and recommendation goes through the pinned `rule-checker`, with the prompt files pasted VERBATIM.
- Then `record --session <transcript id>`, and `resolve` on ONE line with one label per violated question, only AFTER the work it names exists.

Say so at the opener. Never spawn any agent at `max`. A recommendation leans only on the maintainer's OWN words.
**Before any long job, check whether PILOT (`ssh pilot`) or ERIS (`ssh eris`) is idle, and run independent work
there in parallel.**

## START HERE

0. **AT THE OPENER, RUN `python3 tools/agent/sweep.py`.** What the close found and did is in STATE 14z-197's CLOSE row.
1. **Ask the maintainer for the order of work.** The ruled order of work is finished (STATE 14z-197; its fixed tickets are in item 4). The open tickets, by their GitHub severity label:
   - high: #261 (`audit_effect_class_rows` section 4 checks a type-6 fallback inventory that was never frozen), #256 (the close's open-tickets check reads a cited ticket range as its two ends);
   - medium: #243, #257, #258, #259;
   - low: #118, #129, #229, #244;
   - no severity label: #262 and #263 (the C1 extract's two gaps, filed after the 14z-197 close), #264 (a session dashboard, evolution); #260 — the submodule-pin check is implemented and runs at every close (`tools/submodule_pins.py`); the maintainer chose to keep it open at the 14z-197 close (`DECISIONS_HISTORY.md`, the 2026-10-11 entry whose heading ends "#260 stays open").
2. **#118 — the chars gate, PARKED on branch `t118-196`** (ruled: `DECISIONS_HISTORY.md` "Ruled 2026-10-09 (14z-196) — #118's gates and every pristine-only gate move to an ONDEMAND scope; the chars gate parked"). `audit_mizuumi_chars` went through rule-checker runs 902-914 in the worktree `../wt_t118_196`; **914 is VIOLATED on Q1 and unresolved** (two facts frozen only in pooled lines). It lands as `ondemand`.
3. **#129 stays the lowest priority**, captures first (`DECISIONS_HISTORY.md` "Ruled 2026-10-08 (14z-196) — #129: captures first; the ticket stays the lowest priority of the open tickets").
4. **Done, awaiting release** (each closes with the release that carries it): #236, #238, #239, #240, #245, #246, #247, #248, #249, #250, #251, #252, #253, #255. `test_release_launcher_bat`'s Windows half runs on ERIS; the shipped `PLAY.bat` must equal the generator at release (`DECISIONS_HISTORY.md` "Ruled 2026-10-10 (14z-197) — #248's Windows half: the shipped PLAY.bat equals the generator at release only").

## PARKED (not open work)

- #124, parked by the maintainer (`DECISIONS_HISTORY.md` "Ruled 2026-10-09 (14z-196) — #124 parked").

## INSTRUMENT FACTS LEARNED THIS SITTING (read before the work they bear on)

- **Every breakpoint instrument counts EMULATED frames through `tests/lua/emu_clock.lua`.** A new instrument loads it and never keeps its own `frame_done` counter. Its `ALIGN` line's `uiframes` is the UI frames the clock skipped, not a count of stops: a leg with no stop can read 1. Ground truth: `tests/test_emu_clock.sh` ([MFI-5], `docs/platform/gotchas.md` "ONE SHARED CLOCK SINCE 14z-197").
- **A stop is labelled with the last COMPLETED frame.** An event during frame N logs N-1 on the emulated clock.
- **Rigs tuned on the old clock can stop working.** Its inputs landed early. The fresh stage-4 Huitzil build resets on the 2P-dummy rigs and at ~f4700 on the soak rig (not root-caused); the four Huitzil stage gates run on `build/hui61` (ruled).
- **`tools/audit_poked_legs.py` reads a script's comments when deciding which games it boots.** The bare word for the native game beside a MAME runner in a poked script's prose counts as a native leg.
- **`test_gate_follows` reads a path built as `tests/lua/$x` as a reference to all of `tests/lua/`.** Name the files literally.
- **The confirm tier's planner runs ~20 min with no output** (#259). Prove the run alive from its processes, then wait.

## WHAT CLOSED THIS SITTING (14z-197)

- **Closed `done`:** #228 (all seven breakpoint instruments and `pc_count` on the emulated clock). #260 was closed on a misread of the ruling and reopened on the maintainer's word.
- **Closed by the maintainer:** #119, recorded `declined` with no new ticket.
- **Fixed, labelled `done unshipped`:** #245, #246, #247, #248, #249, #250, #251, #252, #253, #255.
- **Filed:** #261.
- **Ruled:** the order of work (#245-#255, P2 first; nothing bbh-related runs here); a fixed ticket is commented and labelled `done unshipped`; #248's newest set, always, and `PLAY.bat` equality at release only; bbh's remaining links; #228's option A; the four Huitzil stage gates on `build/hui61`; the three gate-less instruments converted; #228 closed at this close and #260 kept open; #119 declined. Each, in the maintainer's own words, is its `DECISIONS_HISTORY.md` entry "Ruled 2026-10-10 (14z-197) — ..." or "Ruled 2026-10-11 (14z-197) — ..."; `tools/agent/rulings_verbatim.py` checks those quotes.
