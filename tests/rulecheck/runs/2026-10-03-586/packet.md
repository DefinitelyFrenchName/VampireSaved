THE PACKET

Decision kind: expectation
Subject: 14z-189 merge of the #118 and #123-#129 analysis worktrees: four new gates' first frozen expectations and the ram.md adoptions (after runs 584-585)
Claim (the working agent's sentence): Merge two finished background worktrees and freeze the expectations of the four gates they add (after runs 2026-10-03-584 and -585, resolved). (1) #118: tests/audit_mizuumi_struct.sh (emulator tier, pristine vsavj on MAME: three replays plus two write-tap legs and a poked leg) with its counts, writer PCs and values frozen in tests/expected/mizuumi_struct.tsv (frozen on ERIS, t118_freeze_eris.log, then re-frozen on the Mac after run 585 adding exactly one row, poke_timeover_readback 300/300 — freeze.diff, freeze_mac.log); it PASSes with every count as frozen on the Mac in the merged tree (audit_mizuumi_struct.log, its first line naming the host Darwin arm64) and on ERIS with the same gate and freeze (eris_v585_verify.log, Linux x86_64); both controls fire in-gate — sides-swapped fails 9 checks, C1 C2 C5 among them, and refutation-pokes fires only when the +0x15A refutation fails AND +0x15A reads the poked 1 on 300 of the 300 frames of its poked range AND +0x130 reads back 3000 of 3000 poked values — and each fails the gate as a mode on both hosts (ctl_sides-swapped.log, ctl_refutation-pokes.log, eris_v585_ctl_*.log). On that basis docs/game/atlas/ram.md adopts five mizuumi names (+0x11D, +0x1B6, +0x380, +0x39F, +0x3F0) and the +0x05 match-end values (winner 0x08, loser 0x0A at 03's time-over and 0x0C at 37's KO), records +0x130 and +0x18D with their names not adopted, writes +0x15A as refuted, and adds a cross-check note to the known +0x6C..+0x6F row; every figure and writer PC in those rows is one the gate freezes (merge.diff, tests/expected/mizuumi_struct.tsv, t118_classification.tsv). (2) The analysis worktree's three ci_static gates, static censuses over the decrypted ROM views (ROMDIR only), frozen in their scripts: test_quote_font_window (emitter base immediates vsavj 0x3800 / vs2 0x4200, bank 0x2000; census 331 codes: 289 same, 1 elsewhere, 39 absent, 2 vs2-blank), test_roulette_tag_rows (vsavj's rows 0x10-0x13 all read ALIAS; vs2's 0x10, 0x11, 0x13 read OWN and 0x12 ALIAS), test_copy_flags (+0x3C3 code sites vsavj 0, vs2 28, vh2 31); each PASSes in the merged tree (test_quote_font_window.log, test_roulette_tag_rows.log, test_copy_flags.log) and its control mode fails the gate (test_*_ctl.log); registered in tests/ci_static.txt; the census and page gates PASS (test_gate_descriptions.log, test_must_fire_census.log, test_gate_follows.log, test_gate_index_current.log, test_gate_coverage_current.log, test_annotations_current.log, test_expectation_provenance.log, test_controls_contract.log, test_header_defaults.log, test_doc_anchor_census.log, test_shell_portability.log, test_demand_after_trap.log, test_replay_stage_census.log, test_state_open_lists.log, test_tickets.log), and the palette gate whose header gained a note PASSes on the M22 build (test_ladder_tenant_vs_palette.log). (3) The 14z-116 "~330 glyph tiles" reading is corrected to 39 in the live carriers and marked in place in the archives, and the maintainer's 2026-10-03 rulings on #123-#129 and #145 are recorded verbatim in DECISIONS_HISTORY.md with the ticket index updated (merge.diff). NOT TESTED: the 67 written-but-untested offsets and the 8 unreached ones are not adopted (t118_classification.tsv); +0x130's per-fighter offset (-16, -26 or -27) is measured, not explained; +0x18D's 0 on replay 37's KO win is frozen, not explained; nothing here runs on FBNeo or on a hacked build; the #123 poke A/B and emitter tap rigs and the #127/#129 scratch checks are not gated; the static gates assume the emitter immediates are the only source of the quote font base, which no emulator run here checks; the #125 portrait and reveal defects are recorded as reported, not measured; that the map tag is drawn from row id of 0x26752A ("no code folds it") and that its mini-art comes from the same row rest on the code path and one ungated pool dump on replay 111 — the maintainer reads the portrait beside CPU Phobos's tag as "neither Buletta nor Phobos", recorded beside that claim (merge.diff), and test_roulette_tag_rows' unalias-row control proves only that the tool reads the array in the image, not that the map draws it.
Artifacts (read every one, in full):
  - build/rc189/merge3/claim.txt
  - build/rc189/merge3/merge.diff
  - build/rc189/merge3/freeze.diff
  - build/rc189/merge3/freeze_mac.log
  - build/rc189/merge3/audit_mizuumi_struct.log
  - build/rc189/merge3/ctl_sides-swapped.log
  - build/rc189/merge3/ctl_refutation-pokes.log
  - build/rc189/merge3/eris_v585_verify.log
  - build/rc189/merge3/eris_v585_ctl_sides-swapped.log
  - build/rc189/merge3/eris_v585_ctl_refutation-pokes.log
  - build/rc189/merge3/t118_freeze_eris.log
  - build/rc189/merge3/t118_classification.tsv
  - build/rc189/merge3/test_ladder_tenant_vs_palette.log
  - build/rc189/merge3/test_quote_font_window.log
  - build/rc189/merge3/test_quote_font_window_ctl.log
  - build/rc189/merge3/test_roulette_tag_rows.log
  - build/rc189/merge3/test_roulette_tag_rows_ctl.log
  - build/rc189/merge3/test_copy_flags.log
  - build/rc189/merge3/test_copy_flags_ctl.log
  - build/rc189/merge3/test_gate_descriptions.log
  - build/rc189/merge3/test_must_fire_census.log
  - build/rc189/merge3/test_gate_follows.log
  - build/rc189/merge3/test_gate_index_current.log
  - build/rc189/merge3/test_gate_coverage_current.log
  - build/rc189/merge3/test_annotations_current.log
  - build/rc189/merge3/test_expectation_provenance.log
  - build/rc189/merge3/test_controls_contract.log
  - build/rc189/merge3/test_header_defaults.log
  - build/rc189/merge3/test_doc_anchor_census.log
  - build/rc189/merge3/test_shell_portability.log
  - build/rc189/merge3/test_demand_after_trap.log
  - build/rc189/merge3/test_replay_stage_census.log
  - build/rc189/merge3/test_state_open_lists.log
  - build/rc189/merge3/test_tickets.log
  - tests/audit_mizuumi_struct.sh
  - tests/expected/mizuumi_struct.tsv
  - tests/test_quote_font_window.sh
  - tests/test_roulette_tag_rows.sh
  - tests/test_copy_flags.sh
