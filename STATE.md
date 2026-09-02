# STATE — living progress log

## Session 14z-126b CLOSE (2) — ritual complete for the CONTINUED session. **FIVE ARCS AFTER THE FIRST CLOSE: the
## three grandfathered tags amended and force-pushed (allow-list removed, not left to rot), a red root-caused to the
## macOS tmp reaper, #112 PICKED UP AND ITS PREMISE REFUTED, the black foot FOUND by searching the INPUTS, and two
## gotchas + a gate that came out of it. No build changed. Strict static 126/0/0/0. PUSHED.**

| | |
|---|---|
| opened with | the maintainer's "do all 3, in order, with a push at session close" — then, after the close, four more items they raised in turn |
| after the first close | (1) the three 14z-102 tags AMENDED and force-pushed, and the gate's allow-list REMOVED the moment its reason died; (2) a RED (`test_mister_mra_map`) root-caused in one grep to the documented macOS tmp reaper — 4,099 files deleted from the jtsim scratch while `.git` and HEAD survived, so the pin check could not see it; (3) #112 for knowledge; (4) the black foot; (5) the input-search lesson recorded |
| **#112, the headline** | the maintainer's question — "why a tenant object runs that vanilla sequence" — is answered: **IT DOES NOT.** `0x28394E` is never stored anywhere (all 7 sites disassembled), all 9,755 tenant sprite pointers are relocated (gated), and at runtime nothing holds a vsavj record pointer while the control fires 15/15 on the record-chain fields. The black foot draws `0xbbxx` where clean instances draw `0xe7xx` — real art from the wrong place, not a palette fault and not "dark lift tiles" |
| **the method, and it was the maintainer's** — ~~stated here as "search the inputs, never the art"~~ **OVERSTATED BY ME AND CORRECTED BY THE MAINTAINER 2026-09-01: it is a COST ORDERING, not a prohibition** (1 inputs, cheap+reliable, start here unless you cannot; 2 memory watching, dearer, reliable unless the pattern is not; 3 art search, expensive FOR CLAUDE but **cheap the moment they are shown a capture, which they can confirm or infirm immediately**; 4 the list is not closed). Their words: *"input search is easy and cheap, art search is hard and expensive and long"* — never "never". The absolute did harm: it forbids this project's cheapest confirmation route. Retraction pass run the same day (gotchas both files, NEXT_SESSION, this row, the memory) | "do not look for the image, look for the input" — 25 `41236+K` attempts found in ONE pass over a log already on disk; the last (MK at f14307) is the black one, 2.65 s before their cutoff. That instruction was for THAT hunt and is sound: a motion is a PARTIAL ORDER over mandatory steps, so a human's non-frame-perfect input is absorbed by an ordered-subsequence match, and the inputs are ground truth INDEPENDENT of the defect. What was NOT theirs is the generalisation to a ban on art |
| **what I got wrong, and how it was caught** | four claims failed verification before they set (the "only session with no FREEZE commit", a 3/3 precedent that was really 29/39, a figure that counted my own new tags as its own evidence, "eight freezes" for thirteen) — all caught by MEASURING. Two more were caught by the maintainer: "the black case does not reproduce on merged-m14" (true only of one recording's playback) and filing an OPEN item under a CLOSED banner where they could not find it. Both are recorded as standing lessons |
| new gates / instruments | `test_freeze_tag_coverage.sh` (126 floor), `test_tenant_anim_relocation.sh` + `anim_reloc_audit.py` + `plant_anim_reloc_control.py` |
| gotchas filed | project: an ART-KEYED detector cannot locate a defect in the art (**header and rule REWRITTEN 2026-09-01 to the maintainer's cost ordering — see the row above; the entry as first filed prescribed "never the art", which they never said**). platform: a recording's FRAME NUMBERS are a claim about the BUILD it was played on |
| the close battery, exit statuses captured directly | census `--check` rc=0 · `checkdocshape --no-pending` rc=0 · checkdocs rc=0 · checkskills rc=0 · `gen_annotations --check` rc=0 · `gen_gate_index --check` rc=0 · gotchas index rc=0 · `test_freeze_tag_coverage` rc=0 · `test_tenant_anim_relocation` rc=0. **Strict static PASS 126 / SKIP 0 / FAIL 0 / MISSING 0** |
| patch_notes / patch_index | **checked, correctly NO entry** — nothing under `build/manifest` or `tools/gen_donovan_patch.py` moved |
| not done, by design | ~~#112's remaining question (why THAT instance selects `0xbbxx`)~~ **ANSWERED 2026-09-01 — the question was mis-posed; nothing "selects `0xbbxx`". See the ROOT CAUSE entry above.** (as written: needs a write tap on the f14370 record); Zabel j.LK still awaits the maintainer's recording; Jedah's crouching recovery still needs a tick-accurate instrument; the mizuumi CHARACTER DATA the maintainer has found, queued for a future session against `community_crosscheck` |
| push | **PUSHED** |

## Session 14z-126b addendum (2) — **#112 PICKED UP FOR KNOWLEDGE ONLY (maintainer: "I am perfectly fine with the
## cosmetic imprecision"): THE PREMISE IS REFUTED. "A tenant object runs a vanilla sequence" is not what happens —
## at every Press of Death instance on the current build, the drawing objects' `+0x1C` hold pointers into
## DONOVAN'S PLACED region and NOTHING in work RAM holds a vsavj record pointer, with a positive control. Plus a
## new gate for the class, and a recording whose frame numbers turned out to be build-specific. No build changed.**

| | |
|---|---|
| opened with | the maintainer parking Zabel j.LK for want of the recording and asking for #112's remaining unknown — verbatim: "there is still quite a lot we don't know, including 'Still unknown: why a tenant object runs that vanilla sequence'" |
| **archaeology first ([VSP-14])** | the record is richer than the backlog line: 14z-112 had already RETRACTED both the shelf-pack root cause and the "tenant pointers to `0x28394E`" (an instruction-boundary false positive). What survived was narrow: records and art on the path are vanilla, and *which records the ported animation selects* is the open half. Two traps were already written down and both bit here: [CPE-14] MAME READ TAPS NEVER FIRE on this driver (so the anchor method is unavailable — write taps do fire), and "disassemble, never scan" |
| **(1) `0x28394E` IS NEVER STORED ANYWHERE — the retraction re-confirmed, now exhaustively** | scanning the built image finds 7 candidate sites, ALL in the opcode view; disassembled, every one is `move.l #$...,$28(a4)` followed by `394e` = `move.w a6,$30(a4)` — the displacement word of one instruction matched against the opcode of the next. 14z-112 checked four sites in tenant regions; this checks all seven in the whole image. I reproduced the exact trap the record warns about and only the disassembly caught it |
| **(2) THE PORT DOES NOT POINT A TENANT AT VANILLA RECORDS — measured, then GATED** | walking every tenant's five anim index tables structurally with `tools/anim_nodes.py`: donovan 3722/3722, huitzil 3259/3259, pyron 2774/2774 sprite-record pointers relocated into the placed region, **ZERO left in the vs2 source range**. New gate `tests/test_tenant_anim_relocation.sh` (ci_static, ~2 s) + `tools/anim_reloc_audit.py`, with a must-fire control that plants a source-range pointer in a COPY. Static floor 125 → 126 |
| **(3) THE RUNTIME ANSWER, with a positive control** | at Press of Death frames on merged-m14, a work-RAM scan of `$FF8000-$FFC800` for a `0x287Dxx` pointer returns **ZERO hits**; the same scan for a placed-region pointer (`00 0d`) returns **15**, landing exactly on the record-chain fields — `$FF841C` (fighter P1 `+0x1C`), `$FF951C` (projectile slot `+0x1C`) and `$FFBA58`. So the objects are running the port's OWN placed chain. **The "runs a vanilla sequence" premise is refuted**; what remains is the builder's own documented note — the records' TILE CODES are what the effect map never covered ("Effect/low codes stay untouched … they render garbled, never crash") |
| **(4) THE RECORDING'S FRAME NUMBERS ARE BUILD-SPECIFIC** | `run-merged-m9-05` still plays to END 7490 on merged-m14, length-exact and guard-clean, but the CONTENT diverges: 11 Press of Death instances at completely different frames, NONE drawing the lift (black) set `0xe768-0xe796`, and nine drawing `0xe7c0-0xe7d6` — a range the 14z-112 record never names. Cause: merged-m14 carries the physics port, so identical input yields different positions. [VSP-119]'s "frame-exact" means ON THE SAME PINNED BINARY. NOTE corrected in place so the next session is not misled as I was |
| **what is still open — AND THE CLAIM I NEARLY OVERSTATED** | ~~the BLACK case does not reproduce on the current build~~ **WRONG AS STATED, corrected the same day: it does not reproduce IN THAT RECORDING'S PLAYBACK, which is a fact about the recording, not the build.** The maintainer field-captured `pod-black-m14-01` on merged-m14 within the hour — the LAST Press of Death of the run, second fight, vs BISHAMON, is black; every earlier one is clean. That matches 14z-112's own "the move only reaches the lift phase on some outcomes", so the old recording simply never took those outcomes. The distinction was flagged BEFORE the board time was spent, which is the only reason it cost nothing |
| gameplay surface ([VSP-10]) | none touched. The maintainer's framing stands: the cosmetic imprecision is accepted and no tenant effect animation was given or proposed |
| **(5) THE BLACK FOOT FOUND — by the maintainer's method, not mine** | the maintainer captured `pod-black-m14-01` on merged-m14 (tracked, [VSP-20]) and then said the thing that broke it open: *"if the recording is indeed the recording of inputs, do not look for the image, look for the input, you're looking for a pattern of 41236+K"*. Scanning P1's input stream (`in=IN0,IN1,IN2`, already logged on every `V` line) found ALL 25 `41236+K` attempts in one pass over a log on disk. The LAST is **MK at f14307**, 2.65 s before the cutoff — matching the maintainer's own "3 to 4 seconds". The effect renders at **f14370-14375** (~45-frame lag, cross-checked against the previous MK at f13584 → effect f13629) |
| **what the black frame draws** — ~~"palette 05, but tile codes `0xbbxx`… real art fetched from the wrong place"~~ **RETRACTED AND ROOT-CAUSED 2026-09-01, see the ROOT CAUSE entry above: the pal-05 `bbxx` entries are BYTE-IDENTICAL to a clean instance's (same codes, attrs, sizes and composed `a18`/`a19`, differing only in x/y) — `bbe5`/`bbea` are a NORMAL later phase every clean instance draws, and `0xe768-0xe796` is an EARLIER phase, so the two were never counterparts. The defect is palette row `0b` index 14, not the tiles** | as first written: `bbe5/pal05/4x2` ×2 and `bbea/pal05/3x2` ×2 — **palette 05, but tile codes `0xbbxx`**, where every CLEAN instance draws `0xe768-0xe796`. Same move, same build, same palette row, DIFFERENT TILE CODES: real art fetched from the wrong place ([VSE-29]'s signature), not a palette fault. Snapshot confirms it by eye ([VSP-139]) — solid black sole and toes inside the white/cyan effect |
| **three claims killed** | (a) 14z-112's last surviving conclusion, "the lift-phase tiles simply carry dark art in this build" — the CLEAN instances draw those exact lift tiles; (b) my own "the black case does not reproduce on merged-m14"; (c) **the #112 detector itself** — `inp_probe.lua` keys on `pal 05 + tile 0x0e7xx`, the art of the CLEAN case, so it is structurally blind to the defect it was written for and reported ten confident clean instances. Gotcha filed both sides (project: art-keyed detectors — **its "never the art" prescription corrected to a cost ordering 2026-09-01, see the CLOSE (2) row**; platform: a recording's frames are a claim about its build) |
| **NOT explained, stated as such** | `0xbbe5`, `0xbbea` AND the clean `0xe768` are all absent from `effect_map.json` as src or dst (939 pairs, dst range `0xad80-0xee73` spans both), so "an unmapped effect code" does NOT discriminate black from clean on this evidence. Why this instance selects `0xbbxx` when nine earlier ones in the same fight did not is the open question; the next step is the record behind that OBJ entry at f14370, attributable with a write tap (read taps never fire, [CPE-14]) |
| green | `test_tenant_anim_relocation` PASS · strict static 126/0/0/0 |

## Session 14z-126b addendum (2026-09-01, after the close) — **THE THREE GRANDFATHERED TAGS AMENDED AND
## FORCE-PUSHED at the maintainer's word, so the freeze-tag gate now runs HARD with no allow-list. Found because
## the maintainer went looking for the open item in NEXT_SESSION and COULD NOT FIND IT — it was filed under a
## header announcing a CLOSURE. No build changed.**

| | |
|---|---|
| opened with | the maintainer: "I looked for them and can't find them in next_session, can you elaborate" |
| **the reporting defect, mine** | the item WAS in NEXT_SESSION (lines 51-54) but as the tail of a block headed **"AND THE GAP THE CUT UNCOVERED IS CLOSED"**. A reader scanning an orientation doc for open work skips a block headed CLOSED, so "named in NEXT_SESSION" was technically true and practically false. Same class as the stale headers fixed hours earlier ([VSP-13]: a skimmer reads the HEADER; an appended "actually…" does not reach them). **Standing lesson: an OPEN item never lives under a CLOSED banner — it goes in the block that announces open work** |
| the substance | `freeze/donovan-m10` / `huitzil-m19` / `pyron-m13` (the 14z-102 window freeze) all carried one identical line naming what the freeze CHANGED and no fingerprint, no recipe — against [VSP-94] ("the tag message carries the fingerprint and how to reproduce"). 11 other tags omit the full SHA-1 but carry the 8-char form and so self-identify; these three named nothing |
| **the ruling** | the maintainer chose AMEND-AND-FORCE-PUSH over leaving them, having been given the cost explicitly: these were PUBLISHED refs, so rewriting them changes what other clones have already fetched — unlike the three 14z-91 tags created the same session, which had never existed remotely |
| **done** | all three amended at the SAME commit `3f2c87a` (verified unchanged) with the fingerprint, the batch siblings, the reproduce recipe, and a visible `MESSAGE AMENDED 2026-09-01 (14z-126b)` note stating that the tag object was rewritten and force-pushed while no build byte moved. Force-pushed: `d12b055…6f8c561`, `bfae61a…8cb8527`, `6be7d0a…a3a2a15`. NOT measured — all three build dirs are pruned ([VSP-96]); the fingerprints are transcribed from `registry.tsv`, and each tag says so |
| **the consequence, taken rather than left** | with the reason gone, the gate's allow-list was DEAD — an allowance that outlives its reason is precisely the rot the gate exists to stop (the `checkdocshape` precedent: a row matching nothing FAILS as dead). Section 3 of `test_freeze_tag_coverage.sh` is now **HARD with no exceptions**, and control (b) was rewritten: it no longer empties an allow-list but perturbs one fingerprint in a registry COPY, so a tag whose message lacks its fingerprint fires. All 78 tags now name theirs |
| green | `test_freeze_tag_coverage` PASS (3 sections + 2 controls); the doc battery and strict static re-run below |
| push | **PUSHED** (tags force-pushed; the doc commit follows) |

## Session 14z-126b CLOSE — ritual complete. **THE HANDOFF SHAPE ITEM DONE (the eight `Previous batch` blocks
## DELETE-AND-POINTED, −140 lines) AND THE THREE THINGS IT UNCOVERED ALL CLOSED IN ORDER: a load-bearing fact the
## chronology alone carried, the 14z-91 batch's MISSING FREEZE TAGS (created, two of them MEASURED against
## surviving artifacts, then GATED), and two stale HANDOFF headers. No build changed. Strict static 125/0/0/0.**

| | |
|---|---|
| opened with | the 14z-126 close; the maintainer picked item 3 (the HANDOFF shape item) off NEXT_SESSION's list, then ruled "do all 3, in order, with a push at session close" |
| **the cut** | HANDOFF is REFERENCE and carried eight `**Previous batch (14z-N…)**` blocks plus two un-bolded `Previous batch:` fragments in the same run — 140 lines of chronology, DELETED not moved, replaced by ONE pointer paragraph naming the four carriers (the registry table, `HANDOFF_HISTORY.md` "Build registry narratives", `patch_notes.md`, STATE/STATE_HISTORY). HANDOFF 1382 → 1264 lines. Every block's content was verified to survive elsewhere BEFORE deletion |
| **what the verification caught (1)** | `checkdocs`' `gallon_variant_idiom` lock fired: the deleted 14z-105 block was HANDOFF's ONLY carrier of `PRG:0x020B9C`. The Oboro select hook is CURRENT shipping behaviour, so the fact was restored as current-tense prose beside the playtest instructions (with the vanilla Dark Gallon idiom it preserves by construction) rather than the lock being weakened. `docs/annotations.md` also went stale — four addresses lost HANDOFF as a carrier; regenerated, each keeps six or more others |
| **the durable half** | `checkdocshape.py` + `test_docshape.sh`: a PARAGRAPH-OPENING bold run FAILS in a REFERENCE/REGISTER doc when it LEADS with chronology AND carries a session token. The header rule barred `### 14z-70: …`, so the log came back one level down and nothing looked at it for eight freezes. CALIBRATED against the real corpus — 619 bold openers in the 33 REFERENCE/REGISTER docs, 70 carrying a session token — and it fires on the eight and none of the other 611. `superseded`/`RETRACTED` are deliberately NOT leads: [VSP-13] step 4 requires a retraction marker to stay in body prose. Five self-tests both directions + a ninth must-fire control |
| **the gap the cut uncovered** | the 14z-91 LEGACY-REGRESSION batch (`donovan-m7` / `huitzil-m15` / `pyron-m9`) had `registry.tsv` rows 79-81 but **no `freeze/*` tag and no registry-table row** — breaking the invariant registry.tsv's own header states. Untagged for 35 sessions, visible only in the chronology nobody read. Reported to the maintainer with the evidence; ruled "Do it" |
| **the tags, and the measurement nobody expected to get** | three annotated tags at `271838e` (14z-91 (8), the commit that added the rows), placed by the era's convention — measured across the PRE-EXISTING tagged rows, 29 of 39 sit exactly at their registry-row commit and all ten exceptions are 14z-110-or-later. **TWO OF THE THREE ARE MEASURED, not asserted**: `build/hui41/rompath` and `build/pyron26/rompath` survived the build-dir pruning and `build_fingerprint.py --set vsavjw` returns their registry fingerprints exactly, no rebuild. `donovan-m7` could not be — its rompath was pruned; its tag says so and names the rebuild as the only route |
| **the gate ([VSP-18])** | `tests/test_freeze_tag_coverage.sh` (ci_portable, ~12 s): every registry row that is a BUILD has an ANNOTATED freeze tag (non-builds excused BY SHAPE, not by a name list that would rot); no lightweight tags anywhere; and — grandfathered after measuring — the tag message names its fingerprint, with the three 14z-102 tags that name none frozen as an allow-list so a FOURTH fails. Two must-fire controls wired in, both on copies; never creates, moves or deletes a tag |
| **two stale HANDOFF headers corrected ([VSP-13])** | "`build/m3b_merged8` is the current merged" — false since 14z-92, thirteen freezes stale; and the merged-m1 `KNOWN-OPEN` #91/#92 block — resolved at 14z-94. Headers fixed first, analyses KEPT and marked. The retraction grep found a THIRD carrier the memory-based approach would have missed: `registry.tsv`'s huitzil-m15 row still said "the re-freeze waits for #92"; marked in place, verified note-only (columns 1-2 byte-identical) |
| **four of my own claims failed verification before they could set** | "the only build-producing session with no FREEZE commit" (false — many freeze tags sit on ordinary commits); "3/3 precedent" (a lucky sample; the real figure is 29/39 with a dated exception class); a first "32 of 42" that counted the three NEW tags as evidence for the convention that placed them ([VSP-148]: agreeing evidence sharing a premise is one piece); and "eight freezes superseded" where merged-m1 → m14 is THIRTEEN. All four were caught by MEASURING, none by re-reading |
| process notes | the `pgrep -f` waiter self-match was hit TWICE despite being in memory — a waiter whose own command line contains the pattern never exits; wait on the log's verdict line instead. And a `gen_annotations --check` rc=1 that contradicted a green was a COLLISION with the concurrently running suite, not a defect ([VSP-40]: re-run before believing) — do not run gates alongside `run_all_static` |
| the close battery, exit statuses captured directly | `test_freeze_tag_coverage` rc=0 · census `--check` rc=0 · `checkdocshape --no-pending` rc=0 · checkdocs rc=0 · checkskills rc=0 · `gen_annotations --check` rc=0 · `gen_gate_index --check` rc=0 · gotchas index rc=0. **Strict static tier PASS 125 / SKIP 0 / FAIL 0 / MISSING 0** — the floor rises by one |
| patch_notes / patch_index | **checked, and correctly NO entry**: nothing under `build/manifest` or `tools/gen_donovan_patch.py` moved. No shipped byte changed and nothing was frozen |
| not done, by design | item (2) Zabel j.LK still needs the maintainer's RECORDING ([VSP-20]); item (3) Jedah's crouching recovery still needs a tick-accurate instrument; ~~the three 14z-102 tags that name no fingerprint are grandfathered, not fixed~~ **AMENDED AND FORCE-PUSHED the same day at the maintainer's word — see the addendum above; the gate's allow-list is gone**; the ~90 unadopted mizuumi candidates |
| push | **PUSHED** |

