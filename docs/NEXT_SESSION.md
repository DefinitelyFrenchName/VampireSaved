# NEXT SESSION — orientation (rewritten at the 14z-147 CLOSE, 2026-09-10)

> Rewritten at every session close ([VSP-17]). ROLLOVER: the previous opener
> moves VERBATIM to the top of `NEXT_SESSION_HISTORY.md` — this file holds ONLY
> the live orientation. Session state, not knowledge: facts belong in the docs,
> status in STATE.md.

## STEP TWO OF THE MUST-FIRE MACHINE, PASS 1 LANDED. NO BUILD BYTE MOVED.

M18 (`merged-m18`, `build/m3b_merged26`) is still the current freeze and
release. `git status -sb` says the push state (the close ends with a push
when all is green).

Landed this sitting (STATE 14z-147): the contract's READER
(`tests/lib/controls.sh`, BBX's four regexes copied; spec
`docs/project/must_fire_contract.md`, rule [VSP-181]); the classifier turning
a red controls block into plain FAIL; `run_all_static.sh --exec-controls`
(every declared control EXECUTED as `CONTROL=<name>` after a PASS — LIES /
REFUSED / DIED are failures of the run) and `run_all_emulator.sh --controls`;
the census re-frozen on the grammar with three classes (`declares` 30,
`header-only` 0, `retrofit-debt` 53); `test_controls_contract.sh`; and the
whole PORTABLE tier retrofitted — every one of its declaring gates verified
plain-PASS with every control FIRED and every mode HONOURED.

## START HERE — what is open

- **Must-fire passes 2 and 3**: the `retrofit-debt` class of
  `tests/expected/must_fire_census.tsv` — 19 static-tier gates, then 34
  emulator-tier gates (the ten former header-only gates among them: a real
  control or `# MUST-FIRE: none — <why>` each). The pattern is in the spec:
  ONE `perturb <name> <copy>` function the control section and the mode both
  call; a copy of the real input under the mode; verify with
  `build/mustfire_14z147/verify_gate.sh`-style loops (plain PASS + every
  mode HONOURED). One strict run of the tier per pass is the identity bar;
  the emulator tier's bar is the next release sweep.
- **Lift the controls reader into bbh** (`~/Developer/blackbox-harness`): bbh's
  `run-static` prints no controls block, so the lineage's runner prints it only
  when a tier declares or executes something (F1 exact); F2 — opt-in, the real
  portable tier — carries that known delta until bbh gains the reader (its
  `rebaselines.md` is where a re-baseline is declared, loudly).
- **The open decision** (STATE "Decisions pending"): the cadence of
  `run_all_emulator.sh --controls` at release — recommendation (a), the
  release checklist, measured first.
- **Zabel j.LK proximity guard** — its own session (recording first).
- **The community cross-check**: specials/supers/throws still have no naming
  rigs on vsavj; every cell on the page is arbitrated.
- Smaller: `audit_mask_window_ff42a2` deprecated-vs-case-specific;
  `release/merged-m15` never packaged; #112 option (B); the living-docs
  generalisation (ruled, not scheduled); the wider-host re-measure of the
  pull queue's gain; the `hit` rigs' LP events whiff at contact range.

## TRAPS PAID FOR THIS SITTING — read before the next retrofit

1. **A `#!/bin/sh` gate that spells out a bashism stub carries the
   bashism** — assemble the token from pieces (project gotcha).
2. **`[ ] && f` as the last statement of a loop under `set -e`** ends the
   runner when the test is false — write an `if` (project gotcha).
3. **An edit anchored on a comment-stripped READ misses every time** — the
   anchor lacked the comment lines between two code lines; anchor on single
   lines or re-read verbatim (project gotcha).
4. **A background baseline run, then an edit of the runner it was running**
   voided the baseline — [VSP-110] again; the close's strict run at the same
   commit stood in for "before".
5. **`cp <doc.md> "<dir>"` reads as a section citation** to checkdocshape —
   put the doc path in a variable.
6. **`sort -o` on a TSV with a comment header** reorders the header lines —
   append, never sort, the family TSV.

**IF A DOC IS TOUCHED:** the eight `--check`s, exit statuses captured directly,
`${=cmd}` in zsh. **A running script is never edited** ([MSC-54]). **The static
tier is never run beside another gate run in this tree.**
