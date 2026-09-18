# NEXT SESSION — orientation (rewritten at the 14z-168 CLOSE, 2026-09-18)

> Rewritten at every session close ([VSP-17]). ROLLOVER: the previous opener
> moves VERBATIM to the top of `NEXT_SESSION_HISTORY.md` — this file holds ONLY
> the live orientation. Session state, not knowledge: facts belong in the docs,
> status in STATE.md.

## #136 IS ANALYSED (14z-168): all 108 frozen DIFF rows attributed by ablation and a measured signature (`tests/audit_move_parity_attribution.sh`, OTHER fails). Dark Force corrected at its root: vs2's P+K is Dark Force POWER; the tenants' reference is their vs2 EX move. The maintainer ruled on every capture put to them: the block re-entry, Pyron's form and Donovan's sword are IDENTICAL; the column shock is a defect.

## THE MAINTAINER'S ORDER (ruled 2026-09-17/18): all the analysis first, then the fixes, then relentless regression testing — every rig a gate. The fixes are RULED (standing lines in STATE; verbatim in `DECISIONS_HISTORY.md`), under one condition: *"the total overhead cost of our combined changes is less than 1/60s at all times"* — no new zero-pass frame (`$FF8081`, `tests/audit_pass_overrun.sh`) over the corpus against the build before them.

## START HERE — the analysis the fixes still need (measure, then design)

1. **Defense rows (ruled: take vs2's rows).** Both damage reads index by the victim's
   `+0x382` (`docs/game/engine_internals.md`, the defense port note), so a data-only
   edit of rows and thresholds 0x10/0x13 is possible. Measure first that EVERY hit on
   a tenant victim, over the corpus, reads the tenant's own row and byte (a read watch
   on both tables; `+0x382` is the voice-flavor class in a match).
2. **The class-0x52 rule (ruled: the column shock and the Plasma Trap).** vsavj routes
   class 0x38 to the same shock handler as 0x06, with the same property byte (the
   column paragraph). Before it can be the discriminator: a census of class 0x38 in
   EVERY legacy attack and projectile record (make it a gate; it also carries the
   reaction-table facts, today a static read only), then the thunks' cost.
3. **The other placed reads of vs2's Power flag `+0x1C3`:** 23 besides the three meter
   adders, 4 executed by the corpus (`tests/audit_df_field_readers_live.sh`) — each to be
   measured before #157's Dark Force tail is fixed.
4. **The EX route (ruled: disable it)** and **no gauge in Dark Force** (#157's tail).
   The vs2 EX inputs in use (421+KK, 263+PP, 2623+PP) are my measured candidates; the
   maintainer offered to confirm them.

## THEN FILE THE TICKETS (drafts in `build/p136_14z168/gh/`, written before the 2026-09-18 rulings — update them): the column shock + Plasma Trap (the 0x52 rule), the EX route, the defense rows; comments on #136 and #157. As `mechanyaa-ai`, rule-checker (`recommendation`) first, `tools/tickets.py refresh`.

## ALSO OPEN FROM 14z-168

- The static tier never checks that a `tests/ci_emulator.tsv` gate is EXECUTABLE:
  `tests/audit_df_field_readers_live.sh` was committed without `+x` (7603c86a) and only the
  emulator runner would have said so, at release (MISSING). Found at the 14z-168 close,
  when its static twin `test_defense_rows_census` read MISSING; both fixed. Add the check
  to a static gate.
- A static gate for the unsafe MAME-leg shape (a backgrounded leg writing its status
  under `set -e`; nine gates fixed by hand, `docs/project/gotchas.md`).
- bbh `selftest/test_fidelity_vampire.sh:356`: the F9 provenance pair pipes this tree's
  gate through `sed`, so our exit status reads 0 — a false difference on a red tree.
  Fix it in bbh (writable, pushes at a green close) or file it there.
- `build/manifest/huitzil.toml`'s "DEVIATION (maintainer-accepted …)" comment: update
  it in the 0x52 fix's commit (a manifest edit moves build fingerprints).
- #136's Phobos guard-cancel rig: the first X pin lands before the round starts — a
  RIG fix (the first pin after `$FF812D`), then a re-freeze through the rule-checker.
- #157, #159: the maintainer's to schedule; #158, #154/#155, #153, #150 filed and
  unstarted; every other open ticket is on `docs/project/tickets.md`.

## TRAPS PAID THIS SITTING

1. **vs2's P+K is not the tenants' Dark Force** — it is Dark Force POWER; compare their
   vs2 EX move (the maintainer caught it on the capture).
2. **A light mash inside the block window measures the ADVANCING GUARD** (vsavj fires
   on light presses, vs2 does not) — press after the window to ask "when can I act".
3. **A backgrounded MAME leg under `set -e` loses its status on a teardown segfault**
   (`exited none` on a complete log), and my first scripted fix put `set +e` on the
   wrong subshell in three gates — green runs cannot show a robustness fix; inspect
   every patched site.
4. **A "different palette" by eye was the HUD and the background** — read palette RAM,
   and give every comparison a known difference to see (the HUD rows) or it is blind.
5. **A census built from a grep of MENTIONS is not a census of users** — grep for the
   invocation (the read_tap "ten users" were eight, one missed).
6. **A ruling is cited with the maintainer's words or not at all** — the words of the
   2026-09-17 agreement were recovered from that sitting's transcript.
7. **A heredoc terminator inside the text of another heredoc ends the outer one** —
   patch gate bodies from a file, never an inline `<<'PY'` inside `<<'PY'`.

**IF A DOC IS TOUCHED:** the doc gates (`test_checkdocs`, `test_docshape`,
`test_doc_anchor_census`, `test_checkskills`, `test_gotchas_index_current`,
`test_gate_index_current`, `test_state_open_lists`, `test_tickets`) plus
`tools/check_state_lists.py` and `tools/tickets.py check`, exit statuses captured
directly, `${=cmd}` in zsh. **A running script is never edited** ([MSC-54]). **The
static tier is never run beside another gate run, or heavy work, in this tree.**
