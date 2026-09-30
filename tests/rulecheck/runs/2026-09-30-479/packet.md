THE PACKET

Decision kind: recommendation
Subject: #186 answered for the maintainer's ruling: #159's facing hook moves Pyron's mash ring stream by its EXECUTION and 110_don_arcade_mash's defense reads by its RULE-5 LOGIC (tests/audit_facing_hook_ab.sh)
Claim (the working agent's sentence): tests/audit_facing_hook_ab.sh, run with FREEZE=1 on merged-m21 (build/m3b_merged29, aacc7e71) and verified by a plain run, builds two variants from merged-m21's own patch.json (tools/facing_hook_ab.py): logicoff (the thunk's cmpi.b #5,d0 made #$FF: the hook runs, rule 5 is never taken) and unhooked (the site op at CPU:$01886C dropped, the thunk still placed), each read back from its decrypted opcode view, with ctl (the patch unfiltered) reproducing the build's 8 program members; it shows (1) Pyron's mash ring stream (the ring gate's comparison, pokes and 8400 frames) agrees with solo pyron44 for the whole run on the build and on logicoff, diverges at merged f4742 on unhooked, and the rule-5 store PC writes 0 times on that replay on all three, so the hook's EXECUTION moves it, not the rule-5 logic and not the placement; (2) on 110_don_arcade_mash (9000 frames, the defense gate's read tap in the same run as the facing-write tap), logicoff and unhooked write the same +0x5D facing bytes and read the same 426 defense rows while the build reads 412, agreeing for 366 reads, and the build's first facing write that differs from both variants is a rule-5 store at f4318 (7 in all), so the RULE-5 LOGIC moves it; the scratch comparison build/agent186/t186/cmp2.txt (builds in builds_meta.txt) shows both variants' arcade facing and defense-read streams equal merged-m20's (m3b_merged28) and unhooked's mash facing writes equal M20's; four must-fire controls fire in-gate and each, run as a CONTROL= mode, fails the gate; I recommend putting this to the maintainer as #186's answer. NOT tested: which frame's event the hook's cycles move across a frame boundary on the mash; the corpus's other replays; FBNeo and MiSTer; the replays past 8400 and 9000 frames; that d0 never holds $FF at the thunk beyond the measured zero rule-5 stores on logicoff; the variants' graphics and sound members (copied from the build); a second host.
Artifacts (read every one, in full):
  - tests/audit_facing_hook_ab.sh
  - tools/facing_hook_ab.py
  - tests/expected/facing_hook_ab.tsv
  - build/agent186/t186/g1.log
  - build/agent186/t186/g_verify.log
  - build/agent186/t186/g_mode_variant-inert.log
  - build/agent186/t186/g_mode_stream-shifted.log
  - build/agent186/t186/g_mode_read-dropped.log
  - build/agent186/t186/g_mode_r5-planted.log
  - build/agent186/t186/cmp2.py
  - build/agent186/t186/cmp2.txt
  - build/agent186/t186/builds_meta.txt
  - DECISIONS_HISTORY.md.lines-134-140 (lines 134-140 of DECISIONS_HISTORY.md)
