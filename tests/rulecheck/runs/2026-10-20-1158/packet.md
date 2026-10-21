THE PACKET

Decision kind: recommendation
Subject: #262 closed done: a mid-turn maintainer message (a queued_command attachment from a human) is an M line of the extract (14z-205c)
Claim (the working agent's sentence): #262 can close done: the defect was reproduced on transcript 6426a4a0 with the tool as committed, record 9507's message drawing no M line (repro.txt), and the fixed extract shows it as M [mid-turn] (fixed.txt); tests/test_agent_extract.sh passes on the tree (gate_final.log) and its new control mid-turn-blind fails the gate as its mode (gate_mode_mid-turn-blind.log). Not tested: the enqueue record itself is not read, only the attachment, so a message whose attachment was never written would draw no M line (no such case in the two transcripts read); the census of the form covers two transcripts only.
Artifacts (read every one, in full):
  - build/agent205c/t262/closing_comment.md
  - build/agent205c/t262/repro.txt
  - build/agent205c/t262/fixed.txt
  - build/agent205c/t277/gate_final.log
  - build/agent205c/t262/gate_mode_mid-turn-blind.log
  - build/agent205c/t277/extract_change.diff
  - DECISIONS_HISTORY.md.lines-7307-7320 (lines 7307-7320 of DECISIONS_HISTORY.md: its INDEX entry "## Ruled 2026-10-19 (14z-205) — #262, #263 and #277 are parked under #289", and the entries after it up to line 7320)
  - DECISIONS_HISTORY.md.lines-7491-7500 (lines 7491-7500 of DECISIONS_HISTORY.md: its INDEX entry "## Ruled 2026-10-20 (14z-205c) — #277, #262 and #263 are taken up (parked under #289 since 2026-10-1", and the entries after it up to line 7500)
  - docs/project/tickets.tsv.lines-20-73 (lines 20-73 of docs/project/tickets.tsv)
  - docs/project/tickets.tsv.lines-113-113 (lines 113-113 of docs/project/tickets.tsv)
