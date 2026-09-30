THE PACKET

Decision kind: recommendation
Subject: open a ticket: Pyron's Cosmo Disruption gives Demitri a plain hit reaction on ours where native vs2 gives the fire / knockdown reaction (found under #193)
Claim (the working agent's sentence): The maintainer read the two captures (build/agent186/t193/snap/cosmo_getup_sheet.png, then snap2/cosmo_full_sheet.png, made by cosmo_snap2.sh from audit_move_parity's own pyron_4 replays and pokes) as a defect, quoted verbatim in DECISIONS_HISTORY.md: after Cosmo Disruption [PP tap] native's Demitri takes a fire reaction (engulfed, carried up burning, knocked down, standing at +210) and ours a plain stagger (standing by +150). Measured on the same rig (cls_summary.txt, traced by cls_trace.sh): P2's reaction class +0x54 reads 0x51 on native and 0x4F on ours from the first hit at +114; both legs agree on P2's HP, seq and sub through +131; at +140 ours leaves seq 2 (seq 4, then 0 at +141) while native stays in seq 2 until +200. The white-HP comparison added under #193 is how it surfaced: cmp193.txt lists pyron_4:5, :6, :7 and pyron_5:6, :9 turning IDENT to DIFF on p2white alone, and wh_pyron_4_7.txt shows the same hits on both legs and ours' white refill starting at +190 against native's +249. build/manifest/pyron.toml:1089-1092 remaps Cosmo's record class 0x51 to 0x4F (14z-75, to stop a watchdog reset: vsavj's dispatch table has 80 entries), and engine_internals.md (14z-110) records that 0x51 -> 0x4E/0x4F changes gameplay through a property lookup keyed on the class, and that the dispatch was since widened in code by the reaction_hook. This justifies a ticket to give Cosmo Disruption native's reaction. NOT tested: that the remap is the cause (no build with the byte restored was run); that class 0x51 now dispatches safely on our build's three dispatchers; the reaction class on the other four DIFF events (their white-HP pattern matches, the class was traced only on pyron_4:7); victims other than Demitri; Pyron as P2; FBNeo; which other records carry a class remap.
Artifacts (read every one, in full):
  - DECISIONS_HISTORY.md.lines-30-38 (lines 30-38 of DECISIONS_HISTORY.md)
  - build/agent186/t193/cls_summary.txt
  - build/agent186/t193/cls_trace.sh
  - build/agent186/t193/cosmo_snap2.sh
  - build/agent186/t193/snap2/cosmo_full_sheet.png
  - build/agent186/t193/cmp193.txt
  - build/agent186/t193/wh_pyron_4_7.txt
  - build/manifest/pyron.toml.lines-1080-1093 (lines 1080-1093 of build/manifest/pyron.toml)
  - docs/game/engine_internals.md.lines-530-556 (lines 530-556 of docs/game/engine_internals.md)
