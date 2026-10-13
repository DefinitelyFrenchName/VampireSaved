THE PACKET

Decision kind: recommendation
Subject: #272 built as a flags-only pre-prepare check; recommend flags only and closing #272 on the replay
Claim (the working agent's sentence): Recommend to the maintainer that #272's pre-prepare check stays FLAGS ONLY and that #272 closes on this replay (build/agent199/t272/report.md). Built: tools/packet_check.py, run by tools/rulecheck.py prepare (rulecheck.py lines 462-476 and 536-543), flags a claim figure, quotation or attribution no artifact holds and, in a --deliverable, unsourced figures and untied absolute sentences; prepare has no refusal path for it; gate tests/test_packet_check.sh PASSes with both controls FIRED in-gate and FAILing the gate as modes (gates.log). Measured by a measurer spec (spec_measure_final.md, measurer_final_return.txt): the filed refusing form would have refused 9 of the 17 packets the readers passed in 14z-196..14z-198 (v4held.OK_runs_refused), and the VIOLATED share does not rise with packet size (v4held.by_artifacts, v4tune.by_artifacts). The maintainer's ruling is quoted in DECISIONS_HISTORY.md: "let's try your proposal and iterate on it, based on measured data". NOT TESTED: whether a flag sits on the reader's own finding is the working agent's reading of each match (matches_read.tsv: 7 of the 13 VIOLATED rounds of the 14z-199 report, 5 of 49 VIOLATED runs of 14z-196..14z-198), a judgement no second reader checked; the matches are co-occurrences, an upper bound; whether the flags save rounds in live use; the replay's deliverable is a stand-in (a staged markdown document the claim names), since past packets named none; the full static tier has not run on this change, only the gates in gates.log.
Artifacts (read every one, in full):
  - build/agent199/t272/report.md
  - build/agent199/t272/issue272.md
  - DECISIONS_HISTORY.md.lines-6637-6650 (lines 6637-6650 of DECISIONS_HISTORY.md)
  - tools/packet_check.py
  - tools/rulecheck.py.lines-455-545 (lines 455-545 of tools/rulecheck.py)
  - tests/test_packet_check.sh
  - build/agent199/t272/gates.sh
  - build/agent199/t272/gates.log
  - build/agent199/t272/spec_measure_final.md
  - build/agent199/t272/measurer_final_return.txt
  - build/agent199/t272/matches.py
  - build/agent199/t272/matches_held.txt
  - build/agent199/t272/matches_199.txt
  - build/agent199/t272/matches_read.tsv
  - build/agent199/t272/packet_check_v4_run.py
  - docs/project/rule_checker.md.lines-65-80 (lines 65-80 of docs/project/rule_checker.md)
  - STATE.md.lines-86-86 (lines 86-86 of STATE.md)
