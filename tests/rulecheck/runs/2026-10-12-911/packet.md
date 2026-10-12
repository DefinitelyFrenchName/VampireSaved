THE PACKET

Decision kind: expectation
Subject: re-freeze tests/expected/reaction_class_live.tsv after the #118 replays joined the corpus its vsavj leg globs
Claim (the working agent's sentence): Re-freeze tests/expected/reaction_class_live.tsv (rcl_diff.txt), because the release run's audit_reaction_class_live FAIL on ERIS (audit_reaction_class_live.eris.log) is the vsavj leg's corpus growing from 89 to 97 top-level replays (rcl_corpus.txt: the eight #118 replays added 2026-10-08/09, the gate's tests/replays/*.rpl glob at line 99): the re-frozen file keeps all 350 rows' keys in the same order with run counts ignored, the 44 changed cells are vsavj run counts rising by 1, 6, 7 or 8 with the runs row 89 to 97, and the ours and native legs are unchanged (rcl_keys.txt from rcl_keys.py), and a plain re-run after the freeze PASSes with its controls range-silent and planted-38 FIRED (rcl_verify.log). NOT TESTED: the new counts are this one regeneration's (rcl_freeze.log) and its verification run, both on this Mac at 7c757b12, not a second host; whether the eight replays exercise reaction-class writes worth a dedicated case is not judged — they only raise existing counts.
Artifacts (read every one, in full):
  - build/agent198/skip118/rcl_diff.txt
  - build/agent198/skip118/audit_reaction_class_live.eris.log
  - build/agent198/skip118/rcl_corpus.txt
  - build/agent198/skip118/rcl_keys.py
  - build/agent198/skip118/rcl_keys.txt
  - build/agent198/skip118/rcl_freeze.log
  - build/agent198/skip118/rcl_verify.log
  - tests/audit_reaction_class_live.sh.lines-1-120 (lines 1-120 of tests/audit_reaction_class_live.sh)
