THE PACKET

Decision kind: freeze
Subject: 14z-192: the M23 freeze (after runs 691-694)
Claim (the working agent's sentence): Freeze M23. REGISTRY: registry.diff adds donovan-m27, huitzil-m34, pyron-m28 and merged-m23 (whole-set keys a4c70276 / 51ee6a00 / 6e782cc8 / f601342d, programs 167d870f / cc9c4b68 / 9d135e7b / 6148d0b1); the stock twin (a3910ded) and the stage-4 image (2fa7c2f1) are unchanged and carry donovan-m25-stock and donovan-m23-stage4. DELTA against M22 as op sets (opset_delta.txt): donovan +2 (the two landing words 0441), huitzil +4 (0x022AF4 2811, 0x0BE25A 0018, the two landing words), pyron 0, stock 0, stage-4 0, merged 844 -> 848 (the same four, the landing pair deduped to one shared row each); members (member_delta.txt); the built images read site by site (check_built.txt). Every track rebuilds bit-exact on the final tree (m3a_final.log: six images reproduced, six whole-artifact manifests match), all six program fingerprints and all four expectation sets reproduced on ERIS, the sets differing between hosts only in one line of the merged README, the build dir its carry note names (sets_and_fingerprints.txt, sets_readme_diff.txt). SUITE: the four sets carried, frozen, verified and shape clean (freeze_sets.log). BATTERY (attr/battery_eris_results.tsv, attr/battery_mister_results.tsv): 10 reds in the emulator lanes and 1 in MiSTer, every one attributed (attr/battery_reds.txt) and re-frozen under rule-checker runs 2026-10-05-684 to -690 (684-689 VIOLATED on true findings, each resolved by a new measurement; 690 OK; every row and its resolution in ledger_684_691.tsv): six by their own FREEZE writers, the parity table by FREEZE=1 on the Mac, the MiSTer probe's frozen pair (one file, its pos and neg lines) from its lane's legs, two gates edited (010a -> 010b, #223 closing their documented pair), each verified by a re-run without FREEZE (refreeze_summary.txt), and the EDITED gates shown still to discriminate: on merged-m23 both PASS, on ctl_nolanding (the build without #223, landing words 0448) both FAIL on 010a, each leg stamped with its build (ring223c/); audit_landing_sound's dead control was our sweep's bump of a pinned CTL_BUILD, restored and PASS on both hosts; every line the sweep rewrote was audited three ways by sweep_provenance.py — blamed to the commit that introduced its token (362 of 375 to f3e32bd5, shown to be the M22 freeze commit, the other 13 reviewed), scanned for predecessor names, and every line authored in the uncommitted tree naming an M23 dir listed — with a positive control (run on the tree ERIS's battery ran, it lists the bumped CTL_BUILD) and every listed line of the real input reviewed: no other pinned control was bumped (sweep_provenance2.txt, sweep_provenance_control.txt, sweep_provenance_real.txt, sweep_provenance_review.txt); and, blind to blame, sweep_roles.py classifies the role of every added line naming an M23 dir (383: the variable, usage key, flag or default it sets), its positive control reporting CTL_BUILD on the battery-time tree and the real tree carrying no control, reference, old or before role that points at an M23 dir, all 119 non-standard or OTHER lines reviewed (sweep_roles_control.txt, sweep_roles_real.txt, sweep_roles_review.txt). STATIC TIER (mid-session form on the freeze tree, tier_mid_dispositions.txt, tier_mid_results.tsv): PASS 195, FAIL 10, SKIP 1, each red re-run alone and disposed of: audit_id_writers' missing FOLLOWS entries and MAME_BIN pin fixed (test_gate_follows and test_mame_bin_pinned PASS, the gate PASS with its control fired), two findings reworded (homes_tracked FAIL 0), and three static pins PROPOSED here for re-freeze — test_reaction_classes by FREEZE=1 (the build-identity row only), test_manifest_merge's code_word tuple to (12,12,12), 29, 6 (the M23 rows, the landing pair deduped), test_rule5_census by --freeze --allow-growth with a ledger row (6 new only_variant_slot instances) — while test_freeze_tag_coverage, test_rule_checker, test_annotations_current and test_bbh_fidelity (build names only in the bbh lineage copy) clear by the freeze's own order, and test_release_launcher_bat's Windows half runs on ERIS on the commit. MISTER TAIL: the fork catalogue re-pointed (fork commit 793339da), patch 0039, PINNED bumped, the catalogue check ok against the build, test_jtcores_twin PASS (jtcores_tail.txt); MRAs regenerated and release/merged-m23 packaged (mra_m23.log, package_m23.log), its three manifests and the WIDE MRA's BUILD block naming merged-m23 f601342d (release_tie_partial.txt). the #222/#223 rulings quoted in rulings_222_223.txt and the FBNeo track's status in fbneo_deferral_quote.txt. NOT TESTED: the Mac-frozen tables re-run on ERIS (on ERIS only audit_landing_sound was re-run after the fixes, and audit_defense_row_reads' battery table equals the Mac's); the three proposed static re-freezes, the annotations regeneration, the freeze-cadence static tier on the final tree, the freeze commit, the tags, the bbh lineage re-point and the Windows half on ERIS, which follow this check; a --stale re-run of any MiSTer gate whose followed files the re-freezes moved after the lane ran, which follows the commit; the Linux release binaries on ERIS (records only there, the two gates SKIPPED); FBNeo's full legacy track (accepted-and-deferred); how graphics bytes move the MiSTer probe's program-read counts; whether M22's unexplained probe move was its mark (not re-run).
Artifacts (read every one, in full):
  - build/agent192/m23/freeze/claim5.txt
  - build/agent192/m23/freeze/registry.diff
  - build/agent192/m23/opset_delta.txt
  - build/agent192/m23/member_delta.txt
  - build/agent192/m23/check_built.txt
  - build/agent192/m23/m3a_final.log
  - build/agent192/m23/freeze/sets_and_fingerprints.txt
  - build/agent192/m23/freeze/sets_readme_diff.txt
  - build/agent192/m23/freeze_sets.log
  - build/agent192/m23/attr/battery_eris_results.tsv
  - build/agent192/m23/attr/battery_mister_results.tsv
  - build/agent192/m23/attr/battery_reds.txt
  - build/agent192/m23/freeze/refreeze_summary.txt
  - build/agent192/m23/ring_leg.sh
  - build/agent192/m23/ring223c/electro_m3b_merged31.log
  - build/agent192/m23/ring223c/electro_ctl_nolanding.log
  - build/agent192/m23/ring223c/trap_m3b_merged31.log
  - build/agent192/m23/ring223c/trap_ctl_nolanding.log
  - build/agent192/m23/freeze/ledger_684_691.tsv
  - build/agent192/m23/sweep_apply.py
  - build/agent192/m23/freeze/sweep_provenance.py
  - build/agent192/m23/freeze/sweep_provenance2.txt
  - build/agent192/m23/freeze/sweep_provenance_control.txt
  - build/agent192/m23/freeze/sweep_provenance_real.txt
  - build/agent192/m23/freeze/sweep_provenance_review.txt
  - build/agent192/m23/freeze/sweep_roles.py
  - build/agent192/m23/freeze/sweep_roles_control.txt
  - build/agent192/m23/freeze/sweep_roles_real.txt
  - build/agent192/m23/freeze/sweep_roles_review.txt
  - build/agent192/m23/freeze/tier_mid_dispositions.txt
  - build/agent192/m23/freeze/tier_mid_results.tsv
  - build/agent192/m23/freeze/rule5_census.log
  - build/agent192/m23/freeze/reds/test_manifest_merge.log
  - build/agent192/m23/freeze/reds/test_reaction_classes.log
  - build/agent192/m23/freeze/reds/test_gate_follows.2.log
  - build/agent192/m23/freeze/reds/test_mame_bin_pinned.2.log
  - build/agent192/m23/freeze/reds/audit_id_writers.verify.log
  - build/agent192/m23/freeze/reds/test_bbh_fidelity.log
  - tests/audit_id_writers.sh
  - build/agent192/m23/landing_stamp/battery_time_ctl_build.txt
  - build/agent192/m23/landing_stamp/mac_restored.log
  - build/agent192/m23/landing_stamp/eris_restored.log
  - build/agent192/m23/freeze/jtcores_tail.txt
  - build/agent192/m23/mra_m23.log
  - build/agent192/m23/package_m23.log
  - build/agent192/m23/freeze/release_tie_partial.txt
  - build/agent192/m23/rulings_222_223.txt
  - build/agent192/m23/freeze/fbneo_deferral_quote.txt
  - tests/expected/registry.tsv
