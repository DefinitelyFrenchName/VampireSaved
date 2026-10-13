THE PACKET

Decision kind: recommendation
Subject: #272 built as a flags-only pre-prepare check; recommend flags only and closing #272 on the replay — re-check after runs 962-964
Claim (the working agent's sentence): Recommend to the maintainer that #272's pre-prepare check stays FLAGS ONLY and that #272 closes on this replay (build/agent199/t272/report.md). Built: tools/packet_check.py, run by tools/rulecheck.py prepare (rulecheck.py lines 462-476 and 536-543), flags a claim figure, quotation or attribution no artifact holds and, in a --deliverable, unsourced figures and untied absolute sentences; prepare has no refusal path for it; its replay reads each run's real slot from control.txt and skips a run whose staged copy differs from its manifest.tsv, and its AS FILED tally and size buckets are tally(), each covered by self-test cases on a synthetic ledger; gate tests/test_packet_check.sh PASSes with its four controls FIRED in-gate and FAILing the gate as modes (gates.log). Measured by a measurer spec (spec_measure_r2.md, measurer_r2_return.txt), the code edited after it reproducing its outputs byte for byte (r2_recheck.txt): as filed, refusing on a claim figure or an unquoted attribution, the check would have refused 3 of the 17 packets the readers passed in 14z-196..14z-198 (FIGURE 2, ATTRIB 1), and its refusing flags sat on 4 VIOLATED runs; a first iteration that also refused unstaged files refused 9 of the 17; the VIOLATED share by packet size rises in 14z-196..14z-198 and falls in 14z-184..14z-195, so no threshold is built. The maintainer's ruling is quoted in DECISIONS_HISTORY.md: "let's try your proposal and iterate on it, based on measured data". NOT TESTED: whether a flag is a real defect or sits on the reader's own finding is the working agent's reading of each match and each refused OK packet (matches_read.tsv: the 3 refusals false; one of the 4 refusing matches, 908, the reader's finding; 7 of the 13 VIOLATED rounds of the 14z-199 report; 5 of 49 VIOLATED runs of 14z-196..14z-198), a judgement no second reader checked; the matches are co-occurrences, an upper bound; whether the flags save rounds in live use; the replay's deliverable is a stand-in (a staged markdown document the claim names), since past packets named none; whether the size trend in either window is more than noise; the full static tier has not run on this change, only the gates in gates.log.
Artifacts (read every one, in full):
  - build/agent199/t272/report.md
  - build/agent199/t272/issue272.md
  - DECISIONS_HISTORY.md.lines-6637-6650 (lines 6637-6650 of DECISIONS_HISTORY.md)
  - tools/packet_check.py
  - tools/rulecheck.py.lines-455-545 (lines 455-545 of tools/rulecheck.py)
  - tests/test_packet_check.sh
  - build/agent199/t272/gates.sh
  - build/agent199/t272/gates.log
  - build/agent199/t272/spec_measure_r2.md
  - build/agent199/t272/measurer_r2_return.txt
  - build/agent199/t272/r2_recheck.txt
  - build/agent199/t272/matches.py
  - build/agent199/t272/matches_held.txt
  - build/agent199/t272/matches_199.txt
  - build/agent199/t272/matches_read.tsv
  - build/agent199/t272/packet_check_v4_run.py
  - docs/project/rule_checker.md.lines-65-83 (lines 65-83 of docs/project/rule_checker.md)
  - STATE.md.lines-86-86 (lines 86-86 of STATE.md)
