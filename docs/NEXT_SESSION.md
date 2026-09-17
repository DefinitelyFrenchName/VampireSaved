# NEXT SESSION — orientation (rewritten at the 14z-165 CLOSE, 2026-09-17)

> Rewritten at every session close ([VSP-17]). ROLLOVER: the previous opener
> moves VERBATIM to the top of `NEXT_SESSION_HISTORY.md` — this file holds ONLY
> the live orientation. Session state, not knowledge: facts belong in the docs,
> status in STATE.md.

## THE PARITY RIGS' P2 IS DEMITRI NOW (14z-165), the ruled 14z-164b P2. `tools/name_moves.py` carries `p2_id`/`p2_path` for the three naming tenants, `tools/move_parity.py p2check` asserts P2 = 0x01, never in his two differing ATTACK records `b:0x71`/`b:0x74`, and holds his third differing chain `b:0x10` (the pose push box) EQUALLY on both legs — its pushbox datum a bounded positional confound named for the family pass (the rule-checker caught the missing `b:0x10`, run 2026-09-17-29 Q4) — from each leg's own game image, and five expectations are re-frozen on him: `move_naming_{donovan,huitzil,pyron}.txt`, `projectile_census.txt`, `killshread_es.txt`, `move_parity_events.tsv` (506 events: **372 IDENT / 108 DIFF / 25 NOT-IN-DF / 1 VOID**). The victim rigs are unchanged (their P1 is Victor the attacker). The switch turned 13 former Victor-first DIFF rows IDENT and turned the huitzil_5/6 guard-cancel events DIFF (Demitri's 5HP re-times P1's block) — all frozen AS MEASURED, no family root-caused.

## THE #136 FAMILIES ARE STILL OPEN and are the next work (the ruled order: stable state, #148 DONE, #152 DONE, then everything else — the #136 families included). The 108 DIFF rows of `tests/expected/move_parity_events.tsv` are frozen as measured; NONE is attributed to a side or a mechanism yet. Root-cause them capture-first ([VSP-136], [VSP-20]): the guard-cancel family (huitzil_5/6 Reflect Wall, now DIFF on P1's x/node because gc timing is cued off P2's 5HP — and P2's b:0x10 pushbox is the named candidate for the x rows), the meter-first rows (~30, Pyron's Planet Burning +30 native / +20 ours per use the largest), Cosmo Disruption held (pyron_4, 4 hits ours vs 2), Press of Death's x, pyron_3's stock crossing.

## THE SESSIONS ACT ON GITHUB AS `mechanyaa-ai`; a commit subject never puts close/fix/resolve directly before `#N`. The static tier runs by CADENCE; the close is the session cadence with every control executed, then the push.

M18 (`merged-m18`, `build/m3b_merged26`) is still the current freeze and release.
`git status -sb` says the push state. The withdrawn M19 build dirs are on disk,
UNREGISTERED — do not play them and do not point a gate at them.

## START HERE — what is open (THE ORDER IS RULED, 2026-09-17: stable state, then #148 (DONE), then #152 (DONE), then everything else — the #136 families included)

- **#136 — ROOT-CAUSE THE FAMILIES, capture first.** The parity rigs' P2 is now
  Demitri and the 506 events are frozen on him; the families to convict are the
  guard cancel (huitzil_5/6, DIFF on P1's x/node), the meter fraction (~30 rows,
  Planet Burning the largest), Cosmo Disruption held (pyron_4, 2-vs-4 hits), and
  the residual per-move x/cnt rows. Each is a maintainer-facing finding: measure,
  capture ours-vs-native, run it through `tools/rulecheck.py` before proposing a
  fix, and remember a DIFF may be OUR engine running the move differently, not a
  data-port bug. Bishamon is the P2 FALLBACK if a case arises Demitri cannot
  answer (DECISIONS_HISTORY.md 14z-164b).
- **In-DF coverage is 5LP/5MP (Donovan) and 5LP (Phobos, Pyron)**: the batteries
  outrun the 360-frame DF. A RIG change (re-activate DF per group of events, never
  a comparator tolerance) is needed before any in-DF move is measured — the
  maintainer agreed 2026-09-17; the 25 NOT-IN-DF rows of
  `tests/expected/move_parity_events.tsv` say exactly which events.
- **#154 and #155** (the fidelity gate's FREEZE branch; its hand-typed replica leg),
  **#153** (lever B), **#150** (the freeze ritual's silent-green modes): filed and unstarted.
- Every other open ticket is on `docs/project/tickets.md`; the harness has BBH-frame-based #1.

## TRAPS PAID THIS SITTING

1. **A matched-data P2 turns a data-dependent must-fire control DEAD.** The
   `pins-ignored` control (14z-164) fired only because Victor's data differed
   between the games; Demitri's defense is the same on both, so no real row moved
   and the control read DEAD. Rebuilt as a perturbed-copy of our own trace (x
   altered on the rig's `$FF8410` pin frames). A control whose firing depends on
   the data under test is disarmed by a clean result.
2. **A matched-data P2 stops being a confound but starts feeding P1's timing.**
   The guard-cancel rigs cue P1's block off P2's 5HP; Demitri's 5HP differs from
   Victor's, so those parts re-froze DIFF by construction. A P2 switch re-freezes
   every rig whose P1 input is timed to P2's attack.
3. **`p2check` reads OURS against the build's own `verify_data.bin`**, because
   Demitri is a legacy-unmodified character there, so his graph on the merged
   build equals pristine vsavj's — the native leg uses the vs2 data view.
4. **A skip-then-continue loop over a single-line ruling deletes the NEXT line too**
   (a standing ruling was dropped and restored; assert the file after a
   programmatic STATE edit).

**IF A DOC IS TOUCHED:** the doc gates (`test_checkdocs`, `test_docshape`,
`test_doc_anchor_census`, `test_checkskills`, `test_gotchas_index_current`,
`test_gate_index_current`, `test_state_open_lists`, `test_tickets`) plus
`tools/check_state_lists.py` and `tools/tickets.py check`, exit statuses captured
directly, `${=cmd}` in zsh. **A running script is never edited** ([MSC-54]). **The
static tier is never run beside another gate run, or heavy work, in this tree.**
