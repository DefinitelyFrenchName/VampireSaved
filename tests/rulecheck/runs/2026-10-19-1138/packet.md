THE PACKET

Decision kind: recommendation
Subject: #300 closed done: test_close_tools reads no findings table gracefully (14z-205)
Claim (the working agent's sentence): #300 closes done: the two places tests/test_close_tools.sh read the findings table #288 cut (section 2b, REFUSED exit 3, gate_before_fix.log; section 2d and its output-overwrites control, FAIL and DEAD without a findings row, gate_without_standin.log) are fixed (fix.diff): 2b prints a NOTE when STATE.md has no findings table and still judges a row when one exists (planted_row.log: a build/ home FAILs), 2d uses a stand-in row; the gate passes with all 9 controls fired (gate_pass.log) and CONTROL=output-overwrites fails it (mode_output_overwrites.log); the stale core claim is corrected in HANDOFF, the gate header and static_confirm.py; the lesson is a gotcha; the closing comment (closing_comment.md) and the index row (row_300.tsv) record it. The fix's shape (keep 2b, NOTE when absent, rather than retire it) is the session's choice, not a ruling; the maintainer's words: maintainer_words.txt
Artifacts (read every one, in full):
  - build/agent205/t300/issue_live.md
  - build/agent205/t300/fix.diff
  - build/agent205/t300/gate_before_fix.log
  - build/agent205/t300/gate_without_standin.log
  - build/agent205/t300/gate_pass.log
  - build/agent205/t300/mode_output_overwrites.log
  - build/agent205/t300/planted_row.log
  - build/agent205/t300/maintainer_words.txt
  - build/agent205/t300/row_300.tsv
  - build/agent205/t300/closing_comment.md
