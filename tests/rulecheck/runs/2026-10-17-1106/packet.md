THE PACKET

Decision kind: expectation
Subject: #261: freeze audit_effect_class_rows section 4 (the type-6 fallback inventory) on merged-m23, its runs held to frozen game clocks, BUILD=%MERGED% in the registry (maintainer-ruled 2026-10-17)
Claim (the working agent's sentence): build/manifest/type6_fallback.toml freezes the six counts measured on build/m3b_merged31 (merged-m23, build/agent203/t261/fingerprint.log): 0, 0, 0, 0, 21_don_mash 270, 26_don_arcade_mash 1232, the same in run1.log, run2.log and freeze_counts.log; tests/expected/instr_gameclock/audit_effect_class_rows.tsv gains six merged clocks (freeze_clock3.log), and verify.log passes against both files; the drift-clock control reaches section 4's runs (ctl_drift.log 50 problems with BUILD, ctl_drift_nobuild.log 38 without); the breakpoint offset comes from the tree's huitzil.toml, whose beam_list_type6 thunk is byte-identical at the M23 freeze commit and at a36dd6d3 (huitzil_log.txt); the 14z-89 counts' moves are recorded unattributed as the maintainer ruled (DECISIONS_HISTORY.md, 2026-10-17). NOT TESTED: the cause of either move since 14z-89; the registry row's BUILD=%MERGED% under tests/run_all_emulator.sh (not run yet); a count change of one entry being caught beyond the exact compare in the gate's code (no control perturbs the frozen file).
Artifacts (read every one, in full):
  - build/manifest/type6_fallback.toml
  - tests/expected/instr_gameclock/audit_effect_class_rows.tsv
  - tests/audit_effect_class_rows.sh
  - build/agent203/t261/freeze.diff
  - build/agent203/t261/run1.log
  - build/agent203/t261/run2.log
  - build/agent203/t261/run3_oldclock.log
  - build/agent203/t261/run4_hui30_oldclock.log
  - build/agent203/t261/freeze_clock3.log
  - build/agent203/t261/freeze_counts.log
  - build/agent203/t261/verify.log
  - build/agent203/t261/ctl_drift.log
  - build/agent203/t261/ctl_drift_nobuild.log
  - build/agent203/t261/fingerprint.log
  - build/agent203/t261/huitzil_log.txt
  - tests/ci_emulator.tsv
  - tests/lib/instr_align.sh
  - DECISIONS_HISTORY.md
