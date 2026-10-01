THE PACKET

Decision kind: recommendation
Subject: #191 Donovan 2HK damage
Claim (the working agent's sentence): Recommended: close #191 not-ours (the class #161 closed), because (a) re-measured from two complete traces of the 14z-186 rig (dmg191.txt), Donovan (P1) loses 9 red / 16 white HP to Demitri's 2HK on merged-m21 (aacc7e71) against 8 / 15 on native vsav2, and 13/12 (5HP) and 19/17 (623HP) red; and (b) with no port in the loop (sweep_summary.txt), pristine vsavj takes 1 more red HP than pristine vsav2 from Demitri's same 2HK on 14 of the 15 legacy victims it hit (Victor alone equal; Oboro's 2HK whiffed on vsavj and is excluded), and 13 of those 14 have defense rows byte-equal between the games in the data view, with the attack table and the 2D map equal too (rows191.txt; Sasquatch's row differs) — so the 14z-186 control happened to use the one victim where the engines agree on 2HK. NOT tested: where in vsavj's pipeline the point is added, the damage-level config byte, other attackers or moves, Donovan as P2, FBNeo, and whether Donovan's +1 arises at the same pipeline step as the legacy victims'.
Artifacts (read every one, in full):
  - build/agent187/t191/dmg191.txt
  - build/agent187/t191/dmg191.py
  - build/agent187/t191/sweep_summary.txt
  - build/agent187/t191/sweep/summary.py
  - build/agent187/t191/sweep/leg.sh
  - build/agent187/t191/rows191.txt
  - build/agent187/t191/rows191.py
  - build/agent186/legacy_dmg/legacy_v2_p1.rpl
