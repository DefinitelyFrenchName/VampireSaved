# NEXT SESSION — orientation (rewritten at the 14z-159 CLOSE, 2026-09-16)

> Rewritten at every session close ([VSP-17]). ROLLOVER: the previous opener
> moves VERBATIM to the top of `NEXT_SESSION_HISTORY.md` — this file holds ONLY
> the live orientation. Session state, not knowledge: facts belong in the docs,
> status in STATE.md.

## THE M19 FREEZE WAS BUILT AND WITHDRAWN IN FULL. #147's FIX WAS A REGRESSION AND ITS MEASUREMENT A FORCED-PICK RIG ARTIFACT. NO SHIPPED ROM BYTE MOVED; THE TREE IS AT merged-m18.

M18 (`merged-m18`, `build/m3b_merged26`) is still the current freeze and release.
`git status -sb` says the push state. The build dirs from the withdrawn freeze
(`don_m23`, `hui58`, `pyron42`, `m3b_merged28`, `m5_stock18`, `don_stage4_m19`)
are on disk, UNREGISTERED — do not play them and do not point a gate at them.

## START HERE — what is open

- **#151 — RE-EXAMINE #136, and do this before trusting any of it.** `audit_move_parity`
  has controls proving it sees the speed level and the placement translation, and **none
  proving its native leg is faithful.** Donovan's native leg is a REAL cursor pick;
  Phobos's and Pyron's are FORCED-PICK, and the select confirm latches per-fighter state
  BEFORE the poke lands. So 17 of its 27 frozen verdicts are UNVALIDATED (marked in the
  gate header and in `tests/expected/move_parity.tsv`). Step 1 is the missing control:
  poked native vs REAL-cursor native, same character, diffed over the WHOLE fighter block
  — a field list is how this was missed. Then re-judge the verdicts, then sweep every
  other gate with a forced-pick native leg.
- **#147 — OPEN, premise void.** All that survives is "Phobos's float differs from native
  in some way", and that is unmeasured until a faithful native leg exists. `flavor_default`
  is back at 0x00. Do not re-flip it on a poked measurement.
- **#149 — Phobos's specials skip a 2-frame `seq 4 sub 4` state. READ #151 FIRST: this
  ticket's CENTRAL CLAIM is inside #151's exposure.** "Native plays the state and ours
  skips it" was measured on a **POKED** native leg for Phobos — the same unvalidated rig
  that produced #147's wrong answer. So *whether native plays that state at all* is not
  established; it may be, like the flavor latch, an artifact of a legacy character's
  confirm wearing Phobos's id. The write tap that named `PRG:0x026344` is sound about WHAT
  executed on each leg; what is unproven is that the native leg was a faithful native.
  The candidate cause (the `vs2 0x026252` / `vsavj 0x02706e` reconciliation twin, marked
  `verified` but structurally divergent at its 7th instruction) is separately NOT proven
  ([VSP-116]). Maintainer ruled: all the measurements first, no scoping — and the first
  measurement is #151's faithfulness control, not anything in #149.
- **#152 — the independent adversarial RULE-CHECKER** (maintainer's proposal, 14z-159).
  Redundancy for rule APPLICATION rather than for measurement, because 14z-159's rules were
  all loaded and cited and still did not fire. Every condition in the ticket is load-bearing:
  it reads ARTIFACTS not a summary, a 3-5 question checklist not the rulebook, structured
  `VIOLATED/OK/N-A` + `file:line` output not prose, it must-fire like any other control, and
  a VIOLATED verdict STOPS the action and is reported verbatim. Trigger: before a measurement
  becomes a basis for action, never at session end.
- **#150** (the freeze ritual's three silent-green failure modes) and **#148** (the static
  tier's cost) are filed and unstarted.
- The MiSTer tail of any future freeze: the fork's `doc/mame.xml` CRC entry + pin bump, and
  `tests/expect/mister_prg_window.txt`'s [VSP-178] re-freeze. Not needed while no freeze is open.
- Every other open ticket is on `docs/project/tickets.md`; the harness has BBH-frame-based #1.

## TRAPS PAID THIS SITTING

1. **A forced-pick native leg measures the RIG for anything the select confirm latches** —
   and two poked legs agree with each other perfectly, which looks like a result. Cost: a
   wrong fix taken all the way to a freeze. `docs/project/gotchas.md`.
2. **Captures before conclusions.** No frame of the float, ours or native, was shown to the
   maintainer before a rebuild, four re-frozen expectation sets and a mark bump. The field
   report is what caught it.
3. **Never wait on `pgrep`** — a waiter matched the creating shell's own command line and sat
   4 h 12 min running nothing, reported twice as "progressing" from an empty log. Prove a
   background job produced real output before describing its state.
4. **A retraction grep on WORDING misses a claim encoded as a VALUE** — `test_manifest_merge`
   asserted the retracted polarity as a literal pair.
5. **A re-point sweep needs all matches per line** (a `break` cost two passes) and **a comment
   never follows a line-continuation backslash** ([VSP-177]).

**IF A DOC IS TOUCHED:** the eight `--check`s plus `tools/check_state_lists.py` and
`tools/tickets.py check`, exit statuses captured directly, `${=cmd}` in zsh. **A
running script is never edited** ([MSC-54]). **The static tier is never run beside
another gate run, or heavy work, in this tree.**
