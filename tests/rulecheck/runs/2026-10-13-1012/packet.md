THE PACKET

Decision kind: recommendation
Subject: #270: close done on the maintainer's word, with its done-when measured at the 14z-199 close
Claim (the working agent's sentence): Close #270 `done`: the maintainer, asked with the measurement, answered "Close done (Recommended)" (DECISIONS_HISTORY.md:6702-6708). Its done-when has two halves: the packet's claim names what it covers and what the deterministic checks cover (the done-when as filed: issue270.md "Done when"; the SCOPE sentence that opens every packet claim since run 1002, e.g. tests/rulecheck/runs/2026-10-13-1009/packet.md:5; built and gated in tests/test_rule_checker.sh and tests/test_close_standing.sh, both PASS in the strict tier at a6dcc9a5, gates_a6dcc9a5.tsv taken from that tier's results file; the tier as a whole is NOT GREEN under --strict on one SKIP, test_release_launcher_bat, a Windows-only gate, tier_tail.txt, which PASSed on ERIS at a6dcc9a5 with its control mode first-found FAILing, bat199.log and bat199_ff.log); and a close's packet loop measured against 14z-196..198 — measure.out: 13, 9, 5 and 7 runs, 9.54, 3.70, 0.61 and 2.02 h, from tests/rulecheck/ledger.tsv and each close's transcript (measure.sh), each close's hand-set run range checked against the same session's packet rows counted with no range (measure.out's bracket; the control fired on a planted range dropping run 1002, measure_plant.out). The closing comment (close270.md), the index row (tickets.tsv:80, status done, its four answers), rule_checker.md's MEASURED sentence and NEXT_SESSION's closed list say the same. NOT TESTED: the 14z-196..198 transcripts are identified by which one holds each close's first prepare and last record (measure.sh names them; close_loop_cost.py finds NOT FOUND in the others), not by a session key inside them; the 14z-199 span includes the fixes of two red close tiers made between packet runs, so it is not packet work alone; the run counts count ledger rows whose subject names the close's documentation packet, so a withdrawn run (1003) is not counted; that every VIOLATED run was on an item no deterministic check covers is the working agent's reading of each run's resolution (runs199.out lists the verdicts, the ledger the resolutions); whether the route saves runs at later closes is not measured; the GitHub issue is closed and the comment posted only after this run, and read back then.
Artifacts (read every one, in full):
  - build/agent199/t270/close270.md
  - build/agent199/t270/loop_cost/report.md
  - build/agent199/t270/loop_cost/measure.out
  - build/agent199/t270/loop_cost/runs199.out
  - build/agent199/t270/loop_cost/measure.sh
  - docs/project/tickets.tsv.lines-80-80 (lines 80-80 of docs/project/tickets.tsv)
  - DECISIONS_HISTORY.md.lines-6702-6708 (lines 6702-6708 of DECISIONS_HISTORY.md)
  - docs/project/rule_checker.md.lines-246-268 (lines 246-268 of docs/project/rule_checker.md)
  - docs/NEXT_SESSION.md
  - build/agent199/t270/gates_a6dcc9a5.tsv
  - build/agent199/t270/tier_head.txt
  - build/agent199/t270/tier_tail.txt
  - build/agent199/t270/issue270.md
  - tests/rulecheck/runs/2026-10-13-1009/packet.md.lines-5-5 (lines 5-5 of tests/rulecheck/runs/2026-10-13-1009/packet.md)
  - build/agent199/bat/bat199.log
  - build/agent199/bat/bat199_ff.log
  - build/agent199/t270/loop_cost/measure_plant.out
