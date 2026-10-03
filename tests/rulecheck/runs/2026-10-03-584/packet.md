THE PACKET

Decision kind: expectation
Subject: 14z-189 merge of the #118 and #123-#129 analysis worktrees: four new gates' first frozen expectations and the ram.md adoptions
Claim (the working agent's sentence): Merge two finished background worktrees and freeze the expectations of the four gates they add. (1) #118: tests/audit_mizuumi_struct.sh (emulator tier, pristine vsavj on MAME, three replays) with its counts frozen in tests/expected/mizuumi_struct.tsv; on ERIS its verify run PASSes against the freeze (t118_gate_verify.log), and on the Mac, its first macOS run, it PASSes with every count as frozen and its in-gate control sides-swapped fires (audit_mizuumi_struct.log), and as a mode CONTROL=sides-swapped fails the gate (audit_mizuumi_struct_ctl.log). On that basis seven mizuumi player-struct names are adopted into docs/game/atlas/ram.md (+0x6D, +0x11D, +0x1B6, +0x380, +0x39F, +0x3F0, +0x18D) and two are written as refuted (+0x130, +0x15A) (merge.diff). (2) The analysis worktree's three ci_static gates, each a static census over the decrypted ROM views (ROMDIR only), frozen in their own scripts: test_quote_font_window (the emitter's base immediates, vsavj 0x3800 / vs2 0x4200, bank 0x2000; census 331 codes: 289 same, 1 elsewhere, 39 absent, 2 vs2-blank), test_roulette_tag_rows (vsavj's tag array rows 0x10-0x13 all read ALIAS; vs2's rows 0x10, 0x11 and 0x13 read OWN and 0x12 ALIAS), test_copy_flags (+0x3C3 code sites: vsavj 0, vs2 28, vh2 31) (test_quote_font_window.log, test_roulette_tag_rows.log, test_copy_flags.log). Each PASSes in the merged tree, its in-gate control fires, and its control mode fails the gate (test_*.log, test_*_ctl.log); they are registered in tests/ci_static.txt and the censuses and generated pages pass their gates (test_gate_descriptions.log, test_must_fire_census.log, test_gate_follows.log, test_gate_index_current.log, test_gate_coverage_current.log, test_annotations_current.log, test_expectation_provenance.log, test_controls_contract.log, test_header_defaults.log, test_doc_anchor_census.log, test_shell_portability.log, test_demand_after_trap.log). The 14z-116 "~330 glyph tiles" reading is corrected to 39 in the live carriers and marked in place in the archives (merge.diff). NOT TESTED: the adopted names' 14-replay figures (+0x6D 340 of 360 rises near the fighter's own HP drop, +0x1B6 463 of 484 increments near the opponent's) come from the worktree's scratch analysis (t118_fields_analysis.txt), not the gate, which freezes three replays' counts (48/44/2, 63/59/4); +0x380 being cleared at the loser's continue prompt (replay 37, f6881) is in scratch output only; the 69 written-but-untested offsets and the 8 unreached ones (t118_classification.tsv) are not adopted; nothing here runs on FBNeo or on a hacked build; the #123 poke A/B and emitter tap rigs and the #127/#129 scratch checks are not gated; the static gates assume the emitter immediates are the only source of the quote font base, which no emulator run here checks; no maintainer decision on #123-#129 is drawn — those are put to the maintainer separately.
Artifacts (read every one, in full):
  - build/rc189/merge/claim.txt
  - build/rc189/merge/merge.diff
  - build/rc189/merge/merge_stat.txt
  - build/rc189/merge/audit_mizuumi_struct.log
  - build/rc189/merge/audit_mizuumi_struct_ctl.log
  - build/rc189/merge/t118_gate_verify.log
  - build/rc189/merge/t118_gate_freeze.log
  - build/rc189/merge/t118_classification.tsv
  - build/rc189/merge/t118_fields_analysis.txt
  - build/rc189/merge/t118_analyze_more.txt
  - build/rc189/merge/t118_t37_streak.txt
  - build/rc189/merge/t118_timeover_specific.txt
  - build/rc189/merge/test_quote_font_window.log
  - build/rc189/merge/test_quote_font_window_ctl.log
  - build/rc189/merge/test_roulette_tag_rows.log
  - build/rc189/merge/test_roulette_tag_rows_ctl.log
  - build/rc189/merge/test_copy_flags.log
  - build/rc189/merge/test_copy_flags_ctl.log
  - build/rc189/merge/test_gate_descriptions.log
  - build/rc189/merge/test_must_fire_census.log
  - build/rc189/merge/test_gate_follows.log
  - build/rc189/merge/test_gate_index_current.log
  - build/rc189/merge/test_gate_coverage_current.log
  - build/rc189/merge/test_annotations_current.log
  - build/rc189/merge/test_expectation_provenance.log
  - build/rc189/merge/test_controls_contract.log
  - build/rc189/merge/test_header_defaults.log
  - build/rc189/merge/test_doc_anchor_census.log
  - build/rc189/merge/test_shell_portability.log
  - build/rc189/merge/test_demand_after_trap.log
  - tests/audit_mizuumi_struct.sh
  - tests/expected/mizuumi_struct.tsv
  - tests/test_quote_font_window.sh
  - tests/test_roulette_tag_rows.sh
  - tests/test_copy_flags.sh
