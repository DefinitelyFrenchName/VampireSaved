THE PACKET

Decision kind: expectation
Subject: 14z-181 #169: pyron_3's Galactic Throw pair re-rigged (P2's two-frame jump lead) — both strengths enter a2:0x23 at every double-pass phase, naming/parity/attribution re-frozen, the ticket's close proposed — the second packet, after run 168 (the mechanism claim downgraded to the measured determinant; the fix tested at six shifts)
Claim (the working agent's sentence): GitHub #169 is fixed and its three acceptance items met: (1) pyron_3's two Galactic Throw events both enter a2:0x23 on native vs2 — tools/name_moves.py's shared air_throw recipe now gives P2 a TWO-FRAME JUMP LEAD ((-2, 0, "U", "p2") before P1's (0, 2, "U")), the rigs pyron_3 and huitzil_3 regenerated and committed (only the two p2=U lines per rig moved two frames earlier), tests/expected/move_naming_pyron.txt re-frozen with ONE line changed ([j.6HP] a2:0x14 -> a2:0x23) and verified, Huitzil's naming unchanged (its Sky Capture pair already read a2:0x4e on both strengths and still does; verified PASS with the regenerated rig); (2) the DETERMINANT is measured, the mechanism behind it is not: swept on native with the pair pinned still at 858/898, P2's jump lead over P1's decides the outcome — at -3, -2, -1 both strengths enter a2:0x23 (the throw chain), at 0 one does (the bistable state the ticket froze), at +1..+3 neither (the plain jumping punches a2:0x13/0x14) — and the FIX HOLDS AT EVERY DOUBLE-PASS PHASE: with the -2 lead both strengths enter a2:0x23 at six schedule shifts of pyron_3 (+0, +1, +2, +13, +26, +39: every phase mod 3 and mod 13), with the pair at 858/898 for the first event and at the wall (960/1000) for the second; the five sweeps are one artifact (walk length 30-150 with P2 jumping with P1 — MP only from 120 up, HP never, and the 60-frame walk of move_naming_169_run1.log, both whiff; the pair pinned at x 700-950 — MP always, HP never; the press offset +4..+28 — HP never; P2's lead -3..+3; the six shifts) so the three geometry theories (the right wall every "near" event ends at, the screen-edge clamp of a pin after a throw, the walk length) are eliminated and recorded as rig facts in the generator's comments and the gotcha; WHY the lead matters is NOT isolated and is stated so everywhere: P2's y at the grab frame reads 134 with a lead and 113/111 without, an observation that moves with the lead (a 113-over-111 row still whiffs), no run holds the lead fixed and varies height, and no run recorded press-registration ticks, so a tick race on the double-pass phase is a hypothesis consistent with #168's shift sweep, not a measurement; (3) tests/expected/move_parity_events.tsv re-frozen ALL=1 (526 events of 32 parts) and verified with its four controls firing — exactly the two rows moved: [j.6MP] IDENT -> DIFF +28 meter and [j.6HP] DIFF +20 meter,stock -> DIFF +28 meter — and tests/expected/move_parity_attribution.tsv re-frozen (164 rows) and verified: both rows root as METER-SWAP (the class every other pyron_3 row already carries: native (P1,P2) meter (12, 8), ours (8, 12) at the throw), no OTHER, no UNATTRIBUTED; tests/audit_lag_budget.sh on pyron_3 and huitzil_3 reads no new zero-pass frame with its lag-planted control firing; the move lists carry the re-rig note; a gotcha is filed; the PROPOSED close: the ticket's index row (open at packet time) goes to done with the four answers in the closing commit and the drafted closing comment states the resolution as above. NOT tested: the cause behind the lead (above); the Galactic Throw on OUR build entering a2:0x23 is read by the parity gate only through its compared fields (node translated, seq, sub, x, y, meter, HP — the DIFF is meter alone, so the node and seq columns agree with native's at every sample, which is the throw chain on both legs), not by the naming gate (native-only by design); whether the j.4MP/j.4HP direction throws (the rigs use 6 only); the throw's damage and the ES version; the rig's P2 lead is a rig property of the shared recipe — Huitzil's pair was re-measured unchanged but its own mechanism (why it was never bistable) is not measured; the parity gate's per-frame level and RNG pins and the rig pokes are the shared equalised input accepted in writing at runs 153-166 and put to the maintainer under STATE "Decisions pending"; no capture was produced — the finding is which chain the engine entered, read from RAM, and how the throw LOOKS is not concluded; the sweeps ran on native only; the parity gate is the only ours-leg evidence.
Artifacts (read every one, in full):
  - build/agent181/name_moves_169_14z181.diff
  - build/agent181/rigs_169_14z181.diff
  - build/agent181/expectations_169_14z181.diff
  - build/agent181/moves_toml_169_14z181.diff
  - build/agent181/gotchas_169_14z181.diff
  - build/agent181/air_throw_sweeps_14z181.txt
  - build/agent181/issue169_close.md
  - build/agent181/move_naming_169_run1.log
  - build/agent181/move_naming_169_run2.log
  - build/agent181/move_naming_169_freeze.log
  - build/agent181/move_naming_169_verify.log
  - build/agent181/move_naming_169_hui.log
  - build/agent181/move_parity_169_run1.log
  - build/agent181/move_parity_169_freeze.log
  - build/agent181/move_parity_169_verify.log
  - build/agent181/attribution_169_freeze.log
  - build/agent181/attribution_169_verify.log
  - build/agent181/lag_budget_169.log
  - tests/expected/move_naming_pyron.txt
  - tests/expected/move_naming_huitzil.txt
  - tools/name_moves.py.lines-160-220 (lines 160-220 of tools/name_moves.py)
  - tools/name_moves.py.lines-735-775 (lines 735-775 of tools/name_moves.py)
  - tests/audit_move_parity.sh.lines-1-60 (lines 1-60 of tests/audit_move_parity.sh)
  - docs/project/tickets.tsv.lines-80-80 (lines 80-80 of docs/project/tickets.tsv)
  - tests/rulecheck/runs/2026-09-25-168/verdict_real.txt
  - build/agent181/resolve168.txt
