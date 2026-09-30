THE PACKET

Decision kind: expectation
Subject: #193: re-freeze tests/expected/move_parity_events.tsv, chains174.tsv, chains184.tsv and move_parity_attribution.tsv with both white HP words compared by tools/move_parity.py (after runs 2026-09-30-483 and -484)
Claim (the working agent's sentence): tools/move_parity.py now compares both fighters' white HP words (p2white $FF8852, p1white $FF8452) per event as CUMULATIVE fields, refuses a trace missing a compared field on any compared frame, and excludes a rig pin from every byte it writes (the HP pin ff8850:01200120 is a long setting +0x50 and +0x52) (code_diff.txt); the three gates trace both words; tools/move_parity_attribution.py traces them, reads DMG-VSAVJ on p1hp alone or p1hp with p1white only when the white word also shows ours taking more, and adds the open class REACTION-51-OPEN (P2's class 0x51 native / 0x4F ours, first differing at or before the first DIFF frame or one frame after it, #194). Two new must-fire controls in tests/audit_move_parity.sh cover the new mechanism: white-pin (p2white stepped at the long HP-pin frames leaves every verdict frozen under the per-byte exclusion and moves 10 without it, on donovan_1) and field-dropped (a trace without p2white is refused), each failing the gate as a CONTROL= mode (mp_ctl.log, mp_mode_*.log); white_pin_shadow.txt shows an address-only exclusion moving 8 of 10 verdicts on pyron_5 where the per-byte one moves 0; late_drop_check.txt shows a trace missing p2white only from f6000 on refused. Against the old frozen table (cmp193.txt, an unfrozen run on m3b_merged29 — merged-m21, fingerprint aacc7e71 by builds_meta.txt and patch_index.md lines 20-21): 255 rows unchanged, 251 moved only in their excluded-sample count, 5 IDENT to DIFF on p2white alone (pyron_4:5-7, pyron_5:6, pyron_5:9, all Cosmo Disruption), 7 DIFF rows keep their first frame and gain a white field, pyron_4:12 changes only its coupled column, 6 IDENT rows and one NOT-IN-DF row change only their coupled column; chains174 and chains184 rows move only in their excluded counts. The four expectations were frozen with FREEZE=1 and verified by plain runs after every tool change (vf3_*.log: audit_move_parity ALL=1 with seven controls firing, chains174, chains184 — whose tap run ends in the MAME teardown segfault the gate counts as no failure once its END line is reached — and the attribution); the frozen move_parity table equals an earlier run's row for row (repeat_check.txt), which shows the same tool repeating, not an independent confirmation. The attribution freezes 7 REACTION-51-OPEN rows: 5 roots, each reading class 0x51/0x4F on the event's first hit frame (wh_hits_all.txt: 3874, 4274, 4614, 5429, 6629; the class itself traced on pyron_4:7 in cls_summary.txt), plus 2 surfaced under ablation; it keeps the 6 DMG-VSAVJ rows and has no OTHER root (table_diff_small.txt). Every frozen row rests on the gates' pins, the level at 6 and the RNG word held at 0000 from 2363 (#183 keeps that basis). NOT tested: that the remap is the cause of the REACTION-51-OPEN rows (#194 is open); the REACTION-51-OPEN rule and the DMG-VSAVJ white-direction condition against a negative case (each shown by its positive cases only); the white words in move_parity's p2check and compare modes (unchanged); chains174's and chains184's own controls on the white words (the exclusion lives in the shared comparator, controlled in audit_move_parity); FBNeo; a second host.
Artifacts (read every one, in full):
  - build/agent186/t193/code_diff.txt
  - build/agent186/t193/cmp193.txt
  - build/agent186/t193/repeat_check.txt
  - build/agent186/t193/table_diff_small.txt
  - build/agent186/t193/vf3_audit_move_parity.log
  - build/agent186/t193/vf3_audit_chains174.log
  - build/agent186/t193/vf3_audit_chains184.log
  - build/agent186/t193/vf3_audit_move_parity_attribution.log
  - build/agent186/t193/fz2_attr.log
  - build/agent186/t193/cls_summary.txt
  - build/agent186/t193/wh_hits_all.txt
  - build/agent186/t193/mp_ctl.log
  - build/agent186/t193/mp_mode_white-pin.log
  - build/agent186/t193/mp_mode_field-dropped.log
  - build/agent186/t193/white_pin_shadow.txt
  - build/agent186/t193/late_drop_check.txt
  - build/agent186/t186/builds_meta.txt
  - docs/project/patch_index.md.lines-20-21 (lines 20-21 of docs/project/patch_index.md)
