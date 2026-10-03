THE PACKET

Decision kind: expectation
Subject: M22 freeze: re-freezing the expectations the freeze moves (after runs 575-576)
Claim (the working agent's sentence): The M22 freeze (#194 then #195 applied, mark M21 -> M22) moves the frozen expectations listed in build/rc189/refreeze_index.tsv, each by the mechanism its row names: the 13 battery reds each PASS when re-run on the M21 builds (build/rc189/attr/m21_rerun_results.tsv); the moved addresses tools/attr_placement_moves.py paired are attributed to the merged placement shift with its planted control reported UNATTRIBUTED (build/rc189/tierreds/placement_attr.txt, placement_attr_plant.txt), and audit_reaction_class_live's three address moves, which that tool had mis-paired by position, are paired explicitly and attributed the same way (build/rc189/attr/rcl_placement_attr.txt, from the gate's full diff build/rc189/attr/rcl_full.diff), and  every NON-ADDRESS pair the tool printed is read by hand in build/rc189/non_address_review.txt as the build row, #194, #195 or placement; two instruments are edited, not re-frozen around: tools/audit_reaction_classes.py follows a jsr one level, under the new must-fire control thunk-copy-removed that fires in-gate and fails the gate as a mode (build/rc189/tierreds/test_reaction_classes3.log, test_reaction_classes_mode.log), after which test_reaction_classes differs from its frozen rows only in imm54 +0x20, rec17-cmp +44 and the build row; and tools/move_parity_attribution.py records the REACTION-51-OPEN rows as IDENT at the event level and the maintainer's read of the M22 captures, "M22 matches native" (DECISIONS_HISTORY.md lines 334-344, captures build/rc189/cosmo/cosmo_m22.png and cosmo_m21.png); so re-freezing each by the method its row names is correct. test_mister_prg_window's two address fields are paired explicitly and attributed the same way, first_addr exactly and max by preserved offset past a moved op, the weaker ok-HOLE form (build/rc189/tierreds/prg_window_attr.txt); the battery's other address rows are attributed in build/rc189/attr/placement_attr.txt. NOT TESTED: why audit_reaction_class_live's 0x44+0x4F write-run total goes 6 -> 5 (a relabel of 0x4F to 0x44 alone would keep it; one write run is lost, classed #194/#195, not traced, no control) and why its read-run counts move by one (26 -> 25, 8 -> 9; not traced); which of #195's executions account for test_mister_prg_window's blocks 7 -> 8, cyc +532 and rd_lo +477; whether attr_placement_moves.py's positional pairing hid a moved address in a gate whose diff it paired without a NON-ADDRESS line (an address pair it reads as ok is checked only against the placement, not against the row it should pair with); the re-freezes themselves and their verify runs, which follow this check; the class of test_poked_legs' new P2 row, read as the #202 rig's release poke from the gate's source, not measured.
Artifacts (read every one, in full):
  - build/rc189/refreeze_index.tsv
  - build/rc189/attr/battery_reds.txt
  - build/rc189/attr/m21_rerun_results.tsv
  - build/rc189/attr/placement_attr.txt
  - build/rc189/tierreds/placement_attr.txt
  - build/rc189/tierreds/placement_attr_plant.txt
  - build/rc189/attr/rcl_full.diff
  - build/rc189/attr/rcl_address_pairs.log
  - build/rc189/attr/rcl_placement_attr.txt
  - build/rc189/tierreds/prg_window_pairs.log
  - build/rc189/tierreds/prg_window_attr.txt
  - build/rc189/non_address_review.txt
  - build/rc189/tierreds/test_reaction_classes3.log
  - build/rc189/tierreds/test_reaction_classes_mode.log
  - build/rc189/tierreds/instrument_edits.diff
  - build/rc189/tierreds/weak_diff.txt
  - build/rc189/tierreds/test_manifest_merge.log
  - build/rc189/tierreds/test_rule5_census.log
  - build/rc189/tierreds/test_poked_legs.log
  - build/rc189/attr/bases_m22.txt
  - build/emu_freeze_m22_mister/test_mister_prg_window.log
  - DECISIONS_HISTORY.md.lines-334-344 (lines 334-344 of DECISIONS_HISTORY.md)
  - build/rc189/cosmo/cosmo_m22.png
  - build/rc189/cosmo/cosmo_m21.png
