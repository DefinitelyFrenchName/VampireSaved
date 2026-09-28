THE PACKET

Decision kind: expectation
Subject: M21 freeze: retire the attribution tool's #159 seed (fixed at M21) and re-freeze move_parity_attribution.tsv (re-checked after 402)
Claim (the working agent's sentence): Retire tools/move_parity_attribution.py's SEED entry for donovan_3 (event 5, Killshread Summon (ES), GitHub #159's P2 displacement) and re-freeze tests/expected/move_parity_attribution.tsv from the seedless tool on merged-m21. WHY: the M21 re-freeze lane froze move_parity_events.tsv (verify PASS, all five control modes FAIL; laneA_status.txt) with donovan_3 events 6-13 IDENT and event 14 DIFF uncoupled (events_diff.txt), then the attribution freeze REFUSED: "1 root(s)/row(s) with no measured cause: root donovan_3:5 Killshread Summon (ES) OTHER step=1 seeded root with no P2 displacement" (refusal_freeze.log). The seed existed because the parity table does not compare P2's x (tool.diff, the old SEED line and docstring); WHICH FIX removed the displacement is measured by the committed (seeded) tool itself on the two single-row probes (commands.txt (3)-(4), probe_identities.txt): on the #159-only probe it reads byte-identical to merged-m21 (got_p159_seeded.tsv = got_seeded.tsv: the seeded root OTHER, "seeded root with no P2 displacement"), and on the #182-only probe, with its step-0 table pointed at the M20 table the probe reproduces (shadow_m20ev.diff; the parity tables: parity/diff_merged182.txt empty, parity/diff_probe159.txt = parity/diff_m21.txt), it reads byte-identical to the frozen M20 attribution, P2-DISPLACEMENT included (got_p182_seeded_m20ev.tsv = frozen_m20.tsv). So #159 alone removes it and #182 alone leaves it. #159 landed at M21 under the maintainer's rulings ("Probe plays like native", "Design A, stage for M21 (Recommended)", maintainer_159_probe.txt; "Run the M21 freeze now", maintainer_queue_14z185.txt). MEASURED on merged-m21 by the tool itself, invoked as the gate invokes it (commands.txt): SEEDED (the committed tool, got_seeded.tsv): 25 roots, the one OTHER being the seeded root; SEEDLESS (after tool.diff, got_noseed.tsv): 24 roots, 60 rows, no OTHER and no UNATTRIBUTED. Against the frozen M20 attribution (frozen_m20.tsv, diff_frozen_vs_noseed.txt) the ONLY changes are: the root donovan_3:5 P2-DISPLACEMENT and its five rows (donovan_3 events 6-10) are gone, and the root donovan_3:14 Slay Shred DF-STOCK is found at step 1 instead of step 2 (it was ablated after the seed before); every other root and row is identical. The tool change removes the seed entry only: the SEED mechanism and the P2-DISPLACEMENT class stay, the docstring and the gate header mark them fixed at M21 (tool.diff). CAPTURE: this packet draws no conclusion about how the Summon plays on merged-m21. Its statements are the tool's measurements (P2's x against native in the root's window). The one feel reading is the maintainer's, of probe 159's capture ("Probe plays like native", maintainer_159_probe.txt), and merged-m21 reads byte-identical to that probe on both instruments here: the parity table (parity/diff_m21.txt = parity/diff_probe159.txt) and the seeded attribution (got_seeded.tsv = got_p159_seeded.tsv). HOW: FREEZE=1 with the seedless tool, then a plain verify run, then CONTROL=no-ablation, which must FAIL.
NOT TESTED:
- No capture of merged-m21 itself; the link to the captured probe 159 is the two byte-identical measurements above.
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
  - build/rc185/attr/got_p159_seeded.tsv
  - build/rc185/attr/got_p182_seeded_m20ev.tsv
  - build/rc185/attr/shadow_m20ev.diff
  - build/rc185/probe_identities.txt
  - build/rc185/parity/diff_m21.txt
  - build/rc185/parity/diff_probe159.txt
  - build/rc185/parity/diff_merged182.txt
  - build/agent185/t159/maintainer_159_probe.txt
  - build/agent185/maintainer_queue_14z185.txt
