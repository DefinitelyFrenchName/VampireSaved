THE PACKET

Decision kind: expectation
Subject: #118 B6 (14z-214), after run 2026-10-30-1444: freeze audit_sas_penguin_count's expectations and record +0x36C as consistent with mizuumi's "Sasquatch Penguin Count" (penguins still to throw) and +0x14B's Sasquatch use, after the maintainer's reading of the captures
Claim (the working agent's sentence): CLAIM: freeze tests/audit_sas_penguin_count.sh's expectations and record docs/game/atlas/ram.md's +0x36C row as consistent with mizuumi's "Sasquatch Penguin Count" (the count of penguins still to throw) and +0x14B's Sasquatch use as measured (records.diff; the candidates table re-derived, +0x36C NOT OBSERVED -> CONSISTENT, its batch B6 cleared). It rests on:
1. THE GATE (gate.sh.txt, blob in blobs.txt) on pristine vsavj under the pinned reference MAME, thirteen legs: S1 the write tap of +0x36C (8 at 0x047F14 on f3266, then one decrement at 0x04800E one frame before each of nine punches, 7..0,0xFF, no other in-match write); S2 the field trace agreeing; S3 the Dark Force byte ending 32 f after the ninth decrement on the punch leg and at f3828 untouched; S4 the hold leg's +0x36C held at 8 and its eight penguins removed in one frame at the mode's end; S5 the LP+LK and no-stock legs never writing +0x36C; S6 P2's never written; S7 +0x14B raised 1..8 by 0x05475A in the activation frame and lowered 7..0 by 0x054770, each after its punch and before the end; S8 one punch of each strength, the projectile slot holding type 0x24 sub 7 at f3300 travelling 175/256/351 px and removed 56/68/79 f after f3341, frozen; S9 at f3300 exactly eight type-0x24 penguins, sub-ids 7..0, X rising as the sub-id falls (sub 7 the farthest behind); S10 the eight leaving the pool in sub-id order 7..0, sub 8-k after punch k and before the end; R1 a poked 0x5A read back. plain.log PASS; mode_*.log: each of the seven controls run as a mode FAILs the gate for its own reason.
2. THE CAPTURES AND THE MAINTAINER'S READING (decisions_added.txt, quoted there verbatim): the first sheet was refused ("we don't see each throw ..."); on the close-range clips and pages the maintainer read the chain, then the strength link, and answered "yes" to the reading put to them. capture_activation.jpg, capture_one_punch.jpg and capture_strength.jpg are reduced copies of three of the pages shown (build/agent214/t118/b6/sheets3-5, local, with the clips).
NOT TESTED: one stage, one opponent (Victor, idle) and one spacing per rig; the pair and the stocks are set by poke (forced pick; the latched set +0x3BD/+0x3C2/+0x3E0 is not +0x36C), P1 walked up by a scripted walk; the CPU's coin flip between the sub-states is not exercised; what ends the mode at 0xFF is not traced (+0x176 read 0 on every sampled frame); whether a penguin damages Victor is not judged; S10 ties each release to its punch by the order and timing of the removals, not by the moment each penguin starts to walk (after a release the row closes up toward Sasquatch, so movement alone does not single the released one out); the release mechanism itself (0x059E56 comparing the sub-id with +0x36C) is S0's static read; the travel figures are for the first release only (sub 7) and from f3300's position; the capture rigs ran Homebrew's mame, the gate the pinned reference binary (the figures agree: 175/256/351); no FBNeo leg; vsav2 has no Sasquatch, so no cross-game comparison exists.
Artifacts (read every one, in full):
  - build/agent214/t118/b6/closure/gate.sh.txt
  - build/agent214/t118/b6/closure/blobs.txt
  - build/agent214/t118/b6/closure/plain.log
  - build/agent214/t118/b6/closure/mode_hold-as-toss.log
  - build/agent214/t118/b6/closure/mode_taps-shifted.log
  - build/agent214/t118/b6/closure/mode_p2-side.log
  - build/agent214/t118/b6/closure/mode_readback-unpoked.log
  - build/agent214/t118/b6/closure/mode_strength-swapped.log
  - build/agent214/t118/b6/closure/mode_layout-reversed.log
  - build/agent214/t118/b6/closure/mode_release-off-by-one.log
  - build/agent214/t118/b6/closure/records.diff
  - build/agent214/t118/b6/closure/decisions_added.txt
  - build/agent214/t118/b6/closure/capture_activation.jpg
  - build/agent214/t118/b6/closure/capture_one_punch.jpg
  - build/agent214/t118/b6/closure/capture_strength.jpg
