THE PACKET

Decision kind: recommendation
Subject: close #334 as done (14z-212): the job knobs on PILOT and under load, the 61 knob-less pooled gates timed on ERIS, and each shown to FAIL when its pool loses a run
Claim (the working agent's sentence): CLAIM: close #334 as done (14z-212): closing_comment.md and ticket_row_334.tsv state the resolution; #334's gate edits, the leg checks of audit_type_writes and audit_id_writers, and tests/audit_pool_drop.sh land in this session's commit with #333's. Both of #321's survey gaps are measured. It rests on:
1. ITEM 1 (the knobs on PILOT and under load): pilot_knobs.tsv (14z-211: every setting at its default and a higher value on PILOT, verdicts equal; audit_guard_cancels FAIL at both there, its out-of-tree table absent) and guard_cancels_mac.tsv with guard_cancels_mac_j2.log and _j6.log (14z-212: on the Mac, where the table exists, PASS at 2 and at 6, the logs the same but for temp paths and leg time); mac_parity_under_load.txt with parity_default_results.tsv and parity_12_results.tsv (test_mame_parity beside a strict static tier on the Mac: 596 s at the default 8 and 506 s at 12, PASS both) and mac_load_tier_fails.txt (that tier NOT GREEN, five FAILs of the mid-session tree's content, none a timing).
2. ITEM 2 (the knob-less gates): survey.md (62 gates, two with a shared path); shared_path_gates.diff; eris_times.tsv with eris_setup.out (each of 61 edited gates alone on ERIS, before at 33f85438 and after at 6829e446: 7,648 s -> 4,163 s, every verdict PASS both sides); mtime_readers.txt; mac_pairs_report.tsv (60 gates at one job and four on the Mac, outputs identical); changed_after_6829e446.txt (three of the 61 scripts changed after the timed tree, audit_phase_mode_cost, audit_type_writes and audit_id_writers, plus tests/lib/jobs.sh's hook; no tool any of the 61 names); tests/lib/jobs.sh.
3. EACH CAN STILL FAIL WHEN THE POOL LOSES A RUN: pool_drop_report.tsv (each of the 61 on a Mac snapshot, as is and with the first pooled run of each shell dropped; pass 1: 58 separate, audit_type_writes and audit_id_writers PASS with a run lost, audit_empty_tiles not runnable without its argument; pass 2, after the two gates name their legs and with audit_empty_tiles's argument: all three separate); tests/audit_type_writes.sh and tests/audit_id_writers.sh (the leg checks); tests/audit_pool_drop.sh (the check kept, with its hook-off control; its hook's code is the scratch hook's, comments aside); the gotcha docs/project/gotchas.md lines 7792-7801.
4. THE RULINGS: DECISIONS_HISTORY.md lines 8599-8610 ("All 35 on PILOT", with the picked option's own text), 8714-8726 ("All 62") and 8821-8835 ("Ondemand, new 'harness:' (Recommended)"); the record docs/project/operations.md lines 703-783.
NOT TESTED: test_mame_parity at 12 under a full load for its whole run; audit_id_writers at one job against four on the Mac; the 61 gates' timings on PILOT and on the Mac under load; the timings are single runs, not repeated; the three scripts changed after 6829e446 not re-timed on ERIS; audit_guard_cancels's Mac seconds taken beside the pool-drop runs, not comparable with PILOT's; a run lost after it started (a crash mid-run, a truncated trace) — the pool-drop check drops only each shell's first run; tests/audit_pool_drop.sh itself run only on subsets (audit_df_gold, audit_empty_tiles, audit_type_writes; its hook-off mode on audit_df_gold), the 61 measured by the scratch runner it was written from.
Artifacts (read every one, in full):
  - build/agent212/t334/closure/closing_comment.md
  - build/agent212/t334/closure/ticket_row_334.tsv
  - build/agent212/t334/closure/pilot_knobs.tsv
  - build/agent212/t334/closure/guard_cancels_mac.tsv
  - build/agent212/t334/closure/guard_cancels_mac_j2.log
  - build/agent212/t334/closure/guard_cancels_mac_j6.log
  - build/agent212/t334/closure/mac_parity_under_load.txt
  - build/agent212/t334/closure/parity_default_results.tsv
  - build/agent212/t334/closure/parity_12_results.tsv
  - build/agent212/t334/closure/mac_load_tier_fails.txt
  - build/agent212/t334/closure/survey.md
  - build/agent212/t334/closure/shared_path_gates.diff
  - build/agent212/t334/closure/eris_times.tsv
  - build/agent212/t334/closure/eris_setup.out
  - build/agent212/t334/closure/mtime_readers.txt
  - build/agent212/t334/closure/mac_pairs_report.tsv
  - build/agent212/t334/closure/changed_after_6829e446.txt
  - tests/lib/jobs.sh
  - build/agent212/t334/closure/pool_drop_report.tsv
  - tests/audit_type_writes.sh
  - tests/audit_id_writers.sh
  - tests/audit_pool_drop.sh
  - docs/project/gotchas.md.lines-7792-7801 (lines 7792-7801 of docs/project/gotchas.md)
  - DECISIONS_HISTORY.md.lines-8599-8610 (lines 8599-8610 of DECISIONS_HISTORY.md: its INDEX entry "## Ruled 2026-10-28 (14z-211) — #334 item 1: all 35 settings timed on PILOT; #333's re-trace waits f")
  - DECISIONS_HISTORY.md.lines-8714-8726 (lines 8714-8726 of DECISIONS_HISTORY.md: its INDEX entry "## Ruled 2026-10-28 (14z-211) — #334 item 2: every one of the 62 knob-less gates takes a setting, ti")
  - DECISIONS_HISTORY.md.lines-8821-8835 (lines 8821-8835 of DECISIONS_HISTORY.md: its INDEX entry "## Ruled 2026-10-29 (14z-212) — #334: the pool-drop audit is an ondemand gate, under a new reason ke")
  - docs/project/operations.md.lines-703-783 (lines 703-783 of docs/project/operations.md)
