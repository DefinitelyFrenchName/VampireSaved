THE PACKET

Decision kind: expectation
Subject: merged-m23: eight .masked expectations for the #118 replays audit_legacy_pairings found with none; audit_flicker_attribution's window check fixed and extended with frame 2093
Claim (the working agent's sentence): Freeze composite vsavj/masked-v2 2093 889-1871 for 118_chain, 118_input_sweep and 118_sel_b1..b3 and window vsavj/masked-v2 889 1871 for 118_sel_b4..b6 in tests/expected/merged-m23 (build/agent198/skip118/b_change.txt), resting on vanilla logs added to masked-v2 under the instrument control that re-derived 03_two_player_vs bit-for-bit (b_run.log), the proposer's measured shapes (b_run.log), run_suite's two-run acceptance (suite.log: 8 PASS, SUITE GREEN), the frame-2093 dump diff landing in staging row 0x0C with 118_sel_b4 as the separating case (attr2093.log), and audit_flicker_attribution extended with those cases after its window check was made count-aware with control wrong-window FIRED (accept2.log) and its 41_don_altcolor_vsavj +2313 case retired because that frame shows 0 bytes in staging row 0x0C (accept.log) while merged-m23 specifies 41 as window 889 2091; NOT TESTED: the 889-1871 window is taken as 03_two_player_vs's ratified select window and not re-attributed byte by byte, and 37_victor_ko_vsavj's spec frame 6962 is not a case of the gate.
Artifacts (read every one, in full):
  - build/agent198/skip118/b_change.txt
  - build/agent198/skip118/b_run.log
  - build/agent198/skip118/attr2093.log
  - build/agent198/skip118/suite.log
  - build/agent198/skip118/accept.log
  - build/agent198/skip118/accept2.log
  - build/agent198/skip118/audit_flicker_attribution.wt.sh
  - build/agent198/skip118/audit_legacy_pairings.eris.log
  - tests/expected/merged-m23/03_two_player_vs.masked
  - tests/expected/merged-m23/41_don_altcolor_vsavj.masked
  - tests/expected/merged-m23/37_victor_ko_vsavj.masked
  - docs/project/oracle_classes.md.lines-21-67 (lines 21-67 of docs/project/oracle_classes.md)
