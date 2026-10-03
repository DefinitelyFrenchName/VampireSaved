THE PACKET

Decision kind: freeze
Subject: 14z-189 M22 freeze: registry rows donovan-m26 huitzil-m33 pyron-m27 merged-m22 (donovan-m25-stock and donovan-m23-stage4 carried) and their expectation sets (after runs 575-581)
Claim (the working agent's sentence): Freeze M22. REGISTRY: registry.diff adds donovan-m26, huitzil-m33, pyron-m27 and merged-m22 (whole-set keys 27e10352 / cc946f4d / a62e0fa0 / 797af4a5); the stock twin (program a3910ded) and the stage-4 image (2fa7c2f1) are unchanged and carry donovan-m25-stock and donovan-m23-stage4 (sets_and_fingerprints.txt). DELTA against M21 (deltas2.txt, opset_and_gain.txt): donovan +5 ops and 0 removed (#195's two sites, the pad and two thunks); huitzil 0 ops (the mark only); pyron +5 ops plus #194's byte inside a placed data file; merged 839 -> 844 with nine aligner pairings shown present on both sides and the pad as the tenth EDIT; the stock twin 0 ops. Every track rebuilds bit-exact (m3a_post.log PASS; phasec.log PASS; tenant_loop_post.log PASS with its re-pinned counts), all six program fingerprints are reproduced on ERIS, and the four expectation sets, frozen independently on ERIS, are byte-identical to the Mac's, as is the regenerated build/merged1 (sets_and_fingerprints.txt). SUITE: the four sets carried, frozen, verified and shape clean (suite_freeze_summary.txt). BATTERY (battery_eris_results.tsv, battery_mister_results.tsv): 13 reds in the emulator lanes and 1 in MiSTer, each attributed and re-frozen under rule-checker runs 2026-10-03-575 to -580 (ledger_575_580.tsv: 575-579 VIOLATED on true findings, each resolved; 580 OK; every plant CAUGHT): nine by their own FREEZE writers and the MiSTer pair from its lane's legs, every writer and verify PASS and the new control's mode FAILs the gate (refreeze_summary.txt), and four through the file they follow, bases.tsv for audit_roster_pairings, test_tenant_pairings and audit_defense_row_reads and move_parity_events.tsv for audit_rng_forms, each verify PASS (followers.txt). TIER at freeze cadence with every control executed (tier_freeze_m22.log): PASS 193, FAIL 5, 308 of 308 controls honoured; test_annotations_current is regenerated and passes, and the other four clear only by the freeze's own order (tier_reds_rerun.txt, staleness_mister.txt): the tags, this run's OK row, the GitHub closes the commit records, and a --stale MiSTer re-run on the committed tree. MISTER TAIL: the fork catalogue re-pointed (xml_check.txt: the pre-fix mismatch on the eight member CRCs; xml_check_post.txt: the entry now matches the build), patch 0038, PINNED bumped, MRAs regenerated and release/merged-m22 packaged (mra_m22.log, package_m22.log), tied to this build by its own content (the WIDE MRA's BUILD block and all three manifests name merged-m22, 797af4a5) and by test_release_roundtrip, test_mra_build_line, test_mra_parts, test_mister_mra_map and test_release_asset_shape PASS in the tier of record (release_tie.txt); the fork commit, PINNED, PATCH_NAMES and patch 0038, test_jtcores_twin PASS (jtcores_tail.txt). NOT TESTED: the tags and the commit themselves, which follow this check; the --stale MiSTer re-run and the tier on the committed tree, which follow the commit; the Linux release binaries (none exist for this freeze); FBNeo's full legacy track (accepted-and-deferred); audit_reaction_class_live's lost write run (6 -> 5) and test_mister_prg_window's blocks/cyc/rd_lo moves, recorded as measured, not explained.
Artifacts (read every one, in full):
  - build/rc189/freeze/registry.diff
  - build/rc189/freeze/sets_and_fingerprints.txt
  - build/rc189/freeze/deltas2.txt
  - build/rc189/freeze/opset_and_gain.txt
  - build/rc189/freeze/m3a_post.log
  - build/rc189/freeze/phasec.log
  - build/rc189/freeze/tenant_loop_post.log
  - build/rc189/freeze/suite_freeze_summary.txt
  - build/rc189/freeze/battery_eris_results.tsv
  - build/rc189/freeze/battery_mister_results.tsv
  - build/rc189/freeze/ledger_575_580.tsv
  - build/rc189/freeze/refreeze_summary.txt
  - build/rc189/freeze/followers.txt
  - build/rc189/freeze/tier_freeze_m22.log
  - build/rc189/freeze/tier_reds_rerun.txt
  - build/rc189/freeze/staleness_mister.txt
  - build/rc189/freeze/xml_check.txt
  - build/rc189/freeze/xml_check_post.txt
  - build/rc189/freeze/mra_m22.log
  - build/rc189/freeze/package_m22.log
  - build/rc189/freeze/release_tie.txt
  - build/rc189/freeze/jtcores_tail.txt
