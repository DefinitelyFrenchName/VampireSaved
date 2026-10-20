THE PACKET

Decision kind: recommendation
Subject: #257 closed done: rulings_verbatim checks a second maintainer quote joined on its line (14z-205)
Claim (the working agent's sentence): #257 closes done: tools/agent/rulings_verbatim.py (fix.diff) classes a quote joined to the previous one (then, and, a comma, or a short sub-label ending in a colon) by that one's class, lets a maintainer label carry a sub-label, and finds an elided quote by its parts; the selftest grows to 18 cases, PASS (selftest.log; the old tool passes its own 9, selftest_before.log), and the gate passes with 7 controls fired, the 2 new ones failing it as modes (gate.log, mode_join-blind.log, mode_elision-blind.log). On four sessions' real records old against new (real_compare.txt): three identical, 14z-205 six more quotes checked and found, no new NOT FOUND. Not tested: the gate is ondemand so no tier runs it unless asked; an answer joined to a question by an em dash stays unchecked; the pre-existing NOT FOUND lines are not this ticket's; only four sessions were compared. Closing comment and row: closing_comment.md, row_257.tsv; the request: maintainer_words.txt
Artifacts (read every one, in full):
  - build/agent205/t257/fix.diff
  - build/agent205/t257/selftest.log
  - build/agent205/t257/selftest_before.log
  - build/agent205/t257/gate.log
  - build/agent205/t257/mode_join-blind.log
  - build/agent205/t257/mode_elision-blind.log
  - build/agent205/t257/real_compare.txt
  - build/agent205/t257/maintainer_words.txt
  - build/agent205/t257/closing_comment.md
  - build/agent205/t257/row_257.tsv
