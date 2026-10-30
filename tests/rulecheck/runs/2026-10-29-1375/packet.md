THE PACKET

Decision kind: recommendation
Subject: close #334 as done (14z-212): the job knobs measured on PILOT and on the Mac under a tier's load, and the 61 knob-less pooled gates timed before and after on ERIS
Claim (the working agent's sentence): CLAIM: close #334 as done (14z-212): the closing comment closing_comment.md and the row ticket_row_334.tsv state the resolution; #334's gate edits land in this session's commit with #333's. Both of #321's survey gaps are measured. It rests on:
1. ITEM 1 (the knobs on PILOT and under load): pilot_knobs.tsv (14z-211: every setting at its default and a higher value on PILOT, verdicts equal); mac_parity_under_load.txt with parity_default_results.tsv and parity_12_results.tsv (14z-212: test_mame_parity beside a strict static tier on the Mac, 596 s at the default 8 and 506 s at 12, PASS both; the tier alive at both ends of the first run and ending before the second finished); docs/project/operations.md.lines-703-772 (the record).
2. ITEM 2 (the knob-less gates): survey.md (62 SERIAL-LIST gates, two with a shared path); shared_path_gates.diff (audit_region_movability's manifest copy and test_m2a_flavor_selector's per-run folders made private before pooling); eris_times.tsv with eris_setup.out (each of 61 edited gates alone on ERIS, before at 33f85438 and after at 6829e446, the clones' HEAD lines: 7,648 s -> 4,163 s, every verdict PASS both sides, test_wide_profile re-timed after a clone fix, its first two-sided FAIL kept as _skipref rows) and mtime_readers.txt (only test_wide_profile among them reads a file's mtime); mac_pairs_report.tsv (14z-211: 60 gates at one job and four on the Mac, outputs identical; test_release_binaries ruled out); tests/lib/jobs.sh (the pool and the host-derived cap).
3. THE RULINGS: DECISIONS_HISTORY.md.lines-8598-8607 ("All 35 on PILOT", "Re-trace after #334") and .lines-8711-8723 ("All 62", recovered verbatim from 14z-211's transcript).
NOT TESTED: test_mame_parity at 12 under a full load for its whole run; audit_id_writers at one job against four on the Mac (left out of the 14z-211 batches; ERIS timed it, PASS both sides); the 61 gates' timings on PILOT and on the Mac under load; the timings are single runs, not repeated; the ERIS after-tree 6829e446 predates the widened mktemp census (#333's later guards changed 11 gates' scripts again after the timings).
Artifacts (read every one, in full):
  - build/agent212/t334/closure/closing_comment.md
  - build/agent212/t334/closure/ticket_row_334.tsv
  - build/agent212/t334/closure/pilot_knobs.tsv
  - build/agent212/t334/closure/mac_parity_under_load.txt
  - build/agent212/t334/closure/parity_default_results.tsv
  - build/agent212/t334/closure/parity_12_results.tsv
  - build/agent212/t334/closure/survey.md
  - build/agent212/t334/closure/shared_path_gates.diff
  - build/agent212/t334/closure/eris_times.tsv
  - build/agent212/t334/closure/eris_setup.out
  - build/agent212/t334/closure/mtime_readers.txt
  - build/agent212/t334/closure/mac_pairs_report.tsv
  - tests/lib/jobs.sh
  - docs/project/operations.md.lines-703-772 (lines 703-772 of docs/project/operations.md)
  - DECISIONS_HISTORY.md.lines-8598-8607 (lines 8598-8607 of DECISIONS_HISTORY.md: its INDEX entry "## Ruled 2026-10-28 (14z-211) — #334 item 1: all 35 settings timed on PILOT; #333's re-trace waits f")
  - DECISIONS_HISTORY.md.lines-8711-8723 (lines 8711-8723 of DECISIONS_HISTORY.md: its INDEX entry "## Ruled 2026-10-28 (14z-211) — #334 item 2: every one of the 62 knob-less gates takes a setting, ti")
