THE PACKET

Decision kind: expectation
Subject: test_poked_legs: re-freeze tests/expected/poked_legs.tsv with 16 new rows from the #291 sheet blocks (14z-205)
Claim (the working agent's sentence): The tier's one red, test_poked_legs (census.diff: 23 new census rows, none removed), has two causes. 7 rows were false native legs made by this session's '# SHEET: none' comments naming vsav2 in three poked gates, the documented trap (tool_doc_36_47.txt; comment_sensitivity.txt shows a comment-only copy gaining native rows); the three comments now say vs2, and those rows are gone. The other 16 (census_after_reword.diff) come from the poke text of the sheet blocks added to tests/audit_df_startup_invuln.sh and tests/audit_dmg_legacy_sweep.sh (sheet_poke_lines.txt), which re-run those gates' own legs through the same helpers (pk_char, lpk); none is CROSS-FLAVOR (8 are PARAM, carrying the same conditional note as the gate's frozen $_v rows, 7 CROSS-INERT, 1 SAME), so the census is re-frozen with them (FREEZE=1) and the accepted list is unchanged. The gate's controls fire (gate_after_reword.log). NOT TESTED: each row is a static script-level pairing, not an executed leg (the tool's stated over-approximation); whether the PARAM rows' sweep ever pokes 0x13 or 0x10 on a native leg is not measured here, as for the frozen $_v rows; the re-frozen file is not yet written (it needs the maintainer's go-ahead).
Artifacts (read every one, in full):
  - build/agent205/poked/census.diff
  - build/agent205/poked/census_after_reword.diff
  - build/agent205/poked/comment_sensitivity.txt
  - build/agent205/poked/sheet_poke_lines.txt
  - build/agent205/poked/gate_after_reword.log
  - build/agent205/poked/gate_header.txt
  - build/agent205/poked/tool_doc_36_47.txt
  - tests/expected/poked_legs_accepted.tsv
