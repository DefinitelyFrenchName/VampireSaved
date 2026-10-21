THE PACKET

Decision kind: recommendation
Subject: #277 closed done: the extract sources a rounded decimal, opens a cut span with a 40-line prelude, and quotes figures a 160-character cut hid (14z-205c)
Claim (the working agent's sentence): #277 can close done: its three ways were reproduced on transcript 116d721a with the tool as committed (repro_decimals.txt, repro_part_boundary.txt) and each is gone with the fix (fixed_decimals.txt, fixed_part_boundary.txt); tests/test_agent_extract.sh passes on the tree with its controls firing (gate_final.log), and the three new controls rounding-off, cut-cites-off and prelude-off each fail the gate as modes; the three fix choices were put to the maintainer, who accepted them. Not tested: an integer written from a decimal source (12 for 11.80) is still flagged; the prelude is 40 event lines, not a whole part; A@ reads tool results only, not a cut tool input; packet_check's figure flag inherits the rounding rule and was run only through its own gate (test_packet_check.log).
Artifacts (read every one, in full):
  - build/agent205c/t277/closing_comment.md
  - build/agent205c/t277/repro_decimals.txt
  - build/agent205c/t277/fixed_decimals.txt
  - build/agent205c/t277/repro_part_boundary.txt
  - build/agent205c/t277/fixed_part_boundary.txt
  - build/agent205c/t277/gate_final.log
  - build/agent205c/t277/gate_mode_rounding-off.log
  - build/agent205c/t277/gate_mode_cut-cites-off.log
  - build/agent205c/t277/gate_mode_prelude-off.log
  - build/agent205c/t277/test_packet_check.log
  - build/agent205c/t277/extract_change.diff
  - DECISIONS_HISTORY.md.lines-7307-7320 (lines 7307-7320 of DECISIONS_HISTORY.md: its INDEX entry "## Ruled 2026-10-19 (14z-205) — #262, #263 and #277 are parked under #289", and the entries after it up to line 7320)
  - DECISIONS_HISTORY.md.lines-7491-7510 (lines 7491-7510 of DECISIONS_HISTORY.md: its INDEX entry "## Ruled 2026-10-20 (14z-205c) — #277, #262 and #263 are taken up (parked under #289 since 2026-10-1", and the entries after it up to line 7510)
  - docs/project/tickets.tsv.lines-20-73 (lines 20-73 of docs/project/tickets.tsv)
  - docs/project/tickets.tsv.lines-98-98 (lines 98-98 of docs/project/tickets.tsv)
