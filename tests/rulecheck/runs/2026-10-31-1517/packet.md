THE PACKET

Decision kind: recommendation
Subject: close #129 declined on the maintainer's word
Claim (the working agent's sentence): CLAIM: close #129 as `declined` (14z-215), on the maintainer's word — the GitHub issue gets closing_comment_129.md (its run placeholder filled with this run's id) and is closed, the index row ticket_row_129.tsv records `declined` with its four answers, and the tickets list is refreshed so test_tickets reconciles. It rests on: ruling_close_129.txt (asked after rule-checker runs 2026-10-31-1515 and -1516 OK on the recommendation "B no, A as A1", the maintainer chose "Neither, close #129", whose text read "Neither behaviour ported. #129 closes as not ported, with your reads as the resolution. The CPU AI gate stays as a soak."; then, unasked: "To be clear, #129 never was in scope, it always was bonus content since it's not 2P versus. And since there's no obvious answer between behavior in our build and vs2, better close the ticket"); `declined` is the index's status for "ruled not to be done" (its header); issue_129.md (the issue as it stands on GitHub: OPEN, its body and comments); doc_edits.txt (the live documents updated in the same change: docs/game/engine_internals.md carries the ruling beside the options it rules on, STATE.md records it and drops the 14z-196 standing ruling that no longer constrains work, docs/NEXT_SESSION.md drops #129 from its parked list); test_tickets.log (before the GitHub close: the only check failure is #129 `declined` while the issue is OPEN, plus the generated page, since regenerated). NOT TESTED: test_tickets after the close and refresh (it runs then, and in the commit's tier); nothing is built or measured for #129 — "closed means nothing is left to do" holds because the maintainer ruled neither behaviour ported, not because the differences were removed: Behaviour A's measured difference (36 second continuations in 9 of 15 legs where native refuses) and Behaviour B's (the event split and reaction ids of the matched-start capture) remain, by decision; the closing comment's summary figures are copied from the recommendation packet that runs -1515/-1516 checked, not re-measured here.
Artifacts (read every one, in full):
  - build/agent215/closure129/claim.txt
  - build/agent215/closure129/ruling_close_129.txt
  - build/agent215/closure129/issue_129.md
  - build/agent215/closure129/closing_comment_129.md
  - build/agent215/closure129/ticket_row_129.tsv
  - build/agent215/closure129/doc_edits.txt
  - build/agent215/closure129/test_tickets.log
