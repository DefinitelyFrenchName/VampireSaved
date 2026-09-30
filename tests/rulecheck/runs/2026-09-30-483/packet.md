THE PACKET

Decision kind: expectation
Subject: #193: re-freeze tests/expected/move_parity_events.tsv, chains174.tsv, chains184.tsv and move_parity_attribution.tsv with both white HP words compared by tools/move_parity.py
Claim (the working agent's sentence): tools/move_parity.py now compares both fighters' white HP words (p2white $FF8852, p1white $FF8452) per event as CUMULATIVE fields (frame-to-frame change), refuses a trace missing a compared field, and excludes a rig pin from every byte it writes (the HP pin ff8850:01200120 is a long setting +0x50 and +0x52) (code_diff.txt); the three gates trace both words, and tools/move_parity_attribution.py traces them too, reads its DMG-VSAVJ signature on p1hp alone or p1hp with p1white only when the white word also shows ours taking more, and adds the open class REACTION-51-OPEN (P2's class 0x51 native / 0x4F ours at or before the first DIFF, #194). Against the old frozen table (cmp193.txt, from an unfrozen run on merged-m21): 255 rows unchanged, 251 moved only in their excluded-sample count, 5 IDENT to DIFF on p2white alone (pyron_4:5-7, pyron_5:6, pyron_5:9, all Cosmo Disruption), 8 DIFF rows keep their first frame and gain a white field (one, pyron_4:12, changes only its coupled column), 6 IDENT rows and one NOT-IN-DF row change only their coupled column; chains174 and chains184 rows move only in their excluded counts. The four expectations were frozen with FREEZE=1 on merged-m21 and verified by plain runs (vf_*.log, vf2_attr.log, vf2_c184.log after a header edit), every in-gate control firing; the frozen move_parity table equals the earlier independent run row for row (repeat_check.txt); the attribution freezes 7 REACTION-51-OPEN rows (5 roots, each reading class 0x51/0x4F at its hit frame, plus 2 surfaced under ablation), keeps the 6 DMG-VSAVJ rows and has no OTHER root (table_diff_small.txt). NOT tested: that the remap is the cause of the REACTION-51-OPEN rows (#194 is open); FBNeo; the white words in move_parity's p2check and compare modes (not changed); the gates' control modes run after the edits (their in-gate controls fired); a second host.
Artifacts (read every one, in full):
  - build/agent186/t193/code_diff.txt
  - build/agent186/t193/cmp193.txt
  - build/agent186/t193/repeat_check.txt
  - build/agent186/t193/table_diff_small.txt
  - build/agent186/t193/vf_audit_move_parity.log
  - build/agent186/t193/vf_audit_chains174.log
  - build/agent186/t193/vf2_c184.log
  - build/agent186/t193/fz2_attr.log
  - build/agent186/t193/vf2_attr.log
  - build/agent186/t193/cls_summary.txt
