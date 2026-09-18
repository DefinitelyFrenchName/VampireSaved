# NEXT SESSION — orientation (rewritten at the 14z-168 CLOSE, 2026-09-18)

> Rewritten at every session close ([VSP-17]). ROLLOVER: the previous opener
> moves VERBATIM to the top of `NEXT_SESSION_HISTORY.md` — this file holds ONLY
> the live orientation. Session state, not knowledge: facts belong in the docs,
> status in STATE.md.

## #136 IS ANALYSED (14z-168): all 108 frozen DIFF rows attributed by ablation and a measured signature (`tests/audit_move_parity_attribution.sh`, OTHER fails). Dark Force corrected at its root: vs2's P+K is Dark Force POWER; the tenants' reference is their vs2 EX move. The maintainer ruled on every capture put to them: the block re-entry, Pyron's form and Donovan's sword are IDENTICAL; the column shock is a defect.

## THE MAINTAINER'S ORDER (ruled 2026-09-17/18): all the analysis first, then the fixes, then relentless regression testing — every rig a gate. The fixes are RULED (standing lines in STATE; verbatim in `DECISIONS_HISTORY.md`), under one condition: *"the total overhead cost of our combined changes is less than 1/60s at all times"* — no new zero-pass frame (`$FF8081`, `tests/audit_pass_overrun.sh`) over the corpus against the build before them.

## START HERE — the analysis is done (14z-169); the fixes' DESIGNS go to the maintainer before any byte moves

Measured this sitting (STATE 14z-169): (2) a record remapped to 0x38 cannot be the 0x52
discriminator — the stager rewrites it to 6, Victor carries 0x38, the guard lists it — but
`+0x54` = 0x38 is produced by nothing in vanilla and read by every consumer as 6 (vs2's 0x52
role); (1) every defense read indexes the victim's own id, so the defense-row fix is data-only;
(3) of the 26 `+0x1C3` readers only the three meter adders play differently.

1. **Put the four fix designs to the maintainer** (plan before building): the 0x52 rule through
   a class dead in legacy whose three stager rows point at a stub writing 0x38 and vsavj's 7/8
   handlers, with `reaction[0x38]` (reached by nothing in vanilla) repointed at a copy of vs2's
   shock handler without the attacker write — zero legacy cycles; the alternative is native 0x52
   records through the existing `reaction_hook` plus a reaction-dispatch hook (cycles on every
   hit). Defense rows: vs2's rows into rows/thresholds 0x10/0x13, data only. The gauge: the
   three adder copies' `tst.b $1c3` -> `tst.b $111`. The EX route: still to design — measure
   what the vs2 EX input does on our build when the route is refused.
2. **Before the 0x52 design is built:** choose the class by census (no legacy record, no guard
   list, no tenant record, its stager rows dead in the corpus) and add it to
   `tests/test_reaction_classes.sh`.

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
