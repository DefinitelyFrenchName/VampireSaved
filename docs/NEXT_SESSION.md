# NEXT SESSION — orientation (rewritten at the 14z-195 CLOSE, 2026-10-08)

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

0. **AT THE OPENER, RUN `python3 tools/agent/sweep.py`.** What the close found and did is in STATE 14z-195's CLOSE row.
1. **#124 — THE BUILD** (the maintainer: *"Scope #124, build next"*). The plan is the #124 comment "The build plan (14z-195)", rule-checker run 2026-10-08-749 OK.
   - **Step 0 FIRST, before any byte changes:** debugger read watchpoints over every row the build rewrites, with the select screen's read of `0x26762A`'s P2 rows as the positive control.
   - Then: a `native_c5` `select_records` row for `0x26752A`, and two `site_thunk` bank gates at `0x05FC36`/`0x05FC76`. These replace the approved tile relocation, because the select screen draws the same rows.
   - Then vs2's width words and pool rows, the score ranking's own bank gate (its bank bits measured first), and the gates.
2. **#245-#255 — eleven code-review findings**, filed 2026-10-08 as `mechanyaa-ai` against `d1759b33` and indexed as open bugs at this close.
   - #245 (P1): the WIDE builder overwrites a source zip through its own symlink.
   - The rest are P2/P3: release packaging and appliers, CI, the staleness audit, the replay wrapper, the control classifier.
   - Triage them with the maintainer: bug archaeology first ([VSP-14]).
3. **#129 — PUT THE DECISION** (STATE_HISTORY 14z-194; facts in `docs/game/engine_internals.md` "The CPU AI action-script system"). The maintainer's last priority.
4. **Open, scoped:**
   - #118: three emulator gates landed, now scope `out`; HOMING items 4 and 5 remain.
   - #229: ground throws gated and on the cross-check page; specials, supers and EX/ES moves next.
   - #226: the desktop and clean-host gates are both green on PILOT. Close it, or keep it open until a release runs both? The maintainer's call.
   - #228, deferred.
   - #243, #244.
   - Done, awaiting release: #236, #238-#240.

## INSTRUMENT FACTS LEARNED THIS SITTING (read before the work they bear on)

- **A census of absolute references to a table, plus breakpoints on its known readers, cannot show a screen does NOT read it.** `0x26762A` is reached through `0x2675AA + 0x80`. Use a read watch over the table's bytes, with a positive control (`docs/project/gotchas.md`).
- **podman on PILOT runs rootless.** `docker.io/library/ubuntu:24.04` is pulled. glibc 2.39's `LD_DEBUG=libs` prints `find library=X [0]; searching`, then `(RUNPATH from file Y)` and `trying file=` lines, and no `needed by` lines (`tools/cleanhost_libs.py`).
- **`rulecheck.py` arguments:** `prepare --session` takes the 14z key; `record --session` takes the transcript id (`d93d8edb` this sitting).
- **`claim_lint` refuses an untied "every".** Tie it to an artifact path in the same sentence.
- **zsh does not split a command held in a variable** (`$F args` fails). Write the command out.
- **`ldconfig -p` lines start with a TAB.** Match `^[[:space:]]soname `.

## WHAT CLOSED THIS SITTING (14z-195)

- **Closed `done`:** #237, #241, #242.
- **Filed:** #243, #244.
- **Indexed:** #245-#255.
- **Ruled:**
  - a done-but-unreleased ticket gets a comment saying so;
  - `libudev.so.1` is host-provided;
  - #229's captures confirmed;
  - the four mizuumi gates leave release scope;
  - #124 scoped this sitting, built the next.
