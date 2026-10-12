THE PACKET

Decision kind: expectation
Subject: re-freeze tests/expected/reaction_class_live.tsv after the #118 replays joined the corpus its vsavj leg globs (re-check after run 911)
Claim (the working agent's sentence): Re-freeze tests/expected/reaction_class_live.tsv (rcl_diff.txt): the release run's audit_reaction_class_live FAIL on ERIS (audit_reaction_class_live.eris.log) is the vsavj leg's corpus growing from 89 to 97 top-level replays (rcl_corpus.txt), shown by a separating control — with the eight #118 replays moved out and the c884e6d8 rows restored, the gate at 7c757b12 PASSes with every row as frozen (rcl_old89.log), so the older 89 replays and every other current input (rcl_inputs.txt: outside tests/replays only two manifests' measurement records moved) reproduce the old counts exactly; with the eight in, the re-frozen file keeps all 350 row keys in order with counts ignored, 44 vsavj counts rise by 1, 6, 7 or 8, the runs row reads 89 to 97 and the ours and native legs are unchanged (rcl_keys.txt from rcl_keys.py), and a plain re-run PASSes with range-silent and planted-38 FIRED (rcl_verify.log). NOT TESTED: the regeneration, its verification and the control ran on one host at 7c757b12 (MacBook-Pro.local, rcl_old89.log), not a second host; whether the eight replays deserve a dedicated case is not judged.
Artifacts (read every one, in full):
  - build/agent198/skip118/rcl_diff.txt
  - build/agent198/skip118/audit_reaction_class_live.eris.log
  - build/agent198/skip118/rcl_corpus.txt
  - build/agent198/skip118/rcl_keys.py
  - build/agent198/skip118/rcl_keys.txt
  - build/agent198/skip118/rcl_freeze.log
  - build/agent198/skip118/rcl_verify.log
  - build/agent198/skip118/rcl_old89.sh
  - build/agent198/skip118/rcl_old89.log
  - build/agent198/skip118/rcl_inputs.txt
  - tests/audit_reaction_class_live.sh.lines-1-120 (lines 1-120 of tests/audit_reaction_class_live.sh)
