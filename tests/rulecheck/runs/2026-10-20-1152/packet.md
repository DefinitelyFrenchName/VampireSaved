THE PACKET

Decision kind: recommendation
Subject: #299 closed done: the static tier runs gates in parallel (--jobs), proven equal to a serial run, a close's default at --jobs 8 (14z-205b)
Claim (the working agent's sentence): #299 closes done: its plan's four steps are complete — --jobs N in the runner; the full-tier serial-vs-8-jobs comparison on one snapshot was identical in every verdict (issue_299.txt); nothing differed so nothing needed fixing, with the decrypt-cache and wall-clock hazards addressed as the closing comment says; the maintainer ruled the close's default (ruling_299.txt), applied in the close's tier row and HANDOFF (close_row.txt); test_static_runner section 24 gates it and its three controls each fail the gate as a mode (ctl_*.st, tsr.log). The closing comment names what was not measured.
Artifacts (read every one, in full):
  - build/agent205/t299/closing_comment.md
  - build/agent205/t299/issue_299.txt
  - build/agent205/t299/ruling_299.txt
  - build/agent205/t299/close_row.txt
  - build/agent205/t299/section24.txt
  - build/agent205/t299/decrypt_cache_excerpt.txt
  - build/agent205/t299/tsr.log
  - build/agent205/t299/ctl_pool-blind.st
  - build/agent205/t299/ctl_pool-order-ignored.st
  - build/agent205/t299/ctl_job-carry-blind.st
