THE PACKET

Decision kind: recommendation
Subject: close #340 as done (14z-214), after run 2026-10-30-1441: the emulator runner's tier classifier counts a gate that reads tests/ci_emulator.tsv (audit_pool_drop), so its registry check reads 240 of 240 with no dead row; gated both ways in test_emulator_runner section 3; the class recorded as a gotcha
Claim (the working agent's sentence): CLAIM: close #340 as done (14z-214). The closing comment closing_comment.md and the row ticket_row_340.tsv state the resolution. The ticket (issue_340.md) reported that every strict emulator run read NOT GREEN because the emulator runner's tier classifier did not count tests/audit_pool_drop.sh as emulator-tier and called its registry row a DEAD ROW. It rests on:
1. THE FIX: fix.diff (0a1b9233..550958ad, the 14z-213 close commit): both runners' EMU pattern gains tests/ci_emulator\.tsv; tests/test_emulator_runner.sh section 3 gains a registry-reading stub that must not be DEAD and the same stub without that line that must be.
2. BEFORE: before_fix_mac_mp.out (14z-213, the Mac): 239 emulator-tier gates; 240 registered; 1 DEAD ROW: audit_pool_drop; NOT GREEN with PASS 8 FAIL 0.
3. AFTER, at 550958ad (14z-214, a measurer's commands; each log opens with the identity header identity_14z214.txt wrote: HEAD 550958ad, host MacBook-Pro-2.local Darwin arm64, UTC time, tracked changes, the only one under tests/ being tests/rulecheck/ledger.tsv, which the rule-checker's record wrote and neither runner reads; untracked_timing.txt: the one untracked tests/*.sh this session adds, tests/audit_sas_penguin_count.sh, was created after every after-fix log was written, and is the only untracked tests/*.sh): tier_diff.py and tier_diff.out (the runner's EMU pattern read from each commit by git show, applied to the same checkout with the runner's own skip rules: old 239, new 240, added audit_pool_drop, removed none, no dead or unregistered under the new pattern); emu_dryrun_ondemand_head.log (the runner itself, --scope ondemand --strict --dry-run --only audit_pool_drop: 240 emulator-tier gates; 240 registered; ok: every emulator-tier gate has exactly one registry row); emu_dryrun_head.log (the same at --scope all selected nothing, since the row is ondemand: shown so the ondemand run is not read as a choice of convenience); test_emulator_runner.head.log (the blobs it ran, 81a12e90 and 5d4b1f3a, then PASS, both new cases ok).
4. ON PILOT (14z-213): pilot_r11/ (HEAD 7172e62d, the gate's blob 81a12e90, which equals 550958ad's per the measurer's C2; PASS; 17 controls HONOURED; SAFE) and controls_concurrent_rows.txt (tests/controls_concurrent.txt's rows naming pilot:7172e62d).
5. WHAT WAS LEARNED / WENT WRONG: records.diff, the new docs/project/gotchas.md entry the row's learned and wrong columns cite, and the row itself.
NOT TESTED: the untracked listing in untracked_timing.txt was taken after the logs, not at their time; that no other untracked tests/*.sh existed while they ran rests on it naming only that gate.  no full strict emulator run was made at 550958ad; the registry check is the same block in a dry run and a full run (it is not inside the runner's DRY branch), but that a full strict run now reads GREEN is inferred, not observed. The static runner's side rests on the 14z-213 close tier's "ok: every emulator-free gate is registered" line (build/agent213/close/steps/tier.log), not re-run. That no other gate names tests/ci_emulator.tsv without a wrapper rests on tier_diff.py, which re-implements the runner's loop rather than calling it. The PILOT run was on 14z-213's working tree (commit-tree 7172e62d), not on 550958ad itself; equality rests on the gate's blob.
Artifacts (read every one, in full):
  - build/agent214/t340/closure/closing_comment.md
  - build/agent214/t340/closure/ticket_row_340.tsv
  - build/agent214/t340/closure/issue_340.md
  - build/agent214/t340/closure/fix.diff
  - build/agent214/t340/closure/before_fix_mac_mp.out
  - build/agent214/t340/closure/identity_14z214.txt
  - build/agent214/t340/closure/tier_diff.py
  - build/agent214/t340/closure/tier_diff.out
  - build/agent214/t340/closure/emu_dryrun_ondemand_head.log
  - build/agent214/t340/closure/emu_dryrun_head.log
  - build/agent214/t340/closure/test_emulator_runner.head.log
  - build/agent214/t340/closure/untracked_timing.txt
  - build/agent214/t340/closure/pilot_r11/t213r11.out
  - build/agent214/t340/closure/pilot_r11/t213r11_static/classes.tsv
  - build/agent214/t340/closure/controls_concurrent_rows.txt
  - build/agent214/t340/closure/records.diff
  - tests/run_all_emulator.sh.lines-820-900 (lines 820-900 of tests/run_all_emulator.sh)
