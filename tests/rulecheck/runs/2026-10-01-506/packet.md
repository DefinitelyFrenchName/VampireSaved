THE PACKET

Decision kind: recommendation
Subject: #191 Donovan 2HK damage
Claim (the working agent's sentence): Recommended: close #191 not-ours (the class #161 closed, docs/project/tables/defense_rows.md:166-173), because (a) re-measured from two complete traces of the 14z-186 rig (dmg191.txt; both legs P1 id 0x13 Donovan and P2 id 0x01 Demitri at 2300 and at every hit; the builds per legs_identity.txt and t184_legs.sh: ours set vsavjw from build/m3b_merged29, fingerprint aacc7e71, native set vsav2 from ROMDIR), Donovan loses 9 red / 16 white HP to Demitri's 2HK on ours against 8 / 15 native, the hit taking reaction class 0x49 on both legs, and 13/12 (5HP) and 19/17 (623HP) red; and (b) on pristine vsavj and pristine vsav2 with no port in the loop — both legs under the same RAM pokes: the level pin ff8116:06 every frame from 2000, the RNG pin ff80d4:0000 every frame from 2363, the forced picks and the victim's HP pinned to 288 before each hit — Demitri's same 2HK (first drop f3007, class 0x49 on every leg it hit, attacker id 0x01 at every hit) takes 1 more red HP on vsavj than on vsav2 on 14 of the 15 legacy victims it hit, BOTH with Demitri attacking from P1 (sweep_summary.txt, sweep/leg.sh) and from P2, the port rig's side (sweep2_summary.txt, sweep2/leg.sh); ids named by bases.tsv: Victor 0x03 alone equal, Oboro 0x18's 2HK made no red drop on vsavj and is excluded; 13 of those 14 have defense rows byte-equal between the games in the data view, with the attack table and the 2D map equal too (rows191.txt; Sasquatch 0x0a's row differs) — so the 14z-186 control (run2.sh, v2_summary.txt: Victor, id 0x03) used the one victim where the engines agree on 2HK. NOT tested: where in vsavj's pipeline the point is added, the damage-level config byte, other attackers or moves, Donovan as P2, FBNeo, whether the level and RNG pins themselves change the per-game difference, and whether Donovan's +1 arises at the same pipeline step as the legacy victims'.
Artifacts (read every one, in full):
  - build/agent187/t191/dmg191.txt
  - build/agent187/t191/dmg191.py
  - build/agent187/t191/legs_identity.txt
  - build/agent186/t184_legs.sh
  - build/agent187/t191/sweep_summary.txt
  - build/agent187/t191/sweep/summary.py
  - build/agent187/t191/sweep/leg.sh
  - build/agent187/t191/sweep2_summary.txt
  - build/agent187/t191/sweep2/summary.py
  - build/agent187/t191/sweep2/leg.sh
  - build/agent187/t191/rows191.txt
  - build/agent187/t191/rows191.py
  - build/agent186/legacy_dmg/legacy_v2_p1.rpl
  - build/agent186/legacy_dmg/legacy_v2_p2.rpl
  - build/agent186/legacy_dmg/run2.sh
  - build/agent186/legacy_dmg/v2_summary.txt
  - tests/expected/roster_pairings/bases.tsv
  - docs/project/tables/defense_rows.md.lines-166-173 (lines 166-173 of docs/project/tables/defense_rows.md)