**Ledger rollover:** the 14z-126 group (14z-126 and its CLOSE) moved verbatim
to STATE_HISTORY.md at the 14z-126b CLOSE (2) — STATE had crossed the rule's
~150 KB line again with that entry. STATE holds 14z-126b only (its CLOSE (2),
two addenda and the first CLOSE). The 14z-125 group rolled the same way at the
first 14z-126b close, and 14z-124 at the 14z-126 close.


**SPLIT 2026-08-20 (14z-99 post-freeze close, maintainer-approved): this
file holds the RECENT session groups + THE LEDGER; the full detail of every
older session lives verbatim in `STATE_HISTORY.md`.** How to work with it:
- **Lookup**: "STATE 14z-XX" references resolve here first, then in
  STATE_HISTORY.md — section names are preserved verbatim in the archive.
  A reference to `STATE "Decisions pending"` for an entry no longer here
  resolves in `DECISIONS_HISTORY.md` (entries move there verbatim once
  ruled and no longer shaping work — 14z-109 cleanup).
- **Claim-greps MUST include STATE_HISTORY.md** (the CLAUDE.md §5
  retraction-discipline command names it).
- **ROLLOVER RULE (part of the session-close ritual)**: after writing the
  close entry, move session groups beyond the newest THREE to the TOP of
  STATE_HISTORY.md's body (below its header) and append their one-line
  entries to THE LEDGER below, composed from the group's own banner
  headers. If this file still exceeds ~150 KB, roll the oldest kept group
  early. Standing sections at the bottom of this file (decisions pending,
  the deadness register, open bugs, findings log) are CURRENT STATE — they
  never roll to STATE_HISTORY; entries within them are marked DECIDED/FIXED
  in place, as always. **DECISIONS have their own archive since 14z-109:
  once a ruled decision stops shaping active work, its entry moves
  VERBATIM to `DECISIONS_HISTORY.md`** (grep there by topic; the §5
  retraction grep covers it).

# THE LEDGER — archived sessions, one line each (newest first)

Full detail for every line: `STATE_HISTORY.md` (verbatim; grep the session
tag or any phrase below). `[+N more entries]` = the group has N further
session records in the archive beyond the headline shown.

