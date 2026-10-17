THE PACKET

Decision kind: recommendation
Subject: #291 census (all 231 gates) and design, #261 freeze plan, #256 options, #286 next steps and one question, put to the maintainer for ruling (after run 2026-10-16-1103)
Claim (the working agent's sentence): recs.md and t291/design.md put four items to the maintainer; each figure in them comes from a measurer return (build/agent203/t291/measurer_census_all_return.txt, build/agent203/t286_measurer_return.txt, build/agent203/t286_trace_return.txt) or a named log or file (build/agent203/t261/run1.log, run2.log, run1_t0.txt, fingerprint.log, build/agent203/mid2.log, build/agent203/t286_static_runner2.log); every registry gate has a row with its basis in census_all.tsv; each recommendation is consistent with the rulings in DECISIONS_HISTORY.md (#288, #290, #291). NOT TESTED: the 45 header-only rows of census_all.tsv against their scripts; the 85 screened-out rows not in the 10-gate sample; the screen's recall beyond the 62 gates it was tuned on; reads through git, which the #286 trace counts cannot see.
Artifacts (read every one, in full):
  - build/agent203/recs.md
  - build/agent203/t291/design.md
  - build/agent203/t291/census_all.tsv
  - build/agent203/t291/census_all.py
  - build/agent203/t291/census_class.tsv
  - build/agent203/t291/cand_reading.tsv
  - build/agent203/t291/none_sample_reading.tsv
  - build/agent203/t291/screen.py
  - build/agent203/t291/screen.tsv
  - build/agent203/t291/screen_recall.tsv
  - build/agent203/t291/census_raw.tsv
  - build/agent203/t291/measurer_census_all_return.txt
  - build/agent203/t286_measurer_return.txt
  - build/agent203/t286_trace_return.txt
  - build/agent203/t286_stale_gates.txt
  - build/agent203/mid2.log
  - build/agent203/mid1.log
  - build/agent203/mid1_results.controls.tsv
  - build/agent203/t286_static_runner2.log
  - build/agent203/t261/run1.log
  - build/agent203/t261/run2.log
  - build/agent203/t261/run1_t0.txt
  - build/agent203/t261/fingerprint.log
  - tests/audit_effect_class_rows.sh
  - tests/expected/instr_gameclock/audit_effect_class_rows.tsv
  - tests/ci_emulator.tsv
  - tests/ci_cadence.tsv
  - tests/close_standing_checks.tsv
  - tools/check_state_lists.py
  - tests/run_all_static.sh
  - tests/test_static_runner.sh
  - tools/static_confirm.py
  - build/emu_freeze_m23_p1/results.tsv
  - tools/naming_pair_sheet.sh
  - DECISIONS_HISTORY.md
