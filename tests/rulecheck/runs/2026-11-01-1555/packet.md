THE PACKET

Decision kind: freeze
Subject: M24 freeze: registry rows donovan-m28 huitzil-m35 pyron-m29 merged-m24 and the evidence behind them
Claim (the working agent's sentence): Freeze M24: the four registry rows in registry_rows.txt (donovan-m28, huitzil-m35, pyron-m29, merged-m24) are the six builds' measured keys, reproduced on two machines (fingerprints_mac.txt = fingerprints_eris.txt on program and set key; the four expectation sets file-for-file equal, sets_mac_vs_eris.txt); every fixed site of the merged byte diff is explained (bytediff_fixed_review.txt; bytediff_head.txt is the frozen record's head); the freeze battery's reds were re-frozen and that re-freeze was checked OK (rulecheck_1554_verdicts.txt, verdict OK on the real packet; s2_results.tsv the verifying battery, its two FAILs re-frozen since and its four SKIPs host-covered); on snapshot S4 the gates staled after S2 re-ran green (eris_s4_stale_results.tsv: PASS 29, SKIP 4 host-only, FAIL 1 = audit_ladder_selector; mac_s4_results.tsv: test_mame_parity, test_release_binaries, test_readme_recording, test_mister_prg_window PASS); audit_ladder_selector's red was its frame-pinned saturation window left behind by M24's earlier match-2 selection (ladder/: control timeline the same 15 advances and stage set, 960 frames earlier on merged-m24; window moved by that amount, ladder_m24_fixed.log PASS with merged-m23's original reading, gate_diff.diff); the Linux release plays: audit_release_linux_desktop PASS on merged-m24 with the driver targeting the client window instead of its mutter frame (desktop/plain.log, its three CONTROL= modes FAIL; plain_framewindow_red.log the red before; tool_diff_vs_head.diff the one change), audit_release_linux_cleanhost PASS on merged-m24 (linux_cleanhost_merged-m24.log); the maintainer's rulings this freeze rests on are quoted in rulings.txt and maintainer_reading_345.txt. What this rests on that is NOT tested: (1) the final static freeze tier on the commit's tree has not run yet (it follows this check; the first tier, on S3, was red and its fixes are in the tree); (2) both concurrent-controls lists are being re-traced on PILOT and are not yet refreshed; (3) staleness_freeze_at_s4.txt still FAILs on two gates whose newest runner row is ERIS's host SKIP — audit_release_linux_desktop and audit_release_linux_cleanhost; their PASSes above are direct runs on PILOT, not runner rows, which are still to be recorded; the desktop run used PILOT's S2 checkout with S4's tool blob copied in (S2 to S4 changes none of the gate's other declared paths), the clean-host run S2; (4) nothing was run on hardware (the MiSTer .rbf is unchanged; no board test), no release is published, and the release-cadence gates (the Windows half of test_release_launcher_bat) are not part of a freeze; (5) the RNG-dependent rows of #345 are exempt by the maintainer's ruling and the lag frame is a ruled tradeoff (rulings.txt), not parity.
Artifacts (read every one, in full):
  - build/agent216/m24/rc_freeze/registry_rows.txt
  - build/agent216/m24/rc_freeze/fingerprints_mac.txt
  - build/agent216/m24/rc_freeze/fingerprints_eris.txt
  - build/agent216/m24/rc_freeze/sets_mac_vs_eris.txt
  - build/agent216/m24/rc_freeze/bytediff_fixed_review.txt
  - build/agent216/m24/rc_freeze/bytediff_head.txt
  - build/agent216/m24/rc_freeze/rulecheck_1554_verdicts.txt
  - build/agent216/m24/rc_freeze/s2_results.tsv
  - build/agent216/m24/rc_freeze/eris_s4_stale_results.tsv
  - build/agent216/m24/rc_freeze/mac_s4_results.tsv
  - build/agent216/m24/rc_freeze/staleness_freeze_at_s4.txt
  - build/agent216/m24/rc_freeze/ladder/ladder_m23.log
  - build/agent216/m24/rc_freeze/ladder/ladder_m24.log
  - build/agent216/m24/rc_freeze/ladder/ladder_m24_fixed.log
  - build/agent216/m24/rc_freeze/ladder/gate_diff.diff
  - build/agent216/m24/rc_freeze/desktop/plain.log
  - build/agent216/m24/rc_freeze/desktop/ctl_muted-stream.log
  - build/agent216/m24/rc_freeze/desktop/ctl_unlinked-recorder.log
  - build/agent216/m24/rc_freeze/desktop/ctl_wrong-mark.log
  - build/agent216/m24/rc_freeze/desktop/plain_framewindow_red.log
  - build/agent216/m24/rc_freeze/desktop/tool_diff_vs_head.diff
  - build/agent216/m24/rc_freeze/linux_cleanhost_merged-m24.log
  - build/agent216/m24/rc_freeze/rulings.txt
  - build/agent216/m24/rc_freeze/maintainer_reading_345.txt
