THE PACKET

Decision kind: recommendation
Subject: #183 answered for the maintainer's ruling: keep the parity gates' 0000 RNG pin as their basis, record in their headers that they compare the zero random path only, and close #183 (after run 2026-09-30-480)
Claim (the working agent's sentence): Scratch copies of tests/audit_move_parity.sh (ALL=1, 32 parts), tests/audit_chains174.sh and tests/audit_chains184.sh, differing from the committed gates only in an absolute REPO path and, for forms B and C, the RNG pin line (scratch_vs_gates.diff), were run on merged-m21 (m3b_merged29) under three RNG forms: A, the gates' own 0000 pin (the control); B, 0100 poked on every frame from 2363 (a non-zero word; by the routine in engine_internals.md, a draw from 0100 returns 3); C, 5a5a poked 2363..2599 and then free (as tests/audit_rng_draws.sh seeds). Form A passes all three gates with every in-gate control fired and its move_parity table equals the frozen tests/expected/move_parity_events.tsv (frozen on m3b_merged26) on all 526 rows, so the build change between the freeze and these runs moves no row. Against form A (cmp183b.txt, from the got tables named as artifacts): form B leaves 501 move_parity rows unchanged, turns NO IDENT row DIFF, turns 10 DIFF rows IDENT (donovan_10:1-9 and donovan_11:12) and changes the detail of 15 DIFF rows (all donovan_2); form C changes 104 rows, 32 IDENT to DIFF and 33 DIFF to IDENT. audit_chains174 passes under B with its 14 parity rows equal to form A's; under C, two of them (huitzil_c174:0 and :7) go IDENT to DIFF and its x-moved control reads DEAD. audit_chains184 passes under A (22 parity rows) and fails under both B and C at its native outcome check (Sword Grapple [HP] with P2 jumping at +8 no longer starts a2:0x41 on native), so its rows under B and C were not compared. A MAME segfault at the end of one audit_chains184 tap run appears under A and B alike; the gate's header counts that teardown crash as no failure when the END line is reached, and each tap-run agreement check passed. engine_internals.md records that ours draws the RNG in vsavj's motion trackers where native does not (265, 88 and 63 draws on the three tenants' chains174 rigs) and the maintainer ruled those trackers host behaviour (#176), so a free RNG is not an equalised input for an ours-vs-native gate. On that I recommend: keep the 0000 pin, add to each parity gate's NOT COVERED that it compares the zero random path only, with form B's measurement as the evidence that a non-zero per-frame pin raises no new difference on audit_move_parity's and audit_chains174's current rows, and close #183; the alternatives are a second pinned leg at a non-zero word (twice the runtime, and audit_chains184's grab-whiff rig re-timed), or seed-then-free. NOT tested: which update order the object loop took under B, or which branches a 3 and the frame's later draws select; any other non-zero word; the other gates that pin 0000 (about 20 beyond these three); audit_chains184's rows under B or C; what caused C's IDENT to DIFF rows (not attributed to the trackers or anything else); FBNeo; a second host; run-to-run repeats of any form.
Artifacts (read every one, in full):
  - build/agent186/t183/scratch_vs_gates.diff
  - build/agent186/t183/cmp183b.py
  - build/agent186/t183/cmp183b.txt
  - build/agent186/t183/mp_A.got.tsv
  - build/agent186/t183/mp_B.got.tsv
  - build/agent186/t183/mp_C.got.tsv
  - build/agent186/t183/c174_A/got.tsv
  - build/agent186/t183/c174_B/got.tsv
  - build/agent186/t183/c174_C/got.tsv
  - build/agent186/t183/c184_A/got.tsv
  - build/agent186/t183/mp_A.log
  - build/agent186/t183/mp_B.log
  - build/agent186/t183/mp_C.log
  - build/agent186/t183/c174_A.log
  - build/agent186/t183/c174_B.log
  - build/agent186/t183/c174_C.log
  - build/agent186/t183/c184_A.log
  - build/agent186/t183/c184_B.log
  - build/agent186/t183/c184_C.log
  - tests/expected/move_parity_events.tsv
  - tests/audit_chains184.sh.lines-1-30 (lines 1-30 of tests/audit_chains184.sh)
  - docs/game/engine_internals.md.lines-620-680 (lines 620-680 of docs/game/engine_internals.md)
  - DECISIONS_HISTORY.md.lines-225-241 (lines 225-241 of DECISIONS_HISTORY.md)
