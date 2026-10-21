THE PACKET

Decision kind: recommendation
Subject: #263 closed done: the extract's W§ line quotes the file lines a worker cites beside a W#-flagged figure; neither of the body's sketches (14z-205c)
Claim (the working agent's sentence): #263 can close done: the defect was reproduced at HEAD on transcript 116d721a, record 10520 listing 6630 and 9230 under W# though the worker derived them from lines of a file it read (x199_head.txt); with the fix a W§ line quotes the cited lines from the worker's own read (fixed_986.txt), the figures staying listed; sketch 1 was measured and dropped (proto_derivable.py; 110 of 130 and 30 of 33 figures would clear, mostly falsely); the maintainer accepted W§ in their own words; tests/test_agent_extract.sh passes on the final tree with 13 controls firing (build/agent205c/t277/gate_rc2.log) and cited-lines-off fails it as its mode. Not tested: a derivation whose inputs the report does not cite by file:line (9230 also needs MOVEMENT and NORMALS, defined outside the cited lines); a file read by Grep or Bash rather than Read; a figure derived from another report figure; the W§ line helps the checker but clears nothing, so whether checkers use it is not measured.
Artifacts (read every one, in full):
  - build/agent205c/t263/closing_comment.md
  - build/agent205c/t263/x199_head.txt.lines-30218-30263 (lines 30218-30263 of build/agent205c/t263/x199_head.txt)
  - build/agent205c/t263/fixed_986.txt
  - build/agent205c/t263/proto_derivable.py
  - build/agent205c/t277/gate_rc2.log
  - build/agent205c/t263/gate_mode_cited-lines-off_final.log
  - build/agent205c/t277/extract_change.diff
  - DECISIONS_HISTORY.md.lines-7492-7500 (lines 7492-7500 of DECISIONS_HISTORY.md: its INDEX entry "## Ruled 2026-10-20 (14z-205c) — #277, #262 and #263 are taken up (parked under #289 since 2026-10-1", and the entries after it up to line 7500)
  - DECISIONS_HISTORY.md.lines-7500-7514 (lines 7500-7514 of DECISIONS_HISTORY.md: its INDEX entry "## Ruled 2026-10-20 (14z-205c) — #277's three fixes and #263's W§ line accepted", and the entries after it up to line 7514)
  - docs/project/gotchas.md.lines-7350-7362 (lines 7350-7362 of docs/project/gotchas.md)
  - docs/project/tickets.tsv.lines-20-73 (lines 20-73 of docs/project/tickets.tsv)
  - docs/project/tickets.tsv.lines-112-112 (lines 112-112 of docs/project/tickets.tsv)
