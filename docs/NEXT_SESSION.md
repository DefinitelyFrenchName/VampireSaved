# NEXT SESSION — orientation (rewritten at the 14z-171 CLOSE, 2026-09-20)

> Rewritten at every session close ([VSP-17]). ROLLOVER: the previous opener
> moves VERBATIM to the top of `NEXT_SESSION_HISTORY.md` — this file holds ONLY
> the live orientation. Session state, not knowledge: facts belong in the docs,
> status in STATE.md.

## M19 IS FROZEN (14z-170): the four ruled #136 fixes and the x2b7ef4 repair — donovan-m23 / huitzil-m30 / pyron-m24 / merged-m19, `build/m3b_merged27`

What it carries: no gauge in the tenants' Dark Force; vs2's defense rows for Phobos and Donovan;
the vs2 EX inputs do the no-stock move (Pyron's reads 623+PP, ruled natural); the class-0x52 rule
(column and — on merged — trap), scope S1; and the `x2b7ef4` companion-effect records the
generator's in-place scan had corrupted since at least merged-m16. HANDOFF "Current WIDE builds"
and patch_notes 14z-170 have the detail; STATE 14z-170 the record.

## START HERE

1. **M19 IS FROZEN, NOT RELEASED — and the release WAITS, by ruling (2026-09-20):** *"let's not
   release now, especially since we have tickets relative to the deliverables on various OS"*. The
   blockers are **#144** (macOS blocks the prebuilt binaries), **#145** (Windows: they fail to load)
   and **#146** (the player READMEs), each reported and none yet reproduced. When they are done, the
   release run is `--scope all --lane all --strict --controls` (~5.5 h, HANDOFF "WHAT THE RELEASE RUN
   COSTS"), then `tools/upload_release_assets.sh` on `freeze/merged-m19`. `release/merged-m19/` is
   packaged and gated in-tree; the freeze tags and registry rows stand.
2. **The orange flash** (#162, cosmetic) is ANSWERED and PARKED by agreement — see ALSO OPEN. It is
   NOT a sequence-id defect: ours' row 11 baseline is Donovan's sprite-palette block, native's is
   vs2 seq row 0x2CF, and both games upload seq 0x2D4 identically during the move.
3. **Phobos's remaining +1** (the bug ticket, #161; `tests/audit_phobos_dmg_residual.sh` reproduces it): Demitri's 5HP
   takes 12 on ours, 11 native, with Phobos's defense rows already vs2's — trace the damage staging vars stage by stage on
   both legs for that one hit (`docs/game/engine_internals.md` "The DAMAGE pipeline").
4. **#168 — THE RIG FIX THE MAINTAINER PUT ON THE NEXT PRIORITIES (2026-09-20).** The naming rigs'
   first X pin lands at 2370, inside the round-start entrance, on SEVEN parts (`donovan_13`,
   `huitzil_3/5/6/7`, `pyron_3/5`) — the #136 ENTRANCE class. The fix is WRITTEN AND MEASURED
   (`PIN_FLOOR = 2560`: `move_parity` DIFF 102 -> 95, the ENTRANCE root gone, two events shown never
   to have fired their named move) and BACKED OUT, because moving the first event re-rolls the
   corpus's input-window-edge probes and three regress. What it needs: re-tune `pyron_5` ev5 and
   `huitzil_7` ev8/ev9 until each enters its own `moves_*.toml` chain, then the re-freeze and a
   rule-checker run. The reworked `audit_rig_opening` (green, ground-truthed both ways) comes back
   with it. Everything measured is on the issue.
5. **The #136 tickets still open**: #157 (the throw hit-registration pair — the meter family), #159
   (facing rule 5), #163 (the column/trap rule: its airborne case); the maintainer's to schedule.

## ALSO OPEN (carried from 14z-168/169)

- A column hit on an AIRBORNE victim (the air stager's case) is not measured — #163's one open item (the column KO read clean on the capture, 2026-09-19).
- #162 is ANSWERED and PARKED by agreement: the orange flash is not a sequence-id defect but
  Donovan's sprite-palette block showing through, and his palette-routine row `0x13` is the no-op
  default in all three dispatcher tables where vs2 runs a real routine. The one open measurement is
  which path sets `a0` to the sprite block (a breakpoint at the uploader; registers are trustworthy
  under `-debug`, frame numbers are not). Everything measured is on the issue.

## TRAPS PAID THIS SITTING (14z-171)

1. **A rig change is not "a shift" until every moved row is attributed field by field.** The
   throw table moved by a clean +190 with byte-identical values on one part and GAINED a real
   contact on another; only the column-level diff separated the two.
2. **Separate two changes before believing either.** The pin fix and the stock fix landed
   together and the naming diff looked like one defect; run alone, the stock fix is provably
   INERT (zero chain differences) and every moved chain belongs to the pin fix.
3. **A field named `seq` is not the field the naming walker uses.** An A/B on `$FF8406` read
   "identical engine behaviour" for an event whose reported chain had changed — the wrong
   instrument for the question, and it produced a confident wrong conclusion ([VSP-148]).
4. **Take a baseline at HEAD before concluding a frozen line is stale.** A worktree at HEAD
   showed `test_move_naming` green, which is what proved the moved chains were mine.
5. **A constant validated under the rig's own pokes needs the poke withheld.** The round start
   reads 2545 with AND without the speed-level pin, which is what makes it the intro's property
   rather than the rig's.
6. **Tune nothing to make a symptom go away.** `PIN_FLOOR` 2560 broke three events and 2570
   broke more — a signal that the corpus is frame-fragile, not a number to search.
7. **`git checkout HEAD -- <file>` reverts every edit in that file**, including an unrelated one
   made earlier in the sitting (the P2 retraction had to be re-applied).

**IF A DOC IS TOUCHED:** the doc gates (`test_checkdocs`, `test_docshape`,
`test_doc_anchor_census`, `test_checkskills`, `test_gotchas_index_current`,
`test_gate_index_current`, `test_state_open_lists`, `test_tickets`) plus
`tools/check_state_lists.py` and `tools/tickets.py check`, exit statuses captured
directly, `${=cmd}` in zsh. **A running script is never edited** ([MSC-54]).
