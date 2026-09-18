THE PACKET

Decision kind: expectation
Subject: 14z-169: the analysis before the ruled #136 fixes - reaction_classes, reaction_class_live, defense_row_reads and crouch_flag new; df_modes re-frozen with the Power-flag column
Claim (the working agent's sentence): Five expectation files were frozen with FREEZE=1 and reproduced exactly by a run without FREEZE, every declared must-fire control fired in-gate and every CONTROL mode exited 1 (the logs named): reaction_classes (new, static: the stager and reaction-table routes of classes 06 07 08 38 39 48 4E 52 read from the decrypted opcode and data views of vsavj and vsav2 and from merged-m18's verify_op.bin, the legacy record census by class, every constant write to +0x54 and constant compare against +0x54 and the record's +0x17, the per-class tables), reaction_class_live (new: every write and read of both fighters' +0x54 over the 88 suite replays on pristine vsavj and the 30 #136 naming parts on ours and on vsav2 — no write of 0x38), defense_row_reads (new: the index each defense-curve and rally-threshold read took, by the victim's hitbox base +0x60, over the 12 victim parts, the 30 attacker parts and the 88 suite replays on ours and the 88 on pristine vsavj — always the victim's own id), crouch_flag (new: P1's +0x121 against a scripted Down on vsav2 and ours) and df_modes (re-frozen with a pow column: the frames vs2's Power flag +0x1C3 is held per leg — set on every vsav2 P+K leg, never on Change or on the tenants' vs2 EX); NOT tested or not established: every conclusion is bounded by the paths these corpora run (a 0x38 write into +0x54 or a non-own defense read on an unrun path is not excluded); the static census sees constant writes and compares and absolute table addresses only, so register-form writers and compares are covered only where a corpus runs, and its record census counts records the anim walk reaches, not true records; +0x121 is shown to follow Down on one rig for P1 only (not airborne, blocking or for P2), and the one player-feelable statement in the work — that a record carrying class 0x38 would have to be blocked low — is a reading of the guard's compare lists with that flag about a remap nobody built, with no hit of a 0x38 record against a standing guard run and no capture, used only to rule that remap out; tests/lua/read_tap.lua gained an opt-in RPCS read filter during this work, after reaction_class_live was frozen and verified (its other users are re-run separately); bases.tsv is derived from the merged image and its header, not this work, states its legacy rows equal pristine vsavj's; FBNeo was not run.
Artifacts (read every one, in full):
  - tools/audit_reaction_classes.py
  - tests/test_reaction_classes.sh
  - tests/expected/reaction_classes.tsv
  - build/rc169/static_freeze.log
  - build/rc169/static_verify.log
  - build/rc169/static_ctl_stager-38-copy.log
  - build/rc169/static_ctl_record-06-to-38.log
  - tests/audit_reaction_class_live.sh
  - tests/expected/reaction_class_live.tsv
  - build/rc169/live_freeze.log
  - build/rc169/live_verify.log
  - build/rc169/live_ctl_planted38.log
  - build/rc169/live_ctl_rangesilent.log
  - tests/audit_defense_row_reads.sh
  - tests/expected/defense_row_reads.tsv
  - build/rc169/defense_freeze.log
  - build/rc169/defense_verify.log
  - build/rc169/defense_ctl_planted.log
  - build/rc169/defense_ctl_range.log
  - tests/audit_crouch_flag.sh
  - tests/expected/crouch_flag.tsv
  - build/rc169/crouch_freeze.log
  - build/rc169/crouch_verify.log
  - build/rc169/crouch_ctl.log
  - tests/audit_df_modes.sh
  - tests/expected/df_modes.tsv
  - build/rc169/dfmodes_freeze.log
  - build/rc169/dfmodes_verify.log
  - build/rc169/dfmodes_ctl.log
  - tests/lua/read_tap.lua
  - tests/expected/roster_pairings/bases.tsv
