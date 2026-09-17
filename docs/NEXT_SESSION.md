# NEXT SESSION — orientation (rewritten at the 14z-163 CLOSE, 2026-09-17)

> Rewritten at every session close ([VSP-17]). ROLLOVER: the previous opener
> moves VERBATIM to the top of `NEXT_SESSION_HISTORY.md` — this file holds ONLY
> the live orientation. Session state, not knowledge: facts belong in the docs,
> status in STATE.md.

## THE RULE-CHECKER EXISTS SINCE 14z-163 (#152) AND RUNS BEFORE AN ACTION, NOT AFTER: a `build` on a measurement, a `freeze`, an `expectation` freeze or a `recommendation` to the maintainer goes through `tools/rulecheck.py prepare` (the decision kind, ONE claim sentence saying what is claimed and what was NOT tested, the artifacts by path), two FRESH general-purpose agents on the two prompt files verbatim (one carries a blind plant), `record` with both outputs. A `VIOLATED` stops the action until `resolve` answers each violated question by label; the verdict is reported to the maintainer VERBATIM. A freeze is refused mechanically without an OK `freeze` run. Spec `docs/project/rule_checker.md` ([VSP-183], [VSP-184]); the ledger `tests/rulecheck/ledger.tsv`. The first real run was on the session's own report and it FAILED on three true findings — expect it to catch your sentences, and write the claim with every untested premise named and every file that settles a premise included.

## THE SESSIONS ACT ON GITHUB AS `mechanyaa-ai` — an event by `DefinitelyFrenchName` is the maintainer's; never attribute a GitHub state change to the maintainer without their words. A commit message must never put close/fix/resolve directly before `#N`.

## THE STATIC TIER RUNS BY CADENCE (#148): `tests/run_all_static.sh` is the SESSION run (measured this sitting on a clean tree, nothing triggered: 335 s wall, 140 gates); the close is the session cadence with every control executed, then the push.

M18 (`merged-m18`, `build/m3b_merged26`) is still the current freeze and release.
`git status -sb` says the push state. The withdrawn M19 build dirs are on disk,
UNREGISTERED — do not play them and do not point a gate at them.

## START HERE — what is open (THE ORDER IS RULED, 2026-09-17: stable state, then #148 (DONE), then #152 (BUILT, open until a real run under the bounded questions is accepted), then everything else)

- **#136 — THE FULL RE-EXAMINATION CONTINUES.** The 13 DIVERGES rows are consolidated
  on #136 with each move's first divergent event and family: Phobos — Plasma Trap
  (2, 9), Reflect Wall guard-cancels (5, 6, 8), Ray of Doom (4); Pyron 3, 4; Donovan
  2, 3, 4, 6, 7 (3 and 4 fall on the maintainer's own rulings). Each family a
  root-cause with a capture first ([VSP-136]) and its own ticket. Any
  recommendation that comes out of it is a rule-check packet.
- **#154 and #155 — two real defects in `tests/audit_forced_pick_fidelity.sh`, found
  by rule-checker readers who had never seen it:** the FREEZE branch exits before the
  identity assertions and the controls (19 gates carry a `FREEZE=1` branch to sweep,
  with #150), and the poked leg is a hand-typed replica of the rig's leg with no
  control against drift. Small fixes; each needs the emulator gate re-run and its modes.
- **#153** (lever B, scratch-clone tier runs) and **#150** (the freeze ritual's
  silent-green modes) are filed and unstarted.
- Every other open ticket is on `docs/project/tickets.md`; the harness has BBH-frame-based #1.

## TRAPS PAID THIS SITTING

1. **A claim sentence is where the checker catches you**: three false statements of
   mine in one sitting, each cited to the line that contradicted it. Read the artifact
   before writing the sentence about it.
2. **An incomplete packet reads VIOLATED, correctly**: include every file that settles
   a premise the claim names.
3. **A doc that joins `checkskills.py`'s anchor list joins the harness's consumer config
   too** (`bbh.vampire.toml`), or `test_bbh_fidelity` F11 goes red (gotcha).
4. **A rollover script asserts on the HEADING line and writes both files or neither.**
5. **The tally comes from the ledger, not from memory**: a plant count written from
   recollection was wrong and corrected from `ledger.tsv`.

**IF A DOC IS TOUCHED:** the doc gates (`test_checkdocs`, `test_docshape`,
`test_doc_anchor_census`, `test_checkskills`, `test_gotchas_index_current`,
`test_gate_index_current`, `test_state_open_lists`, `test_tickets`) plus
`tools/check_state_lists.py` and `tools/tickets.py check`, exit statuses captured
directly, `${=cmd}` in zsh. **A running script is never edited** ([MSC-54]). **The
static tier is never run beside another gate run, or heavy work, in this tree.**
