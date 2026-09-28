THE PACKET

Decision kind: expectation
Subject: M21 freeze: retire the attribution tool's #159 seed (fixed at M21) and re-freeze move_parity_attribution.tsv
Claim (the working agent's sentence): Retire tools/move_parity_attribution.py's SEED entry for donovan_3 (event 5, Killshread Summon (ES), GitHub #159's P2 displacement) and re-freeze tests/expected/move_parity_attribution.tsv from the seedless tool on merged-m21. WHY: the M21 re-freeze lane froze move_parity_events.tsv (verify PASS, all five control modes FAIL; laneA_status.txt) with donovan_3 events 6-13 IDENT and event 14 DIFF uncoupled (events_diff.txt), then the attribution freeze REFUSED: "1 root(s)/row(s) with no measured cause: root donovan_3:5 Killshread Summon (ES) OTHER step=1 seeded root with no P2 displacement" (refusal_freeze.log). The seed existed because the parity table does not compare P2's x (tool.diff, the old SEED line and docstring); #159's fix, which landed at M21 under the maintainer's rulings ("Probe plays like native", "Design A, stage for M21 (Recommended)", maintainer_159_probe.txt; "Run the M21 freeze now", maintainer_queue_14z185.txt), is what removed the displacement, so the seeded root no longer has one. MEASURED on merged-m21 by the tool itself, invoked as the gate invokes it (commands.txt): SEEDED (the committed tool, got_seeded.tsv): 25 roots, the one OTHER being the seeded root; SEEDLESS (after tool.diff, got_noseed.tsv): 24 roots, 60 rows, no OTHER and no UNATTRIBUTED. Against the frozen M20 attribution (frozen_m20.tsv, diff_frozen_vs_noseed.txt) the ONLY changes are: the root donovan_3:5 P2-DISPLACEMENT and its five rows (donovan_3 events 6-10) are gone, and the root donovan_3:14 Slay Shred DF-STOCK is found at step 1 instead of step 2 (it was ablated after the seed before); every other root and row is identical. The tool change removes the seed entry only: the SEED mechanism and the P2-DISPLACEMENT class stay, the docstring and the gate header mark them fixed at M21 (tool.diff). HOW: FREEZE=1 with the seedless tool, then a plain verify run, then CONTROL=no-ablation, which must FAIL.
NOT TESTED:
- The seedless tool on merged-m20: its step 0 must reproduce the frozen parity table, which is now M21's, so it would VOID; that the seed was needed on M20 rests on the M20 frozen attribution's own evidence ("P2's x differs in the window while the tenant's fields are IDENT", frozen_m20.tsv), not re-measured today.
- A root invisible to the parity table in some other part the way #159's was: without a seed such a root is attributed by ablation to whatever DIFF row comes first, under that row's own signature, or not at all; nothing here searches for one.
- The direct tool runs used --jobs 4 and a kept work dir; the gate uses --jobs 6 and a temp dir (commands.txt); the frozen run itself goes through the gate.
Artifacts (read every one, in full):
  - build/rc185/attr/refusal_freeze.log
  - build/rc185/attr/laneA_status.txt
  - build/rc185/attr/events_diff.txt
  - build/rc185/attr/tool.diff
  - build/rc185/attr/commands.txt
  - build/rc185/attr/got_seeded.tsv
  - build/rc185/attr/got_noseed.tsv
  - build/rc185/attr/frozen_m20.tsv
  - build/rc185/attr/diff_frozen_vs_noseed.txt
  - build/agent185/t159/maintainer_159_probe.txt
  - build/agent185/maintainer_queue_14z185.txt
