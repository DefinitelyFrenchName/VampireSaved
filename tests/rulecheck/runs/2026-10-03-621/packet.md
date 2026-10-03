THE PACKET

Decision kind: expectation
Subject: 14z-189: the minimum air-attack height corrected from 36 to 24, locked by tests/test_air_attack_height.sh
Claim (the working agent's sentence): Correct the minimum air-attack height from 36 to 24 and lock it with a new static gate: vsavj's table at PRG:0x0BE23A, which the routine at PRG:0x027B80 loads with movea.l #$0BE23A,a0 (PRG:0x027B92; test_air_attack_height.log's checks 'the instruction' and 'its only reference in the opcode view'), reads 0x0018 = 24 for rows 0x04, 0x0D, 0x0F and 0x14 and 0 for the other 20 of rows 0x00-0x17, the tenants' 0x10/0x11/0x13 included (its checks 'non-zero rows' and 'zero rows'); the 14z-121 "36" is the hex 0x24 read as decimal. The new tests/test_air_attack_height.sh (ci_static, ROMDIR only, decrypt_cache) takes the address from the instruction's immediate, checks it is the only reference, and freezes the rows; its must-fire control row-misread (row 0x04 rewritten to 0x0024 in a copy of the data view) fires in-gate and, run as a mode, fails the gate (test_air_attack_height.log, test_air_attack_height_ctl_row-misread.log). The fix: build/manifest/bank_map.toml's gap_be23a note (the source) and docs/game/engine_internals.md say 24; the three tenant tables docs/project/tables/chars/{donovan,huitzil,pyron}.{json,md} are regenerated from the edited note by tools/charmap_gen.py and tools/charmap_md.py (the command test_charmap_current prints), which then PASSes with its controls firing and the out-of-tree page hashes unchanged (test_charmap_current.log); STATE_HISTORY.md, an archive, keeps its text with the correction marked in place (a note under the 14z-121 header, an inline CORRECTED on the table row); a re-grep of the tracked tree finds the claim only in those two marked archive lines and 0 live carriers (retraction_grep.txt). The gate is registered (tests/ci_static.txt, tests/gate_index.tsv family character-data, tests/expected/gate_descriptions.tsv and must_fire_census.tsv) and the generated pages regenerated; the census and page gates PASS (test_gate_*.log, test_must_fire_census.log, test_annotations_current.log, test_gotchas_index_current.log, test_controls_contract.log, test_header_defaults.log, test_doc_anchor_census.log, test_shell_portability.log, test_demand_after_trap.log, test_docshape.log, test_expectation_provenance.log), as do the static gates that read bank_map.toml (test_tables_current.log, test_shared_writes.log, test_capture_kf_ownership.log, test_df_startup_provenance.log). NOT TESTED: the three emulator-tier gates that also read bank_map.toml (test_hui_ladder, test_pyron_blink, test_pyron_ladder) and a rebuild from the edited manifest — the edit changes only a note string, and no build tool's use of that string was checked; the table rows beyond 0x17; what the height means in play (the doc states the code's rule, not a measured jump); vs2's and vh2's tables (only #162's census row 0x10 is cited, not gated here).
Artifacts (read every one, in full):
  - build/rc189/h1/claim.txt
  - build/rc189/h1/fix.diff
  - build/rc189/h1/retraction_grep.txt
  - build/rc189/h1/gen_donovan.log
  - build/rc189/h1/gen_huitzil.log
  - build/rc189/h1/gen_pyron.log
  - build/rc189/h1/md_donovan.log
  - build/rc189/h1/md_huitzil.log
  - build/rc189/h1/md_pyron.log
  - build/rc189/h1/test_air_attack_height.log
  - build/rc189/h1/test_air_attack_height_ctl_row-misread.log
  - build/rc189/h1/test_annotations_current.log
  - build/rc189/h1/test_capture_kf_ownership.log
  - build/rc189/h1/test_charmap_current.log
  - build/rc189/h1/test_controls_contract.log
  - build/rc189/h1/test_demand_after_trap.log
  - build/rc189/h1/test_df_startup_provenance.log
  - build/rc189/h1/test_doc_anchor_census.log
  - build/rc189/h1/test_docshape.log
  - build/rc189/h1/test_expectation_provenance.log
  - build/rc189/h1/test_gate_coverage_current.log
  - build/rc189/h1/test_gate_descriptions.log
  - build/rc189/h1/test_gate_follows.log
  - build/rc189/h1/test_gate_index_current.log
  - build/rc189/h1/test_gotchas_index_current.log
  - build/rc189/h1/test_header_defaults.log
  - build/rc189/h1/test_must_fire_census.log
  - build/rc189/h1/test_shared_writes.log
  - build/rc189/h1/test_shell_portability.log
  - build/rc189/h1/test_tables_current.log
