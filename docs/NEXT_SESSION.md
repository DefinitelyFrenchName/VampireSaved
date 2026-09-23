# NEXT SESSION — orientation (rewritten at the 14z-174 CLOSE, 2026-09-22)

> Rewritten at every session close ([VSP-17]). ROLLOVER: the previous opener
> moves VERBATIM to the top of `NEXT_SESSION_HISTORY.md` — this file holds ONLY
> the live orientation. Session state, not knowledge: facts belong in the docs,
> status in STATE.md.

## M19 IS RELEASED. The tree is at `build/m3b_merged27`; no shipped ROM byte moved

Seven assets published on `freeze/merged-m19`, each downloaded back from GitHub and
compared file-by-file against the tree; **merged-m18's seven are pruned**, so the README
that told macOS players to right-click > Open is no longer downloadable. Every package
carries `apply_release.html`, the browser applier — no Python, no terminal.

**Confirmed by the maintainer, 2026-09-22, which is the part no gate could give:**
*"I tested on MiSTer, M19 is clean and the rom made with the local webapp is good"*.

The gates behind it: emulator tier at release scope **PASS 281, FAIL 0, TIMEOUT 0**, one
approved SKIP, controls `fired 92 / declared 92`, with the MiSTer lane carried on
`tools/audit_lane_carry.py`'s recorded evidence; static tier at release cadence **PASS
169, SKIP 0, FAIL 0**, controls `201 / 201`.

## START HERE

1. **#171 — QUALIFY EVERY GATE. This is the largest open item and the maintainer opened
   it from evidence, not suspicion.** The M19 release tier came back with **eight reds,
   none of them a defect in the romset**, in four distinct shapes: five gates that had
   asserted nothing for four days (a deleted constant, caller never updated); three
   expectations stale behind rigs that legitimately moved; a control killed by its own
   timeout on every run; and a column that read the rig's own poke back. The maintainer:
   *"either the gates are moving silently or they never were validated and in both cases
   that's a lot of both uncertainty and wasted time"*. The common factor is that **the
   emulator tier only runs at a freeze or a release**, so breakage accumulates and
   surfaces at the worst moment.    reconciles it against the registry. Two tools exist to build on —
   `tools/audit_lane_carry.py` and `tools/attribute_expectation.sh` — and **the first is
   itself a case this ticket must fix: its subject lists are HARDCODED and known
   INCOMPLETE** (it omits `tests/replays`, a load-bearing operand of a mister gate, and
   `ci_emulator.tsv` itself; nothing reconciles the lists against the registry). **A
   `MAY CARRY` from it is NECESSARY, NOT SUFFICIENT** — check the omitted paths by hand,
   as the M19 release did. It prints its own unchecked paths with every verdict.
   and `tools/attribute_expectation.sh`.
2. **#172 — the agent-level architecture**, raised from this sitting's own worst failure:
   polling was chosen as the right strategy, stated, and then not done, leaving three
   finished jobs idle for 2.5 h, 1.5 h and 1.5 h. The maintainer's shape — a Fable
   orchestrator that cannot override Opus/Sonnet checkers which hold the rules and no
   project context, with narrowly-specified workers — is quoted verbatim on the issue,
   along with what `tools/rulecheck.py` already proves about that pattern and the gap it
   does NOT cover: nothing currently asks whether the ORCHESTRATOR followed its own
   procedure.
3. **#145 Windows binaries** — "fails to load", still unreproduced, no longer a blocker.
   Patch 0003 drops SDL2_image there too, so the next Windows build shrinks that bundle
   from 31 files for free; whether that is the same problem is unknown.
4. **No Windows launcher.** `PLAY.command` is macOS/Linux. The browser applier now covers
   step 1 on every OS, so what is left for Windows is steps 2 and 3 only.
5. **#170** (notarize macOS, PARKED on community demand), **#161**, **#169**, and the #136
   tickets **#157 / #159 / #163** — all untouched, all the maintainer's to schedule.

## TRAPS PAID THIS SITTING (14z-174)

1. **A STRATEGY YOU STATE AND DO NOT EXECUTE IS WORSE THAN NONE**, because it reads as
   handled. Polling long background jobs is the right approach here and is written down
   (`poll-long-jobs-directly`); it was chosen out loud and then not done, three times,
   for ~5.5 h of wall clock during a release. The maintainer's diagnosis is the one to
   keep: *"Polling is likely the good option. The problem is actually doing it."* #172.
2. **Measure the platform BEFORE designing for it.** The applier plan's central
   assumption — the page could read the manifest and patches beside it — is false in
   every browser. A 20-minute probe before any code cost nothing; discovering it later
   would have cost the design.
3. **One buffer is not a corpus.** `CompressionStream` matched Python's zlib byte for
   byte on one 200 KB fixture and disagreed on all 32 real members. The fixture agreed
   by being a single chunk.
4. **A control that does not fire is a bug report about the control, not the code.**
   `no-member-check` was dead on its first run: VCDIFF's own adler32 catches a corrupted
   patch first. Re-aim the control at the perturbation only that check can see.
5. **PAIR THE ROWS BEFORE READING A DIFF.** A unified diff invites comparing a removed
   line against the wrong added line: that is how "damage moved" was reported to the
   maintainer when only a meter count had. Pair them and name which FIELDS moved.
6. **An estimate borrowed from a different workload is a guess wearing a number.** "~2 h"
   for the non-MiSTer tier came from dividing its serial time by the speedup the FULL run
   achieved — but that speedup came from four long MiSTer jobs running side by side. It
   took 6 h. Say "I don't know how well this parallelises".
7. **`sh -n` before running a new `#!/bin/sh` script**, and no process substitution in
   one — `<(...)` is a syntax error there, and a script that does not parse never runs
   at all, which looks exactly like a script that ran and did nothing.
8. **An iframe's `contentDocument` is `about:blank` until the real navigation lands**,
   and that placeholder already reports `readyState === "complete"`.
9. **`git checkout <commit> -- path` STAGES the old version**, and `git checkout HEAD --`
   destroys uncommitted work in that path. Both bit this sitting; `tools/attribute_expectation.sh`
   exists partly to make the safe form the easy one.

**IF A DOC IS TOUCHED:** the doc gates (`test_checkdocs`, `test_docshape`,
`test_doc_anchor_census`, `test_checkskills`, `test_gotchas_index_current`,
`test_gate_index_current`, `test_state_open_lists`, `test_tickets`) plus
`tools/check_state_lists.py` and `tools/tickets.py check`, exit statuses captured
directly, `${=cmd}` in zsh. **A running script is never edited** ([MSC-54]).
