THE PACKET

Decision kind: recommendation
Subject: #191 Donovan 2HK damage
Claim (the working agent's sentence): Recommended: close #191 not-ours (the class #161 closed), because (a) re-measured from two complete traces of the 14z-186 rig (dmg191.txt), Donovan (P1) loses 9 red / 16 white HP to Demitri's 2HK on merged-m21 (aacc7e71) against 8 / 15 on native vsav2, the hit taking reaction class 0x49 on both legs, and 13/12 (5HP) and 19/17 (623HP) red; and (b) on pristine vsavj and pristine vsav2 with no port in the loop — both legs under the same RAM pokes: the level pin ff8116:06 every frame from 2000, the RNG pin ff80d4:0000 every frame from 2363, the forced P2 pick and P2's HP pinned to 288 before each hit (sweep/leg.sh) — Demitri (P1 id 0x01 at every hit) takes 1 more red HP on vsavj than on vsav2 with the same 2HK (first drop f3007, class 0x49 on every leg it hit) on 14 of the 15 legacy victims it hit (sweep_summary.txt; ids named by bases.tsv: Victor 0x03 alone equal; Oboro 0x18's 2HK made no red drop on vsavj and is excluded), and 13 of those 14 have defense rows byte-equal between the games in the data view, with the attack table and the 2D map equal too (rows191.txt; Sasquatch 0x0a's row differs) — so the 14z-186 control (run2.sh, v2_summary.txt: Victor, p2 0x03) used the one victim where the engines agree on 2HK. NOT tested: where in vsavj's pipeline the point is added, the damage-level config byte, other attackers or moves, Donovan as P2, FBNeo, whether the level and RNG pins themselves change the per-game difference, and whether Donovan's +1 arises at the same pipeline step as the legacy victims'.
Artifacts (read every one, in full):
  - build/agent187/t191/dmg191.txt
  - build/agent187/t191/dmg191.py
  - build/agent187/t191/sweep_summary.txt
  - build/agent187/t191/sweep/summary.py
  - build/agent187/t191/sweep/leg.sh
  - build/agent187/t191/rows191.txt
  - build/agent187/t191/rows191.py
  - build/agent186/legacy_dmg/legacy_v2_p1.rpl
  - build/agent186/legacy_dmg/run2.sh
  - build/agent186/legacy_dmg/v2_summary.txt
  - tests/expected/roster_pairings/bases.tsv