- Session 14z-126 CLOSE — THE DF-STARTUP QUESTION ANSWERED (the window is `+0x147`, armed PER CHARACTER — neither global nor inherited), which the maintainer's "where do the values come from?" turned into a PRESERVATION FINDING (vs2 and vh2 carry the VS-style DF handlers for all 18 and never reach them, so the port RESTORED Capcom's own values) with its own document `docs/game/preserved_data.md`; and the frame-data privacy rule ruled and shipped the same session. No build changed; strict static 124/0/0/0  [+1 more entries]  [rolled 14z-126b CLOSE (2), early — STATE was 152 KB]
- Session 14z-125b CLOSE — THE COMMUNITY CROSS-CHECK DELIVERED AND THEN FINISHED IN ONE DAY: all 15 vanilla characters derived for the first time, ~96% agreement per column, the JOIN measured in-emulator after a fitted model was overturned, and the residue arbitrated — two families closed, one honestly open; two defects found, both OURS; no build changed; strict static 123/0/0/0  [+2 more entries]  [rolled 14z-126b close, early — STATE was 154 KB]
- Session 14z-124 CLOSE — THE DOCUMENTATION RATIONALIZATION PASS IS DONE (G7): engine_internals' last third rationalized and the document flipped to REFERENCE, doc_shape has ZERO PENDING, the ci floor 15 → 60, inferred_claims CLOSED; one tooling defect found on the way (the wrap-blind atlas-rows splitter); THEN CLAUDE.md PASS 2 the same day (414 → 344 lines; oracle_classes.md is the class spec of record). No build changed; portable 61/0  [rolled 14z-126 close]
- Session 14z-123 CLOSE — THE DOCUMENTATION RATIONALIZATION PASS, ONE DAY: T1 (annotations.md CREATED, generated), G2 (three T3 rigs — EVERY claim RETRACTED: Sasquatch's DF armor, the roulette tag, the advancing guard), G3 (a)+(b), G4, G6 (HANDOFF 3,652 → 1,374; the gate index GENERATED), CLAUDE.md pass 1; no build changed; PUSHED  [+1 more entries]  [rolled 14z-125b close]
- Session 14z-122 CLOSE (2) — ritual complete for the CONTINUED session: two new rulings recorded (the annotations row is CHECK-FIRST; THE CLAUDE.md CONDENSING PASS is a named item), G1 executed after the specimen's ratification — eight document commits, the atlas retagged, 6 docs still PENDING  [+3 more entries]  [rolled 14z-125b close]
- Session 14z-121 CLOSE — ONE DAY, FROM THE M12 VERDICT TO THE CHARACTER PAGES: the board verdict GREEN; the Killshread ruling; the phase-3 remainder; the pushback = a STEP TABLE on record +0xC; the three CHARACTER PAGES; no build changed; PUSHED  [+7 more entries]  [rolled 14z-123 close, early — STATE was 158 KB]
- Session 14z-120 CLOSE — ONE DAY, THE CHARACTER-DATA MAP FROM THE MOVE LISTS TO PHASE 3: the three move lists, every chain NAMED on native vs2 (`test_move_naming`), the hitbox encoding / attack record / reaction sets MEASURED; no build changed; strict 117/0/0/0  [+4 more entries]  [rolled 14z-123 close]
- Session 14z-119 CLOSE — THE PHYSICS-PORT FREEZE: donovan-m18 / huitzil-m25 / pyron-m19 / merged-m14 (mark M12), the stock twin MOVED by design; strict 117/0/0/0; FIELD VERDICT GREEN 14z-121  [+1 more entries]  [rolled 14z-122 close]
- Session 14z-118 CLOSE (3) — the session's close. One day, four arcs: the M11 board verdict  [+4 more entries]  [rolled 14z-121 close]
- Session 14z-117 CLOSE (3) — the session's last act. The VS/VS2 data-architecture page CORRECTED from a row-by-row measurement after the maintainer read it; the next session is RULED: a full documentation audit — measured, consis… [+4 more entries]
- Session 14z-116 CLOSE — THE COSMETIC/EXTRAS ARC: win quotes MEASURED THEN FORGONE, the hidden characters DECODED (Shadow takes the tenant — confirmed on the board), and PYRON'S MEDALLION WHITE-OUT FIXED after two years parked; 13 commits pushed; nothing frozen (the freeze battery = 14z-117). The close ritual audited: patch_notes/patch_index/HANDOFF/gotchas had been skipped on the first pass and were written.
- Session 14z-115 CLOSE — THE SELECT-WHEEL SEPARATION FROZEN (donovan-m15 / huitzil-m22 / pyron-m16 / merged-m11, mark M9, stock twin unchanged), tagged at `b30611a`, strict 111/0/0/0, guard corpus 340/340; emulation verdict "no regression", the maintainer's own mockup the next cut (moved to STATE_HISTORY 14z-118)
- Session 14z-115 — THE SELECT-WHEEL SEPARATION ("E2"): the three tenant medallions repositioned by the maintainer's pixel offsets, hover rings tuned by eye, a 1 px black outline authored per cell; the OPEN FBNeo two-run-family instrument question first recorded (moved to STATE_HISTORY 14z-118)
- Session 14z-114 CLOSE — ALL SIX SKILLS DISTILLED AND LOCKED TO THE DOCS in one session (the MiSTer pair, the CPS-2 pair, the game skill and the port skill — 425 rules, every one anchored in the paragraph it distils, every number in a log; four staleness passes run first, each its own commit) (moved to STATE_HISTORY 14z-117)
- Session 14z-114 — the MiSTer SKILLS distilled with their checker: two skill packages (level 1 `[MSC-1..73]`, level 2 `[MSV-1..36]`), every rule ID-anchored in the doc paragraph it distils; the log gained the 14z-108/109 measurements it never had; the field test got an in-tree carrier (moved to STATE_HISTORY 14z-117)
- Session 14z-113 CLOSE — the MiSTer SCOPE DOCUMENT written and its three decisions ruled; the S1-S20 staleness pass run; bundle 14z112 field-verified; merged-m10 FROZEN; the RELEASE FORMAT ruled and shipped (one self-sufficient directory per platform) (moved to STATE_HISTORY 14z-116)
- Session 14z-113 — `docs/project/mister_scope.md` written (scope only, not the skills): the two-level split, the doc dependency map, and the known-stale inventory S1-S20 (moved to STATE_HISTORY 14z-116)
- Session 14z-112 CLOSE — #99 CLOSED on a green field verdict (the board on bundle 14z111 / merged-m9 M8 does not crash on Bishamon > Phobos; MAME agrees on four hand-played recordings, all guard-clean, tracked as `play-merged-m9-01`, `run-merged-m9-02..05`); #112 (Press-of-Death palette) reproduced, ruled COSMETIC and parked; #113 measured VANILLA on emulator (the one-frame white-out at a down); the WIDE profile stopped breaking stock Vampire Savior — a WIDE set is ONE zip, the four patched group-A members inside `vsavjw.zip`, the parent pristine (`build/m3b_merged17`; frozen as merged-m10 at 14z-113) (moved to STATE_HISTORY 14z-115)
- Session 14z-112 — FIELD VERDICT GREEN on merged-m9 (M8): #99 CLOSED by the maintainer; the four recordings tracked; #113 re-read as a sprite-dropout frame; playback length now MEASURED (a recording ends where the human stopped; `test_inp_corpus` plays to MAX_FRAMES=6000 by default) (moved to STATE_HISTORY 14z-115)
- Session 14z-111 CLOSE — #99 ROOT-CAUSED (CPU-Phobos ran DEMITRI's AI: the four per-class AI action-script tables `PRG:0xBF01A/09A/11A/19A` are 16 classes + the same 16 repeated, so tenant classes read the aliased row) AND FIXED by option A (the tenants' own vs2 AI script blocks as data roots, zero code); frozen donovan-m14 / huitzil-m21 / pyron-m15 / merged-m9, mark M8; board bundle 14z111 ready; FIELD REPORTS ARE RECORDINGS promoted to CLAUDE.md §4 law with `tests/test_inp_corpus.sh` (moved to STATE_HISTORY 14z-114)
- Session 14z-111 — OPENED WITH A CLOSE-RITUAL AUDIT of 14z-110b (clean but unchecked): the three in-flight validations re-run and accepted; then the field verdict RED on merged-m8 (the board STILL crashes on Bishamon > Phobos, MAME by hand too) -> the maintainer's hand-played `.inp` captured under the new `tools/run_inp_guarded.sh` found the real mechanism the two poke-derived fixes never touched (moved to STATE_HISTORY 14z-114)
- Session 14z-110b CLOSE — the 0x51->0x44 remap BUILT, FROZEN (donovan-m13 / merged-m8, M7 mark carried) and MAME-VALIDATED; the board bundle carries merged-m8; the FBNeo partial oracle's reduced refit RULED and in progress; closed at the maintainer's call (context ceiling) with three validations in flight — re-run and accepted at the 14z-111 opening audit
- Session 14z-110b addendum — THE FBNEO ORACLE RED ROOT-CAUSED TO THE RULED d2-WINDOW CYCLES (110), NOT THE REMAP (110b): m12 == m13 RAM at the failing frame; the hunt cost a paid-for instrument trap; resolution = per-replay measured-clean frame overrides, 26_don_arcade_mash dropped for 05_timeout_idle (maintainer-ruled)
- Session 14z-110b — THE RESIDUAL #99 ROOT-CAUSED AND THE REMAP RULED-BY-CONDITION: the STORED state 0x51 over-runs a SECOND 80-vs-84 dispatcher (PRG:0x2384E) the 14z-43 audit also missed; fix = 0x51 -> 0x44 on the six deity nodes + one ported immediate, measured equivalent at every consumer both engines have. (Field: STILL CRASHED — the real #99 was the AI script-table alias, found 14z-111 from the maintainer's recording.)
- Session 14z-110 (4) — CLOSE. THE RULED ORDER IS COMPLETE: FIX -> AUDIT -> RE-FREEZE. The #99 d2-window fix built, audited and frozen (donovan-m12 / merged-m7, mark M7), with the MiSTer CRC tail and a field bundle. Its verdict came later and was RED: the crash survived, and 14z-111 root-caused the real mechanism.  [+3 more entries]  [rolled 14z-112 close]
- Session 14z-109 (4) — THE #99 CRASH INVESTIGATED ON EMULATOR after the FIELD TEST PASSED on a real DE10-Nano (tenants selectable, playable, voices heard, feel better than emulator) with one 100%-reproducible crash. Root-caused the same day to vs2 type byte 0x51 in Donovan's ported block — a conclusion 14z-111 later RETRACTED as poke-contaminated. Also: the OBJ-list oracle, the DECISIONS_HISTORY split.  [+3 more entries]  [rolled 14z-112 close]
- Session 14z-108 CLOSE — ritual complete. THE FUNCTIONAL CHAIN IS COMPLETE IN SIMULATION AND THE CORE FITS A CYCLONE V — BUT IT DOES NOT RELIABLY CLOSE TIMING. A tenant FIGHTS on the core and fights CORRECTLY against MAME; the QSound extension is FETCHED; bank 1 under load is GO; scroll is structurally cleared; the CPS-2 video registers are documented for the first time. AND THE SESSION'S OWN HEADLINE IS THAT FOUR OF ITS FINDINGS WERE CORRECTIONS OF THINGS PUBLISHED EARLIER THE SAME DAY — three of them mine. 22 commits, ALL LOCAL.  [rolled 14z-111 close]
- Session 14z-108 — THE SIM HARNESS'S DIRECTION BITS WERE REVERSED END FOR END, NOT TRANSPOSED IN TWO — measured on all four before one bit was changed, and the half nobody had exercised is where the previous reading was wrong. `tools/rpl2siminputs.py` fixed (one dict, no fork commit, no RTL), verified against the game's own input mirror on both implementations, and the gate rebuilt with a per-direction lock and a must-fire control. One of the two frozen expectations the record said would move DID NOT MOVE AND COULD NOT — which also means the frozen sim anchor could not move. AND THE PAYOFF LANDED THE SAME SESSION: OBJ BANK 4 — THE FIGHTER ART — IS FETCHED FOR THE FIRST TIME ON ANY FPGA IMPLEMENTATION, 843 OF ITS TRAFFIC FRAMES INSIDE A MATCH. A TENANT HAS FOUGHT ON THE CORE. Bank 1 under load answered from the same run and it is GO. Still never: HARDWARE — and no Quartus synthesis has ever been run, so resource fit and timing closure are unknown. That is now the largest gap in the arc.  [rolled 14z-111 close]
- Session 14z-107 CLOSE (final) — THE WIDE ROMSET BOOTS ON THE CORE, draws our select screen and fetches our wheel art: six RTL slices D0-D5 (the MRA, the runtime profile gate + QSound width, the SDRAM placement, the CPS-2 Turbo object promote, the 6 MB program window, and D5 THE DECRYPTION RANGE — the CPS-2 key's encrypted-opcode range word is stored COMPLEMENTED and jtcps2_dec_ctrl reads it straight, which no stock CPS-2 game could ever expose); 105 distinct tenant tile codes out of obj bank 5 with the control leg at zero; bank 0's traffic under the redirect ANSWERED and GO; both stock legs green. **The arc's headline was methodological: SEVEN instrument and harness defects found in this lane, every one of which would have read as an RTL fault, with D5 the counter-example where the RTL genuinely was at fault.**  [+3 more entries]  [rolled 14z-108 close]
- Session 14z-106 CLOSE — ritual complete: HOUSEKEEPING executed (the 14z-105 evidence logs + the guard-corpus TSV committed, the rehearsal probes attic'd, `../build_attic_14z102` 8.1 GB deleted under the standing policy, `emu/fbneo`'s modified content verified as patches 0001+0002) and THE MiSTer ARC OPENED with no RTL touched — the framing RULED (an EXTENSION OF JOTEGO'S jtcps CORE, not an FPGA re-implementation of MAME) and all five alignment questions answered the same day (separate core, GPL-3.0 fork, measure-then-choose profile, sim = gate / hardware = field test, MRA+RBF with a stock-vsavj reference leg); LICENSE = GPL-3.0; slice A landed the public fork `DefinitelyFrenchName/jtcores@vampire-saved` with the separate core `cores/cps2w` -> `jtcps2w.rbf`, pinned as submodule `emu/jtcores` + `tools/setup_jtcores.sh` + gate `test_jtcores_twin`, and the twin proof MEASURED (the vsavj MRA byte-identical to stock cps2's except `<rbf>`); slice B measured the fit (`mister_fit.md`: PRG 4.82 MB, QSound banks 0x80-0x8E all aliasing, GFX 52,347 roster codes / 6.39 MB against 4,028 blank tiles / 0.49 MB in ALL of vanilla's 32 MB — a wider GFX tier REQUIRED) and slice C proved THE VERILATOR SIMULATION LANE ON macOS (stock jtcps2 running vsavj, ~1.4 s/frame, the full recipe in `docs/platform/mister.md`, the `.rpl` -> `sim_inputs.hex` translator gated)  [+3 more entries]  [rolled 14z-107 close (final)]
- Session 14z-105 CLOSE (final) — THE MAINTAINER-DIRECTED WINDOW EXECUTED END TO END and field-confirmed: W1 the OBORO SELECT HOOK (cursor on Bishamon + hold START -> vanilla vsavj's Oboro, id 0x18, P1 and P2, vanilla's own Gallon-variant idiom one cell over) and W2 the VERSION STRING ("M6" at the select screen, the naked-eye A/B tell CLAUDE.md §5 had wanted since 14z-92, authored glyphs pixel-exact) — frozen as donovan-m11 / huitzil-m20 / pyron-m14 / merged-m6 with the stock twin m5_stock6 = `883e7d17` BIT-IDENTICAL, every gate and both soaks green, pushed 2026-08-22; the GFX TILE CODEC was found MIRRORED on the way (plane bit i draws at pixel 7-i; 14 sessions old, nothing had ever read pixel ORDER until the first authored tile) and the 14z-104 prediction that more sprites would move the select-window specs DIED by measurement over all 148 specs; RELEASE PACKAGING landed (`release/merged-m6/`, xdelta3 against the reference dumps, no ROM byte in the package) and was ruled IN-TREE until MiSTer  [+3 more entries]  [rolled 14z-107 close]
- Session 14z-104 CLOSE — THE §4 COVERAGE DEBT TACKLED end to end (maintainer-directed): the mandate measured cell by cell, six new audits built and green on merged-m5 and the matrix documented as a maintained artifact; THE PURSUIT answered and instrumented (audit_pursuit_leap); coverage gap 1 (tech roll + throw tech, both directions) and gap 2 closed; THE OBORO QUESTION answered with a live demonstration; the 14z-105 window (Oboro hook + version string) prepped in NEXT_SESSION  [+4 more entries]  [rolled 14z-107 close]
- Session 14z-103 — THE A4 PIN-CLEANUP PASS EXECUTED (every stale reference re-pointed, run green, or ruled a deliberate pin) plus the three findings it surfaced (the gate_failures litter class, GitHub #110, four LEGACY replays promoted off self-frozen .sha1); #110 FIXED AND CLOSED — the mechanism was the ARCADE DRAW, not cycle drift, both audits re-derived on pinned-opponent rigs and green on merged-m5; the Circuit Scrapper report measured and not reproduced  [+1 more entry]  [rolled 14z-107 close]
- Session 14z-102 CLOSE — THE #107+#109 WINDOW frozen as donovan-m10/huitzil-m19/pyron-m13/merged-m5 (#109 re-derived from scratch to effect-class ROW 31, the DF clone-mode beam emitter vsavj stubbed; #107 row flip; gold tint kept; build-dir triage 8.1 GB atticked; N-2 deletion policy adopted)  [+6 more entries]  [rolled 14z-105 close]
- Session 14z-101 CLOSE — the agreed #108->#107->#106 sequence executed windowless (#108 INVERTED to not-a-defect: the satellite word is our own bank row, native satellites equally sweep-inert; #107 twin-anchored statically + tie-refusal landed; #106 closed via verify_pcrel_data --extract); guard-corpus built 316/316; DF mechanics measured ours-vs-native (frameworks differ BY DESIGN; ours == pristine vsavj on the legacy control); #109 found, root-caused through two in-place retractions, and fully prepped  [+9 more entries]  [rolled 14z-104 close]
- Session 14z-100 CLOSE — THE HARDENING PROGRAM opened and executed same-session (pointer/flow comb H1, escape triage H2, the #99 continue-switch lock H3, the contact rig H4 with the -debug/non-debug instrument paradox left to 14z-101); #99 CLOSED (maintainer); #106/#107/#108 filed; the build-dir decision package delivered  [+3 more entries]  [rolled 14z-104 close]
- Session 14z-99 FREEZE + field-confirmation — THE WINDOW EXECUTED END TO END (donovan-m9/huitzil-m18/pyron-m12/merged-m4; #43(b)+#103+#104+#105; merged BIT-FOR-BIT the rehearsal; stock twin moved by design); field pass CLOSED all three tickets same day (incl. transformation throws) and un-parked #99; the skipped close ritual caught up post-freeze  [+7 more entries]  [rolled 14z-102 close]
- Session 14z-98 CLOSE — #103 root-caused+staged (window = uncomment+battery), #102 answered (vanilla's own continue), #104 found/reproduced/mechanism-closed-then-14z-99-corrected, #105 filed + AUTO selection solved, "instance 2" retracted (the 2-byte-poke class); NO SHIPPED BYTE MOVED  [+9 more entries]  [rolled 14z-101 close]
- Session 14z-97 CLOSE — #96 CLOSED (the battery's target FOLLOWS THE BUILD via registry.tsv); the §4 masked-compare vocabulary unified to ONE implementation (tests/lib/masked_compare.sh, proven 3 ways); the #99 continue rig BUILT and blocked one screen short by #103 (instance 2); #102 filed (arcade chaining quirks); 08_challenger_join's 3807 attributed to $FF06E1 (ram.md:62); two measured-wrong-thing defects fixed (propose_masked_specs absolute-builddir trap; the lifted diverge branch)  [+9 more entries]  [rolled 14z-100 close]
- Session 14z-96 CLOSE — ritual complete  [+7 more entries]
- Session 14z-95 — FOUR MAINTAINER RULINGS TAKEN, #52 LANDED, and the Phobos sfx report corrected from "a sound missing" to "a WRONG sound"
- Session 14z-94 (11) — THE MERGED-M2 PLAYTEST RESULT (maintainer, 2026-08-18, build/m3b_merged9 on MAME). NO REGRESSION — and one CRASH.  [+11 more entries]
- Session 14z-93 CLOSE — ritual complete  [+3 more entries]
- Session 14z-92 CLOSE — ritual complete  [+6 more entries, incl. GitHub #75 closed — the merged gfx-verify abort was a verifier artifact]
- Session 14z-91 CLOSE — THE LEGACY REGRESSION FIXED (obj_hook de-thunked: walker relocated, callers repointed; fixture-override deletion; type-6 change), m5/m13/m7 -> m7/m15/m9 re-freeze, EIGHT maintainer rulings applied (Rule 1 v2 retitle #35, PNG goldens ruled outside rule 7 #73, CI drafted #41...). THIS GROUP ALSO HOLDS, as ### sub-entries: 14z-90 (the 2026-08-15 adversarial audit re-judged, tier 1 complete), 14z-83..89 (Phobos DF gold block huitzil-m6, M5 voice samples design + Z80 driver RE, the 14z-85 owner-tag family, 14z-86 M5 voice batch, 14z-87 voice-class borrow + 87b beep/medallion, 14z-88 medallion revert, 14z-89 QSound ledger binding)
- Session 14z-82d — the playtest reports, measured  [+3 more entries]
- Session 14z-81 — THE MERGED-LEGACY MEASUREMENT: legacy safe, tenants not
- Session 14z-80 — THE N-TENANT LOOP: `main()` iterates, and the three traps that were not in the spec
- Session 14z-79 — (b') LANDED, AND BULLETA'S DARK FORCE WAS BROKEN FOR TEN SESSIONS
- Session 14z-71 — THE BEAM: row 16 of the effect-class table is a STUB in vsav, and underneath it vsav has no list-type 12
- Session 14z-76 — Pyron's EFFECT PALETTE ported; the "16-row hazard" retracted
- Session 14z-78 — `anim` MOVES: M3b's blocker was a hex literal
- Session 14z-77 — M3b slice C: rows get an OWNER, and the gating family asks it instead of the build scalar
- Session 14z-75 — PYRON FROZEN as `pyron-m1` (d8b282da)  [+1 more entries]
- Session 14z-74 — PYRON's render rung OPENED (Steps 0/1/3 landed), and a GENERATOR BUG found under it  [+1 more entries]
- Session 14z-73 — the grab victim: FIXED and MAINTAINER-CONFIRMED (both grabs, MAME + FBNeo). The victim's capture-pose keyframe-pointer table row for H aliased character 0's block; ported H's own block. Also: the FG "slowness" was the broken GFX, not timing — resolved by observation.  [+1 more entries]
- Session 14z-71 CLOSE — ritual complete  [+6 more entries]
- RESOLVED the same session — TAKE OVER THE DEAD LIST-TYPE 6 (maintainer-approved; build/hui20, fingerprint 40cc10b1)
- Session 14z-70 — THE BEAM IS AN ANIM-SELECTION DEFECT: our build never walks the beam anim nodes (measured, both legs, one emulator)  [+3 more entries]
- Session 14z-69 CLOSE — ritual complete  [+8 more entries]
- Session 14z-68 (the effect-flow closure — root cause found)
- Session 14z-67 (D4: the Phobos gfx vertical)
- Session 14z-66 (playtest round-1 worklist)
- Session 14z-65 (M3b OPENED 2026-08-07 — plan + decisions register)
- Session 14z-64 SESSION CLOSE (2026-08-07)  [+3 more entries]
- Session 14z-63 (phase 3 item 1: the wheel bank-5 move — REAL MEDALLION ART, vanilla cells pixel-identical by construction)
- Sessions 14z-62j/62k (same day — OPTION A PHASES 1-2 LANDED and PLAYTEST-VALIDATED: the select family serves from group C bank 5; Jedah confirmed indistinguishable from vanilla by human playtest)  [+1 more entries]
- Session 14z-61 (WIDE GARBLE FIXED — a shadowed ROM member, not the emulator; and the rendering gate that should have caught it)
- Session 14z-60 (select cursor MEASURED; the id space is CONVENTIONAL)
- Session 14z-59l (ROSTER ACCESS decided; the vs2 wheel measured properly)  [+1: 14z-59j dual-track invariant established — later SUPERSEDED 14z-94 (#95), see the archive's marked banner]
- Session 14z-59i (M5 SOUND IS AUDIBLE; WIDE build registered; a false fingerprint corrected)  [+5 more entries]
- Session 14z-49 (rounds 61-62: HUD MUGSHOT + NAME + SELECT MEDALLION — the whole per-slot venue-asset family fixed)
- Session 14z-58e (handoff hygiene: reproducibility PROVEN)  [+1 more entries]
- Session 14z-57 (WIDE B4 attempt 2 — clean fail, narrowed to the loader)
- Session 14z-56 (WIDE B4 attempt 1: an invalid canary, honestly)
- Session 14z-55 (WIDE B2 — the 19-bit tile address; and the gate's video blind spot)
- Session 14z-54 (WIDE Phase B0+B1: the first two regions grown and proven inert)
- Session 14z-53 (RE-CONTEXTUALIZED: from "fit in the holes" to CPS-2 WIDE; Phase A measurements complete)
- Session 14z-52 (M5 phase 1: music bug root-caused; 13 rows restored; the rest is a SPACE problem)
- Session 14z-51 (M5 sounds: discovery phase — the id-space myth dies)
- Session 14z-50 (round 65: M2b+ASSETS FREEZE at b91647c7)
- Session 14z-49d (round 64: mask window RATIFIED; recolor necessity proven; audit script)  [+2 more entries]
- Session 14z-48b (rounds 59-60: HC moves maintainer-CONFIRMED; HUD portrait = wrong ART not palette; select medallion re-listed)  [+1 more entries]
- Session 14z-47 (SELECT POST-CONFIRM BLINK FIXED — accent thunks gain the owner-link venue fallback; battery pending at entry time)
- Session 14z-46 (SWORDLESS-DEITY PALETTE FIXED — the state_hook seq-id synthesis was wrong for 8 of 12 stubs; battery pending at entry time)
- Session 14z-45b (round 56 on 4f69589d: win screen maintainer-CONFIRMED; lose/continue NO-ISSUE)  [+1 more entries]
- Session 14z-44c (round 55: WIN-screen item corrected + sharpened)  [+2 more entries]
- Session 14z-43b (round 52 on 22ada38e: THE NEUTRAL-POSE TRIGGER FOUND — it's the ES FINISH; death-path class consumer = the suspect)  [+1 more entries]
- Session 14z-42c (round 51: LP/MP closed as native; ES = the known class-0x51 interim, UPGRADED to accuracy item; win-screen art item added; KO bug parked)  [+2 more entries]
- Session 14z-21 (queue: alt-color item closed NO-BUG; mirror native-exact; 2026-07-31)  [+1 more entries]
- Session 14z-41 (call-pair audit: pair 3 = the known sound stub; PAIR 1 = the real suspect — a lost spawner)
- Session 14z-40 (mash bridge: the walker block audited clean — divergence narrowed to three reconciled engine-call pairs)
- Session 14z-39 (round 49: maintainer clarifications — the Lightning Sword reference data)
- Session 14z-38 (mash bridge: three fields exonerated; theory sharpened to the input-struct read)
- Session 14z-37 (round 48: shock CONFIRMED with a caveat — hit counts maxed; mash mechanic mapped to the doorstep)
- Session 14z-36 (SWORDED-421P SHOCK + DEATH FIXED — the final reconcile; the class-0x4E saga closes)
- Session 14z-35 (type-0x51 cluster resolved — the engines RENUMBERED the copy-class record family; latent crash preempted)
- Session 14z-34 (round 46: crash fix CONFIRMED + swordless shock RESTORED — the record-type insight reframes the remaining queue)
- Session 14z-33 (COLUMN CRASH FIXED — record-type dispatch aliases; permanent guarded gate)
- Session 14z-32 (round 45: blink fix CONFIRMED everywhere but the select screen; column-crash fix session)
- Session 14z-31 (round 44: BLINK ROOT-CAUSED + FIXED (color-aware accent); CRASH REPRODUCED + PINPOINTED)
- Session 14z-30 (round 43: crash triage — repro scaffold built, blocked on the plant input; classification of the other reports)
- Session 14z-29 (consumer-trace session: supplementary facts; repo stays at the 14z-28 interim)
- Session 14z-28 (round 41: 14z-27 class remap REVERTED — gameplay regression; three-consumer map final; deity palette item confirmed)
- Session 14z-27 (round 40: CHANGE IMMORTAL KO FULLY FIXED — native class remap; aura palettes explained)
- Session 14z-26 (round 39: 421P correction -> ROOT CAUSE FOUND + partial fix shipped; collapse handoff remains)
- Session 14z-25 (round 38: select-sword CONFIRMED by maintainer; 421K match-end KO bug logged + repro hunt banked)
- Session 14z-24 (SELECT-SWORD FIXED — draw-behind flag; machinery live at stage 6, battery pending)
- Session 14z-23 (select-sword: diagnosis CORRECTED — offset+priority, not missing art; still staged 99)
- Session 14z-22 (select-sword: machinery BUILT+VERIFIED, staged 99 pending the record-walk-gap fix)
- Session 14z-21c (select-sword: FULL activation chain reverse-engineered; fix ready to implement)  [+1 more entries]
- Session 14z-20 (row-0x0F fixture override SHIPPED; sword-shock aura resolved as engine-global; 2026-07-31)
- Session 14z-19 addendum (round 36 CONFIRMED, 2026-07-31)  [+1 more entries]
- Session 14z-18 (round 34: accent super-cycle completed; statue rows found and fixed; two new items logged) — CONCLUSIONS CORRECTED IN 14z-19
- Session 14z-17 (THE SWORD/STATUE BLINK IS FIXED — build f4a7e00e)
- Session 14z-16 (blink: vs2 STEADY confirmed; the complete fix design)
- Session 14z-15 (blink driver FULLY mapped: the stage palette-anim refresh system)
- Session 14z-14 (sword-blink fix session: driver mapped to the palette-JOB system; third table repointed; ONE tap from the finish)
- Session 14z-13 (round 33: electrocute FULLY CONFIRMED incl. yellow; sword blink mechanism DECODED)
- Session 14z-12 (round 32: X-ray STRUCTURE confirmed; effect-palette block ported; purple-vs-yellow = DECISION)
- Session 14z-11 (round 31: the X-RAY OVERLAY — offset-computed records swept; build 6f96f45b)
- Session 14z-10 (THE GARBLE FIX SHIPPED: protected-tile policy + exception pool)
- Session 14z-9c (ROUND-29 ROOT CAUSE, FINAL AND PHYSICAL: the Jedah-band tile window is NOT dead)  [+2 more entries]
- Session 14z-8 (round 28: the 14z-7 clear was a PHANTOM FIX — reverted; the real shock-garble mechanism characterized)
- Session 14z-7 (Victor-shock garble FIXED — stale-OBJ countdown clear)
- Session 14z-6 (round 27: sword CONFIRMED; Victor-shock garble scoped)
- Session 14z-5 (round 26 continuation: SWORD SWING FIXED — build 2da7d910)
- Round 26 (2026-07-30, maintainer): 597ae55b re-confirmed clean
- Session 14z-4 (round 25: spark-thunk visual regression; full rollback to 597ae55b)
- Session 14z-3 (the sword-swing BLOCKER: mechanism fully mapped, fix staged)
- Maintainer priority statement (round 24, 2026-07-30)
- Session 14z-2 (throw teleport ROOT-CAUSED and fixed: victim-keyframe table)
- Session 14z (round 22: winpal copies convicted and fully reverted)
- Session 14x (round 20: throw rollback per maintainer; sword-attack rendering logged)
- Session 14w-c resolution (ALL GREEN at d6a751cb)  [+4 more entries]
- Session 14v (grab-pointer work vars fixed — the Felicia float)
- Session 14u (win-quote palette SHIPPED at 1f5fa38e — pending playtest)
- Session 14t (win-quote palette: decoded, port REVERTED by the gate)
- Session 14s (playtest round 16: overlay REVERTED; pixel gate born)
- Session 14r (overlay port COMPLETED to a 22-site shipping config)
- Session 14q (stage-7 overlay port: architecture PROVEN, closure blocked)
- Session 14p (feet fixed; blink mechanism = Jedah's overlay records)
- Session 14 highlights (M2a FROZEN)
- Session 14o (THROW DAMAGE FIXED — the fourth same-value class found)
- Session 14n (round 12: revert validated; two new items scoped)
- Session 14m (f8eda2ca REVERTED — regression + board reset)
- (reverted) Session 14l (bank-attribution fix)
- Session 14k-b (blink TRULY root-caused: per-record bank attribution)
- (superseded analysis) Session 14k (OBJ budget saturation theory)
- Session 14j (THE EFFECT TAIL SHIPPED — elemental swords restored)
- (earlier) Session 14i-b (round-9 mechanisms pinned)
- (earlier same session) Playtest round 9 diagnosis
- Session 14h highlights (win-quote portrait ported; HUD name found)
- Session 14g highlights (VS splash SHIPPED; three superset traps caught and fixed)
- Session 14f highlights (select palettes fixed; splash/win specified)
- Session 14e highlights (select phase 2 SHIPPED: portrait + name on screen)  [+1 more entries]
- Session 14d highlights (select-screen port: phase 1 = negative result, map corrected)
- Session 14c highlights (select-screen pipeline mapped)
- Session 14b highlights (M2b static phase — R2 cracked)
- Session 7 highlights (M2a stage 4 — frontier closed; the crash was ours)
- Sessions 5-6 highlights (M2a stage 4 — the port runs)
- Session 4 highlights (M2a — the real Donovan port)
- Session 3 highlights
- Early standing sections (Current milestone / Next actions / Open items / Decisions made) — 2026-07-era snapshots, STALE, kept verbatim in the archive; the closed early decisions (base revision vsavj, per-member checksums, byte-order convention) are all recorded in CLAUDE.md/HANDOFF too
- OPEN BUG (14z-60y): WIDE renders Donovan/Anita with WRONG TILES — FIXED 14z-61 (the shadowed-ROM-member hash-resolution trap); header kept as written

---

# STANDING SECTIONS (current state — never archived)
## STANDING PRINCIPLE (maintainer, 2026-08-05): vanilla wins ties

**[VSP-21]** "vsav vanilla is always better when we can." **When a console port and
arcade vsav differ and both would work, take vanilla.** A console port's
choice is not evidence that vanilla is wrong; it is evidence of what that
port's designers preferred.

This is a general rule, not a one-off: the PS1 capture is a reference for
what is POSSIBLE and for data we cannot otherwise obtain (cell placement,
the adjacency of NEW cells), not a style guide for content vsav already
defines. Paired with the maintainer's other statement — "as long as we can
select characters it's good" — the test is: does keeping vanilla still let
the feature work? If yes, keep vanilla.

Applied immediately, twice:
- **`Bishamon DL` and `Aulbath DR` stay vanilla** (Anakaris / Sasquatch).
  PS1 sets both to "no move"; neither is needed for reachability, so
  vanilla stands.
- **Horizontal wrap stays vanilla.** Vsav wraps left/right (cell `0x01`
  Left goes to `0x05`, measured and confirmed in-emulator); the PS1 report
  of "no wrapping" reflects untested extremes. We touch none of those
  cells, so nothing to decide.

Judgment applied under the same rule, open to veto: the three inbound edges
from `0x0B` (`D`/`DL`/`DR` into the new row) DO diverge from vanilla, and
strictly they are not required — Phobos and Donovan are already reachable
via `Bishamon D` and `Aulbath D`, and Pyron through them. They are kept
because without them, pressing Down on the cell directly above the new row
does nothing while three medallions are visible below it, which is the UX
failure "as long as we can select characters" is meant to exclude. Dropping
them would reduce the legacy footprint from 5 bytes to 2.

## Decisions pending (human)

*(Cleaned 14z-109, maintainer-directed: resolved and no-longer-shaping
entries moved VERBATIM to `DECISIONS_HISTORY.md` — grep there by topic.
Lifecycle: rulings are still marked DECIDED in place here first; they move to
the archive once they stop shaping active work.)*

- **#112's FIX — SCOPED 2026-09-01 at the maintainer's direction ("I'd want to
  scope the second properly before recommending it -> do it"). NOT STARTED;
  needs a ruling, and my recommendation is (C).**
  **THE SELECTION POINT, measured:** the palette source is
  `base + seq_id*32` with the base CONSTANT — Donovan's `+0x3A4` is written
  exactly twice in a 14,375-frame run (round starts, `PC 0x01C68E`, value
  `0x0CEB50`) and `[0x38C1E4]` holds the same pointer. So nothing about the
  base or the blocks varies: **only the SEQ ID does** — `1` for the default
  (Donovan's body palette, idx14 = `f111`) and `46` for the effect
  (idx14 = `fcff`). The black foot is seq 1 being re-requested 29 frames
  before the pool object finishes drawing.
  **THE PIECES AND WHO OWNS THEM** (all verified against `vanilla_op/data`):
  the copy routine `0x02AD20-0x02AD80` is VANILLA, byte-identical; the base
  pointer at `[0x38C1E4]`, the palette blocks at `0x0CEB50+`, the char-table
  row for id `0x13`, the resolver hook at `PRG:0x3FFAF0` and the palette
  animator at `PRG:0x471560` are ALL OURS (vanilla holds `0xFF` filler or a
  different pointer at each).
  **AND THE PORT ALREADY HAS OWNER-AWARE EFFECT PALETTES.** `0x3FFAF0`'s
  second branch reads the drawing object's OWNER (`+0x30`) and, if the owner
  is Donovan, resolves `[0x38C1E4] + owner(+0x3AE)*128`. It exists and is
  shipped — but it is NOT exercised here: all 24 palette writes in the window
  carry `A6 = $FF8400`, the PLAYER. The effect's sprites simply draw with
  pal row `0b`, which the player's machinery fills.
  **OPTIONS:**
  **(A) Delay the revert** — gate the seq-1 request while an owned effect is
  alive. Smallest byte-wise, WORST placed: the request site is on a path every
  character runs, so it needs a tenant-only condition on legacy-reachable
  code, plus a flicker-inventory measurement. It also changes WHEN a legacy
  data path writes, which is the class the superset invariant exists to
  refuse. NOT RECOMMENDED without a much stronger reason than a cosmetic.
  **(B) The effect owns its palette** — make the pool object request its own
  palette into its own row via the EXISTING owner branch. Architecturally
  right and reuses shipped machinery. **COST, and it is the reason this is not
  free: it needs a FREE PALETTE ROW** (unmeasured, and rows are scarce), the
  pool object must carry the fields the hook reads (`+0x30`, `+0x382`,
  `+0x3AE`, `+0x18B` — none verified present on pool objects), and every
  effect sprite record must be repointed to the new row. Two to three
  sessions, and a new render gate.
  **(C) RECOMMENDED — DO NOTHING TO THE BUILD, and say why in the docs.** The
  defect is one palette entry on one frame of one super, on a build the
  maintainer has already accepted as cosmetically imperfect. What CHANGED
  today is not the cost of a fix but the QUALITY OF THE RECORD: the mechanism
  is fully known, the 2026-08-28 "vanilla data" objection is retired as
  FALSE, and the work is now a scoped engineering task rather than an
  unknown. That is worth banking without spending a freeze on it.
  **WHAT IS STILL UNMEASURED, and (B) cannot be costed without it:** whether a
  free palette row exists, and whether pool objects carry the four fields the
  owner branch reads. Both are half a session.

- **A NEW SESSION SERIES — RESOLVED TOWARD (d) KEEP `14z-`, 2026-09-01;
  awaiting only the maintainer's one-word confirm.** The maintainer: "I like
  S127 but if there's a risk, even low, I don't mind keeping the 14z prefix
  honestly." **THE RECOMMENDATION FLIPPED FROM (a) TO (d), and NOT on the
  risk** — the risk is the wrong axis. The `checkdocshape`-blindness failure
  is a known three-line change that a must-fire control eliminates, which is
  this project's own standard for "not a risk"; residual is only an unknown
  fourth consumer (405 files grepped, 3 parses found). **The real reason is
  that the BENEFIT collapsed when the prefix was DOCUMENTED an hour earlier:**
  [VSP-162] fixes the confusion by explaining it, so a reader is un-confused
  in ten seconds, and what a rename adds beyond that is cosmetic legibility —
  bought at a PERMANENT second namespace and a seam that every future grep and
  reader must know, which no control removes. For a key whose whole value is
  resolving cleanly, a boundary is an ongoing cost against a cosmetic gain.
  If it is ever wanted, the cheap moment is a NATURAL BOUNDARY (a new
  milestone, or the MiSTer arc closing), not mid-arc. The options as put:** The existing keys are SETTLED:
  they stay as they are, resolvable forever ([VSP-162]). This is only about
  what the NEXT session is called. **Why it is even on the table:** the
  maintainer read [VSP-162] as written and asked "why are we still on session
  14?" — the prefix is fossilised and actively misleads (session 14 was ONE
  sitting, 2026-07-28, the M2a freeze; MiSTer opened 104 sessions later at
  `14z-106`).
  **Options:**
  **(a) RECOMMENDED — `S127`: drop the dead prefix, KEEP the live counter and
  the whole grammar** (letter suffix = continuation `S127b`; parenthetical =
  phase `S127 (3)`). The seam is one line — "S127 immediately follows
  14z-126b" — chronological order is preserved, every existing habit carries
  over, and nothing in the archive moves.
  **(b) Restart at `S1`. NOT RECOMMENDED: it COLLIDES** with the early bare
  integers still live in the archive (`Session 3`, `4`, `5-6`, `7`, `9`,
  `13`, `14`), so `S1`..`S14` would be ambiguous to exactly the greps the key
  exists to serve.
  **(c) Date-based (`2026-09-01a`).** Self-describing, but sessions are
  context windows (~8/day measured), so it needs letter suffixes anyway and
  buys nothing the counter does not.
  **(d) Do nothing** — defensible; the prefix is inert and now documented, so
  the confusion it caused is a one-time cost already paid.
  **THE COST, MEASURED 2026-09-01 (and it is small but has a TRAP):** of 405
  files mentioning `14z`, only THREE are PARSES —
  `tools/gen_gate_index.py:60` (`SESSION_RE`) and `tools/checkdocshape.py:78`
  and `:79` (`SESSION_TOKEN`, `CHRONO`). Everything else is prose citation,
  which is exactly why renaming old keys is forbidden and why a NEW series is
  nearly free. **THE TRAP: `checkdocshape`'s two regexes are the gate that
  bars a REFERENCE doc from re-accreting chronology (built 14z-126b). A new
  prefix not added there makes that gate SILENTLY BLIND to the new tags** —
  green while checking nothing, the failure mode that let eight freezes of
  chronology accrete in HANDOFF unseen. So the ruling, if it is (a), lands as
  ONE commit: three regexes extended + a must-fire control proving the new
  prefix is caught + the seam line in [VSP-162] and the port skill. No
  gameplay surface; the maintainer's convention, so theirs to rule.

- **FRAME DATA IN A PUBLIC REPO — DECIDED (maintainer, 2026-08-31: "I agree
  with the recommendation") AND IMPLEMENTED 14z-126, option (b).** THE CLASS
  RULE: every per-move ROM-derived table — OURS AND THIRD-PARTY ALIKE — is
  generator output kept OUT of the public tree; the tree ships the READERS
  and the VERDICTS, and currency is locked by hash instead of by publishing
  the numbers. What moved to `../charpages/framedata/` (new producer
  `tools/framedata_pages.sh`, which refuses an in-repo output dir):
  `<tenant>_anim.md` ×3, `<tenant>.html` ×3 (the artifacts are published from
  there now), `community_crosscheck_full.md` (the move-by-move comparison),
  `vanilla_hit_damage.tsv`. What STAYS in the tree: the generators, the
  verdict rows (`tests/expected/community_crosscheck.txt`, 91), the measured
  slot map (chain ids, not frame data), the mechanisms and "What is NOT
  known", and two new hash locks — `tests/expected/charmap_pages.sha256` (6)
  and `tests/expected/vanilla_hit_damage.sha256`. The committed
  `community_crosscheck.md` is now the VERDICT-ONLY rendering (1060 → 359
  lines, zero per-move value rows, no workbook values). History is ACCEPTED,
  not rewritten (the maintainer's call; a rewrite of pushed `main` was not
  done). The original entry follows.
  **The proposal, as recorded before the ruling:** The repo is PUBLIC
  (`DefinitelyFrenchName/VampireSaved`). The maintainer's position, in
  substance: frame data has been published in community docs and in
  Capcom-sanctioned mooks, so the DIFFS forwarded to the community are fine,
  but we should refrain from publishing the data ourselves — remove the
  public documents that carry it, keep them private, and instead ship TOOLS
  that regenerate the frame-data documentation from the romsets, as the
  character pages already do (`tools/charpages_internal.sh` -> `../charpages/`);
  argued as beneficial because the focus moves to the validity of the
  reader/interpreter and the documentation can never go stale. Claude's
  assessment (given in session): agree with the direction — it is [VSP-12]'s
  GENERATED-doc law applied one step further — with four riders: (1)
  regeneration guarantees CURRENCY, not correctness — both 14z-125 defects
  were interpretation defects a hash-locked page would have reproduced; the
  in-emulator rigs (`test_vanilla_frame_join`, the hit rig) stay the validity
  gates and carry no tables; (2) draw the line by CLASS, not file: per-move
  ROM-derived numbers live today in `community_crosscheck.md` (ours + the
  workbook's), the three tenant `_anim.md`/`.html` pages, and
  `tests/expected/vanilla_hit_damage.tsv` — the 91-row
  `community_crosscheck.txt` is already verdict-shaped; (3) the workbook's
  OWN values stay out regardless (the compilation is the author's work) —
  the delta-only `render_md` fix; (4) removing a file from HEAD does not
  remove it from the PUBLIC history (24 pushed commits) — accept-in-history
  is the recommendation; a rewrite of pushed `main` is destructive and the
  maintainer's alone. **Options:** (a) third-party values only out, ours
  stay; (b) RECOMMENDED — every per-move ROM-derived table (ours and theirs)
  becomes generator output under `../charpages/` via one route
  (`tools/framedata_pages.sh` beside `charpages_internal.sh`), the in-tree
  `community_crosscheck.md` keeps verdicts / mechanisms / counts /
  "What is NOT known" only, the tenant pages move to the same route, gates
  lock SHA-256s of the regenerated output under ROMDIR plus the verdict rows;
  (c) leave as is. Half a session for (b); the class boundary and the
  history question are the maintainer's to rule.
- **DF-STARTUP INVINCIBILITY FOR THE TENANTS — ANSWERED 14z-126, MEASURED,
  NO CHANGE NEEDED (DECIDED by measurement; nothing to rule unless a window
  is to be retuned).** The window is `+0x147` (the victim's invincibility
  timer, the hit test's gate at `PRG:0x018064`), armed PER CHARACTER by the
  seq-0x16 handler `dispatch_16` selects — NEITHER global (the shared body
  arms only `+0x143` = 0x14, the throw immunity) NOR inherited (the tenants'
  rows are repointed to their own vs2 handlers): Donovan 64 ticks (Victor 59),
  Huitzil 79 (Bulleta 41), Pyron 41 (Demitri 41, coincident by value). All 15
  vanilla values measured and frozen too (`tests/expected/df_startup_invuln.tsv`,
  gate `tests/audit_df_startup_invuln.sh`; engine_internals "Dark Force" ->
  "The STARTUP INVINCIBILITY window"). Natively on vs2: no window at all
  ([VSE-69]). Retuning a tenant is one data byte in its ported handler, if
  ever wanted. The original entry follows. **RECORDED, not started — and it is THE NEXT ARC
  (maintainer, 2026-08-31: the DF question first, then the Zabel j.LK patch,
  then Jedah's crouching recovery).** THE MAINTAINER SHARPENED IT (2026-08-31):
  not just *do the tenants have the startup invincibility*, but **if they do, is
  it a GLOBAL property of the DF activation or is it INHERITED FROM THE SHELL
  CHARACTER?** That third possibility is the one the tree makes most likely and
  the measurement plan below did not name: the tenants sit at variant ids
  `0x10`/`0x11`/`0x13`, which ALIAS base-half rows in every table vsavj did not
  repoint ([VSE-10]), so a flag read from an id-indexed row would hand Phobos
  Bulleta's, Pyron Demitri's and Donovan Victor's. **So the rig needs three
  legs, not two: the tenant, its SHELL character, and a legacy control** — if
  the tenant matches its shell rather than its vs2 self, the answer is
  inheritance and the fix is a repoint, not a port. The original question: do the VS2
  tenants get the invulnerable STARTUP window vanilla characters get at Dark
  Force activation? What the tree knows: activation is the shared body
  `PRG:0x027000` (seq 0x16, one stock) followed by the PER-CHARACTER
  `dispatch_16` row (`PRG:0x0BF31A`) — the tenants' rows are repointed to
  their ported vs2 handlers, which were written for vs2's DIFFERENT DF system
  ([VSE-69], `oracle`-independent: `engine_internals.md` "Dark Force"). So if
  the window is armed in the shared body the tenants inherit it; if it is
  armed in the per-character handler, they do not — that is the seam to
  measure. `ram.md` names `+0x11E/+0x134/+0x145/+0x1A4` as
  "invulnerability/status flags", class [C] (a candidate, never verified).
  Measurement (T3, half a session): replay 97's activation rig
  (`tests/replays/df/97_df_mech.rpl`, `audit_df_framework.sh`) with the
  opponent's attack timed to land INSIDE the startup window, legacy control
  Demitri (expect no hit) vs each tenant, positive control = the same attack
  landing outside the window; instrument = field_trace of `+0x54` /
  HP / the four flag bytes across the window; freeze as
  `tests/audit_df_startup_invuln.sh`. If a tenant lacks it, the fix is a
  GAMEPLAY decision ([VSP-10]) under the DF ruling above ("adjustments per
  character, never to the general mechanic") — options then: (a) arm the
  vanilla flag from the tenant's ported handler (a thunk on our own code,
  legacy-clean by construction); (b) accept. No recommendation before the
  measurement.
- **THE COMMUNITY CROSS-CHECK — our data vs the best community reverse
  engineering (maintainer backlog item, 2026-08-31, 14z-124). ~~RECORDED, not
  started~~ PHASE 1 DELIVERED 14z-125 (the maintainer's order: "start with item
  2 to get proper confirmed data"): all 15 vanilla characters derived, the
  standing-normal join MEASURED in-emulator, and every comparable column
  classified — ~96% agreement per move under one stated convention each
  (`docs/project/tables/community_crosscheck.md`, gates
  `test_community_crosscheck` + `test_vanilla_frame_join`). STILL OPEN, and
  named on the page: **~~the residual ~4% outliers are not yet arbitrated
  in-emulator~~ ARBITRATED 14z-125b — two of the three families closed (the
  damage residue is the WORKBOOK double-counting records that share the engine's
  +0x10 dedup key, confirmed by a hit rig 75/78; the duration bytes are the
  engine's, 334/380, but a frame-rate trace cannot resolve a one-frame
  convention, so startup +1 / recovery +2 stay named conventions). ~~STILL OPEN:
  Jedah's crouching recovery (+3, not +2)~~ **CLOSED 2026-09-02 — ARBITRATED IN
  ENGINE TICKS, AND THE RESIDUE IS THE WORKBOOK'S.** The instrument the entry
  said did not exist does: a write tap fires per WRITE, and `PRG:0x027F70`
  (`subq.b #$1,$20(a6)`) IS one engine tick, so the multi-tick frames that
  defeated the frame-rate trace are fully visible. **18 of 18 derived totals
  equal the engine's measured tick count EXACTLY** (JE, LI, DE crouching
  normals; no tolerance). Our `startup` and `active` are not flagged and agree
  with the workbook's own conventions, and the total is now ground truth — so
  our recovery is right and the workbook's sits one frame below its own
  convention for those seven moves. `tools/tick_durations.py` +
  `tests/test_tick_durations.sh` (with a must-fire control). **THE SEVEN AERIAL OUTLIERS — PARTLY RESOLVED 2026-09-02.**
  `tick_durations.py` separates the move from the jump for chains that LOOP
  (BI 5/6 exact; the miss is the flagged `J.HP`, ours 28 vs the engine's 27; BU
  `J.LK`/`J.LP` exact). NOT separable yet: aerials whose last node HOLDS with no
  further pointer write before landing (VI, FE, SA) — those still report
  AIRTIME, and identical numbers across a character's moves are the tell.
  **THE LIKELY CAUSE IS NOW NAMED, from the community corpus that arrived
  2026-09-02:** mizuumi distinguishes NEUTRAL-jump from FORWARD-jump variants of
  the same button (`8J.LP` vs `9J.LP`, `J.HP8` vs `9J.HP`) where our slot map
  carries ONE chain per aerial button. If the flagged moves are exactly those
  whose variants differ, we are collapsing a variant, not miscounting. Needs a
  two-direction jump rig; not yet measured.
  ~~`red damage` needs the [VSE-40] scaler to be comparable at all~~ **WRONG and
  RETRACTED 14z-125b: the workbook's `red damage` is our `+8` PLUS `+9`, the
  move's total — 266/281 (94%) once compared as the sum;**
  specials / supers / throws / the `CL.` and `6`-prefixed rows need their own
  vsavj naming rigs (the bulk of the workbook's 730 rows); seven workbook
  columns have no counterpart in the tree. The WIKI half — the 146
  player-struct offsets against `ram.md` — was DEFERRED by the maintainer this
  session to item 1's session, whose lead `+0x1B3` sits in the same table; note
  the page carries NO per-move frame data, so it was never a second frame-data
  source. The original entry follows.** Two sources the maintainer will provide: a
  WEBPAGE, and an EXCEL of frame data for the VANILLA characters. What we
  have: frame data DERIVED for the three tenants only (`docs/project/tables/
  chars/<tenant>_anim.md` "Frame data (derived): startup / active /
  recovery", read off anim-node durations + attack records by the charmap,
  phase 2, 14z-120/121; move identities measured on native vs2 by
  `test_move_naming`), and NOTHING collected for vanilla characters; the
  derivation has never been checked against an independent source. Plan:
  (1) inputs — the URL and the `.xlsx`, kept OUTSIDE the tree (third-party
  work; we commit only our comparison and cite the source); (2) derive the
  same figures for the vanilla characters from vsavj's own 32-row bank
  (does `tools/charmap_gen.py` walk a vanilla character? if not, extend it —
  the bank is per-character by law) and compare per move: startup / active /
  recovery, damage, hit counts; (3) every mismatch is MEASURED in-emulator
  on vanilla (a replay + field_trace) — the emulator is the arbiter, not the
  sheet and not our derivation; (4) if the sources cover vs2, compare the
  tenants' derived figures the same way. Deliverable:
  `docs/project/tables/community_crosscheck.md` + a gate freezing the
  agreements and naming the measured disagreements. Cost: T3, one to two
  sessions. **INPUTS RECEIVED 2026-08-31 + THE RULE, maintainer's words:**
  "measurement is king, not a source that we don't know how it was measured;
  however, community information is precious: if it aligns perfectly or
  with a constant offset, then we know the measure is good; if we find an
  inconsistent pattern, then we must search whether the measurement is
  correctly done or not." So every column's deltas are classified EXACT /
  CONSTANT OFFSET (a convention difference — state it) / INCONSISTENT (a
  defect in somebody's measurement — re-measure OURS in-emulator first).
  The sheet: `../community/vsav-framedata.xlsx` — 15 sheets = the 15
  vanilla characters (FE AN AU BI BU DE GA JE LE LI MO QB SA VI ZA; ~37-68
  moves each), per move `startup / active / recovery / on hit / renda on
  hit / on block / renda on block / throw tech / red damage / white damage /
  gauge whiff / gauge block` (AN adds gauge hit / cancel / guard);
  multi-hit actives as text (`2(4)3,2`, `3{(3)3}x6`); NO vs2 characters, no
  Oboro / Dark Gallon. **Sheet names = the first two letters of the
  JAPANESE character name (maintainer-confirmed 2026-08-31), mapped to our
  ids:** BU Bulleta `0x00` · DE Demitri `0x01` · GA Gallon `0x02` · VI
  Victor `0x03` · ZA Zabel `0x04` · MO Morrigan `0x05` · AN Anakaris `0x06`
  · FE Felicia `0x07` · BI Bishamon `0x08` · AU Aulbath `0x09` · SA
  Sasquatch `0x0A` · QB Q-Bee `0x0C` · LE Lei-Lei `0x0D` · LI Lilith `0x0E`
  · JE Jedah `0x0F` (the two to not confuse: LE = Lei-Lei, LI = Lilith).
  The webpage:
  https://mizuumi.wiki/w/Vampire_Savior/Reverse_Engineering ("arguably the
  best source of deep information on Vampire Savior") — BLOCKED for any
  fetcher by a bot challenge (WebFetch 403; curl with a browser UA gets the
  challenge page) — **RESOLVED 2026-08-31: the maintainer saved it as a PDF**
  (`../community/Vampire Savior_Reverse Engineering - Mizuumi Wiki.pdf`,
  74 pages; text extracted with `pypdf` in a scratch venv — poppler is not
  installed — to `../community/mizuumi_reverse_engineering.txt`, 74 K
  chars, 421 address tokens). Both sources stay out of the tree.
  **FIRST-PASS INVENTORY of the wiki page (14z-124; an inventory, NOT an
  adoption — nothing in the atlas changes until measured):** sections =
  the CPS2 memory map, the IVT, RAM maps by base (`$FF8000` globals, `$FF8280`
  stage/camera, `$FF8400/$FF8800` the player struct — CPS2 AND the PS1
  `MIPS 0x8D8400` mirror), graphics/palettes/raster matrices, ROM function
  and per-character data/function tables, per-character move
  "Conditions" (pp. 25-63), data structures, palettes, backgrounds, HUD.
  Method not stated (credits "Thanks Jed"; disassembly-shaped comments);
  region unstated — but `0x275CE` / `0x28D50` / `0x2246E` sit exactly at our
  vsavj addresses. Their player struct: 146 offsets, 52 also named in our
  `ram.md`, 94 only theirs (candidates), ~50 only ours. CONVERGENCES with
  our measurements: `+0x110/+0x111/+0x176` the vsavj DF fields (they name
  `+0x17B` "Dark Force Flight" — Huitzil's form), `+0x189` DF timer
  reduction, `+0x3B4` "CPU Opponent Flag"; and the 14z-123 advancing guard
  field for field under VS's OWN NAME, **Tech Hit**: `0x275CE` "Tech-Hit
  Checks", `0x28D50` "Tech-Hit Chance Tables" (our RNG table), `+0x170`
  Tech Hit Input Counter, `+0x171` Tech Hit Active State (0x10 frames — the
  consumer we never traced), `+0x1AB` Tech-Hit Timer, `+0x1B0` Push-block
  Push-back Timer, `+0x126/+0x127` Mash to Escape. DIRECT LEAD for the DF
  backlog item: **`+0x1B3` "Dark Force Startup"** and `+0x1B5` "Dark Force
  type-2 (HP+HK)" (we had read `+0x1B5` as set by JUMPING — a disagreement),
  `+0x147` "Invincibility Timer" (ours: the multi-hit re-hit gate —
  compatible), `+0x143` Throw Invulnerability Timer; ROM `0x26FD2` DF
  Activate / `0x2706E` DF Deactivate bracket our activation body `0x027000`.
  DISAGREEMENTS to measure: `+0x161` "Oboro Fight Flag" vs our live-measured
  Sasquatch DF accumulator (`audit_df_accumulator`, 9 frozen lines — ours is
  a measurement, theirs a name; the byte may serve both); `0x2246E` "System
  Timer Reducers" vs our "class-0xFF block handler" (14z-123). Naming to
  adopt after measurement: "Tech Hit" beside "advancing guard". **BOTH
  RESOLVED 14z-126 (the opcode listing): `0x2246E` IS the System Timer
  Reducer (one `subq.b` per tick on `+0x147/+0x174/+0x143/+0x158/+0x1AB`);
  the block window is OPENED by the block-entry handler `0x2395A`-`0x23966`
  — 14z-123's write tap had named the decrementer, corrected in `ram.md`,
  engine_internals and `test_advancing_guard.sh`; and `+0x161` is a
  per-character DF WORK BYTE written by Sasquatch's (the measured
  accumulator), Bishamon's, Anakaris's and Aulbath's handlers — mizuumi's
  "Oboro Fight Flag" is Bishamon/Oboro's use of it: both names true. Four
  wiki rows adopted into `ram.md` with the mechanism measured or read
  (`+0x134`, `+0x145`, `+0x143`, `+0x1B3`); the other ~90 candidates stay
  unadopted [C].**

- **THE CLAUDE.md CONDENSING PASS (maintainer-directed 2026-08-30, 14z-122
  close). PASS 1 DONE 14z-123 (441 → 414 lines; narratives → rule + citation;
  anchors and headers intact). PASS 2 DECIDED (maintainer, 2026-08-31: "Then
  do the CLAUDE.md pass 2") AND DONE 14z-124 — (a)+(b)+(c) as recommended:
  414 → 344 lines; [VSP-27..30] live in `docs/project/oracle_classes.md`
  (the spec of record, 105 lines), the document roster in `docs/README.md`
  "The documents, by role", the recordings how-to in HANDOFF; §4/§5 keep the
  law and point; census re-frozen for the four moved anchors. ~~PASS 2 NEEDS
  A RULING~~ — the remaining bulk is
  law-dense, and the honest next cut is STRUCTURAL, by the file's own Rule 1 v2
  principle ("the spec is NOT copied here — two copies drift"): (a) §4's five
  oracle-class definitions ([VSP-27]..[VSP-31], ~75 lines) → a canonical
  `docs/project/oracle_classes.md`, §4 keeping the class NAMES, the standing
  watch and a pointer (the anchors move with the paragraphs; the port skill's
  D.2 rules cite "§4 v1/v2..v5" and would cite the new document; census
  re-frozen); (b) §5's document taxonomy list → `docs/README.md`'s routing
  table, §5 keeping the one-question rule and a pointer (~30 lines); (c) the
  recordings rule's operational how-to (the run/playback commands) → HANDOFF,
  the rule keeping capture-first, naming and cleanup (~10 lines). Estimated
  end state ~290 lines. Recommendation: (a) and (b); (c) is marginal.
  Nothing in pass 2 is Claude's to decide — it moves anchored law out of the
  constitution.** The original ruling: The maintainer's words, in substance: CLAUDE.md
  "has become very big and looks to have been extended like a log. This is
  not bad but wastes resources: we should plan a pass on it to remove
  duplicates if any and rewrite the contents in a more concise and to the
  point manner, without losing precious information, especially on the work
  style and discipline." Constraints the pass's tooling already enforces:
  CLAUDE.md carries **30 `**[VSP-N]**` anchors** (checkskills + the census
  freeze every one by section) and is a LOG for VSP skill numbers — every
  rewrite keeps each marker with its fact or moves the rule ([VSP-13]-grade
  discipline; the census diff is the review artifact). Shape suggestion to
  ratify at the pass: the LAW (rules 1-8, §4's classes, §5's standing
  orders) stays verbatim-precise; the CORRECTION NARRATIVES appended inside
  rules (the 14z-91/94/110b/114 stories) condense to the rule + a dated
  citation, with the narrative in the docs that already carry it. ~~Slot:
  before G7 (the close bumps floors; the law should settle first).~~ (G7
  CLOSED 14z-124 without it — pass 2 stands alone, no slot constraint.)
- **ZABEL j.LK PROXIMITY GUARD — A LEGACY-CONTENT PATCH, ITS OWN SESSION
  (maintainer, 2026-08-30, 14z-122). RULED as the SECOND of two future items;
  not started.** The maintainer's report, in substance: Zabel's j.LK does not
  trigger proximity guard properly — "afaik it does, but not all the time it
  should, and definitely unlike any normal of any character". The ask: a
  SURGICAL patch for BOTH vanilla vsav and the WIDE build that corrects this
  and nothing else — no side effects. What that implies for the session that
  takes it: (1) it is a deliberate change to LEGACY behaviour, so by
  definition outside the superset invariant's "untouched" set — it needs its
  own ratified expectation class and its own build flag (CLAUDE.md §1/§4; a
  stock `vsav` patch is a NEW track, not the stock twin); (2) [VSP-20]
  first — a hand-played MAME recording of the whiff BEFORE any theory;
  (3) [VSP-14] — archaeology on "proximity guard" across STATE_HISTORY and
  the engine docs before measuring; (4) measure vanilla's proximity-guard
  test against every other normal (the maintainer's own comparison class)
  so the fix is bounded by a measured difference, not an impression.
  Recommendation: a data-side fix on Zabel's j.LK record (the guard-range or
  a record flag) if the difference is in his data; a code-side change only if
  the engine special-cases the move. Nothing decided beyond "its own session".
- **DARK FORCE STOCK COST FOR THE TENANTS (14z-120, found by the naming rig). DECIDED (maintainer, 2026-08-30): option (a) — the character-specific DF at VS (vanilla) cost is ON PURPOSE; "vanilla stays untouched and guides how the game should be played"; adjustments, if any, will be per character, never to the general mechanic.** On native vs2 Donovan's Slay Shred spends TWO stocks (`+0x109` 9 -> 7 at activation; Huitzil measured the same 14z-69); on our vsav engine every Dark Force, tenants included, spends ONE (the two engines run different DF systems, [VSE-69]). So a tenant's DF is cheaper here than at home. Options: (a) keep vsav's 1 stock — every character in this cabinet pays the same, "vanilla wins ties" [VSP-21]; (b) charge the tenants VS2's 2 stocks (a per-character cost hook the vsav engine does not have — new code on the DF path). **Recommendation: (a).** Note also (maintainer, 14z-120): Phobos's and Pyron's physics rows were CHECKED — `port_param32 = true` in both manifests and every value field of the 32-row bank equals VS2 for all three tenants (the map, `docs/project/tables/chars/*.json`; only relocated pointers differ). What the bank does NOT cover — throw-arc rows, hit-freeze tuning, the generation-drift class [VSE-6] — is phase 2's measurement.
- **DONOVAN'S PHYSICS ROWS (14z-118, found by the character-data map). DECIDED (maintainer, 2026-08-29): "use VS2 parameters and not the shell character's" — option (a); `port_param32 = true` set, probe + soak below, freeze at the next battery. **FROZEN 14z-119 as donovan-m18 / merged-m14 (M12); the stock twin moved with it, by design — STATE 14z-119.**
  `param32_a` (walk fwd/back), `param32_b` and `jump_params` (three jumps x
  xv/xaccel/yv/gravity) are NOT ported for Donovan: `build/manifest/donovan.toml`
  carries no `port_param32 = true`, so gen's `VALUE_SKIP` leaves his bank
  rows at the vsavj alias — **Victor's** values (row `0x03`). Measured on
  `build/don_m17`: walk 2.5 / −2.25 vs VS2's 3.0 / −2.625; back-jump xv
  −3.625 vs −4.25, neutral yv 8.0 vs 7.75, forward yv 8.0 vs 7.875, gravity
  −0.352 vs −0.375 (16.16). Huitzil (14z-66, after his own soak) and Pyron
  port theirs. The skip was the 14w-b crash guard written for the slot-0x0F
  port ("Jedah speeds retained"); whether the hazard survives the move to a
  variant id was never re-examined for Donovan. **Options:** (a) set
  `port_param32 = true` for Donovan and run the same soak battery Huitzil
  ran (RECOMMENDED — VS2-faithful movement is the project's default; the
  cost is one freeze); (b) keep Victor's physics deliberately (record it as
  a tuning decision in `charmap_donovan.toml`'s header so the map stops
  flagging it). Gameplay feel: the maintainer's call.

- **THE `docs/project/tables/` PROMISE (14z-118, from the documentation
  audit's inventory `docs/project/doc_audit_14z118.md` §3). DECIDED
  (maintainer, 2026-08-29): option (a) — generate the two missing
  manifests and refresh all three.** The
  directory's README says "per-character data manifests for Donovan /
  Huitzil / Pyron" and still opens with "Empty until a ported character
  exists"; it holds `donovan.md` (2026-08-09, never refreshed) and no
  Huitzil or Pyron file. CLAUDE.md §2 rule 5 ([VSP-6]) makes these the
  community-facing tunables. Options: **(a) generate `huitzil.md` /
  `pyron.md` with the extractor that produced `donovan.md` and refresh all
  three from the current manifests — RECOMMENDED, it is what the rule
  says;** (b) retract the promise and name `build/manifest/*.toml` as the
  table of record. Blocks audit step 5 only; steps 1-4 proceed.

- **THE TENANTS' WIN QUOTES — FORGONE FOR NOW (maintainer, 2026-08-28,
  14z-116). DECIDED.** The ruling, verbatim in substance: *"Let's forgo for
  now but document everything so that, should we want to do it in the
  future. And should we ever do it, we'd do it the clean way, not touching
  vanilla."* So this is PARKED, not closed, and it is parked WITH A
  CONSTRAINT ON ANY FUTURE ATTEMPT: **the clean way only — the vanilla bank,
  the four-entry region root, tables A/B and `RAM:$FFF230`'s vanilla value
  all stay byte-identical. The 14z-76 whole-bank relocation is RULED OUT by
  this decision, not merely un-preferred.** The buildable shape is the one
  measured below (group C bank 5's blank font window + the shipping
  `winquote_bank_variant_id` gate + one tenant-only selector thunk), and the
  single open measurement before it could be scoped is named there. Nothing
  in the tree needs undoing: Phase 0 shipped only tools, a gate and
  corrections. Everything below is the measurement record.

  PHASE 0 AS MEASURED (14z-116): The maintainer's framing for this task: cosmetic, no 2P surface,
  so equip the suite against a silent state poison — and **forgo it outright
  if the implementation carries structural risk or costs compatibility**.
  Phase 0 was run before any shipped byte. What it found:
  - **A data-only fix is IMPOSSIBLE, confirmed.** `tools/scan_quote_window.py`
    re-derived the 14z-76 prose claim as a script: **zero** runs of `0x20`+
    free bytes within `±0x8000` of the bank base, and zero around any of the
    16 winner blocks (the second hop). A control at `0x8` finds exactly one
    9-byte run, so the scanner is not blind.
  - **The 14z-76 relocation plan is wrong in three places** (all corrected in
    place, `engine_internals.md` §8 + the `patch_index.md` header): the root
    is a FOUR-ENTRY REGION array whose other three banks are the ENGLISH
    text, not one long; the bank is `0x4104` bytes, not `0x40DC`; and lines
    can be 17 codes — the real bound is the renderer's own 66-word buffer,
    which is exactly what a bad offset overruns.
  - **The relocation is NOT legacy-invisible.** `move.l a1,$30(a4)` installs
    an absolute bank pointer at `RAM:$FFF230`, measured live during the
    VANILLA win screen (replay 23 `0x00331136`, replay 28 `0x0033101E`). So
    the deferral's "change one long" would move legacy work RAM on every
    win-reaching replay and buy a permanent superset-invariant tax, with a
    new ratified class per replay, for a cosmetic.
  - **THE REAL COST IS GLYPHS, and nobody had measured it.** The three vs2
    tenant blocks use 331 distinct codes; at the shared font base **326 of
    327 non-pad codes draw a DIFFERENT character in vsavj**. Every glyph
    DOES exist in vsavj — but at tiles `0x22000-0x2FFFF`, gfx **bank 1**,
    unreachable from a 12-bit code in the quote object's bank — and vsavj's
    bank-0 font window is **4096/4096 non-blank**, so there is no free slot
    to remap into. A code remap cannot fix this: ~330 glyph tiles must
    travel, which no version of the 14z-76 plan budgeted.
  - **AND THERE IS A CLEAN ROUTE, if you want it.** Group C **bank 5's**
    font window (in-group `0x13800-0x147FF`) is **4096/4096 blank** on
    `build/m3b_merged18`, and the shipping `winquote_bank_variant_id` gate
    (14z-62j, `site 0x05F328`, `only_variant_slot`) already flips the
    win-quote drawer to bank 5 on a TENANT WIN ONLY. So the glyphs can be
    authored into space we own, by the same mechanism the 14z-115 outline
    sprites used, with **no vanilla tile touched**; the text would ride one
    `site_thunk` on the selector for winner `>= 0x10`, leaving the vanilla
    bank, the root array and `$FFF230`'s vanilla value byte-identical.
    **NOT YET MEASURED, and it is the one thing left before a build could be
    scoped:** whether the TEXT object (set up at `PRG:0x00C840-0x00C862`,
    fed by `$30(a4)`) takes its bank from the same field that gate writes —
    the gate patches the drawer object at `0x5F328`, which is a different
    chain. If it does not, the thunk writes the bank itself.
  **THE PRICE THAT DECIDED IT:** ~330 authored glyph tiles + a thunk on a
  legacy-reachable site + a new win-quote RENDER gate (pixels — no RAM gate
  can ever see text), for a single-player cosmetic surface the standing
  "cosmetic is optional" scope calls nice-to-have. **RESUMING IT LATER
  COSTS NOTHING EXTRA**: the decoder, the font audit, the reach scan and the
  structure gate are all in the tree and green, so a future session starts
  at Phase 1 with the one open measurement, not at archaeology.

- **THE MiSTer SCOPE DOCUMENT — three decisions, ALL DECIDED (maintainer,
  2026-08-28, 14z-113; `docs/project/mister_scope.md` §8).**
  (1) **The split stands as written** ("in line with what I would do";
  the maintainer defers on the CPS-II-vs-VS specifics and follows the
  recommendation, MRA mechanics at level 1 included).
  (2) **The staleness pass (S1-S20) is MANDATORY before any distillation
  — but WAITS for the board results the maintainer is producing in
  parallel right now** (the #113 hand check and bundle 14z112's stock
  coexistence), so the pass lands on a settled state and does not have to
  be re-done. **Sequencing: board results -> record them -> the S1-S20
  pass (one commit) -> only then the skills.**
  (3) **The `.rbf` AND the MRAs are TRACKED IN-TREE** — the maintainer's
  ruling: they belong with any BPS/xdelta used to patch vanilla ROMs, i.e.
  under `release/`. **This opens a NEW item, the MiSTer RELEASE FORMAT**
  (below): what a `release/<name>/` carries for MiSTer, how and where it is
  generated, and its provenance record.

- **DOES THE STOCK CONTROL MRA STILL HAVE A USE? (maintainer's question,
  2026-08-28, after it booted fine on bundle 14z112.) DECIDED (maintainer,
  2026-08-29, 14z-118): KEEP IT, RE-SCOPED — run once per NEW `.rbf`
  (seed / slice / pin), off the per-release checklist; stays in every
  release's `mister/`. The recommendation as it was put:** It was built (14z-109) to separate a fault in our
  PROFILE from one in the bitstream/card/module/video chain, at a time when
  the bundle's `vsav.zip` was patched and no stock MRA could serve as a
  control. Two of its three jobs are now done by something else: a stock
  MRA on Jotego's own core covers "the board/card/module is fine" (and it
  just did), and the shared pristine `vsav.zip` means no bundle can poison
  stock art any more. **The job nothing else does: it is the EMULATOR
  SUPERSET INVARIANT ON SILICON** — stock `vsavj` running on OUR `.rbf`
  with the profile bit at the `0xFF` fill, i.e. CLAUDE.md rule 1 v2's
  "the patched binary running stock is untouched by construction",
  measured on hardware rather than in Verilator (`test_mister_wide_inert`
  is the simulated form). That claim is about the BITSTREAM, so the control
  needs running **once per new `.rbf` (new seed / new slice / new pin),
  NOT per romset release** — the `.rbf` has not changed since 14z-108, so
  today's pass covers it until the next synthesis. Cost of keeping: one
  XML file in the bundle and one line in the README. Recommendation: keep
  it in the release format (the MRAs are tracked in-tree now), label it
  "run when the bitstream changes", and drop it from the per-release
  checklist. Dropping it outright is also defensible — the maintainer's
  call; no gameplay surface.

- **THE RELEASE FORMAT — DECIDED (maintainer, 2026-08-28, 14z-113) AND
  IMPLEMENTED FOR merged-m10.** The ruling, verbatim in substance: the
  `release/<name>/` recommendation below is accepted WITH the caveat that
  **each platform is self-sufficient per format — not every file at the
  same level; each platform directory holds everything that platform needs
  and only that** (FBNeo needs nothing MiSTer and vice-versa; platform
  drivers packaged with their platform), and **every version releases all
  platforms even when the change touched one.** Two details I asked and the
  maintainer chose: the patch set is COPIED into each platform dir (not one
  shared dir + per-platform zips); FBNeo/MAME carry the driver PATCH + build
  recipe, not binaries. Spec `docs/project/release_format.md`; producer
  `tools/package_release_platforms.py`; gate `test_release_roundtrip.sh`
  §4; first instance `release/merged-m10/{fbneo,mame,mister}/` (manifests
  byte-identical). **Refined the same day (maintainer): the bitstream is a
  BUILD RESOURCE, canonical at `release/bitstreams/<seed>/` with `CURRENT`,
  hash-verified into every release, never copied from another release** —
  the `.rbf` (seed 18269, sha256 `46fc74af…`) is in the tree there and in
  `merged-m10/mister/`. The recommendation as it was put:
  *What ships.* `jtcps2w.rbf` (3.1 MB; GPL-3.0 output of a public fork, not
  ROM content — rule 7 is not engaged), the two MRAs (WIDE + the
  `[STOCK CONTROL]` reference leg — XML metadata: names, CRCs, offsets), and
  a provenance record: fork pin, **seed, reported slack, sha256, build
  datestamp** (the hash identifies the artefact, the seed the result —
  `mister.md` "REPRODUCING THE SHIPPING BITSTREAM"). NOT the `.rom`
  (ROM-derived, rule 7) and NOT any zip.
  *Where.* Recommendation: **inside the same `release/<name>/` as the
  xdelta package**, e.g. `release/merged-m9/mister/{jtcps2w.rbf, *.mra,
  BITSTREAM.txt}` — one release = one directory for all three
  implementations, which is what `package_release.py` already promised
  ("MiSTer later adds a DISTRIBUTION layer over the SAME members", HANDOFF).
  Alternative: a separate `release/mister/` keyed by bitstream, since the
  `.rbf` changes on a DIFFERENT cadence from the romset (it did not move
  from 14z-108 to 14z-112 while the romset moved three times). The two can
  coexist: the bitstream lives once under `release/mister/<seed>/` and each
  romset release's `mister/` holds the MRAs plus a pointer to the bitstream
  it was verified with.
  *How generated.* The MRAs already come from `tools/mister_mra.sh --no-rom`
  (ROM-free, deterministic); the bundle assembly is by hand today
  (`../mister_fieldtest_14z11x/` + README + FIELD_TRIAGE). The natural home
  is a `--mister` mode of `tools/package_release.py` (or a sibling
  `package_mister.py`) that copies the MRAs, verifies the `.rbf` against the
  recorded sha256 and refuses on mismatch, writes the provenance record,
  and runs `check_mra_parts.py` against the release's own members. Gate:
  `test_release_roundtrip.sh` gains a MiSTer leg (MRA parts resolve, hash
  matches record).
  *What it retires.* The out-of-tree field bundles as the only carrier, and
  S18 of the scope document (the untracked `.rbf` path).
  **Not started; waits behind the board results and the staleness pass by
  the maintainer's own sequencing.** No gameplay surface.

- **#112 — ROOT-CAUSED 2026-09-01 (14z-126b): AN OVERWRITE RACE ON PALETTE
  ROW `0b` INDEX 14. Still cosmetic, still accepted — this is knowledge, not a
  fix.** The foot is **row `0b` index 14**, NOT row 05. Row `0b` is written by
  VANILLA engine code (`PRG:0x02AD64` + `PRG:0x02AD78`, a 16-entry palette
  copy; both well below the relocated tenant region). Index 14's DEFAULT value
  is `f111` = rgb(17,17,17), near-black; the effect's own load writes `fcff`,
  bright cyan. Measured over f13400-14375 with `tests/lua/tap_writes.lua`
  (memory tap, no debugger, so playback stays frame-exact): **24 writes to
  index 14, only TWO of them `fcff` — one per Press of Death.**
  * CLEAN: `fcff` at **f13589** survives 56 frames to the foot draw at
    **f13645**.
  * BLACK: `fcff` at **f14313** is **OVERWRITTEN back to `f111` at f14341**,
    29 frames before the foot draws at **f14370**.
  Both values come from the SAME PC, so it is the SOURCE that differs — two
  palette-sequence requests racing, not a bad code path. That is why it is
  intermittent and cannot be reproduced on demand, and it is consistent with
  14z-112's own "the move only reaches the lift phase on some outcomes".
  **THREE PRIOR CLAIMS RETRACTED, all measured on merged-m14:** (a) "draws
  `bbe5`/`bbea` at pal 05 where every clean instance draws `0xe768-0xe796`" —
  those are DIFFERENT ANIMATION PHASES; clean f13645 and black f14370 have
  BYTE-IDENTICAL pal-05 entries (16 codes, same attrs/sizes, same `a18`/`a19`,
  differing only in x/y); (b) "real art fetched from the wrong place" — same
  art, same composed addresses; (c) "not a palette fault" — it IS one, on row
  `0b`. Row 05 is genuinely constant across the whole 14,400-frame run, which
  is why checking it alone said "no palette fault".
  **THE FOOT<->ROW LINK IS NOW CAUSAL, NOT CORRELATIONAL (2026-09-01, after
  the maintainer asked "is it truly complete?" — it was NOT).** As first
  published, "the foot is row `0b` index 14" was ASSERTED from a colour
  coincidence (`f111` = rgb(17,17,17) being the commonest colour near the
  effect) and from comparing pixel boxes at the SAME SCREEN COORDINATES in two
  frames where the effect sits at DIFFERENT positions — i.e. mismatched
  content. That was correlation dressed as a root cause. **Replaced by an
  INTERVENTION:** forcing `$90C17C` = `fcff` across the black frame moves
  EXACTLY 7,007 pixels, every one of them rgb(17,17,17) -> rgb(204,255,255),
  and the black sole and toes vanish from the snapshot. **Control fired:**
  poking the neighbouring entry `$90C17A` moves 8,898 DISJOINT pixels, none of
  them black — so the attribution is index-specific. Gated as
  `tests/test_pod_black_foot_palette.sh`.
  **LANGUAGE CORRECTED: "race" was too strong.** What is measured is an
  OVERWRITE with an ordering: the effect's `fcff` load is followed, before the
  sprite draws, by another write from the SAME palette-copy routine putting
  `f111` back. Whether two requests genuinely race or the ordering is
  deterministic is NOT established.
  **THE DETAIL CHAIN, dug out 2026-09-01 at the maintainer's direction.**
  * **The writer is VANILLA code, byte-identical to pristine vsavj**
    (`PRG:0x02AD20-0x02AD80`, verified against `vanilla_data.bin`). It is a
    generic 16-entry palette copy: dest row from `+0x18B` of the object,
    source from `a0`, and it preserves the destination's top nibble
    (`andi.l #$f000f000`).
  * **Its resolver entry (`0x02AD20`) is a TWO-LEVEL lookup:**
    `a0 = charPaletteBase[(a6+0x382)] + (seq_id & 0xFFF)*32`, with the
    per-character base table at **`PRG:0x38C218`**. `0x02AD3C` is a SECOND
    entry point with `a0` preloaded, and that is the one our writes come
    through — so the caller, not this table, chose the block.
  * **The two source blocks are FOUND:** `PRG:0x0CF110` is the CLEAN one
    (idx 14 = `fcff`) and `PRG:0x0CEB70` the BLACK one (idx 14 = `f111`).
  * **PROVENANCE, AND IT IS THE ANSWER TO THE FIX QUESTION: BOTH BLOCKS ARE
    OURS.** Pristine vsavj holds `0xFF` FILLER at both addresses — unused ROM
    space the port allocated. The char-table row for id `0x13` is also ours
    (vanilla aliases Donovan's slot to `0x393460`, Victor's base; the port
    repoints it to `0x0FF180`). The routine itself is untouched vanilla.
  **SO THE 2026-08-28 REFUSAL OF OPTION (b) RESTED ON A FALSE PREMISE.** It
  read "the sequence is vanilla vsavj data, so editing it breaks the superset
  invariant". The palette data in play is NOT vanilla — it is port-authored
  bytes in filler vanilla never reads. **That does NOT by itself make a fix
  right** (see the caution below); it means the risk must be re-assessed
  rather than assumed. Maintainer's call ([VSP-10]).
  **THE CAUTION, and it is why no fix is proposed here:** what differs
  between clean and black is WHICH BLOCK IS SELECTED, not what the blocks
  contain. Block `0x0CEB70` is used for 22 of the 24 index-14 writes in the
  window, so `f111` is presumably correct for its other uses; editing it
  would be a WORKAROUND that could damage them. A sound fix targets the
  SELECTION.
  **CLOSED 2026-09-01 — `a0` MEASURED** with `tap_writes.lua`'s existing
  `REGLOG` (no tooling needed; its own comment says it exists to "name the
  source table pointers for computed cursors"). Every index-14 write in
  f13400-14375 carries **`A6 = 0x00FF8400`, P1's FIGHTER BLOCK** — the same
  object every time — and the source varies: `0x0CEB70` (idx 0, the DEFAULT,
  20 of 24 writes), `0x0CF050` (39), `0x0CF070` (40), `0x0CF110` (**45**, the
  effect's own, idx14 = `fcff`).
  **THE TIMELINE IS THE WHOLE MECHANISM:**
  * CLEAN — seq 45 loaded f13589, **foot draws f13645**, revert to seq 0 at
    f13697: the revert lands 108 frames after the load, PAST the draw.
  * BLACK — seq 45 loaded f14313, **revert to seq 0 at f14341**, foot draws
    f14370: the revert lands 28 frames after the load, 29 frames BEFORE it.
  **THE TWO TIMELINES ARE DECOUPLED BY DESIGN: the palette is requested by the
  PLAYER OBJECT's state machine (`$FF8400`), while the foot sprite is drawn by
  a SEPARATE POOL OBJECT with its own lifetime.** When the player's state
  advances and reverts the palette before the pool object has finished
  drawing, the sprite renders against the default block. That is why it is
  intermittent, why it cannot be reproduced on demand, and why nothing about
  the tiles, the records or the addresses was ever wrong.
  **THE TRIGGER, MEASURED 11/11 (2026-09-02, the maintainer's question "why
  such a specific issue, on a single move, and not even all the time?"):
  DONOVAN IS HIT WHILE HIS OWN EFFECT IS STILL DRAWING.** The effect palette
  (seq 46) has a FIXED nominal lifetime: across the whole recording it is
  loaded ELEVEN times and survives 108/108/109x7/144 frames — except once, at
  f14313, where it survives **28**. That one load is the ONLY one whose window
  contains P1 taking damage (`hp1` 203 -> 201 exactly at the f14341 revert
  frame). Being hit moves the player's state machine to a reaction, which
  re-requests his DEFAULT body palette (seq 1); the pool object is still
  drawing and borrows his row, so it renders against the wrong block.
  **So the answer to "why only this move, and not always" is exact:** the move
  is a super whose effect OUTLIVES the player's state (~109 frames), and the
  condition is GETTING HIT during that window. Ten clean instances, none hit,
  all held the palette for its full lifetime. **This also RETRACTS the earlier
  guess** that the state advanced at outcome-dependent speeds — it does not;
  the lifetime is fixed and only an interruption shortens it.
  **WHAT A FIX WOULD TARGET, now the mechanism is known:** the LIFETIME
  RELATIONSHIP, not the palette bytes — either the player's revert waits for
  the effect, or the effect owns its palette instead of borrowing the
  player's. Both are gameplay-adjacent and neither is Claude's to choose
  ([VSP-10]). What IS now known is that the bytes in play are OURS, so the
  superset invariant is not the obstacle it was believed to be.
  **A method note worth keeping:** the first discriminator appeared to REFUTE
  this (three clean instances carried the "black" row `0b`) — they never reach
  the `bbxx` foot phase at all. Scope a discriminator to the phase that draws
  the thing, or it measures nothing. Original entry follows.
- **#112 — PRESS OF DEATH BLACK FOOT: ACCEPTED AS COSMETIC. DECIDED
  (maintainer, 2026-08-27): option (c) — accept for now; option (a) (give
  tenants their own effect animation) is PARKED for a later pass over the
  port's remaining purely-cosmetic items.** Option (b) (trim the borrowed
  sequence) is refused outright: the sequence is vanilla vsavj data, so
  editing it breaks the superset invariant regardless of what it does to the
  move. Rationale for (c): the defect is purely visual on a single-player
  surface, the project already carries small cosmetic imprecisions, and the
  mechanism is not understood well enough to patch safely — the whole draw
  path measured VANILLA (writer `PC 0x01B2BE` byte-identical to stock,
  vanilla record `0x287D7C`, vanilla sequence, vanilla art, tile window
  byte-identical to stock), and WHY a tenant runs that sequence is still
  unknown. GitHub #112 stays OPEN as the parked record; do not re-derive the
  eliminations, they are listed in the 14z-112 group above. **When the
  cosmetic pass happens, the entry point is a DISASSEMBLY-based trace of the
  effect spawn — not a byte scan** (two instruction-boundary false positives
  were paid for here: `e768 7105` and `0028394E`).

- **#113 — THE ONE-FRAME WHITE-OUT AT A DOWN IS VANILLA. CLOSED BY THE
  MAINTAINER 2026-09-01 ("I closed #113 since the behavior is indeed
  vanilla"), option (a) — GitHub #113 CLOSED 2026-09-01T11:16:19Z.** The
  board agrees with the emulator measurement: the camera/MiSTer evidence the
  2026-08-28 update was waiting for came back consistent, so the finding
  stands as measured and nothing was re-derived. The accessibility softening
  (b) was NOT taken and needs a fresh ruling if ever revived. **What survives
  as an honest boundary: the MECHANISM (palette RAM blanked vs a CPS-B
  layer/priority register) is still NOT measured — only the framebuffer is.**
  **-> ANSWERED 2026-09-01, SAME DAY THE TOPIC WAS OPENED: THE WHITE FRAME IS
  A DELIBERATE PALETTE-BASE SWAP.** The game writes CPS-A register
  `0x80410a` (`CPS1_PALETTE_BASE`, confirmed from MAME's `cps1.h`
  `CPS1_PALETTE_BASE = 0x0a/2`) from its normal `0x90c0` to **`0x9240`** for
  exactly ONE frame; the region at `0x924000` is filled wall-to-wall with
  `ffff`, so every pixel of every layer resolves to white. The next frame the
  base returns to `0x90c0`. **BOTH CANDIDATES IN THIS ENTRY WERE WRONG:** it
  is NOT palette RAM being blanked (rows `0x00-0x5f` at `0x90c000` change only
  by +/-1 colour cycling across the flash, mean luma 344 -> 344) and NOT a
  CPS-B layer/priority register. It is the palette POINTER.
  **TWO DIFFERENT "WHY"s, AND ONLY ONE IS ANSWERED — corrected 2026-09-01
  after the maintainer read this entry and said "I still don't understand why
  would Capcom want to blink the screen, but now we at least know how".** They
  are right and the first version of this entry overstated it:
  * **WHY THIS IMPLEMENTATION — ANSWERED.** Given that a full-screen flash is
    wanted, a palette-base swap is the cheapest way to get one: a single
    register write flashes every layer at once, disturbs no colour and no
    sprite, and reverses instantly.
  * **WHY A FLASH AT ALL — STILL OPEN, and it is the interesting half.**
    Nothing measured says what design purpose a one-frame white-out serves.
    THE ONE OBSERVATION WORTH CARRYING, stated as an observation and not a
    theory: all four occurrences in the run sit at STATE TRANSITIONS (the
    match-intro pair, match start, and the first down), not at arbitrary
    moments — so "an impact accent" and "a side effect of a palette swap at a
    transition" are both still live. Evidence AGAINST the second: the palette
    at `0x90c000` shows NO bulk reload around the flash (writes are a flat
    ~96/frame across f6640-6652, no burst at f6646), so if it is a swap
    artifact the reload is not happening there. Not pursued further; nothing
    depends on it.
  **DISCRIMINATOR, 4/4:** `0x9240` occurs EXACTLY FOUR TIMES in the 6,700-frame
  run — f1908, f1910, f2147, f6645 — one frame before each of the four known
  white frames (1909/1911/2148/6646) and nowhere else. Cross-implementation:
  FBNeo reproduces the same inventory at +1 frame (hash `0e86f1dc0b964325` at
  1910/1912/2149), so it is not a MAME artifact. The frame is genuinely 100%
  white (86,016 px, ONE distinct colour). Rig: `tests/lua/tap_writes.lua`
  `TAP=80410a,2` + `inp_probe.lua` `PAL_BASE=924000`, on STOCK vsavj with
  `104_1p_auto_ko_win.rpl` — the `test_down_flash_vanilla.sh` rig.
  **TWO INSTRUMENT TRAPS PAID FOR, both caught by controls:** (1) the first
  register tap used `0x800100`, which the driver's own map comments call
  "Mirror (sfa)" — NEVER written by this game, so a "zero writes" elimination
  was measuring a dead address (the tap MECHANISM was control-proven at
  `0x90c000`, which is not the same as proving the ADDRESS meaningful); the
  live block is `0x804100-0x80417f`. (2) `0x90c0` was briefly read as the
  flash value; it is the NORMAL one, and only the whole-run distribution shows
  which is rare. **Nothing is proposed and nothing changes** — vanilla
  behaviour, #113 stays closed, and the superset invariant forbids touching
  it. The original topic follows.
  **-> OPENED AS A RESEARCH TOPIC (maintainer, 2026-09-01): "we don't know the
  mechanism, much less the reason (there has to be one and I must admit I
  wonder why this is like this). We should open a research topic on it and
  tackle it after we get to the bottom of the black foot analysis."
  SEQUENCED AFTER #112.** Note it is TWO questions, and the second is the
  maintainer's real curiosity: (1) the MECHANISM — what makes the frame
  white (palette RAM zeroed vs a CPS-B layer/priority register at that
  frame); (2) the REASON — why Capcom's engine does it at all at a down.
  Knowledge work on VANILLA behaviour, not a port defect and not a fix: the
  superset invariant forbids changing legacy frames, and #113 is closed.
  WHAT EXISTS TO START FROM, so nothing is re-derived: the behaviour is
  frozen and gated (`tests/test_down_flash_vanilla.sh` — one all-white frame,
  fnv `eab1fb569cb99b25`, 57..96 frames after every down, plus the intro pair
  and the match-start frame), it is present in BOTH vsavj and vsav2
  (`37_victor_ko_vsav2`), and the framebuffer half is measured while the
  palette/register half never was. The instrument gap is the whole topic:
  a framebuffer hash cannot distinguish a blanked palette from a disabled
  layer — that wants a palette-RAM dump or a CPS-B register read AT the white
  frame ([CPE-14]: MAME read taps never fire on this driver, so a write tap
  or a frame-anchored dump is the route). `inferred_claims` row 11 is the
  standing record of the unmeasured half.
  The original entry follows. (measured 14z-112,
  `tests/test_down_flash_vanilla.sh` PASS on stock vsavj / reference MAME).
  Stock Vampire Savior draws ONE all-white frame (fnv `eab1fb569cb99b25`,
  whole framebuffer) 57..96 frames after every down, plus the intro pair and
  the match-start frame — merged-m9 reproduces exactly that inventory and
  nothing more. So it is not a port defect, and the photosensitivity concern
  is with Capcom's design. **The decision:** (a) CLOSE as vanilla behaviour
  (RECOMMENDED — the superset invariant forbids changing legacy frames, and
  the flash fires on every legacy down); (b) an OPT-IN accessibility
  softening (dip/config-gated, WIDE-only, default OFF, so default legacy
  output stays bit-identical) — a deliberate legacy-content change that
  needs its own ruling, a measured mechanism (palette-RAM vs CPS-B layer
  register at the white frame — not yet measured) and a gate; not free.
  The CRT "background stays, sprites vanish" is consistent with one white
  frame on phosphor (interpretation, not measured).
  **Maintainer's rule (2026-08-27): vanilla in VS with VS characters =>
  close regardless of vs2; measured BOTH — vsavj (104: +96) AND vsav2
  (37_victor_ko_vsav2, native Donovan: +88) show it. Awaiting the
  maintainer's own hand check on stock vsavj, then CLOSE.**
  **~~UPDATE 2026-08-28~~ SUPERSEDED 2026-09-01 — the camera evidence below
  ARRIVED and AGREED with the emulator finding; #113 is CLOSED. The
  paragraph is kept because its eliminations and its "if the board
  disagrees" clause are the reasoning that made the closure safe.**
  **UPDATE 2026-08-28 (maintainer): NOT closed, and not to be closed yet.
  The maintainer is gathering CAMERA evidence because original
  hardware/MiSTer may DISAGREE with the emulation finding, and wants
  bulletproof evidence before the topic is reopened. Until that arrives:
  the emulator measurement stands as measured, nothing is re-derived, and
  #113 stays OPEN. If the board does show something the emulators do not,
  that is a cross-implementation finding about the white frame's
  rendering (palette/CPS-B layer register at that frame — never measured,
  see (b) above), not about the game data.**
- **~~#99 — THE TYPE-0x51 REMAP~~ RE-RULED (maintainer, 2026-08-26, 14z-110):
  THE REACTION_HOOK D2-WINDOW SHAPE IS APPROVED, in the explicit order
  FIX -> AUDIT -> RE-FREEZE.** "Very well, I agree with all the proposal."
  What is approved, precisely:
  * **Shape: the reaction_hook THUNK BODY is extended — never the vanilla
    dispatcher.** The engine's patched footprint does not grow (still the one
    6-byte `jmp` at `0x018458`); the thunk's bne-arm (the only entry into
    dispatcher 2 at `0x018508`) gains the same `0x50-0x53` window test it
    already runs for dispatcher 1, dispatching via a SECOND ext table to vs2's
    dispatcher-2 twin (`0x016DE4`) handlers VERBATIM; every other index takes
    `jmp 0x018508` exactly as today. Data stays native `0x51` — dispatcher 3,
    the `es_type51_dispatch` thunk and the `property[0x51]=0x19` lookup are
    untouched.
  * **Scope: DATA-TRIGGERED, deliberately NOT tenant-id-gated.** The branch
    keys on the node byte's VALUE (`0x50-0x53`), which only vs2-numbered
    ported data can carry — vanilla data reaching dispatcher 2 with such a
    byte crashes today, so no legacy behavior can depend on the added branch
    (legacy-safe by IMPOSSIBILITY, the index_window_018468 precedent). An
    id-gate would be WRONG: the field proved the walking object can be a
    LEGACY character's (Bishamon) — the trigger is whose DATA the node lives
    in, not whose object walks it.
  * **Ownership: `donovan.toml`'s `[reaction_hook]` singleton** (merged
    inherits; solo Huitzil/Pyron don't declare it and the census measured
    them at ZERO out-of-range nodes, so they don't need it).
  * **The one global cost is CYCLES** — every object on the hit-stun path
    (`+0x38` set) executes the ~2 added compares, all characters. The
    flicker-inventory measurement (step 2 of the order) is the gate: if the
    frozen inventory moves, STOP and return to the maintainer — never widen.
  * **Order is binding: FIX (manifest + emitter) -> AUDIT on the fix build
    (flicker inventory, test_fsm_census still 6/6 native, audit_don_vs_cpu,
    guard soaks, audit_continue_switch re-measure) -> RE-FREEZE
    (donovan-m12/huitzil-m21/pyron-m15/merged-m7) + the MiSTer CRC tail.**
    Field pass on the new bundle is the actual #99 verification (MAME cannot
    reproduce the crash).
  This supersedes the 2026-08-26 (a)+(b)+(c) ruling's part (b); (a) — vanilla
  dispatcher never patched — is honored by construction, and (c)'s census came
  back EMPTY of further members. The measured basis below stands as the trail.
  **Original re-ask (14z-110), kept for the trail:** The census is
  DONE and the fix shape needed a fresh decision; (b) was not implemented.
  **WHAT THE CENSUS FOUND (measured 14z-110, `tools/audit_fsm_census.py` with
  the vs2 oracle + `tests/lua/fsm_census.lua` corpus):**
  1. **There is only ONE out-of-range family, and it is the KNOWN one.** The
     static family-aware census (node-record signature: 0x20-stride, monotonic
     +0x10 counter, +0x17 a valid state) finds exactly SIX out-of-vsavj-range
     node-state bytes across ALL THREE tenants — the six `0x51` records in
     Donovan's hitbox (`0x3FB862`-`0x3FB902`, +0x17 at blob offsets
     `0x10E9..0x1189`), which ARE the 14z-35 cluster. **Huitzil and Pyron have
     ZERO.** No `0x50/0x52/0x53` node clusters exist. **So the escalation
     clause resolves cleanly: there are no OTHER members to classify.** (Bound:
     signature-based; the dynamic corpus census found no idx >= 0x50 dispatched
     on any leg, mapping the reachable tenant node regions — a coverage bound,
     stated, not a universal proof.)
  2. **The node byte feeds THREE dispatchers, not one, and they are 80-entry
     not "~0x28".** `0x018460`/`0x018508`/`0x0185D2` (vs2 twins `0x016D34`/
     `0x016DE4`/`0x016EB6`, 84 entries -> gap `0x50-0x53`). The 14z-43
     `es_type51_dispatch` thunk's consumer audit named dispatchers 1+3 and
     MISSED dispatcher 2 (`0x018508`) — that is where #99 crashes. The records
     were left native `0x51` on purpose (dispatcher 3 + the property lookup
     need it).
  3. **A DATA remap breaks things:** `0x51 -> 0x19` diverges on dispatcher 3
     (there `0x19` -> handler `0x18694`, NOT the copy handler) AND fails the
     `es_type51_dispatch` thunk's `cmpi #0x51`. `0x51 -> 0x4E/0x4F` is
     copy-aliased on all three dispatchers, BUT the copy handler STORES the
     class and a downstream property lookup keys on it
     (`property[0x51]=0x19` vs `property[0x4E]=0x0F`, the 14z-44 ES-freeze
     family) — so it changes gameplay. **No data value is both
     dispatcher-exact on all three AND property-preserving.** Ruling (b) as
     written ("`0x51 -> 0x19`, zero gameplay surface") is therefore wrong on
     both counts.
  **RECOMMENDATION (measure-first order, port-the-handler caveat honored):**
  the clean fix is **CODE-SIDE on dispatcher 2's arm, inside a hook that
  already owns the only entry to it** — the `reaction_hook` site prefix
  (`0x018458`) already re-creates `tst.b (0x38,a1); bne 0x018508`, so its
  bne-arm gains the same `0x50-0x53` window the reaction_hook already runs for
  dispatcher 1, using vs2's dispatcher-2 twin `0x016DE4` handlers verbatim.
  Data stays native `0x51` (dispatcher 3 + property untouched). Cost: ~2
  compares on a path legacy executes when `+0x38` is set — **must be measured
  against the frozen flicker inventory before it ships** (that is the only open
  cost; if it moves the inventory, stop and root-cause). This is NOT a "port
  the handler" import — it reuses handlers already present; it adds a window
  test, not a foreign routine. **Delivered this window regardless of the
  ruling:** the census tool + gate (`test_fsm_census`, negative controls
  green), the deterministic Donovan-vs-CPU-Phobos coverage gate
  (`audit_don_vs_cpu`, closes #111's core gap), replay 110. The fix itself
  waits on this ruling.
  **HONEST GAP unchanged:** #99 does NOT reproduce on MAME from a P1-mash
  (full venue-0x02 Donovan-vs-Phobos marathon ran clean to END 40620) — the
  bad node needs the specific cross-fighter walk the maintainer sees 100% on
  the CORE. So no MAME regression lock is possible; the fix is verified by the
  census (node no longer >= table size on dispatcher 2's reachable path) + a
  field pass.
  **~~ORIGINAL RULING (maintainer, 2026-08-26), SUPERSEDED BY THE ABOVE~~:**
  (a)+(b)+(c) — (a) data-side extraction remap, never the dispatcher; (b)
  `0x51 -> 0x19`; (c) census + escalation. (a) and (c) stand in spirit; (b) is
  the part the measurement overturns. Kept for the trail.**
  **THE MAINTAINER'S STANDING CAVEAT ON (c), recorded verbatim in spirit:**
  for escalated hits, "port the handler" LOOKS like the best default (no
  error states + vs2-consistent tenant behavior) — **but it is NOT free: not
  in memory, not in cycles, and not in side-effects. Measure first. And if
  the maintainer seems too eager to say yes to a port, RAISE THIS POINT** —
  their own instruction. The project's evidence agrees: a ported handler
  imports code that may touch fields vsav lays out differently, may call vs2
  helpers at vs2 addresses (thunk/relocation work), costs bytes and
  per-frame cycles, needs its own gates — and "consistent with vs2" can
  still be WRONG under vsav's engine (the DF-frameworks-differ-BY-DESIGN
  lesson, 14z-101; the effect-class root that pulled cascading dependencies,
  14z-102). Default order for an escalated hit: measure what the state DOES
  and how often our content reaches it -> consider neutralize-to-default ->
  port ONLY when the behavior demonstrably matters to feel.
  **Original measured entry:** Step 1 done (14z-109 (7)), all three answers:
  1. **Family**: the object-script FSM node stream — 0x18-byte nodes whose
     `+0x17` byte is the NEXT-STATE index — inside Donovan's ported
     character block. Our node `0x3FB882` = vs2 `0x0C9CAA`, ported
     byte-verbatim (single content-search hit, 0x28-byte window).
  2. **What vs2's `0x51` means**: vs2's FSM table (dispatcher `0x016D2C`,
     table `0x016D34`) has **0x54 states**; entry `0x51` (offset `0x023C`)
     is vs2's MOST-ALIASED **DEFAULT handler** — `move.b (0x17,a3),(0x54,a1);
     rts`, the plain "advance to the node's next state". ~20 vs2 states
     alias it.
  3. **The vsavj equivalent**: vsavj's default at table offset `0x017C`
     (handler `0x01868C`, aliased by `0x19-0x1C`/`0x20-0x23`/`0x27`) is
     **BYTE-IDENTICAL** to vs2's `0x51` handler.
  **PROPOSED RULING: remap node-state `0x51 -> 0x19`** (the lowest vsavj
  default-alias) — semantically exact, both engines run identical
  instructions, zero gameplay surface. **Plus the census before the fix
  window**: scan ALL THREE tenants' ported node streams for `+0x17` values
  `>= 0x28` (vsavj's table size) and remap each by the same
  handler-equivalence method — one missed member is how THIS one shipped.
  Fix = extraction remap rule (14z-33/35 shape), landing with #111's
  coverage work in one window. Original entry:** Root cause is on the issue: node `ROM 0x3FB899` in Donovan's
  relocated block carries vs2 type byte `0x51`; vsavj's dispatcher at
  `PRG:0x018508` has no row for it and no bounds check. The fix wants THREE
  answers before any byte moves: (1) which record family `0x3FB882` belongs
  to in the extraction; (2) what vs2's `0x51` MEANS there (its handler in
  vs2's own table); (3) the correct vsavj renumbering — then a REMAP RULE in
  the extraction per the 14z-33/35 shape, never a hand-poke. Gameplay
  surface possible (the node does something in vs2 that vsavj may express
  differently), hence maintainer-ruled. **#111 (coverage rot) should land in
  the same window**: re-point or replace `26_don_arcade_mash`, re-measure
  `audit_continue_switch`, and add the missing Donovan-vs-CPU-Phobos gate
  (the venue-byte steer makes a deterministic one possible). The build-time
  guard — validate every ported type/selector byte against the consuming
  dispatch's bounds — is what keeps the NEXT missed family member off a CRT.

- **~~THE TIMING-MARGIN RESPONSE~~ DECIDED (maintainer, 2026-08-25).**
  `cps2w` fails 4 of 12 fitter seeds (14z-108). Options were laid out A-E.
  **RULED: A + B, with C IN RESERVE. D is ACCEPTABLE. E is OPPOSED unless
  there is no better choice.**
  * **A — do nothing to the RTL.** We distribute a PREBUILT `.rbf`, so the
    fragility is ours and not the users'.
  * **B — PIN THE SEED AT RELEASE.** Every shipped bitstream is built from a
    NAMED seed with its slack and sha256 recorded and verified, never from
    an `xjtcore.sh` random draw. The current baseline is **seed 18269,
    +0.066 ns, sha256 `46fc74af…`**. Costs nothing and converts "we got a
    lucky draw" into "we know which draw, and we check it".
  * **C — shed load on the SDRAM address cone** (bank 0 carries SEVEN slots
    since D2; the rejected 14z-107 alternative was moving the Z80 out).
    HELD IN RESERVE: it is the only fix that stays inside Rule 1 v2 and
    touches no shared infrastructure, but it would invalidate the bank-1
    bandwidth measurement, so it is not to be spent on headroom we do not
    currently need. **Revisit BEFORE the next RTL slice, not after.**
  * **D — pipeline the SDRAM address path.** ACCEPTABLE if C is not enough.
    Note it means overriding jtframe's shared controller in `cores/cps2w`.
  * **E — lower the SDRAM clock.** OPPOSED unless nothing else works: bank 0
    already peaks at 43.9% of its 96 MHz ceiling, so the clock is buying
    headroom we are using.

- **~~MiSTer PACKAGING: which MRA is MAIN, and how a release carries both
  `vsav.zip` flavours~~ DECIDED (maintainer, 2026-08-25): OPTION A, a
  WIDE-ONLY RELEASE, with option B as the eventual target.**
  **The collision, named exactly (14z-108):** the four ported-art members
  are `vm3.13m/.15m/.17m/.19m`, and they live in **`vsav.zip`, not
  `vsavjw.zip`**. So the WIDE MRA needs a PATCHED `vsav.zip` while every
  stock MRA needs the PRISTINE one — same filename, one `games/mame/`
  folder — and jtframe resolves members **by CRC32 alone**, so the wrong one
  is silently filled rather than refused.
  **Ruled: ship the WIDE MRA only.** The maintainer's reasoning, recorded
  because it settles the "which MRA is main" half too: **Jotego's own
  `jtcps2` core already runs vanilla**, so our core does not need to, and
  the stock regional MRAs are a development reference leg rather than a user
  feature. The generator currently makes the **Euro** set the main MRA and
  buries the WIDE entry in `_alternatives/`, which is backwards for a core
  whose purpose is the roster.
  ~~**Option B stays the target shape "in time"**~~ **OPTION B WAS SHIPPED AT
  14z-113 AND THIS ENTRY WAS STALE FOR THIRTEEN FREEZES — corrected
  2026-09-02 after the maintainer asked for it to be "made ready for the next
  freeze" and the archaeology ([VSP-14]) found it already done.** Measured on
  `build/m3b_merged21`: the build packs NO `vsav.zip` at all, and
  `vsavjw.zip` carries all 25 members including the four patched group-A ones
  (`vm3.13m/15m/17m/19m`), so `vsav.zip` stays pristine from `$ROMDIR` and a
  user's existing romset folder works untouched. The freeze that did it is the
  14z-113 ONE-ZIP PACKAGING FREEZE (merged-m10). **What was still undone is
  the OTHER half of this decision — "which MRA is MAIN" — and that landed
  2026-09-02:** `parse.main_setnames=["vsavjw"]` in the fork's
  `cores/cps2w/cfg/mame2mra.toml` (fork `5fd9bb9a6`), the upstream mechanism
  kiwi/s16/s16b already use, so the WIDE set is no longer filed under
  `_alternatives/` while a stock regional set takes the main slot. The
  original text follows: move those four members
  INTO `vsavjw.zip` so `vsav.zip` can stay pristine and a user's existing
  romset folder works untouched. Not done now because it is a build-pipeline
  change touching the hash-shadowing class that cost two sessions in
  14z-60z/61, and it must not sit between the maintainer and a field test.

- **THE REMAINING SKILLS — PLANNED AND ALL FOUR SHIPPED 14z-114 (`docs/project/skills_scope.md`,
  now the record); the five decisions were taken under stated assumptions and remain OPEN TO VETO — a veto means re-cutting a shipped skill, which the checker makes mechanical:** (1) FOUR
  skills — `cps2-hardware`, `cps2-emulation` (split per "MiSTer separate
  from emulation"), `vampire-savior-engine`, `vampire-saved-port`; (2) the
  game skill quotes NO ROM addresses (laws + the atlas row it names); (3)
  the port skill anchors into CLAUDE.md and points, never restates it; (4)
  each skill's staleness pass runs in the same session as its distillation
  as its own commit (the MiSTer ruling generalised); (5)
  `engine_internals.md` counts as a LOG for the game skill's number-citation
  check. Sequencing A+B (platform) -> C (game) -> D (port). Distillation of
  A+B began the same session — and all four landed in it: `[CPH-1..30]`, `[CPE-1..42]`, `[VSE-1..83]`, `[VSP-1..161]`; 425 rules across six skills, `checkskills` ALL PASS.
- **DISTILL AI SKILLS FROM THE PROJECT'S LEARNINGS (maintainer direction,
  2026-08-24).** ~~Recorded as FUTURE, UNPLANNED work — nothing scheduled.~~
  **ALL SIX SKILLS ARE DONE 14z-114** (`mister-cps2-wide-core`,
  `mister-vampire-saved`, `cps2-hardware`, `cps2-emulation`,
  `vampire-savior-engine`, `vampire-saved-port`; checker `tools/checkskills.py`;
  STATE 14z-114). The maintainer's sketch — a CPS-II skill separate from a
  VS/VS2/VH2 skill — is met by the `cps2-*` pair and `vampire-savior-engine`;
  the checker shape (docs as the human rendition, anchored IDs, numbers cite
  the log) is the pattern any future skill reuses.
  As was done for Sailor Moon S, distil the project's learnings into agent
  SKILLS, **scoped by subject rather than by task**. The maintainer's sketch:
  at least a **CPS-II** skill separate from a **VS / VS2 / VH2** skill, and
  **MiSTer** separate from **emulation**; exact scopes to be agreed. Stated
  rationale: they make further work markedly easier.
  **The precedent is concrete and observable from inside a session** — the
  SMS project produced `romhacking-methodology` (general RE/patch discipline)
  and `snes-romhacking` (platform-specific hard rules), and both load into
  Claude Code sessions on this machine today.
  **Three observations to carry into the scoping conversation:**
  1. **The split the maintainer proposes is the one `docs/README.md` already
     uses.** "Would this still be true if we abandoned the roster hack
     tomorrow?" separates `platform/` (CPS-2, MAME, FBNeo, MiSTer) from
     `game/` (Vampire Savior itself) from `project/` (this port) — and it is
     the same question that separates a CPS-II skill from a VS/VS2/VH2 skill
     from a port skill. A skill that mixes those scopes fails the same way a
     doc filed by task instead of by fact does.
  2. **A skill is loaded BEFORE the work, so it must carry what you need to
     know before you know you need it** — laws, traps and negative controls,
     not reference data. SMS made this split explicitly:
     `sms_hacking_playbook.md` quotes ZERO addresses on purpose and points at
     the checked docs instead. Skill = the discipline; docs = the facts.
     Candidate content from this project, all paid for: measure-don't-infer,
     probe sparsity, the negative-control rule, "identify moves by measured
     EFFECTS not the script's input name", "a gate that stops checking reads
     GREEN not RED", "suspect the instrument before the thing under test",
     and the §4 vocabulary of frozen non-exact classes.
  3. **Skills go stale exactly like docs, and need the same enforcement.**
     SMS ships `tools/checkskills.py`, which ID-locks the human playbook to
     the agent skill so the two cannot drift. Whatever is distilled here
     should ship with its checker in the same commit.
  Sequencing: this naturally follows the living-documentation effort above
  (a skill is a distillation, so it wants the synthesis to exist first), and
  both follow MiSTer.

- **MiSTer DOCUMENTATION + SKILL DISTILLATION, AT TWO LEVELS (maintainer
  direction, 2026-08-27). DONE 14z-114 — both levels distilled, see the
  14z-114 entry; `mister_scope.md` carries the status.** FIRST STEP AGREED 2026-08-27: produce the SCOPE
  DOCUMENT ONLY — ~~queued in `docs/NEXT_SESSION.md`~~ DONE 14z-113:
  `docs/project/mister_scope.md`; its three follow-on decisions are the
  entry "THE MiSTer SCOPE DOCUMENT — three decisions" above.** The scope document
  names what skills should exist, where each boundary falls, which existing
  docs feed which, and what is known-stale; the skills themselves wait on it.
  Rationale for splitting it out: the sources run ~4,000 lines and must be
  READ, and the state is not settled (merged17 unfrozen, two field checks
  outstanding), so writing reference material now would bake in claims that
  are still moving. Recorded as FUTURE work alongside the existing
  skill-distillation and living-documentation items, not scheduled. The
  maintainer's scoping: document (and possibly distil into skills) the MiSTer
  implementation **at each level** — (1) the **WIDE CPS-II core** level (the
  profile, the runtime profile bit, the SDRAM map, the simulation lane: all
  game-independent), and (2) the **VS-specific** level (this romset's
  placement, catalogue/MRA generation, the field-test bundle). The split
  mirrors `docs/README.md`'s own test ("would this still be true if we
  abandoned the roster hack tomorrow?") and the CPS-II-vs-VS/VS2/VH2 split
  already sketched for the skills. Raw material exists and is large:
  `docs/platform/mister.md` (core, lane, profile gate, SDRAM ceilings) and
  `docs/project/mister_fit.md` (what this port needs vs what jtcps2 offers).

- **THE LIVING-DOCUMENTATION EFFORT, and the option it creates (maintainer
  direction, 2026-08-24).** Recorded as DIRECTION, not as a task — nothing is
  scheduled and MiSTer stays the current arc. In their words: an important
  documentation effort is coming, "not replacing your logs, but creating a
  living documentation that can easily be referenced by you or me, doesn't go
  stale or lost in a statistically never read file." The SailorMoonS project's
  documentation AND WORK DISCIPLINE are the reference; formats, document types
  and visualisations are to be chosen as the best fit for THIS project rather
  than copied. Motivation: the emulator side is now essentially fully mapped.
  **The option it opens:** after the MiSTer core is finished, potentially
  "go back to the canvas, with all the documentation, and redo the project
  from the docs, because it might create a cleaner, more consistent extended
  codebase." Explicitly a possibility to preserve, not a commitment.
  **Two things worth holding on to when it is scheduled:**
  1. **Staleness is defeated by ENFORCEMENT, not by format.** What keeps the
     SMS docs alive is `tools/checkdocs.py` re-deriving documented addresses
     from the cartridge, `--check` modes on every generator, `health.sh` in
     CI, and the rule that no number reaches a doc without a run that produced
     it in that session ("an unquoted address is a claim nobody can falsify").
     The prose should be shaped so it CAN be checked. Being lost in an unread
     file is a SEPARATE problem with a separate fix — routing: "if you want to
     know X, read Y" tables at every entry point, and every synthesis document
     naming its journal twin and vice versa.
  2. **A rebuild here is unusually provable, and its feasibility is
     MEASURABLE TODAY.** The harness compares ROM BEHAVIOUR, not source
     structure, so a rebuilt artifact has a real acceptance test that already
     exists: bit-identical to vanilla on the legacy corpus, field-identical to
     the current build on tenant content, same replays, same frozen
     expectations. What decides it is not the docs but **how much of the build
     is DATA versus CODE** — the artifact encodes hundreds of measured facts
     (reconciliation rows, planted tripwires, pc-rel escapes, the ~70 re-point
     defaults, the op-count freezes), and a rebuild that does not carry them
     re-pays every debugging session that produced them. CLAUDE.md rule 5
     already requires behavioural values to live in documented tables rather
     than in code, so feasibility is essentially the degree to which rule 5
     has been honoured — which can be MEASURED rather than estimated.
     RECOMMENDATION when the effort is scheduled: make the first structural
     deliverable the EXTRACTION of measured facts from manifests/generators
     into reviewable tables with provenance. It makes the current codebase
     auditable whether or not the rebuild happens, and it is the precondition
     that turns the rebuild from a hope into an option.

## THE DEADNESS REGISTER (opened 14z-71, maintainer's standing instruction)

**[VSP-23]** Every claim of the form **"legacy never reaches this, so we may reuse
it"**. Each is measured by ABSENCE, which is the weakest kind of evidence
we accept, so each is listed here with its guard. **These are the FIRST
PLACES TO CHECK for any unexplained regression in vanilla assets, engine
behaviour or rendering** — before anything else is suspected.

| Reused resource | Claim | Guard | Fallback if wrong |
|---|---|---|---|
| ~~palette-seq ids 0x1E-0x21 (`0x39ACC0`)~~ **CLAIM FALSE, ROW WITHDRAWN 14z-79 (they are Bulleta's DF block)** | vanilla only ever requests 0x26/0x27 | `tests/audit_palette_seq_ids.sh` (10,504 sampled calls) | none — the palette path never transits work RAM, so the audit is the ONLY guard |
| effect-class row 16 (`0x080AEC`) | vanilla never dispatches class 16 | `tests/audit_effect_class_rows.sh` §1, 0 reads vs a 1760-hit control | none needed: the row was a stub (`rts`), so a wrong claim costs at most the old no-op |
| ~~drawer list-type 6 (`0x01B6AA`)~~ **CLAIM FALSE (measured 14z-89) — LEGACY LISTS DO REACH TYPE 6** | vanilla has no type-6 sprite lists | `audit_effect_class_rows.sh` §1/§4 + `tests/test_beam_list_type6.sh` | **THE FALLBACK HELD — this is what a safe-and-loud design buys.** 14z-89 measured the tripwire ARMED on legacy content on huitzil-m13: `21_don_mash` 387 times and `26_don_arcade_mash` 948 times, PC-attributed to inside the thunk body (0x0FD060). Rendering stayed correct throughout (the fallback runs vsav's own type-6 code, reproduced instruction-for-instruction), so nothing rendered wrong and no playtest ever saw it — exactly the outcome the register's "prefer designs where being wrong is safe and loud" rule was written for. WHY IT WAS MISSED: the deadness measurement was sound but its COVERAGE was four replays (`02/07/09/30`), and the gate has always run on that default set; the two replays that arm it are long mash/arcade rigs nobody pointed it at. COST TODAY: `$FF010C/$FF010D` is a live work-RAM counter vanilla does not keep, so both replays diverge permanently from the vanilla masked basis — they are `.pending` on huitzil-m13 pending the maintainer's ruling. OPEN: does the fallback need to stop counting (make the tripwire diagnostic-only / move it out of work RAM), or is the counter acceptable? See "Decisions pending — 14z-89" |

**[VSP-22]** Rules for adding a row: the claim must be measured with a POSITIVE CONTROL
on the same instrument and leg (a blind instrument and a real zero look
identical — paid for three times in 14z-71); it must name its guard; and
it must say what happens if the claim is wrong. Prefer designs where being
wrong is *safe and loud* over designs that are merely well-measured.

## Open bugs

- ~~**WIDE sprite garble (14z-60y)**~~ **FIXED 2026-08-05 (14z-61).** Not a
  rendering defect: the shipped WIDE romset carried group C as byte copies
  of the stock group B, so those copies held group B's CRCs and the loader
  — which resolves by hash before name — served PRISTINE tiles for the
  members the build had patched. Fixed in the pipeline (shippable overlay
  zero-filled, canary romset separated, `tools/audit_romset_identity.py`
  wired into the build), verified on both emulators with pristine and
  stock-track controls, and gated by `tests/test_wide_render_content.sh`
  (pixel A/B vs the stock track + a positive control) and
  `tests/test_romset_identity.sh`. Full write-up: session 14z-61.
  **CLOSED — maintainer playtest of `build/m5_wide` (`9bac6ee3`) confirms
  it**, with and without Donovan: no regression, graphics good, gameplay
  genuine, sounds good.
- ~~Minor win-screen palette issues~~ **FIXED 14z-68m** (build/hui11):
  the palette source is the OPCODE-view remap table, and the portrait
  position row needed vs2's own values. Gate: `tests/test_hui_winscreen.sh`.
- **OPEN (cosmetic):** win QUOTE TEXT — **all THREE tenants still show their
  SHELL's quote** (corrected 2026-08-27 by the maintainer; this entry used to
  say "Huitzil's", which understated the scope). Root-caused, not built: the
  first-level table at the quote bank base ALIASES its variant half
  (`0x10->0x00`, `0x11->0x01`, `0x13->0x03`) — *corrected 14z-116: this entry
  said "consumer bias `lea -4(a0,d0.w)` -> reads index `0x60+id-1`", which is
  the 14z-73 reading of the PORTRAIT fetch and was retracted in
  `engine_internals.md` the same session; it is not the quote mechanism.*
  MEASURED 14z-116 (see the session entry and "Decisions pending"): a
  data-only fix is impossible, the relocation perturbs legacy work RAM, and
  ~330 glyph TILES have to travel. NOTE the
  win-quote ART is already native and complete (14z-62e/62j, group C bank 5) —
  what remains is the TEXT. See the cosmetic backlog below.
- **OPEN (gameplay, GitHub #114): DONOVAN'S 421+P DOES NOT REPRODUCE NATIVE —
  MEASURED 2026-09-02, and `test_don_reactions.sh` is GREEN THROUGHOUT.**
  Native vsav2 lands **6 hits / 10 damage** and HOLDS the victim at x=728 to
  f2685; ours lands **3 hits / 11 damage** and pushes the victim 728 -> 852,
  ending f2640. Positions are byte-identical between the games until the move
  connects, so the confound is eliminated: **our reaction does not hold the
  victim**, the opponent leaves range after three hits and the remaining deity
  ticks whiff. Not a count-tuning error.
  **WHY IT LOOKED CLOSED:** the 14z-42 cadence root cause (vsavj's older
  freeze tuning) and the 14z-43 dispatch fix were real and stand; the
  MULTI-HIT VALUES half was never validated against native — it was tuned
  against playtest + community information. The gate cannot see the gap: all
  four legs run `vsavj`, `native == 10` is a hardcoded constant from
  testimony, its window starts at f2630 while our first hit is at **f2627**
  (so it sums 7 of the true 11), and its bounds are ONE-SIDED so an
  undershoot passes.
  **NOT TIGHTENED, DELIBERATELY:** widening the window and making the bounds
  two-sided turns the gate RED, and a red gate halts forward work ([VSP-7]).
  Maintainer's call. Next: why the victim is not held (reaction/pushback path,
  `0x2783C[record +0xC]`), then mizuumi's Donovan page as a third opinion.
- **OPEN:** FG pacing — untouched.

### THE COSMETIC BACKLOG (parked, 2026-08-27 — the maintainer's own list)

Ruled a single later pass over "the purely cosmetic things that remain related
to the port", opened when #112 was accepted as cosmetic. Nothing here is
scheduled, and none of it is competitive-2P surface (see the standing
"cosmetic is optional" scope: cosmetic + single-player-only surfaces are
nice-to-have). Collected so the pass does not start from a blank page:

| item | status | what is known |
|---|---|---|
| **Win-quote TEXT for all three tenants** (each still shows its shell's quote) | **FORGONE FOR NOW (maintainer 14z-116); parked WITH A CONSTRAINT — if ever done, the CLEAN way only, vanilla untouched** | the first-level table aliases the variant half; a data-only fix is IMPOSSIBLE (zero free bytes at either hop, re-derived by `tools/scan_quote_window.py`), the bank relocation perturbs `RAM:$FFF230` on legacy win screens, and ~330 glyph tiles must travel. Art side already native (14z-62e/62j) |
| **Arcade ladder OPPONENT-ROULETTE TAG for a tenant opponent** (1P, tenant-plays-1P only — the CPU draws a tenant only on a tenant's ladder row) | measured 14z-123, not fixed | the tag shows the BASE character's name and mini-art (Phobos `0x10` → "BULLETA", a 4-bit-folded consumer, PC not attributed) drawn in pool row `PRG:0x3A3CA0 + id*32`'s own colours (a brown ramp for `0x10`; `0x13` is a grey ramp). The VS screen itself is correct (pixel-identical to the 2P path). Fix shape if ever wanted: author three pool rows (`0x3A3EA0/0x3A3EC0/0x3A3F00`, 32 bytes each, in a table vanilla never indexes past `0x0F` — legacy-invisible by construction) plus un-fold the tag's name/art consumer (its own measurement). Gate `tests/test_ladder_tenant_vs_palette.sh` |
| **Arcade ladder MAP NAMES and PICTURES** | not investigated | the map screen is the one that follows the win screen (a documented rig trap, STATE_HISTORY 14z-99); stage banners decode via `tools/decode_stage_banners.py`, venue byte `$FF8100` |
| **Character SELECT WHEEL polish** | not investigated | the wheel is functionally correct and emulator-identical; this is look-and-feel only. Layout facts in `docs/game/atlas/select_screen.md`, the 21-cell roster and its inbound edges |
| ~~**PYRON'S MEDALLION WHITENS on the select screen**~~ **FIXED 14z-116** | **FIXED and FROZEN 14z-117** as merged-m12 (`build/m3b_merged19` rebuilt with the M10 mark, `cde712e1`; the 14z-116 candidate was `af21bc88` under M9 — same bytes) | **The long-parked residual is closed, and it was never the accent march.** WRITE-TAP ATTRIBUTION (16 word writes, PCs `0x3FFC60-0x3FFCA6`) named **our own 14z-62k sword thunk** at `PRG:0x05F9D0`: its P2 branch wrote `0x90C340` = row `0x1A`, which is also Pyron's medallion row. Not Donovan's portrait (the 14z-87b supposition), and not the marcher — the marcher was already neutralised for `0x16/0x19/0x1A` in 14z-64. **Maintainer chose the fix from three options (2026-08-28): drop the P2 write.** `tst.b $381(a4)` now `bne`s to the pop/rts, two NOPs replace `adda.w #$60,a1` — same byte count, no allocation ripple. **ACCEPTED TRADE, field-observed 2026-08-29 (and NOT what I predicted):** the P2 sword does not revert to grey — it draws with whatever row `0x1A` holds, which is now Pyron's medallion palette, so its pixels go from steel blue-white `(153,170,221)` to orange-gold `(255,136,34)` and, on Donovan's own gold-and-red costume, read as the sword being ABSENT. The grey ramp was the PRE-62k state, before a medallion lived in that row. **A partial fix is IMPOSSIBLE (measured): sword and medallion draw from THE SAME entries of row `0x1A` — 23 shared colours — so the row cannot be split by pen.** **VALIDATED ON THE BOARD (maintainer, 2026-08-29): "Confirmed, the sword is
actually orange, and only on the select wheel screen, this is a good
tradeoff. The fix is validated."** The scope confirmation matters as much as
the verdict: the trade is CONFINED TO THE SELECT SCREEN — no in-match
surface — which is what the thunk's site (`PRG:0x05F9D0`, the select figure
uploader) predicts and the board now measures. MEASURED: row `0x1A` holds Pyron's vs2 palette across the whole select with P2 on Donovan; P1's accent on row `0x17` byte-for-byte unchanged; **`38_victor_p1_vsavj`, `05_timeout_idle` and `63_idle_select` BIT-IDENTICAL to merged18** (the changed path runs only on a P2 tenant hover, which no legacy replay does) — note `38` is the exact replay whose one-main-loop slip forced the 14z-88 revert of the previous attempt. Gate: **`tests/test_pyron_medallion_2p.sh`**, two legs, verified to FAIL on merged18 and PASS on merged19. **It closes a real coverage gap:** `test_wheel_bank5` 3b's two protocols are both SINGLE-PLAYER, so it could never see this and stayed green through every freeze. **NOT FROZEN — a freeze is a separate decision** |
| **#112 Press of Death black foot** (Donovan's EX foot super) | DECIDED cosmetic, parked; **maintainer 2026-08-28: too risky for a small cosmetic gain** | whole draw path measured VANILLA. ~~why a tenant runs that vanilla sequence is unknown~~ **REFUTED 14z-126b: it does NOT run one** — at every instance on merged-m14 the drawing objects' `+0x1C` point into Donovan's PLACED region and no work-RAM field holds a vsavj record pointer (positive control fired 15/15); `0x28394E` is never stored anywhere (all 7 candidate sites disassembled to instruction-boundary noise); and all 9,755 tenant sprite pointers are relocated (now gated). WHAT REMAINS: the records' TILE CODES — the effect map's coverage, the builder's own "render garbled, never crash" note. The BLACK case does not reproduce on the current build (needs a rebuild from `freeze/merged-m9` or a fresh recording) |
| ~~**RANDOM SELECT should include the three tenants**~~ — ADDED TO THE LIST by the maintainer 2026-08-28; **BUILT 14z-117 at the maintainer's word ("do the random-select includes the tenants then"), gated (`test_random_select_tenants.sh`: draw = 15 vanilla + this build's tenants; confirm on a tenant frame loads the tenant's own record; must-fire control), frozen as merged-m13 (M11); FIELD VERDICT GREEN on the board (maintainer, MiSTer, 2026-08-29, STATE 14z-118)** | DONE 14z-117 — TWO sites, not one: the walker re-reads the table on its non-tick frames (`select_screen.md` "THE WALKER HAS TWO PATHS"); a bound-only thunk crashed the figure refresh with a code byte as id | the "?" cell walks a FIXED 15-entry table at `PRG:0x020C88` (`04 07 02 0C 05 0F 0A 00 0E 03 08 01 0D 09 06` = the base-half roster minus `0x0B`), 3-frame cursor, wrap `cmpi.b #$f`. Both bounds hard -> a tenant can never come up. **The siblings are the precedent**: vsav2's twin table (`PRG:0x01F8B4`) lists `10 11 13`, vhunt2's too — including the newcomers is what the source games do. FIX SHAPE: 18-entry relocated table + bound `#$f` -> `#$12`; it cannot grow in place (15 bytes + 1 pad, then code at `0x020C98`) and the table is read PC-relative, so it is a `site_thunk` on `PRG:0x020C80` + a `code` op, not a data poke. COST TO WATCH: the added cycles land on the select screen, whose legacy replays are already the bounded-window class — measure the onset before and after |
| **MARIONETTE — a vs2 character, PARKED UNTIL FURTHER NOTICE (maintainer, 2026-08-28)** | not ported, not planned | **Assets live in VS2, not in VS.** She is not in Vampire Savior at all, so nothing in our romset is missing or broken by her absence. The maintainer's framing, and it is the right one: **Marionette and Shadow are both just MIRROR-MATCH MECHANISMS** — the shared machinery at `PRG:0x009BB2` copies the opponent's id and palette, so "playing as" either is playing the opponent's character. That makes porting her a low-value item: it adds a second route to a mirror match, not a character. **Not before everything else.** If it is ever revisited, note that vs2's arming counter is the SAME single `#$5` check as vsavj's (`PRG:0x01F8D6`), so whatever arms her in vs2 is a different mechanism and has not been located |
| **Oboro's intro eats into the round** | **DECLINED by the maintainer 2026-08-28 — do NOT delay round start or cut the intro** | recorded so it is not revived: it would be a match-state TIMING change on a shared path for a cosmetic reason, which is the trade the superset invariant exists to refuse. The maintainer will instead check whether vsavj's Oboro has an alternate SHORT intro |
| ~~(#113 first-down white-out)~~ **CLOSED 2026-09-01** | **not ours** — vanilla in vsavj AND vsav2, and the board agrees | the maintainer's MiSTer check came back consistent and they closed GitHub #113 the same day. Mechanism (palette RAM vs CPS-B layer register) still unmeasured — an honest boundary, not an open item |

**THE ARCADE HIDDEN-CHARACTER ROSTER — CONFIRMED BY THE MAINTAINER
2026-08-28.** Exactly THREE exist in the arcade game: **Oboro Bishamon,
Dark Gallon and Shadow.** *(First stated as four including Marionette, then
corrected by the maintainer within the hour: **Marionette is a Vampire
Savior 2 character, not a Vampire Savior one**, and the "7 START presses"
code belongs to vs2. Recorded because the ROM agreed with the correction
before it arrived — see the Shadow row.)* *The alternate Lilith, Aulbath and
Victor are CONSOLE-PORT ONLY* — which independently confirms the 14z-116
table measurement (the only variant datasets in any of the three ROMs are
our three tenants plus two Oboros; there is no Lilith/Victor/Aulbath
alternate anywhere). Status of each on our build, all measured 14z-116:
- **Oboro `0x18`** — shipping, ours, gated (`test_oboro_select.sh`), field-confirmed 14z-105. **CAUTION for the maintainer's floated idea of removing the hold-START hook "since Oboro and Dark Gallon were already in VS" (2026-08-28): that is true of DARK GALLON and NOT of OBORO.** Measured 14z-116: the only immediate writes of a character id in vsavj are `0x02`, `0x04`, `0x0B` and `0x12` — **no vanilla path anywhere writes `0x18` to `$382`.** vsavj ships Oboro's DATA complete (record `0x0B3450`, own palette block, 20 distinct bank rows) but no player-facing select path, which is precisely why 14z-105 added one. Removing the hook would make Oboro UNREACHABLE again; Dark Gallon would survive untouched, since that path is vanilla's own.
- **Dark Gallon `0x12`** — vanilla's own path (Gallon + START + 2-3 punches *or* 2-3 kicks, `PRG:0x020B9C`); our Oboro hook displaces that block's first instruction and re-executes it, so it is preserved BY CONSTRUCTION. Statically certain, **never played** — the maintainer is field-testing it.
- **FIELD VERDICT ON M9 (maintainer, MiSTer, 2026-08-28): "everything seems
  right... the new character wheel already looks almost perfect on CRT,
  Shadow works as intended, Dark Gallon is properly selectable with hold
  start + 3 punches at the same time. All seems perfectly fine."** So the
  E2 wheel is CRT-confirmed, Shadow is confirmed working on silicon, and
  **DARK GALLON IS CONFIRMED PLAYABLE** — which also validates the 14z-116
  static decode of `PRG:0x020C18` (the trigger accepts `0x300`/`0x500`/
  `0x600`/`0x700`, i.e. two OR three punches; the board used three).
  **TWO THINGS HE COULD NOT TEST IN ~2 HOURS OF TRYING, AND BOTH ARE
  STRUCTURALLY IMPOSSIBLE — the time was spent on things that cannot
  happen. Measured, so nobody spends another two hours:**
  1. **A tenant from RANDOM SELECT.** Already measured this session: the
     "?" draw is a fixed 15-entry table (`PRG:0x020C88`) holding no
     variant-half id, bound `cmpi.b #$f`. It is not luck, it cannot occur.
  2. **SHADOW vs a tenant, in 1P arcade.** NEW measurement: scanning ladder
     table A (`PRG:0x00B268`, 36 rows x 8 groups, reachable indices 0-5 —
     the scan bound `$FF8138` is 6) for a tenant candidate returns **rows
     16, 17 and 19 ONLY — i.e. classes `0x10`/`0x11`/`0x13`, the tenants'
     own rows.** A tenant appears as a CPU opponent *only when the player is
     a tenant* (which is exactly the shape of the #99 field crash: Donovan
     1P -> CPU Phobos). **Shadow's own pool is rows 32-34** (`0x800 +
     $3BD*8`) **and contains no tenant in any group.** So Shadow can never
     draw one from the ladder, however long you play.
  **HOW TO TEST IT ON THE BOARD:** 2P VERSUS — P2 picks the tenant with the
  sticks, P1 does the Shadow code. That is exactly what the emulator rig
  does (`tests/replays/113_shadow_vs_tenant.rpl`), and it is the only route
  either implementation has to that matchup.
  **-> DONE, AND GREEN (maintainer, MiSTer, 2026-08-28): "Shadow works
  perfectly even with the VS2 tenants in 2P vs, so that's a win."** The
  board agrees with the emulator leg on the one case that mattered, so the
  Shadow-vs-tenant question is CLOSED on both implementations.
- **NO LEGACY CHARACTER EVER MEETS A TENANT IN 1P ARCADE — RULED NOT A
  PROBLEM (maintainer, 2026-08-28): "not a problem since we're way focused
  on 2p vs". CLOSED, no work planned.** Kept as a measured fact because it
  explains field observations rather than because it needs fixing.** Rows `0x00-0x0F`
  contain no reachable tenant candidate at all, so a 1P run as Morrigan (or
  anyone vanilla) can never be scheduled against Donovan, Phobos or Pyron.
  The port authored the tenants' OWN rows (what they fight) and never added
  them to anyone else's. This is the same family as the random-select item
  and arguably more noticeable in play — a player's whole arcade experience
  never shows the new characters unless they pick one. **Not built, not
  scoped, no recommendation without a ruling**, and it is a GAMEPLAY-FEEL
  change (who you fight, and the ladder is already a lottery), so it is the
  maintainer's call per CLAUDE.md 5.
- **TENANT CPU AI LOOKS "LACKLUSTER" — maintainer observation (2026-08-28),
  UNPROVEN, DEPRIORITISED.** Verbatim: *"when I do fight against any of the
  VS2 tenants it seems their AI is lackluster to say the least and I'm
  pretty sure that's a side effect of the port although I can't prove it...
  but once again, we're 2P vs focused."* Recorded rather than investigated,
  with the archaeology a future session would start from so it is not
  re-derived: the four per-class AI action-script tables
  (`PRG:0x0BF01A/09A/11A/19A`) are **16 classes THEN THE SAME 16 REPEATED**
  (Capcom's aliasing guard), which is what made CPU-Phobos play DEMITRI's
  AI and was the root cause of #99; 14z-111 fixed it by making each
  tenant's OWN vs2 AI script block a data root (option A, zero code). So
  the tenants do have their own scripts now — but whether those scripts are
  as *deep* as a legacy character's on this engine has never been measured,
  and "feels weaker" is not a measurement. **If it is ever picked up, the
  first question is whether the ported script blocks are COMPLETE** (a
  truncated block would present exactly like this), not whether the tables
  are aliased. CPU-side only — 2P versus never reads them ([VSE-75]).
- **SHADOW vs A TENANT — MEASURED AND GREEN (14z-116).** The maintainer's
  question ("the big problem is not selecting him, it's knowing whether the
  game breaks", INCLUDING "does Shadow take the SHELL character instead of
  the tenant") was answered by a RUN, not by disassembly. Rig:
  `tests/replays/113_shadow_vs_tenant.rpl`, gate `tests/test_shadow_tenant.sh`
  (emulator tier, ~6 min, two runs, must-fire control). **RESULT: Shadow
  takes the TENANT.** P1 armed the code (5 START presses on "?"), beat P2
  Donovan, and at the round end flipped `0x00 -> 0x13` with the loader
  installing **Donovan's own record `0x003FA9D0`** — not Victor's
  `0x0009769E`, the shell `0x13` aliases, which is exactly the quiet failure
  the gate is written to catch. HUD reads "Donovan", art is his, and the run
  is **guard-clean END 21120** across several further morphs.
  **TWO CORRECTIONS TO MY OWN EARLIER STATIC PASS, both from this run:**
  (1) `PRG:0x009BB2` is NOT match init — it is the ROUND/MATCH-END path
  (`$13A`/`$13C` are the winner/loser pointers), so **Shadow does not keep a
  pick, he takes the character he just beat, round by round**; (2) arming
  alone leaves you playing the roulette's pick rendering NORMALLY (measured:
  Bulleta, no silhouette), so what produces the black-silhouette
  presentation on this Japan set is still unestablished — it blocks nothing.
- **Shadow** — present and vanilla: exactly 5 START presses on the "?" cell then any attack button (`select_screen.md`), which matches the community code instruction for instruction. The mechanism copies the OPPONENT's id and palette **UNMASKED** at `PRG:0x009BB2`, and every table the copied id then indexes is 32 rows with our tenant rows populated, **so Shadow-copying a TENANT is structurally expected to work**. Never run — this is the `coverage_matrix` "morphing INTO a tenant" cell, and it now has a mechanism attached rather than an unknown.


## Findings log

- 2026-07-25: key masters — vsavj `0xfa8f4e33a4b881b9` (watchdog
  `cmpi.l #$726A4BAF, D0`), vsav2 `0xd681e4f460371edf`, vhunt2
  `0x36c1eba326b10f18` (vsav2/vhunt2 share watchdog
  `cmpi.l #$06920760, D0` — sibling builds). All three: encrypted range
  `PRG:0x000000-0x0FFFFF` only (first 1MB of 4MB). Decryption of all three
  proven bit-identical to MAME (`tests/test_decrypt_oracle.sh <set>`).
- 2026-07-25: ROM file byte order ≠ 68k logical order; cost ~1h; conventions
  locked and oracle-tested (docs/GOTCHAS.md).
- 2026-07-25: MAME 0.288 vsavj boots and runs attract deterministically
  headless (`-video none -sound none`, fresh sandbox per run).

## Integration notes — SMS docs (imported 2026-07-24)

Conventions live in CLAUDE.md §4/§5 now; taxonomy files exist as of this
session. Still to mine when relevant (park, don't re-derive):
- SMS `coltest.lua` pattern (scripted char-select navigation → saved match
  state) for generating the 18×18 matrix states in M4.
- `trace.lua`/`trace_plan.lua` config shape for the CPS-2 input logger.
