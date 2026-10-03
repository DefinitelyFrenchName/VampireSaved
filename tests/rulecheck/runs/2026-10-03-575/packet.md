THE PACKET

Decision kind: expectation
Subject: M22 freeze: re-freezing the expectations the freeze moves
Claim (the working agent's sentence): The M22 freeze (#194 then #195 applied, mark M21 -> M22) moves the frozen expectations listed in build/rc189/refreeze_index.tsv, and each moves only by the mechanism its row names: every one of the 13 battery reds PASSES when re-run on the M21 builds (build/rc189/attr/m21_rerun_results.tsv), every moved address in the static pins and the battery's address rows is attributed to the merged placement shift by tools/attr_placement_moves.py with its planted control reported UNATTRIBUTED (build/rc189/tierreds/placement_attr.txt, placement_attr_plant.txt, build/rc189/attr/placement_attr.txt), the remaining moved rows are the build row, #194's Cosmo Disruption events turning IDENT to native, or #195's hooks, as build/rc189/attr/battery_reds.txt and the index cite, and two instruments are edited, not re-frozen around: tools/audit_reaction_classes.py now follows a jsr one level so the copy displaced into #195's thunk is still read as the stager route (test_reaction_classes then differs from its frozen rows only in imm54 +0x20, rec17-cmp +44 and the build row, build/rc189/tierreds/test_reaction_classes2.log), and tools/move_parity_attribution.py marks REACTION-51-OPEN fixed (build/rc189/tierreds/instrument_edits.diff); so re-freezing each by the method its row names is correct. NOT TESTED: why audit_reaction_class_live's 0x44+0x4F run total goes 6 -> 5 and its read runs move by one (classed #194/#195, not traced); which of #195's executions account for test_mister_prg_window's blocks 7 -> 8, cyc +532 and rd_lo +477; the re-freezes themselves and their verify runs, which follow this check; the class of test_poked_legs' new P2 row, read as the #202 rig's release poke from the gate's source, not measured.
Artifacts (read every one, in full):
  - build/rc189/refreeze_index.tsv
  - build/rc189/attr/battery_reds.txt
  - build/rc189/attr/m21_rerun_results.tsv
  - build/rc189/attr/placement_attr.txt
  - build/rc189/tierreds/placement_attr.txt
  - build/rc189/tierreds/placement_attr_plant.txt
  - build/rc189/tierreds/test_reaction_classes2.log
  - build/rc189/tierreds/instrument_edits.diff
  - build/rc189/tierreds/weak_diff.txt
  - build/rc189/tierreds/test_manifest_merge.log
  - build/rc189/tierreds/test_rule5_census.log
  - build/rc189/tierreds/test_poked_legs.log
  - build/rc189/attr/bases_m22.txt
  - build/emu_freeze_m22_mister/test_mister_prg_window.log
