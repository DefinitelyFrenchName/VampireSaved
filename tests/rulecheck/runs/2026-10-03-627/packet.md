THE PACKET

Decision kind: expectation
Subject: 14z-189: the minimum air-attack height corrected (36 to 24; Lilith to Lei-Lei), locked by tests/test_air_attack_height.sh
Claim (the working agent's sentence): Correct the minimum air-attack height from 36 to 24, and its characters from "Zabel, Lilith and Jedah" to Zabel, Lei-Lei and Jedah, and lock both with a new static gate (after rule-checker runs 2026-10-03-621 to -626, each VIOLATED Q1 Q4 and resolved in fix.diff's ledger): vsavj's table at PRG:0x0BE23A, which the routine at PRG:0x027B80 loads with movea.l #$0BE23A,a0 (PRG:0x027B92; test_air_attack_height.log's checks 'the instruction' and 'its only reference in the opcode view'), indexes by fighter byte +0x382 at word stride — capstone (imported and used by tools/audit_marionette_cost.py, capstone_use.txt) decodes the eight instructions after the load as move.w $14(a6),d0 / sub.w $3a(a6),d0 / move.b $382(a6),d1 / ext.w d1 / add.w d1,d1 / move.w (a0,d1.w),d1 / cmp.w d1,d0 / bcs.b, frozen by the gate's check 'the index: char id +0x382 at word stride' — and its 32 rows read 0x0018 = 24 for 0x04, 0x0D, 0x0F and their +0x10 mirrors 0x14, 0x1D, 0x1F, and 0 for the other 26, the tenants' 0x10/0x11/0x13 included (its checks 'non-zero rows' and 'zero rows'). +0x382 is the character id per docs/game/atlas/ram.md (ram_382.txt), and ids 0x04, 0x0D, 0x0F are Zabel, Lei-Lei and Jedah, Lilith being 0x0E, per docs/game/atlas/character_tables.md (char_ids.txt); how 14z-121 obtained "36" is not recorded (the explanation offered for it in run 623's packet, a hex 0x24 misread, rested on no artifact and is withdrawn from every carrier, the gate's own MUST-FIRE line included, which now calls 36 "the 14z-121 figure"), and its "Lilith" was the wrong name for 0x0D. The new tests/test_air_attack_height.sh (ci_static, ROMDIR only, decrypt_cache) takes the address from the instruction's immediate, checks it is the only reference, freezes the index sequence and the 32 rows; its two must-fire controls fire in-gate and, run as modes, fail the gate — row-misread (row 0x04 rewritten to 0x0024 in a copy of the data view) and index-changed (add.w d1,d1 at PRG:0x027BA6 replaced by a nop in a copy of the opcode view) (test_air_attack_height.log, test_air_attack_height_ctl_row-misread.log, test_air_attack_height_ctl_index-changed.log). The fix (fix.diff, over the whole tracked tree including build/manifest/): build/manifest/bank_map.toml's gap_be23a note (the source, one line) and docs/game/engine_internals.md say 24 and Zabel, Lei-Lei and Jedah, and that how 36 was obtained is not recorded; the three tenant tables docs/project/tables/chars/{donovan,huitzil,pyron}.{json,md} are regenerated from the edited note by tools/charmap_gen.py and tools/charmap_md.py (the command test_charmap_current prints), which then PASSes with its controls firing and the out-of-tree page hashes unchanged (test_charmap_current.log); STATE_HISTORY.md, an archive, keeps its text with both corrections marked in place (a note under the 14z-121 header, an inline CORRECTED on the table row); the retraction grep (retraction_grep.py, run on the final tree after run 626's resolution, over every tracked text file, rule-checker records under tests/rulecheck/ included and classified RECORD) looks for both old claims and the withdrawn explanation by pattern, not fixed string — a 36 near the table, its address or the three names; 0x0D within 20 characters of Lilith with words allowed between, or Zabel, Lilith and Jedah within 50; decimal, misread or misreading within 40 characters of hex, 0x24 or 0x0024 (word-bounded, either order) or 0x24 = 36, on a line that also names the table subject (36, height, air-attack, be23a) — and classifies each hit: 3 ARCHIVE-MARKED (STATE_HISTORY.md), 5 QUOTED (the old text named as 14z-121's inside a correction), the RECORD lines, 12 READ and 0 LIVE; a READ hit is an explicit entry in the script (file, line, a substring that must still be on that line, and why it is not a carrier — correct Lei-Lei 0x0D / Lilith 0x0E statements, and tools/audit_poked_legs.py:60 with #218's three index and page rows: a different defect, a shifted id-to-name map, filed as #218, not fixed here); each of its three patterns carries its own control, a line planted in a copy and worded unlike the old text (refused below 36 pixels; the table row for id 0x0D is the one Lilith uses; for the height table the 14z-121 author took the hex word for a decimal count), each found LIVE by its own pattern (CONTROL FIRED x3, retraction_grep.txt). The gate is registered (tests/ci_static.txt, tests/gate_index.tsv family character-data, tests/expected/gate_descriptions.tsv and must_fire_census.tsv) and the generated pages regenerated; the census, page and ticket gates PASS (test_tickets.log, test_state_open_lists.log, test_gate_*.log, test_must_fire_census.log, test_annotations_current.log, test_gotchas_index_current.log, test_controls_contract.log, test_header_defaults.log, test_doc_anchor_census.log, test_shell_portability.log, test_demand_after_trap.log, test_docshape.log, test_expectation_provenance.log), as do the static and portable gates that read bank_map.toml by the census in bank_map_readers.txt (test_tables_current.log, test_shared_writes.log, test_capture_kf_ownership.log, test_df_startup_provenance.log, test_annotations_current.log). NOT TESTED: a carrier of either old claim, or of the withdrawn hex explanation, worded beyond the grep's three patterns — no pattern grep can prove every wording absent; that +0x382 holds the character id and that the ids name those characters — this gate does not re-measure them, it rests on ram.md's row (verified on both emulators there) and character_tables.md's table (pinned there by scripted picks), and no control here can perturb what the game stores at +0x382; the three emulator-tier gates that also read bank_map.toml (test_hui_ladder, test_pyron_blink, test_pyron_ladder) and a rebuild from the edited manifest — the edit changes only a note string, and no build tool's use of that string was checked; what the height means in play (the doc states the code's rule, not a measured jump); vs2's and vh2's tables (only #162's census row 0x10 is cited, not gated here).
Artifacts (read every one, in full):
  - build/rc189/h4/claim.txt
  - build/rc189/h4/fix.diff
  - build/rc189/h4/retraction_grep.py
  - build/rc189/h4/retraction_grep.txt
  - build/rc189/h4/ram_382.txt
  - build/rc189/h4/char_ids.txt
  - build/rc189/h4/capstone_use.txt
  - build/rc189/h4/bank_map_readers.txt
  - build/rc189/h4/gen_donovan.log
  - build/rc189/h4/gen_huitzil.log
  - build/rc189/h4/gen_pyron.log
  - build/rc189/h4/md_donovan.log
  - build/rc189/h4/md_huitzil.log
  - build/rc189/h4/md_pyron.log
  - build/rc189/h4/test_air_attack_height.log
  - build/rc189/h4/test_air_attack_height_ctl_index-changed.log
  - build/rc189/h4/test_air_attack_height_ctl_row-misread.log
  - build/rc189/h4/test_annotations_current.log
  - build/rc189/h4/test_capture_kf_ownership.log
  - build/rc189/h4/test_charmap_current.log
  - build/rc189/h4/test_controls_contract.log
  - build/rc189/h4/test_demand_after_trap.log
  - build/rc189/h4/test_df_startup_provenance.log
  - build/rc189/h4/test_doc_anchor_census.log
  - build/rc189/h4/test_docshape.log
  - build/rc189/h4/test_expectation_provenance.log
  - build/rc189/h4/test_gate_coverage_current.log
  - build/rc189/h4/test_gate_descriptions.log
  - build/rc189/h4/test_gate_follows.log
  - build/rc189/h4/test_gate_index_current.log
  - build/rc189/h4/test_gotchas_index_current.log
  - build/rc189/h4/test_header_defaults.log
  - build/rc189/h4/test_must_fire_census.log
  - build/rc189/h4/test_shared_writes.log
  - build/rc189/h4/test_shell_portability.log
  - build/rc189/h4/test_state_open_lists.log
  - build/rc189/h4/test_tables_current.log
  - build/rc189/h4/test_tickets.log
