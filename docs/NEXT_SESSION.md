# NEXT SESSION — orientation (rewritten at the 14z-164 CLOSE, 2026-09-17)

> Rewritten at every session close ([VSP-17]). ROLLOVER: the previous opener
> moves VERBATIM to the top of `NEXT_SESSION_HISTORY.md` — this file holds ONLY
> the live orientation. Session state, not knowledge: facts belong in the docs,
> status in STATE.md.

## THE #136 SCOPE CENSUS IS DONE AND RULED (14z-164): the move-parity gate judges EVERY EVENT (`tests/expected/move_parity_events.tsv`, 506 events of 30 parts: 377 IDENT / 103 DIFF / 25 NOT-IN-DF / 1 VOID), with the meter fraction and Victor's HP compared and every "in DF" event asserted in DF; the 13 old divergences are RE-LABELLED on #136 (5 Victor-first, 3 DF activations, 2 Phobos-HP-by-1, donovan_2, huitzil_5, pyron_3); NO legacy character carries the same data on both games (`tests/test_same_data_p2.sh`; Demitri nearest, one cursor move for P2 on both wheels; Victor's hitstun head hurtbox is retuned on vs2 and that is why contact rows diverge in his state). The maintainer agreed the three propositions (`DECISIONS_HISTORY.md` "Ruled 2026-09-17 (14z-164)").

## THE RULE-CHECKER CAUGHT THIS SESSION FOUR TIMES (runs 22-25 in `tests/rulecheck/ledger.tsv`), every finding true: a damage split mis-read, a cross-part count, Phobos's stock figures copied from Donovan's, a window "identical" while Victor already differed, and TWO instrument defects — the census's own change-from-window-start comparison turning the rig's HP pin into a DIFF, and two line ranges of one file colliding in the checker's staging (#156, fixed). Write the claim after reading the artifact, name every shared pin, and expect the checker to be right.

## THE SESSIONS ACT ON GITHUB AS `mechanyaa-ai`; a commit subject never puts close/fix/resolve directly before `#N`. The static tier runs by CADENCE; the close is the session cadence with every control executed, then the push.

M18 (`merged-m18`, `build/m3b_merged26`) is still the current freeze and release.
`git status -sb` says the push state. The withdrawn M19 build dirs are on disk,
UNREGISTERED — do not play them and do not point a gate at them.

## START HERE — what is open (THE ORDER IS RULED, 2026-09-17: stable state, then #148 (DONE), then #152 (BUILT, open until a real run under the bounded questions is accepted — runs 22-25 are real runs), then everything else)

- **#136 — the P2 decision, then the families.** The maintainer agreed to a same-data P2;
  none exists among the legacy characters (`tests/expected/same_data_p2.tsv`, differing
  chains per table, shared seqs, invalid-on-one-side classed apart): for a P2 that stands
  and gets hit what counts is table a (base states) and b (reactions), then c (thrown
  poses) — Demitri a 0 / b 3 / c 0, Bishamon 2 / 2 / 0, Bulleta 3 / 1 / 0, Lei-Lei 4 / 1 / 0,
  Victor 0 / 7 / 19 (his hitstun head hurtbox, the confound); every b list includes 0x10,
  the engine-wide held-pose push box. So Demitri (P2 path `R` on both wheels; a rig must
  assert he never enters `b:0x71/0x74`) or a second TENANT (same vs2 data on both legs by
  construction, but its own port under test too). That is a decision for the maintainer
  (asked 2026-09-17, rationale given at the 14z-164 close); switching P2 changes
  every naming rig's prologue and re-freezes `test_move_naming`, `test_projectile_census`,
  `audit_move_parity`. Only then root-cause the families, capture first ([VSP-136]):
  the 103 DIFF rows are frozen as measured, 30 of them meter-first (Pyron's Planet
  Burning +30 native / +20 ours per use is the largest), Cosmo Disruption held lands 4
  hits on ours against 2 (`pyron_4`, +156), Press of Death's x, huitzil_5's gc window.
- **In-DF coverage is 5LP/5MP (Donovan) and 5LP (Phobos, Pyron)**: the batteries outrun
  the 360-frame DF. A RIG change (re-activate DF per group of events, never a comparator
  tolerance) is needed before any in-DF move is measured — the maintainer agreed
  2026-09-17 ("agreed and this should be in next_session.md"); the 25 NOT-IN-DF rows of
  `tests/expected/move_parity_events.tsv` say exactly which events.
- **#154 and #155** (the fidelity gate's FREEZE branch; its hand-typed replica leg), **#153**
  (lever B), **#150** (the freeze ritual's silent-green modes): filed and unstarted.
- Every other open ticket is on `docs/project/tickets.md`; the harness has BBH-frame-based #1.

## TRAPS PAID THIS SITTING

1. **A gate's must-fire control overwrites the first part's native trace in its work dir**
   (`audit_move_parity`'s unpinned-level control): keep traces from a copy that puts an
   IDENTICAL part first, or the kept trace is the unpinned one (`lvl=8` is the tell).
2. **Indices are not content**: comparing anim chains by `hb8`/`hbA` read half of every
   character as differing — vs2 renumbered the tables; resolve the boxes first.
3. **A cumulative field compared from the window start turns a periodic pin into a DIFF
   at the pin frame**; compare per-frame changes and exclude the rig's own pin frames.
4. **The projectile chains index the PROJECTILE hitbox tables**, not the fighter's.
5. **`ALL=1` must take its part list from the rigs on disk**, never from the expectation
   file it is about to write (a freeze of zero parts reads as success).
6. **Two line ranges of one artifact collided in `rulecheck.py` staging** (#156, fixed):
   the reader saw only the last range and answered Q5 from it.

**IF A DOC IS TOUCHED:** the doc gates (`test_checkdocs`, `test_docshape`,
`test_doc_anchor_census`, `test_checkskills`, `test_gotchas_index_current`,
`test_gate_index_current`, `test_state_open_lists`, `test_tickets`) plus
`tools/check_state_lists.py` and `tools/tickets.py check`, exit statuses captured
directly, `${=cmd}` in zsh. **A running script is never edited** ([MSC-54]). **The
static tier is never run beside another gate run, or heavy work, in this tree.**
