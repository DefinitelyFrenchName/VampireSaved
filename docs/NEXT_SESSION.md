# NEXT SESSION — orientation (rewritten at the 14z-172 CLOSE, 2026-09-20)

> Rewritten at every session close ([VSP-17]). ROLLOVER: the previous opener
> moves VERBATIM to the top of `NEXT_SESSION_HISTORY.md` — this file holds ONLY
> the live orientation. Session state, not knowledge: facts belong in the docs,
> status in STATE.md.

## M19 IS FROZEN (14z-170) AND STILL NOT RELEASED — donovan-m23 / huitzil-m30 / pyron-m24 / merged-m19, `build/m3b_merged27`

No shipped ROM byte moved at 14z-171 or 14z-172; the tree is still at merged-m19.
What the freeze carries is in HANDOFF "Current WIDE builds" and patch_notes 14z-170.

## START HERE

1. **THE RELEASE STILL WAITS, by ruling (2026-09-20):** *"let's not release now, especially since we
   have tickets relative to the deliverables on various OS"*. The blockers are **#144** (macOS blocks
   the prebuilt binaries), **#145** (Windows: they fail to load) and **#146** (the player READMEs),
   each reported and none yet reproduced. When they are done the release run is
   `--scope all --lane all --strict --controls` (~5.5 h, HANDOFF "WHAT THE RELEASE RUN COSTS"), then
   `tools/upload_release_assets.sh` on `freeze/merged-m19`.
2. **#169: `pyron_3`'s Galactic Throw connects on only ONE strength**, and which one depends on the
   schedule — at HEAD `[j.6HP]` is frozen as `a2:0x14`, a plain j.HP, so the rig has recorded a whiff
   under the move's name since 14z-120. It is the one event family in the corpus whose outcome does
   NOT follow the engine's double-pass phase — the rule that now governs every rig schedule change
   (`engine_internals.md` "THE CADENCE IS STRICTLY PERIODIC IN THE FRAME INDEX", gate
   `audit_tick_phase`) — so the second factor behind it is unidentified and is the interesting part.
   Everything measured is on the issue.
3. **#161 — Phobos's remaining +1** (`tests/audit_phobos_dmg_residual.sh` reproduces it): Demitri's
   5HP takes 12 on ours, 11 native, with Phobos's defense rows already vs2's — trace the damage
   staging vars stage by stage on both legs for that one hit (`engine_internals.md` "The DAMAGE
   pipeline"). Its expectation re-froze at 14z-172 as a pure +195 shift; the residual is untouched.
4. **The #136 tickets still open**: **#157** (the throw hit-registration pair — the meter family),
   **#159** (facing rule 5), **#163** (the column/trap rule: its airborne case); the maintainer's to
   schedule. #136's own DIFF table is now 94 rows.

## ALSO OPEN (carried)

- **#162 is ANSWERED and PARKED by agreement** — the orange flash is not a sequence-id defect but
  Donovan's sprite-palette block showing through, and his palette-routine row `0x13` is the no-op
  default in all three dispatcher tables where vs2 runs a real routine. The one open measurement is
  which path sets `a0` to the sprite block.
- A column hit on an AIRBORNE victim (the air stager's case) is not measured — #163's one open item.

## TRAPS PAID THIS SITTING (14z-172)

1. **A script that mutates a tool must restore it, or every later measurement is of the control.**
   Four control runs left `tools/name_moves.py` at a different quantum and the parity gate was then
   run against it; the tables turned out byte-identical, but the figures had not been measured on the
   schedule that lands. `build/rig172/shift_control.sh` now restores on EXIT.
2. **Two clean data points are not a law.** "The period is exactly 39" followed rigorously from four
   measurements and was falsified by the fifth (273 = 7x39 is not clean). Run the one that would
   break it, especially when the evidence looks settled.
3. **A chain id is looked up in a table that covers THE CHARACTER.** 14z-171 glossed `a2:0x03`
   and `a2:0x02` as "a walk"; they are `a2` NORMALS (walks are table `a`), and `a2:0x02` is Pyron's
   own `5MP` by his part-1 row. The correction then over-reached in turn, reading them as the FAR
   and NEAR MP slots from `vanilla_normal_slots.tsv` — which covers the 15 VANILLA characters only
   and maps `far MP` to `a2:0x03` for just 10 of them. Pyron is not in it. The rule-checker caught
   that (run `2026-09-20-87` Q1); the capture is what settles the range.
4. **A control defined in the instrument's own coordinates validates the search, not the
   coordinates.** 14z-156's modulus search over `$FF8080` carried a plant and fired it, and was still
   blind, because the byte wraps at 256 and the plant was defined in the byte's own terms.
5. **The field a rig POKES cannot be evidence that two legs converged.** The first version of the
   rewritten `audit_rig_opening` sampled the pin frame itself inside its convergence assertion — the
   rule-checker's Q3 found it.

**IF A DOC IS TOUCHED:** the doc gates (`test_checkdocs`, `test_docshape`,
`test_doc_anchor_census`, `test_checkskills`, `test_gotchas_index_current`,
`test_gate_index_current`, `test_state_open_lists`, `test_tickets`) plus
`tools/check_state_lists.py` and `tools/tickets.py check`, exit statuses captured
directly, `${=cmd}` in zsh. **A running script is never edited** ([MSC-54]).
