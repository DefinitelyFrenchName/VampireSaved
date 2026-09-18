THE PACKET

Decision kind: expectation
Subject: 14z-168: freeze eight new #136 expectations (Dark Force modes and gauge, the Power-field readers, the block re-entry legacy control, the column shock, the move-parity attribution, the entrance draw, the pass overrun)
Claim (the working agent's sentence): Each of the eight expectation files was frozen with FREEZE=1 and then reproduced exactly by a second run without FREEZE (every row as frozen), with its declared must-fire control fired in-gate and its CONTROL mode exiting 1 (the logs); the defect and engine-difference rows (df_meter, column_shock, the ex/ours rows of df_modes, guard_reentry, pass_overrun) are frozen AS MEASURED so a fix re-freezes them deliberately; they rest on the #136 parity rigs with real cursor picks, the speed level pinned to 6 and the RNG pinned from 2363, non-debug read taps and field_trace samples on MAME; NOT tested or not established: the tenants' vs2 EX inputs (421+KK, 263+PP, 2623+PP) are my measured candidates, not confirmed canonical by the maintainer; the attribution's signatures name each root's class but do not by themselves prove each mechanism (DEFENSE-ROW rests on the 14z-145 root cause and the ruled defense rows, not a counterfactual build; SLOWDOWN on the pass counter, not on cycle counts); the idle measure is scheduler dispatch counts, not CPU cycles; the block re-entry legacy control uses Demitri only; the entrance draw covers six seeds; FBNeo was not run
Artifacts (read every one, in full):
  - tests/audit_df_modes.sh
  - tests/audit_df_meter.sh
  - tests/test_df_field_readers.sh
  - tests/audit_guard_reentry.sh
  - tests/audit_column_shock.sh
  - tests/audit_move_parity_attribution.sh
  - tests/audit_entrance_draw.sh
  - tests/audit_pass_overrun.sh
  - tests/expected/df_modes.tsv
  - tests/expected/df_meter.tsv
  - tests/expected/df_field_readers.tsv
  - tests/expected/guard_reentry.tsv
  - tests/expected/column_shock.tsv
  - tests/expected/move_parity_attribution.tsv
  - tests/expected/entrance_draw.tsv
  - tests/expected/pass_overrun.tsv
  - build/p136_14z168/df_modes_verify.log
  - build/p136_14z168/df_modes_ctl.log
  - build/p136_14z168/df_meter_verify.log
  - build/p136_14z168/df_meter_ctl.log
  - build/p136_14z168/guard_verify.log
  - build/p136_14z168/column_verify.log
  - build/p136_14z168/attr_verify.log
  - build/p136_14z168/attr_ctl.log
  - build/p136_14z168/entr_verify.log
  - build/p136_14z168/overrun_verify.log
  - tools/move_parity_attribution.py
  - tools/audit_df_field_readers.py
  - tests/expected/PROVENANCE.md.lines-117-124 (lines 117-124 of tests/expected/PROVENANCE.md)
  - DECISIONS_HISTORY.md.lines-30-57 (lines 30-57 of DECISIONS_HISTORY.md)
  - docs/game/engine_internals.md.lines-3895-3980 (lines 3895-3980 of docs/game/engine_internals.md)
